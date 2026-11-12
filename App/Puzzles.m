// Puzzles.m

#import "Puzzles.h"
#import "ChessBoard.h"
#import "ChessPiece.h"
#import "SettingsManager.h"
#import "YFUI.h"
#include "ChessEngine.h"
#include "ChessBot.h"
#include "ChessPuzzles.h"

// Puzzels per groep: 0 = mat in 1, 1 = mat in 2, 2 = eindspel (vind de zetten), 3 = eindspel tegen de bot.
static NSInteger PuzzleGroup(const CPPuzzle *p) {
    if (p->type == CP_MATE) return p->n == 1 ? 0 : 1;
    if (p->type == CP_LINE) return 2;
    return 3;
}

static NSArray *PuzzleIndexesInGroup(NSInteger group) {
    NSMutableArray *a = [NSMutableArray array];
    for (int i = 0; i < cp_count(); i++) {
        if (PuzzleGroup(cp_get(i)) == group) [a addObject:@(i)];
    }
    return a;
}

// Alle puzzels in de volgorde van de lijst.
static NSArray *AllPuzzlesInOrder(void) {
    NSMutableArray *a = [NSMutableArray array];
    for (NSInteger g = 0; g < 4; g++) [a addObjectsFromArray:PuzzleIndexesInGroup(g)];
    return a;
}

static NSString *DifficultyText(int rating) {
    if (rating <= 0) return nil;
    if (rating < 1000) return @"\u2605 makkelijk";
    if (rating < 1300) return @"\u2605\u2605 gemiddeld";
    return @"\u2605\u2605\u2605 moeilijk";
}

static int SquareFromText(const char *s) {
    if (!s || s[0] < 'a' || s[0] > 'h' || s[1] < '1' || s[1] > '8') return -1;
    return (s[1] - '1') * 8 + (s[0] - 'a');
}

static NSString *PuzzleFEN(int index) {
    const CPPuzzle *p = cp_get(index);
    return p ? [NSString stringWithUTF8String:p->fen] : @"";
}

#pragma mark - Lijst

@implementation PuzzleListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Puzzels";
    self.tableView.rowHeight = [YFUI isPad] ? 60 : 50;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [YFUI applyThemeToController:self];
    self.tableView.backgroundColor = [SettingsManager shared].backgroundColor;
    self.tableView.backgroundView = nil;
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)PuzzleIndexesInGroup(section).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *idx = PuzzleIndexesInGroup(section);
    NSInteger solved = 0;
    for (NSNumber *n in idx) if ([[SettingsManager shared] isPuzzleSolved:PuzzleFEN(n.intValue)]) solved++;
    NSString *name = section == 0 ? @"Mat in 1" : section == 1 ? @"Mat in 2"
                   : section == 2 ? @"Eindspel: vind de juiste zetten" : @"Eindspel: zet mat tegen de bot";
    return [NSString stringWithFormat:@"%@ (%ld van %lu opgelost)", name, (long)solved, (unsigned long)idx.count];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 2) return @"Vind steeds de beste zet. De tegenstander antwoordt vanzelf. De oranje markering is de laatste zet van je tegenstander.";
    if (section == 3) return @"Hier speel je tegen de bot. Zet mat binnen het aantal zetten.";
    if (section == 1) return @"Mat-puzzels en eindspel-reeksen (behalve de eerste) komen uit de openbare lichess-puzzeldatabase.";
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]])
        ((UITableViewHeaderFooterView *)view).textLabel.textColor = [SettingsManager shared].secondaryTextColor;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]])
        ((UITableViewHeaderFooterView *)view).textLabel.textColor = [SettingsManager shared].secondaryTextColor;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pz"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"pz"];
    SettingsManager *s = [SettingsManager shared];
    int index = [PuzzleIndexesInGroup(indexPath.section)[indexPath.row] intValue];
    const CPPuzzle *p = cp_get(index);
    BOOL solved = [s isPuzzleSolved:PuzzleFEN(index)];
    CEPosition pos;
    ce_from_fen(&pos, p->fen);
    cell.backgroundColor = s.panelColor;
    cell.textLabel.textColor = s.textColor;
    cell.detailTextLabel.textColor = s.secondaryTextColor;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:[YFUI isPad] ? 19 : 16];
    cell.textLabel.text = [NSString stringWithFormat:@"%ld. %@%@", (long)indexPath.row + 1,
                           [NSString stringWithUTF8String:p->title], solved ? @"  ✓" : @""];
    NSString *who = pos.side == CE_WHITE ? @"Wit" : @"Zwart";
    NSString *detail;
    if (p->type == CP_MATE) detail = [NSString stringWithFormat:@"%@ aan zet \u2022 mat in %d", who, p->n];
    else if (p->type == CP_LINE) detail = [NSString stringWithFormat:@"%@ aan zet \u2022 %d zetten vinden", who, p->n];
    else detail = [NSString stringWithFormat:@"%@ aan zet \u2022 mat binnen %d zetten", who, p->n];
    NSString *diff = DifficultyText(p->rating);
    if (diff) detail = [detail stringByAppendingFormat:@" \u2022 %@", diff];
    cell.detailTextLabel.text = detail;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    int index = [PuzzleIndexesInGroup(indexPath.section)[indexPath.row] intValue];
    [self.navigationController pushViewController:[[PuzzleViewController alloc] initWithPuzzleIndex:index] animated:YES];
}

@end

#pragma mark - Puzzel oplossen

@interface PuzzleViewController () <ChessBoardViewDelegate>
@end

@implementation PuzzleViewController {
    int _index;
    const CPPuzzle *_puzzle;
    CEPosition _start;
    CEPosition _pos;
    CEPosition _beforeTry;
    NSMutableData *_hashes;
    int _userColor;
    int _movesLeft;      // mat: zetten tot mat; eindspel: zetten over
    int _movesUsed;
    BOOL _busy;
    BOOL _done;
    int _hintLevel;
    int _selected;
    int _lastFrom, _lastTo;
    NSUInteger _generation;
    NSArray *_lineMoves;   // CP_LINE: oplossing
    NSUInteger _step;      // volgende zet in de oplossing
    ChessBoardView *_board;
    UIView *_panel;
    UILabel *_taskLabel;
    UILabel *_feedbackLabel;
    YFButton *_hintButton;
    YFButton *_retryButton;
    YFButton *_nextButton;
    YFButton *_flipButton;
}

- (instancetype)initWithPuzzleIndex:(int)index {
    self = [super init];
    if (self) {
        _index = index;
        _puzzle = cp_get(index);
        if (!_puzzle) { _index = 0; _puzzle = cp_get(0); }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _board = [[ChessBoardView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
    _board.delegate = self;
    [self.view addSubview:_board];
    _panel = [[UIView alloc] init];
    _panel.layer.cornerRadius = 10;
    [self.view addSubview:_panel];
    CGFloat fs = [YFUI isPad] ? 20 : 16;
    _taskLabel = [YFUI labelWithSize:fs bold:YES];
    _taskLabel.textAlignment = NSTextAlignmentCenter;
    [_panel addSubview:_taskLabel];
    _feedbackLabel = [YFUI labelWithSize:fs - 1 bold:NO];
    _feedbackLabel.textAlignment = NSTextAlignmentCenter;
    [_panel addSubview:_feedbackLabel];
    _hintButton = [YFUI buttonWithTitle:@"\U0001F4A1 Tip" target:self action:@selector(hintTapped)];
    _retryButton = [YFUI buttonWithTitle:@"↻ Opnieuw" target:self action:@selector(retryTapped)];
    _nextButton = [YFUI buttonWithTitle:@"Volgende ▶" target:self action:@selector(nextTapped)];
    _flipButton = [YFUI buttonWithTitle:@"⇅ Draai bord" target:self action:@selector(flipTapped)];
    for (UIView *b in @[_hintButton, _retryButton, _nextButton, _flipButton]) [_panel addSubview:b];
    [self loadPuzzle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    SettingsManager *s = [SettingsManager shared];
    [YFUI applyThemeToController:self];
    _panel.backgroundColor = s.panelColor;
    _taskLabel.textColor = s.textColor;
    for (YFButton *b in @[_hintButton, _retryButton, _nextButton, _flipButton]) [b applyTheme];
    _board.showCoordinates = s.showCoordinates;
    [_board refreshTheme];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _generation++;   // lopende bot-zet negeren
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width, H = self.view.bounds.size.height;
    CGFloat top = self.topLayoutGuide.length + 10, bottom = self.bottomLayoutGuide.length + 10;
    CGFloat availH = H - top - bottom, m = 10;
    CGRect pf;
    if (W > H * 1.05) {
        CGFloat size = floor(MIN(availH, W * 0.62) / 8.0) * 8.0;
        _board.frame = CGRectMake(m, top + (availH - size) / 2.0, size, size);
        CGFloat px = CGRectGetMaxX(_board.frame) + m;
        pf = CGRectMake(px, top, W - px - m, availH);
    } else {
        CGFloat size = floor(MIN(W - 2 * m, availH * 0.64) / 8.0) * 8.0;
        _board.frame = CGRectMake((W - size) / 2.0, top, size, size);
        CGFloat py = CGRectGetMaxY(_board.frame) + m;
        pf = CGRectMake(m, py, W - 2 * m, H - bottom - py);
    }
    _panel.frame = pf;
    CGFloat pw = pf.size.width, pad = 12;
    CGFloat y = pad;
    CGSize ts = [_taskLabel sizeThatFits:CGSizeMake(pw - 2 * pad, 400)];
    _taskLabel.frame = CGRectMake(pad, y, pw - 2 * pad, ceil(ts.height)); y += ceil(ts.height) + 10;
    CGSize fsz = [_feedbackLabel sizeThatFits:CGSizeMake(pw - 2 * pad, 400)];
    CGFloat fh = MAX(ceil(fsz.height), [YFUI isPad] ? 60 : 44);
    _feedbackLabel.frame = CGRectMake(pad, y, pw - 2 * pad, fh); y += fh + 12;
    CGFloat bh = [YFUI isPad] ? 54 : 44;
    [YFUI layoutViews:@[_hintButton, _retryButton, _nextButton, _flipButton] x:pad y:y width:pw - 2 * pad
           itemHeight:bh columns:2 spacing:8];
}

#pragma mark - Puzzel

- (void)loadPuzzle {
    _generation++;
    ce_from_fen(&_start, _puzzle->fen);
    _pos = _start;
    _userColor = _start.side;
    _movesLeft = _puzzle->n;
    _movesUsed = 0;
    _busy = NO;
    _done = NO;
    _hintLevel = 0;
    _selected = -1;
    _lastFrom = _lastTo = -1;
    if (_puzzle->last && strlen(_puzzle->last) >= 4) {
        _lastFrom = SquareFromText(_puzzle->last);
        _lastTo = SquareFromText(_puzzle->last + 2);
    }
    _step = 0;
    _lineMoves = (_puzzle->type == CP_LINE && _puzzle->line)
        ? [[NSString stringWithUTF8String:_puzzle->line] componentsSeparatedByString:@" "] : @[];
    _hashes = [NSMutableData dataWithBytes:&_pos.hash length:sizeof(uint64_t)];
    [_board setFlipped:_userColor == CE_BLACK animated:NO];
    int number = 0;
    NSInteger groupNr = PuzzleGroup(_puzzle);
    NSArray *group = PuzzleIndexesInGroup(groupNr);
    for (NSUInteger i = 0; i < group.count; i++) if ([group[i] intValue] == _index) number = (int)i + 1;
    NSString *kind = groupNr == 0 ? @"Mat in 1" : groupNr == 1 ? @"Mat in 2" : @"Eindspel";
    self.title = [NSString stringWithFormat:@"%@ • %d", kind, number];
    [self updateTask];
    [self setFeedback:@"Tik op een stuk en dan op een veld." color:nil];
    [_nextButton setPrimary:NO];
    [self render:-1 to:-1];
}

- (NSString *)colorName {
    return _userColor == CE_WHITE ? @"Wit" : @"Zwart";
}

- (void)updateTask {
    NSString *t;
    if (_puzzle->type == CP_MATE) {
        if (_movesLeft == 1) t = [NSString stringWithFormat:@"%@ aan zet: geef mat in 1 zet.", [self colorName]];
        else t = [NSString stringWithFormat:@"%@ aan zet: geef mat in %d zetten.", [self colorName], _movesLeft];
    } else if (_puzzle->type == CP_LINE) {
        int mine = (int)(_step / 2) + 1;
        if (mine > _puzzle->n) mine = _puzzle->n;
        t = [NSString stringWithFormat:@"%@ \u2022 %@ aan zet: vind de beste zet (%d van %d).",
             [NSString stringWithUTF8String:_puzzle->title], [self colorName], mine, _puzzle->n];
    } else {
        t = [NSString stringWithFormat:@"%@: zet mat tegen de bot. Nog %d zetten over.",
             [NSString stringWithUTF8String:_puzzle->title], _movesLeft];
    }
    _taskLabel.text = t;
    [self.view setNeedsLayout];
}

- (void)setFeedback:(NSString *)text color:(UIColor *)color {
    _feedbackLabel.text = text;
    _feedbackLabel.textColor = color ? color : [SettingsManager shared].secondaryTextColor;
    [self.view setNeedsLayout];
}

- (void)render:(int)from to:(int)to {
    _board.lastFrom = _lastFrom;
    _board.lastTo = _lastTo;
    _board.selectedSquare = _selected;
    _board.targetSquares = @[];
    _board.checkSquare = ce_in_check(&_pos, _pos.side) ? ce_king_square(&_pos, _pos.side) : -1;
    BOOL anim = [SettingsManager shared].animations && from >= 0;
    [_board setBoard:_pos.board animatedFrom:anim ? from : -1 to:to];
}

- (void)applyMove:(CEMove)m {
    ce_make(&_pos, m);
    [_hashes appendBytes:&_pos.hash length:sizeof(uint64_t)];
    _lastFrom = m.from;
    _lastTo = m.to;
    _selected = -1;
    [self render:m.from to:m.to];
}

- (void)solved {
    _done = YES;
    [[SettingsManager shared] markPuzzleSolved:[NSString stringWithUTF8String:_puzzle->fen]];
    [self setFeedback:@"★ Opgelost! Goed gedaan." color:[SettingsManager shared].okColor];
    [_nextButton setPrimary:YES];
    if ([SettingsManager shared].animations) {
        _feedbackLabel.transform = CGAffineTransformMakeScale(0.6, 0.6);
        [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.45 initialSpringVelocity:0.9 options:0 animations:^{
            self->_feedbackLabel.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)failed:(NSString *)text {
    _done = YES;
    [self setFeedback:[text stringByAppendingString:@" Tik op Opnieuw om het nog eens te proberen."]
                color:[SettingsManager shared].errorColor];
}

- (void)wrongMove:(CEMove)m {
    // Fout: laat de zet even zien en zet hem dan terug.
    _beforeTry = _pos;
    int oldFrom = _lastFrom, oldTo = _lastTo;
    [self applyMove:m];
    _busy = YES;
    [self setFeedback:@"Helaas, dat is niet de oplossing. Probeer het nog eens." color:[SettingsManager shared].errorColor];
    NSUInteger gen = ++_generation;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (gen != self->_generation) return;
        self->_pos = self->_beforeTry;
        self->_hashes.length = self->_hashes.length - sizeof(uint64_t);
        self->_lastFrom = oldFrom;
        self->_lastTo = oldTo;
        self->_busy = NO;
        [self render:-1 to:-1];
    });
}

- (BOOL)lineMove:(NSString *)uci into:(CEMove *)out {
    return ce_parse_uci(&_pos, uci.UTF8String, out) != 0;
}

- (void)userLineMove:(CEMove)m {
    NSString *expected = _step < _lineMoves.count ? _lineMoves[_step] : nil;
    char buf[8];
    ce_move_to_uci(m, buf, sizeof buf);
    NSString *played = [NSString stringWithUTF8String:buf];
    CEPosition after = _pos;
    ce_make(&after, m);
    CEMove tmp[CE_MAX_MOVES];
    BOOL mates = ce_gen_legal(&after, tmp) == 0 && ce_in_check(&after, after.side);
    if (![played isEqualToString:expected] && !mates) {
        [self wrongMove:m];
        return;
    }
    [self applyMove:m];
    _step++;
    if (mates || _step >= _lineMoves.count) {
        [self solved];
        return;
    }
    [self updateTask];
    [self setFeedback:@"Goed zo! De tegenstander antwoordt\u2026" color:[SettingsManager shared].okColor];
    _busy = YES;
    NSUInteger gen = ++_generation;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (gen != self->_generation) return;
        CEMove reply;
        if (self->_step < self->_lineMoves.count && [self lineMove:self->_lineMoves[self->_step] into:&reply]) {
            [self applyMove:reply];
            self->_step++;
        }
        self->_busy = NO;
        [self updateTask];
        [self setFeedback:@"Goed zo! Zoek nu de volgende zet." color:[SettingsManager shared].okColor];
    });
}

- (void)userMove:(CEMove)m {
    _hintLevel = 0;
    if (_puzzle->type == CP_LINE) {
        [self userLineMove:m];
        return;
    }
    if (_puzzle->type == CP_MATE) {
        if (!cb_move_mates_within(&_pos, m, _movesLeft)) {
            // Fout: laat de zet even zien en zet hem dan terug.
            _beforeTry = _pos;
            [self applyMove:m];
            _busy = YES;
            [self setFeedback:@"Helaas, dat is niet de oplossing. Probeer het nog eens." color:[SettingsManager shared].errorColor];
            NSUInteger gen = ++_generation;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (gen != self->_generation) return;
                self->_pos = self->_beforeTry;
                self->_hashes.length = self->_hashes.length - sizeof(uint64_t);
                self->_lastFrom = self->_lastTo = -1;
                self->_busy = NO;
                [self render:-1 to:-1];
            });
            return;
        }
        [self applyMove:m];
        CEMove dummy[CE_MAX_MOVES];
        if (ce_gen_legal(&_pos, dummy) == 0) {
            [self solved];
            return;
        }
        _movesLeft--;
        [self updateTask];
        [self setFeedback:[NSString stringWithFormat:@"Goed zo! Nu nog mat in %d.", _movesLeft] color:[SettingsManager shared].okColor];
        // De tegenstander verdedigt zo goed mogelijk.
        _busy = YES;
        NSUInteger gen = ++_generation;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (gen != self->_generation) return;
            CEMove d;
            if (cb_best_defense(&self->_pos, self->_movesLeft, &d)) [self applyMove:d];
            self->_busy = NO;
        });
        return;
    }
    // Eindspel tegen de bot.
    [self applyMove:m];
    _movesUsed++;
    _movesLeft--;
    [self updateTask];
    if ([self checkEndgameState]) return;
    if (_movesLeft <= 0) {
        [self failed:@"De zetten zijn op en het is nog geen mat."];
        return;
    }
    _busy = YES;
    [self setFeedback:@"De bot denkt na…" color:nil];
    NSUInteger gen = ++_generation;
    CEPosition p = _pos;
    NSData *hist = [_hashes copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CEMove reply;
        int ok = cb_choose_move(&p, (const uint64_t *)hist.bytes, (int)(hist.length / sizeof(uint64_t)), 4, &reply, NULL);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (gen != self->_generation) return;
            self->_busy = NO;
            if (ok) [self applyMove:reply];
            if (![self checkEndgameState])
                [self setFeedback:[NSString stringWithFormat:@"Jij bent aan zet. Nog %d zetten.", self->_movesLeft] color:nil];
        });
    });
}

// Geeft YES als het eindspel voorbij is (gewonnen of mislukt).
- (BOOL)checkEndgameState {
    CEStatus st = ce_status(&_pos, (const uint64_t *)_hashes.bytes, (int)(_hashes.length / sizeof(uint64_t)));
    switch (st) {
        case CE_ONGOING: return NO;
        case CE_CHECKMATE:
            if (_pos.side != _userColor) [self solved];
            else [self failed:@"Jij staat mat!"];
            return YES;
        case CE_STALEMATE: [self failed:@"Pat! Dat is remise. Laat de koning altijd een veld over."]; return YES;
        case CE_DRAW_MATERIAL: [self failed:@"Remise: er is te weinig materiaal over om mat te zetten."]; return YES;
        case CE_DRAW_REPETITION: [self failed:@"Remise door herhaling van zetten."]; return YES;
        case CE_DRAW_FIFTY: [self failed:@"Remise door de 50-zettenregel."]; return YES;
    }
    return NO;
}

#pragma mark - Bord

- (void)boardView:(ChessBoardView *)board didTapSquare:(int)sq {
    if (_done || _busy || _pos.side != _userColor) return;
    if (_selected >= 0) {
        CEMove mv[CE_MAX_MOVES];
        int n = ce_gen_legal(&_pos, mv);
        BOOL legal = NO, promo = NO;
        for (int i = 0; i < n; i++) {
            if (mv[i].from == _selected && mv[i].to == sq) {
                legal = YES;
                if (mv[i].flags & CE_FLAG_PROMO) promo = YES;
            }
        }
        if (legal) {
            int from = _selected;
            _selected = -1;
            _board.selectedSquare = -1;
            _board.targetSquares = @[];
            if (promo) [self askPromotionFrom:from to:sq];
            else {
                CEMove m;
                if (ce_find_move(&_pos, from, sq, 0, &m)) [self userMove:m];
            }
            return;
        }
    }
    uint8_t pc = _pos.board[sq];
    if (pc && CE_COLOR(pc) == _userColor && sq != _selected) {
        _selected = sq;
        _board.selectedSquare = sq;
        NSMutableArray *t = [NSMutableArray array];
        if ([SettingsManager shared].showLegalMoves) {
            CEMove mv[CE_MAX_MOVES];
            int n = ce_gen_legal(&_pos, mv);
            for (int i = 0; i < n; i++)
                if (mv[i].from == sq && ![t containsObject:@(mv[i].to)]) [t addObject:@(mv[i].to)];
        }
        _board.targetSquares = t;
    } else {
        _selected = -1;
        _board.selectedSquare = -1;
        _board.targetSquares = @[];
    }
}

- (void)askPromotionFrom:(int)from to:(int)to {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Promotie" message:@"Waar moet je pion in veranderen?"
                                                        preferredStyle:UIAlertControllerStyleAlert];
    int types[4] = { CE_QUEEN, CE_ROOK, CE_BISHOP, CE_KNIGHT };
    for (int i = 0; i < 4; i++) {
        int t = types[i];
        NSString *title = [NSString stringWithFormat:@"%@  %@", [ChessPiece textGlyphForPiece:CE_PIECE(_userColor, t)],
                           [ChessPiece dutchNameForType:t]];
        [a addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
            CEMove m;
            if (ce_find_move(&self->_pos, from, to, t, &m)) [self userMove:m];
        }]];
    }
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

#pragma mark - Knoppen

- (void)hintTapped {
    if (_done || _busy) return;
    NSString *tip = [NSString stringWithUTF8String:_puzzle->hint];
    if (_puzzle->type == CP_ENDGAME || _hintLevel == 0) {
        _hintLevel = 1;
        [self setFeedback:[@"Tip: " stringByAppendingString:tip] color:nil];
        return;
    }
    CEMove m;
    if (_puzzle->type == CP_LINE) {
        if (_step >= _lineMoves.count || ![self lineMove:_lineMoves[_step] into:&m]) return;
    } else if (!cb_find_mate_move(&_pos, _movesLeft, &m)) return;
    if (_hintLevel == 1) {
        _hintLevel = 2;
        _selected = m.from;
        _board.selectedSquare = m.from;
        _board.targetSquares = @[];
        [self setFeedback:@"Tip: speel met het blauw gemarkeerde stuk. Tik nog eens op Tip voor de hele zet." color:nil];
    } else {
        _selected = m.from;
        _board.selectedSquare = m.from;
        _board.targetSquares = @[@(m.to)];
        char san[16];
        ce_move_to_san(&_pos, m, san, sizeof san);
        [self setFeedback:[NSString stringWithFormat:@"Oplossing: %@",
                           [ChessPiece figurineSAN:[NSString stringWithUTF8String:san]]] color:nil];
    }
}

- (void)retryTapped {
    [self loadPuzzle];
}

- (void)nextTapped {
    NSArray *order = AllPuzzlesInOrder();
    NSUInteger pos = [order indexOfObject:@(_index)];
    int next = (pos == NSNotFound || pos + 1 >= order.count) ? [order.firstObject intValue] : [order[pos + 1] intValue];
    _index = next;
    _puzzle = cp_get(next);
    [self loadPuzzle];
}

- (void)flipTapped {
    [_board setFlipped:!_board.flipped animated:[SettingsManager shared].animations];
}

@end
