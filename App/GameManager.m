// GameManager.m

#import "GameManager.h"
#include "ChessBot.h"

// Een vlag die de bot op een andere thread leest om te stoppen.
@interface BotCancelToken : NSObject {
@public
    volatile int flag;
}
@end
@implementation BotCancelToken
@end

@implementation GameManager {
    CEPosition _pos;
    CEPosition _initial;
    NSMutableArray *_records;   // per halve zet: positie ervoor, notatie, geslagen stuk, van/naar
    NSMutableData *_hashes;     // Zobrist-sleutels van alle stellingen
    BotCancelToken *_token;
    NSUInteger _generation;
    dispatch_queue_t _analysisQueue;
}

- (instancetype)initWithFEN:(NSString *)fen mode:(GameMode)mode humanColor:(int)humanColor botLevel:(NSInteger)level {
    self = [super init];
    if (self) {
        ce_init();
        if (!fen.length || !ce_from_fen(&_initial, fen.UTF8String)) ce_start(&_initial);
        _mode = mode;
        _humanColor = humanColor;
        _botLevel = level;
        _analysisQueue = dispatch_queue_create("nl.yf.chess.analyse", DISPATCH_QUEUE_SERIAL);
        [self resetToInitial];
    }
    return self;
}

- (void)dealloc {
    if (_token) _token->flag = 1;
}

- (void)cancelAnalyses {
    for (NSDictionary *r in _records) {
        BotCancelToken *t = r[@"token"];
        if (t) t->flag = 1;
    }
}

- (void)resetToInitial {
    [self stopBot];
    [self cancelAnalyses];
    _pos = _initial;
    _records = [NSMutableArray array];
    _hashes = [NSMutableData dataWithBytes:&_pos.hash length:sizeof(uint64_t)];
    _lastFrom = -1;
    _lastTo = -1;
    _startFullmove = _initial.fullmove;
    _startSide = _initial.side;
    [self updateStatus];
}

- (CEPosition)position { return _pos; }
- (NSUInteger)plyCount { return _records.count; }

- (void)updateStatus {
    _status = ce_status(&_pos, (const uint64_t *)_hashes.bytes, (int)(_hashes.length / sizeof(uint64_t)));
}

- (NSArray *)sanMoves {
    NSMutableArray *a = [NSMutableArray arrayWithCapacity:_records.count];
    for (NSDictionary *r in _records) [a addObject:r[@"san"]];
    return a;
}

- (NSArray *)capturedByColor:(int)color {
    NSMutableArray *a = [NSMutableArray array];
    for (NSDictionary *r in _records) {
        int cap = [r[@"cap"] intValue];
        if (cap && CE_COLOR(cap) != color) [a addObject:@(cap)];
    }
    return a;
}

- (NSArray *)legalTargetsFrom:(int)square {
    CEMove mv[CE_MAX_MOVES];
    int n = ce_gen_legal(&_pos, mv);
    NSMutableArray *a = [NSMutableArray array];
    for (int i = 0; i < n; i++) {
        if (mv[i].from != square) continue;
        NSNumber *t = @(mv[i].to);
        if (![a containsObject:t]) [a addObject:t];
    }
    return a;
}

- (BOOL)isPromotionFrom:(int)from to:(int)to {
    CEMove m;
    if (!ce_find_move(&_pos, from, to, CE_QUEEN, &m)) return NO;
    return (m.flags & CE_FLAG_PROMO) != 0;
}

- (BOOL)isHumanTurn {
    if (_mode == GameModeLocal) return YES;
    return _pos.side == _humanColor;
}

- (BOOL)isGameOver {
    return _status != CE_ONGOING;
}

- (void)applyMove:(CEMove)m {
    char san[16];
    ce_move_to_san(&_pos, m, san, sizeof san);
    uint8_t captured = (m.flags & CE_FLAG_EP) ? CE_PIECE(_pos.side ^ 1, CE_PAWN) : _pos.board[m.to];
    NSData *before = [NSData dataWithBytes:&_pos length:sizeof(CEPosition)];
    NSMutableDictionary *rec = [@{ @"pos": before,
                                   @"san": [NSString stringWithUTF8String:san],
                                   @"cap": @(captured),
                                   @"from": @(m.from),
                                   @"to": @(m.to),
                                   @"color": @(_pos.side) } mutableCopy];
    [_records addObject:rec];
    if (_ratingEnabled && (_mode == GameModeLocal || _pos.side == _humanColor)) {
        [self analyseRecord:rec before:_pos move:m history:[_hashes copy]];
    }
    ce_make(&_pos, m);
    [_hashes appendBytes:&_pos.hash length:sizeof(uint64_t)];
    _lastFrom = m.from;
    _lastTo = m.to;
    [self updateStatus];
    if (self.onChange) self.onChange(self, m.from, m.to);
    [self startBotIfNeeded];
}

- (void)analyseRecord:(NSMutableDictionary *)rec before:(CEPosition)before move:(CEMove)m history:(NSData *)hist {
    BotCancelToken *token = [[BotCancelToken alloc] init];
    rec[@"token"] = token;
    rec[@"pending"] = @YES;
    __weak GameManager *weakSelf = self;
    dispatch_async(_analysisQueue, ^{
        CBMoveAnalysis a;
        memset(&a, 0, sizeof(a));
        int ok = 0;
        if (!token->flag)
            ok = cb_analyse_move(&before, (const uint64_t *)hist.bytes, (int)(hist.length / sizeof(uint64_t)),
                                 m, 3, &a, &token->flag);
        NSString *bestSan = nil;
        if (ok && a.rating != CB_RATE_BEST && a.rating != CB_RATE_FORCED) {
            char buf[16];
            ce_move_to_san(&before, a.best, buf, sizeof buf);
            bestSan = [NSString stringWithUTF8String:buf];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [rec removeObjectForKey:@"pending"];
            [rec removeObjectForKey:@"token"];
            GameManager *me = weakSelf;
            if (!me || !ok || token->flag) return;
            if ([me->_records indexOfObjectIdenticalTo:rec] == NSNotFound) return;
            rec[@"rating"] = @(a.rating);
            if (a.rating != CB_RATE_FORCED) rec[@"loss"] = @(a.winLoss);
            if (bestSan) rec[@"best"] = bestSan;
            if (me.onRatingChange) me.onRatingChange(me);
        });
    });
}

- (NSDictionary *)recordAtPly:(NSUInteger)ply {
    return ply < _records.count ? _records[ply] : nil;
}

- (double)accuracyForColor:(int)color count:(int *)count {
    double sum = 0;
    int n = 0;
    for (NSDictionary *r in _records) {
        NSNumber *loss = r[@"loss"];
        if (!loss || [r[@"color"] intValue] != color) continue;
        sum += cb_move_accuracy(loss.doubleValue);
        n++;
    }
    if (count) *count = n;
    return n ? sum / n : 0;
}

- (BOOL)makeMoveFrom:(int)from to:(int)to promotion:(int)promoType {
    if ([self isGameOver] || ![self isHumanTurn] || _botThinking) return NO;
    CEMove m;
    if (!ce_find_move(&_pos, from, to, promoType ? promoType : CE_QUEEN, &m)) return NO;
    [self applyMove:m];
    return YES;
}

- (BOOL)canUndo {
    return _records.count > 0;
}

- (void)popRecord {
    NSDictionary *r = _records.lastObject;
    if (!r) return;
    BotCancelToken *t = r[@"token"];
    if (t) t->flag = 1;
    [r[@"pos"] getBytes:&_pos length:sizeof(CEPosition)];
    [_records removeLastObject];
    _hashes.length = _hashes.length - sizeof(uint64_t);
}

- (void)undo {
    [self stopBot];
    if (!_records.count) return;
    [self popRecord];
    // Tegen de bot: terug tot jij weer aan zet bent.
    if (_mode == GameModeBot) {
        while (_records.count && _pos.side != _humanColor) [self popRecord];
    }
    NSDictionary *last = _records.lastObject;
    _lastFrom = last ? [last[@"from"] intValue] : -1;
    _lastTo = last ? [last[@"to"] intValue] : -1;
    [self updateStatus];
    if (self.onChange) self.onChange(self, -1, -1);
    [self startBotIfNeeded];
}

- (void)restart {
    [self resetToInitial];
    if (self.onChange) self.onChange(self, -1, -1);
    [self startBotIfNeeded];
}

- (void)stopBot {
    if (_token) _token->flag = 1;
    _token = nil;
    _generation++;
    if (_botThinking) {
        _botThinking = NO;
        if (self.onThinkingChange) self.onThinkingChange(self);
    }
}

- (void)startBotIfNeeded {
    if (_mode != GameModeBot || [self isGameOver] || _pos.side == _humanColor || _botThinking) return;
    _botThinking = YES;
    if (self.onThinkingChange) self.onThinkingChange(self);
    NSUInteger gen = ++_generation;
    BotCancelToken *token = [[BotCancelToken alloc] init];
    _token = token;
    CEPosition pos = _pos;
    NSData *hist = [_hashes copy];
    int level = (int)_botLevel;
    NSTimeInterval started = [NSDate timeIntervalSinceReferenceDate];
    __weak GameManager *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CEMove move;
        int ok = cb_choose_move(&pos, (const uint64_t *)hist.bytes, (int)(hist.length / sizeof(uint64_t)),
                                level, &move, &token->flag);
        // Even wachten zodat de bot niet "onmiddellijk" terugslaat.
        NSTimeInterval spent = [NSDate timeIntervalSinceReferenceDate] - started;
        double wait = spent < 0.45 ? 0.45 - spent : 0.0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(wait * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            GameManager *me = weakSelf;
            if (!me || token->flag || gen != me->_generation) return;
            me->_botThinking = NO;
            me->_token = nil;
            if (me.onThinkingChange) me.onThinkingChange(me);
            if (ok) [me applyMove:move];
        });
    });
}

- (NSString *)colorName:(int)c {
    return c == CE_WHITE ? @"Wit" : @"Zwart";
}

- (NSString *)resultTitle {
    switch (_status) {
        case CE_CHECKMATE: {
            int winner = _pos.side ^ 1;
            if (_mode == GameModeBot) return winner == _humanColor ? @"Schaakmat! Jij wint!" : @"Schaakmat. De bot wint.";
            return [NSString stringWithFormat:@"Schaakmat! %@ wint.", [self colorName:winner]];
        }
        case CE_STALEMATE: return @"Pat: remise.";
        case CE_DRAW_FIFTY: return @"Remise (50-zettenregel).";
        case CE_DRAW_REPETITION: return @"Remise (3 keer dezelfde stelling).";
        case CE_DRAW_MATERIAL: return @"Remise (te weinig stukken om mat te zetten).";
        default: return @"";
    }
}

- (NSString *)statusText {
    if ([self isGameOver]) return [self resultTitle];
    BOOL check = ce_in_check(&_pos, _pos.side);
    NSString *who;
    if (_botThinking) who = @"De bot denkt na…";
    else if (_mode == GameModeBot) who = [NSString stringWithFormat:@"Jij bent aan zet (%@)", [self colorName:_humanColor]];
    else who = [NSString stringWithFormat:@"%@ is aan zet", [self colorName:_pos.side]];
    if (check) return [who stringByAppendingString:@" — Schaak!"];
    return who;
}

@end
