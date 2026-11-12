// Puzzles.m
// YF Schaak - puzzellijst, puzzels oplossen en gratis extra puzzels downloaden van lichess.org.

#import "Puzzles.h"
#import "ChessBoard.h"
#import "ChessPiece.h"
#import "SettingsManager.h"
#import "LichessClient.h"
#import "YFUI.h"
#include "ChessEngine.h"
#include "ChessBot.h"
#include "ChessPuzzles.h"
#include "ChessEndgame.h"

// Soorten: 0 = mat in 1, 1 = mat in 2, 2 = eindspel (winnen tegen de bot).
static const NSUInteger kMaxDownloaded = 2000;

#pragma mark - Puzzelgegevens

@interface PuzzleItem : NSObject
@property (nonatomic) int type;          // CP_MATE, CP_ENDGAME of CP_LINE
@property (nonatomic) int n;
@property (nonatomic) int rating;
@property (nonatomic, copy) NSString *fen;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *hint;
@property (nonatomic, copy) NSString *line;
@property (nonatomic, copy) NSString *last;
@property (nonatomic, copy) NSString *puzzleId;
@property (nonatomic) BOOL downloaded;
- (NSInteger)group;
- (NSDictionary *)dictionary;
+ (instancetype)itemWithDictionary:(NSDictionary *)d;
@end

@implementation PuzzleItem

- (NSInteger)group {
    if (self.type == CP_MATE) return self.n == 1 ? 0 : 1;
    if (self.type == CP_ENDGAME) return 2;
    return -1;   // oude soort (zettenreeks): wordt niet meer getoond
}

- (NSDictionary *)dictionary {
    NSMutableDictionary *d = [@{ @"type": @(self.type), @"n": @(self.n), @"rating": @(self.rating),
                                 @"fen": self.fen ?: @"", @"title": self.title ?: @"", @"hint": self.hint ?: @"" } mutableCopy];
    if (self.line) d[@"line"] = self.line;
    if (self.last) d[@"last"] = self.last;
    if (self.puzzleId) d[@"id"] = self.puzzleId;
    return d;
}

+ (instancetype)itemWithDictionary:(NSDictionary *)d {
    if (![d isKindOfClass:[NSDictionary class]] || ![d[@"fen"] isKindOfClass:[NSString class]]) return nil;
    PuzzleItem *p = [[PuzzleItem alloc] init];
    p.type = [d[@"type"] intValue];
    p.n = [d[@"n"] intValue];
    p.rating = [d[@"rating"] intValue];
    p.fen = d[@"fen"];
    p.title = d[@"title"];
    p.hint = d[@"hint"];
    p.line = [d[@"line"] isKindOfClass:[NSString class]] ? d[@"line"] : nil;
    p.last = [d[@"last"] isKindOfClass:[NSString class]] ? d[@"last"] : nil;
    p.puzzleId = d[@"id"];
    p.downloaded = YES;
    if (p.n < 1) p.n = 1;
    return p;
}

@end

static NSString *CStr(const char *s) {
    return s ? [NSString stringWithUTF8String:s] : nil;
}

static NSArray *BuiltinItems(void) {
    static NSArray *items = nil;
    if (!items) {
        NSMutableArray *a = [NSMutableArray array];
        for (int i = 0; i < cp_count(); i++) {
            const CPPuzzle *c = cp_get(i);
            if (c->type == CP_LINE) continue;
            PuzzleItem *p = [[PuzzleItem alloc] init];
            p.type = c->type;
            p.n = c->n;
            p.rating = c->rating;
            p.fen = CStr(c->fen);
            p.title = CStr(c->title);
            p.hint = CStr(c->hint);
            p.line = CStr(c->line);
            p.last = CStr(c->last);
            [a addObject:p];
        }
        items = a;
    }
    return items;
}

#pragma mark - Opslag van gedownloade puzzels

@interface PuzzleStore : NSObject
+ (NSArray *)downloadedItems;
+ (NSUInteger)addItems:(NSArray *)items;   // geeft het aantal nieuwe terug
+ (void)removeItemWithFEN:(NSString *)fen;
+ (void)removeAll;
+ (void)removeGroup:(NSInteger)group;
@end

@implementation PuzzleStore

static NSMutableArray *gDownloaded = nil;

+ (NSString *)path {
    NSString *dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [dir stringByAppendingPathComponent:@"gedownloade_puzzels.json"];
}

+ (void)loadIfNeeded {
    if (gDownloaded) return;
    gDownloaded = [NSMutableArray array];
    NSData *data = [NSData dataWithContentsOfFile:[self path]];
    NSArray *arr = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    if (![arr isKindOfClass:[NSArray class]]) return;
    for (NSDictionary *d in arr) {
        PuzzleItem *p = [PuzzleItem itemWithDictionary:d];
        if (p && p.group >= 0) [gDownloaded addObject:p];
    }
}

+ (void)save {
    NSMutableArray *arr = [NSMutableArray array];
    for (PuzzleItem *p in gDownloaded) [arr addObject:[p dictionary]];
    NSData *data = [NSJSONSerialization dataWithJSONObject:arr options:0 error:nil];
    [data writeToFile:[self path] atomically:YES];
}

+ (NSArray *)downloadedItems {
    [self loadIfNeeded];
    return [gDownloaded copy];
}

+ (NSUInteger)addItems:(NSArray *)items {
    [self loadIfNeeded];
    NSMutableSet *seen = [NSMutableSet set];
    for (PuzzleItem *p in gDownloaded) {
        if (p.puzzleId) [seen addObject:p.puzzleId];
        [seen addObject:p.fen];
    }
    for (PuzzleItem *p in BuiltinItems()) [seen addObject:p.fen];
    NSUInteger added = 0;
    for (PuzzleItem *p in items) {
        if ((p.puzzleId && [seen containsObject:p.puzzleId]) || [seen containsObject:p.fen]) continue;
        if (gDownloaded.count >= kMaxDownloaded) break;
        [gDownloaded addObject:p];
        if (p.puzzleId) [seen addObject:p.puzzleId];
        [seen addObject:p.fen];
        added++;
    }
    if (added) [self save];
    return added;
}

+ (void)removeItemWithFEN:(NSString *)fen {
    [self loadIfNeeded];
    for (NSUInteger i = 0; i < gDownloaded.count; i++) {
        if ([[gDownloaded[i] fen] isEqualToString:fen]) { [gDownloaded removeObjectAtIndex:i]; break; }
    }
    [self save];
}

+ (void)removeAll {
    [self loadIfNeeded];
    [gDownloaded removeAllObjects];
    [self save];
}

+ (void)removeGroup:(NSInteger)group {
    [self loadIfNeeded];
    NSMutableArray *keep = [NSMutableArray array];
    for (PuzzleItem *p in gDownloaded) if (p.group != group) [keep addObject:p];
    gDownloaded = keep;
    [self save];
}

@end

// Ingebouwde puzzels van deze soort, met de gedownloade/gemaakte erachter.
static NSArray *ItemsInGroup(NSInteger group) {
    NSMutableArray *a = [NSMutableArray array];
    for (PuzzleItem *p in BuiltinItems()) if (p.group == group) [a addObject:p];
    for (PuzzleItem *p in [PuzzleStore downloadedItems]) if (p.group == group) [a addObject:p];
    return a;
}

static NSString *DifficultyText(int rating) {
    if (rating <= 0) return nil;
    if (rating < 1000) return @"★ makkelijk";
    if (rating < 1300) return @"★★ gemiddeld";
    if (rating < 1800) return @"★★★ moeilijk";
    return @"★★★★ heel moeilijk";
}

static int SquareFromText(const char *s) {
    if (!s || s[0] < 'a' || s[0] > 'h' || s[1] < '1' || s[1] > '8') return -1;
    return (s[1] - '1') * 8 + (s[0] - 'a');
}

static NSString *GroupName(NSInteger g) {
    switch (g) {
        case 0: return @"Mat in 1";
        case 1: return @"Mat in 2";
        default: return @"Eindspel";
    }
}

#pragma mark - Lichess-puzzels omzetten

static NSString *TitleForThemes(NSArray *themes) {
    NSArray *table = @[
        @[@"mateIn1", @"Mat in 1"], @[@"mateIn2", @"Mat in 2"], @[@"mateIn3", @"Mat in 3"],
        @[@"smotheredMate", @"Stikmat"], @[@"backRankMate", @"Achterste rij"],
        @[@"pawnEndgame", @"Pioneneindspel"], @[@"rookEndgame", @"Toreneindspel"], @[@"queenEndgame", @"Dame-eindspel"],
        @[@"knightEndgame", @"Paardeneindspel"], @[@"bishopEndgame", @"Lopereindspel"], @[@"queenRookEndgame", @"Dame en toren"],
        @[@"endgame", @"Eindspel"], @[@"fork", @"Vork"], @[@"pin", @"Penning"], @[@"skewer", @"Spies"],
        @[@"sacrifice", @"Offer"], @[@"promotion", @"Promotie"], @[@"discoveredAttack", @"Aftrekaanval"],
        @[@"hangingPiece", @"Onbeschermd stuk"], @[@"opening", @"Opening"], @[@"middlegame", @"Middenspel"] ];
    for (NSArray *t in table) if ([themes containsObject:t[0]]) return t[1];
    return @"Puzzel";
}

static NSString *HintForThemes(NSArray *themes) {
    NSArray *table = @[
        @[@"mateIn1", @"Zoek een schaak die geen vluchtveld overlaat."],
        @[@"mateIn2", @"Begin met een sterke schaak of een stille dreiging."],
        @[@"promotion", @"Kan er een pion promoveren?"], @[@"fork", @"Zoek een vork: val twee stukken tegelijk aan."],
        @[@"skewer", @"Zoek een spies: val een stuk aan met een ander stuk erachter."], @[@"pin", @"Gebruik een penning."],
        @[@"discoveredAttack", @"Zet een stuk opzij zodat een ander stuk aanvalt."],
        @[@"hangingPiece", @"Er staat iets onbeschermd."], @[@"sacrifice", @"Durf iets te offeren."],
        @[@"deflection", @"Lok een verdediger weg."], @[@"zugzwang", @"Soms is wachten het sterkst."],
        @[@"advancedPawn", @"Er staat een pion ver naar voren. Gebruik hem."], @[@"backRankMate", @"De koning zit vast op de achterste rij."] ];
    for (NSArray *t in table) if ([themes containsObject:t[0]]) return t[1];
    return @"Zoek de sterkste zet: eerst schaak, slaan of dreigen.";
}

// Zet een puzzel uit de lichess-API om. Geeft nil als iets niet klopt.
static PuzzleItem *ItemFromLichess(NSDictionary *entry) {
    NSDictionary *pz = entry[@"puzzle"], *game = entry[@"game"];
    if (![pz isKindOfClass:[NSDictionary class]] || ![game isKindOfClass:[NSDictionary class]]) return nil;
    NSString *pgn = game[@"pgn"];
    NSArray *solution = pz[@"solution"];
    if (![pgn isKindOfClass:[NSString class]] || ![solution isKindOfClass:[NSArray class]] || !solution.count) return nil;
    NSInteger initialPly = [pz[@"initialPly"] integerValue];
    NSMutableArray *tokens = [NSMutableArray array];
    for (NSString *t in [pgn componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]) {
        if (!t.length || [t rangeOfString:@"."].location != NSNotFound) continue;
        [tokens addObject:t];
    }
    if ((NSInteger)tokens.count < initialPly + 1) return nil;
    CEPosition p;
    ce_start(&p);
    NSString *last = nil;
    for (NSInteger i = 0; i <= initialPly; i++) {
        CEMove m;
        if (!ce_parse_san(&p, [tokens[i] UTF8String], &m)) return nil;
        char buf[8];
        ce_move_to_uci(m, buf, sizeof buf);
        last = [NSString stringWithUTF8String:buf];
        ce_make(&p, m);
    }
    char fen[128];
    ce_to_fen(&p, fen, sizeof fen);
    // Oplossing controleren.
    CEPosition q = p;
    for (NSString *u in solution) {
        CEMove m;
        if (![u isKindOfClass:[NSString class]] || !ce_parse_uci(&q, u.UTF8String, &m)) return nil;
        ce_make(&q, m);
    }
    NSArray *themes = [pz[@"themes"] isKindOfClass:[NSArray class]] ? pz[@"themes"] : @[];
    PuzzleItem *item = [[PuzzleItem alloc] init];
    item.fen = [NSString stringWithUTF8String:fen];
    item.puzzleId = pz[@"id"];
    item.rating = [pz[@"rating"] intValue];
    item.last = last;
    item.line = [solution componentsJoinedByString:@" "];
    item.title = TitleForThemes(themes);
    item.hint = HintForThemes(themes);
    item.downloaded = YES;
    int mine = (int)(solution.count + 1) / 2;
    if ([themes containsObject:@"mateIn1"] && mine == 1) { item.type = CP_MATE; item.n = 1; }
    else if ([themes containsObject:@"mateIn2"] && mine == 2) { item.type = CP_MATE; item.n = 2; }
    else return nil;   // alleen mat-puzzels
    return item;
}

#pragma mark - Downloaden / nieuwe eindspelen maken

@interface PuzzleDownloadViewController : UIViewController
@property (nonatomic) NSInteger category;   // 0 mat in 1, 1 mat in 2, 2 eindspel
@end

@implementation PuzzleDownloadViewController {
    UIScrollView *_scroll;
    UILabel *_info;
    UILabel *_kindLabel, *_levelLabel, *_countLabel;
    UISegmentedControl *_kind, *_level, *_egKind, *_count;
    YFButton *_downloadButton;
    YFButton *_deleteButton;
    UILabel *_status;
    UIActivityIndicatorView *_spinner;
    BOOL _busy;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Meer puzzels";
    CGFloat fs = [YFUI isPad] ? 18 : 15;
    _scroll = [[UIScrollView alloc] init];
    _scroll.alwaysBounceVertical = YES;
    [self.view addSubview:_scroll];
    _info = [YFUI labelWithSize:fs bold:NO];
    _kindLabel = [YFUI labelWithSize:fs bold:YES];
    _kindLabel.text = @"Soort:";
    _kind = [[UISegmentedControl alloc] initWithItems:@[@"Mat in 1", @"Mat in 2", @"Eindspel"]];
    _kind.selectedSegmentIndex = MAX(0, MIN(2, self.category));
    [_kind addTarget:self action:@selector(kindChanged) forControlEvents:UIControlEventValueChanged];
    _levelLabel = [YFUI labelWithSize:fs bold:YES];
    _level = [[UISegmentedControl alloc] initWithItems:@[@"Heel makkelijk", @"Makkelijk", @"Normaal", @"Moeilijk"]];
    _level.selectedSegmentIndex = 1;
    _egKind = [[UISegmentedControl alloc] initWithItems:@[@"Gemengd", @"Dame", @"Toren", @"Pion", @"2 torens", @"Lopers", @"D-stuk"]];
    _egKind.selectedSegmentIndex = 0;
    _countLabel = [YFUI labelWithSize:fs bold:YES];
    _countLabel.text = @"Hoeveel?";
    _count = [[UISegmentedControl alloc] initWithItems:@[@"10", @"25", @"50"]];
    _count.selectedSegmentIndex = 0;
    _downloadButton = [YFUI buttonWithTitle:@"" target:self action:@selector(downloadTapped)];
    _downloadButton.primary = YES;
    _deleteButton = [YFUI buttonWithTitle:@"Alle extra puzzels van deze soort verwijderen" target:self action:@selector(deleteTapped)];
    _status = [YFUI labelWithSize:fs bold:YES];
    _status.textAlignment = NSTextAlignmentCenter;
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.hidesWhenStopped = YES;
    for (UIView *v in @[_info, _kindLabel, _kind, _levelLabel, _level, _egKind, _countLabel, _count, _downloadButton, _spinner, _status, _deleteButton])
        [_scroll addSubview:v];
    [self kindChanged];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [YFUI applyThemeToController:self];
    SettingsManager *s = [SettingsManager shared];
    for (UILabel *l in @[_info, _kindLabel, _levelLabel, _countLabel, _status]) l.textColor = s.textColor;
    for (UISegmentedControl *c in @[_kind, _level, _egKind, _count]) c.tintColor = s.accentColor;
    [_downloadButton applyTheme];
    [_deleteButton applyTheme];
    _spinner.color = s.accentColor;
}

- (BOOL)isEndgame {
    return _kind.selectedSegmentIndex == 2;
}

- (NSUInteger)extraCount {
    NSUInteger n = 0;
    for (PuzzleItem *p in [PuzzleStore downloadedItems]) if (p.group == _kind.selectedSegmentIndex) n++;
    return n;
}

- (void)kindChanged {
    BOOL eg = [self isEndgame];
    _level.hidden = eg;
    _egKind.hidden = !eg;
    _levelLabel.text = eg ? @"Welke stukken?" : @"Moeilijkheid:";
    [_downloadButton setTitle:eg ? @"➕ Nieuwe eindspelen maken" : @"⬇ Gratis downloaden van lichess"
                     forState:UIControlStateNormal];
    _status.text = @"";
    [self updateInfo];
}

- (void)updateInfo {
    NSUInteger n = [self extraCount];
    if ([self isEndgame]) {
        _info.text = [NSString stringWithFormat:
            @"De app maakt zelf nieuwe eindspelen met weinig stukken waarin jij kunt winnen. "
            @"Hier is geen internet voor nodig. Elke stelling wordt gecontroleerd: bij koning + pion met een "
            @"volledig uitgerekende tabel, bij de andere soorten met de bot.\n\n"
            @"“D-stuk” = dame tegen paard of loper. Je hebt nu %lu extra eindspelen.", (unsigned long)n];
    } else {
        _info.text = [NSString stringWithFormat:
            @"Haal gratis echte puzzels op van lichess.org (wifi nodig, geen account). "
            @"Ze worden op deze iPad bewaard en werken daarna ook zonder internet.\n\n"
            @"Je hebt nu %lu extra puzzels van deze soort.", (unsigned long)n];
    }
    _deleteButton.enabled = n > 0;
    [self.view setNeedsLayout];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width;
    _scroll.frame = self.view.bounds;
    CGFloat colW = MIN(W - 32, 600), x = (W - colW) / 2.0;
    CGFloat y = self.topLayoutGuide.length + 16;
    CGFloat bh = [YFUI isPad] ? 60 : 50;
    _kindLabel.frame = CGRectMake(x, y, colW, 26); y += 30;
    _kind.frame = CGRectMake(x, y, colW, 36); y += 50;
    CGSize s = [_info sizeThatFits:CGSizeMake(colW, 1000)];
    _info.frame = CGRectMake(x, y, colW, ceil(s.height)); y += ceil(s.height) + 16;
    _levelLabel.frame = CGRectMake(x, y, colW, 26); y += 30;
    _level.frame = CGRectMake(x, y, colW, 36);
    _egKind.frame = CGRectMake(x, y, colW, 36); y += 50;
    _countLabel.frame = CGRectMake(x, y, colW, 26); y += 30;
    _count.frame = CGRectMake(x, y, colW, 36); y += 50;
    _downloadButton.frame = CGRectMake(x, y, colW, bh); y += bh + 12;
    _spinner.center = CGPointMake(W / 2.0, y + 14); y += 32;
    CGSize ss = [_status sizeThatFits:CGSizeMake(colW, 400)];
    _status.frame = CGRectMake(x, y, colW, MAX(24, ceil(ss.height))); y += MAX(24, ceil(ss.height)) + 24;
    _deleteButton.frame = CGRectMake(x, y, colW, bh * 0.8); y += bh;
    _scroll.contentSize = CGSizeMake(W, y + 20);
}

- (void)setBusy:(BOOL)busy text:(NSString *)text {
    _busy = busy;
    _downloadButton.enabled = !busy;
    _kind.enabled = !busy;
    if (busy) [_spinner startAnimating]; else [_spinner stopAnimating];
    _status.textColor = [SettingsManager shared].textColor;
    _status.text = text;
    [self.view setNeedsLayout];
}

- (void)downloadTapped {
    if (_busy) return;
    NSArray *counts = @[@10, @25, @50];
    NSInteger nb = [counts[MAX(0, _count.selectedSegmentIndex)] integerValue];
    if ([self isEndgame]) {
        [self makeEndgames:nb];
        return;
    }
    NSString *angle = _kind.selectedSegmentIndex == 0 ? @"mateIn1" : @"mateIn2";
    NSArray *levels = @[@"easiest", @"easier", @"normal", @"harder"];
    NSString *level = levels[MAX(0, _level.selectedSegmentIndex)];
    [self setBusy:YES text:@"Downloaden…"];
    NSString *path = [NSString stringWithFormat:@"/api/puzzle/batch/%@?nb=%ld&difficulty=%@", angle, (long)nb, level];
    __weak PuzzleDownloadViewController *weakSelf = self;
    [[LichessClient shared] publicRequest:path completion:^(NSInteger status, id json, NSString *errorText) {
        NSArray *list = [json isKindOfClass:[NSDictionary class]] ? json[@"puzzles"] : nil;
        if (errorText || ![list isKindOfClass:[NSArray class]]) {
            [weakSelf finishWithText:errorText ?: @"Lichess gaf een onverwacht antwoord." ok:NO];
            return;
        }
        // Omzetten op de achtergrond (notatie lezen kost even tijd op een oude iPad).
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *items = [NSMutableArray array];
            NSUInteger bad = 0;
            for (NSDictionary *entry in list) {
                PuzzleItem *it = [entry isKindOfClass:[NSDictionary class]] ? ItemFromLichess(entry) : nil;
                if (it) [items addObject:it]; else bad++;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUInteger added = [PuzzleStore addItems:items];
                NSUInteger dup = items.count - added;
                NSMutableString *t = [NSMutableString stringWithFormat:@"✓ %lu nieuwe puzzels toegevoegd.", (unsigned long)added];
                if (dup) [t appendFormat:@" %lu had je al.", (unsigned long)dup];
                if (bad) [t appendFormat:@" %lu overgeslagen.", (unsigned long)bad];
                [weakSelf finishWithText:t ok:YES];
            });
        });
    }];
}

- (void)makeEndgames:(NSInteger)count {
    int kind = (int)_egKind.selectedSegmentIndex;   // zelfde volgorde als EG_MIX, EG_QUEEN, ...
    [self setBusy:YES text:@"Eindspelen maken en controleren…"];
    __weak PuzzleDownloadViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        uint32_t seed = (uint32_t)([NSDate timeIntervalSinceReferenceDate] * 1000.0) ^ arc4random();
        NSMutableArray *items = [NSMutableArray array];
        static const int ratings[EG_KIND_COUNT] = { 1000, 700, 900, 1100, 600, 1500, 1100 };
        for (NSInteger i = 0; i < count; i++) {
            CEPosition p;
            int limit = 30;
            const char *title = NULL, *hint = NULL;
            int k = kind;
            if (k == EG_MIX) k = 1 + (int)(arc4random_uniform(EG_KIND_COUNT - 1));
            if (!ce_generate_endgame(k, &seed, &p, &limit, &title, &hint)) continue;
            char fen[128];
            ce_to_fen(&p, fen, sizeof fen);
            PuzzleItem *it = [[PuzzleItem alloc] init];
            it.type = CP_ENDGAME;
            it.n = limit;
            it.fen = [NSString stringWithUTF8String:fen];
            it.title = CStr(title);
            it.hint = CStr(hint);
            it.rating = ratings[k];
            it.downloaded = YES;
            [items addObject:it];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUInteger added = [PuzzleStore addItems:items];
            [weakSelf finishWithText:[NSString stringWithFormat:@"✓ %lu nieuwe eindspelen gemaakt.", (unsigned long)added] ok:YES];
        });
    });
}

- (void)finishWithText:(NSString *)text ok:(BOOL)ok {
    [self setBusy:NO text:text];
    SettingsManager *s = [SettingsManager shared];
    _status.textColor = ok ? s.okColor : s.errorColor;
    [self updateInfo];
}

- (void)deleteTapped {
    NSInteger cat = _kind.selectedSegmentIndex;
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Verwijderen?"
                                                               message:@"Alle extra puzzels van deze soort worden van deze iPad verwijderd. De ingebouwde puzzels blijven."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Verwijderen" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *act) {
        [PuzzleStore removeGroup:cat];
        self->_status.text = @"Verwijderd.";
        [self updateInfo];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

@end

#pragma mark - Startscherm met drie vakjes

@interface PuzzleViewController ()
- (instancetype)initWithItems:(NSArray *)items index:(NSUInteger)index;
@end

@interface PuzzleCategoryViewController : UITableViewController
@property (nonatomic) NSInteger category;
@end

// Een groot vakje om aan te tikken.
@interface PuzzleTile : UIControl
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *countLabel;
@end

@implementation PuzzleTile
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 16;
        _iconLabel = [[UILabel alloc] init];
        _nameLabel = [[UILabel alloc] init];
        _countLabel = [[UILabel alloc] init];
        for (UILabel *l in @[_iconLabel, _nameLabel, _countLabel]) {
            l.textAlignment = NSTextAlignmentCenter;
            l.adjustsFontSizeToFitWidth = YES;
            l.minimumScaleFactor = 0.5;
            l.userInteractionEnabled = NO;
            [self addSubview:l];
        }
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize s = self.bounds.size;
    CGFloat h = s.height;
    _iconLabel.font = [UIFont systemFontOfSize:MIN(h * 0.38, s.width * 0.3)];
    _nameLabel.font = [UIFont boldSystemFontOfSize:MIN(h * 0.14, 28)];
    _countLabel.font = [UIFont systemFontOfSize:MIN(h * 0.09, 18)];
    _iconLabel.frame = CGRectMake(8, h * 0.06, s.width - 16, h * 0.46);
    _nameLabel.frame = CGRectMake(8, h * 0.54, s.width - 16, h * 0.2);
    _countLabel.frame = CGRectMake(8, h * 0.75, s.width - 16, h * 0.16);
}
- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.alpha = highlighted ? 0.6 : 1.0;
}
@end

@implementation PuzzleHomeViewController {
    NSArray *_tiles;
    UILabel *_intro;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Puzzels";
    _intro = [YFUI labelWithSize:[YFUI isPad] ? 18 : 15 bold:NO];
    _intro.textAlignment = NSTextAlignmentCenter;
    _intro.text = @"Kies wat je wilt oefenen.";
    [self.view addSubview:_intro];
    NSMutableArray *tiles = [NSMutableArray array];
    NSArray *icons = @[@"♛", @"♜", @"♚"];
    NSArray *names = @[@"Mat in 1", @"Mat in 2", @"Eindspel"];
    for (NSInteger i = 0; i < 3; i++) {
        PuzzleTile *t = [[PuzzleTile alloc] initWithFrame:CGRectZero];
        t.tag = i;
        t.iconLabel.text = icons[i];
        t.nameLabel.text = names[i];
        [t addTarget:self action:@selector(tileTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:t];
        [tiles addObject:t];
    }
    _tiles = tiles;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [YFUI applyThemeToController:self];
    SettingsManager *s = [SettingsManager shared];
    _intro.textColor = s.secondaryTextColor;
    NSArray *subs = @[@"zet mat in één zet", @"zet mat in twee zetten", @"win met weinig stukken"];
    for (PuzzleTile *t in _tiles) {
        NSArray *items = ItemsInGroup(t.tag);
        NSInteger solved = 0;
        for (PuzzleItem *p in items) if ([s isPuzzleSolved:p.fen]) solved++;
        t.backgroundColor = t.tag == 0 ? s.accentColor : s.buttonColor;
        UIColor *fg = t.tag == 0 ? (s.darkTheme ? [UIColor colorWithWhite:0.1 alpha:1] : [UIColor whiteColor]) : s.buttonTextColor;
        t.iconLabel.textColor = fg;
        t.nameLabel.textColor = fg;
        t.countLabel.textColor = fg;
        t.countLabel.text = [NSString stringWithFormat:@"%@ • %ld van %lu opgelost", subs[t.tag], (long)solved, (unsigned long)items.count];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width, H = self.view.bounds.size.height;
    CGFloat top = self.topLayoutGuide.length + 12, bottom = self.bottomLayoutGuide.length + 16;
    _intro.frame = CGRectMake(16, top, W - 32, 26);
    top += 36;
    CGFloat m = 16, gap = 14;
    CGFloat availH = H - top - bottom;
    if (W > H) {
        CGFloat w = (W - 2 * m - 2 * gap) / 3.0;
        CGFloat h = MIN(availH, w * 1.15);
        CGFloat y = top + (availH - h) / 2.0;
        for (NSInteger i = 0; i < 3; i++) [_tiles[i] setFrame:CGRectMake(m + i * (w + gap), y, w, h)];
    } else {
        CGFloat w = MIN(W - 2 * m, 560);
        CGFloat h = MIN((availH - 2 * gap) / 3.0, w * 0.6);
        CGFloat y = top + (availH - (3 * h + 2 * gap)) / 2.0;
        for (NSInteger i = 0; i < 3; i++) [_tiles[i] setFrame:CGRectMake((W - w) / 2.0, y + i * (h + gap), w, h)];
    }
}

- (void)tileTapped:(PuzzleTile *)t {
    PuzzleCategoryViewController *list = [[PuzzleCategoryViewController alloc] initWithStyle:UITableViewStyleGrouped];
    list.category = t.tag;
    [self.navigationController pushViewController:list animated:YES];
}

@end

#pragma mark - Lijst van een soort

@implementation PuzzleCategoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = GroupName(self.category);
    self.tableView.rowHeight = [YFUI isPad] ? 60 : 50;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [YFUI applyThemeToController:self];
    self.tableView.backgroundColor = [SettingsManager shared].backgroundColor;
    self.tableView.backgroundView = nil;
    [self buildHeader];
    [self.tableView reloadData];
}

- (void)buildHeader {
    CGFloat w = self.tableView.bounds.size.width;
    CGFloat bh = [YFUI isPad] ? 58 : 50;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, bh + 24)];
    NSString *title = self.category == 2 ? @"➕ Meer eindspelen maken (gratis)" : @"⬇ Meer puzzels downloaden (gratis)";
    YFButton *b = [YFUI buttonWithTitle:title target:self action:@selector(moreTapped)];
    b.primary = YES;
    CGFloat colW = MIN(w - 32, 560);
    b.frame = CGRectMake((w - colW) / 2.0, 14, colW, bh);
    b.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [header addSubview:b];
    self.tableView.tableHeaderView = header;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self buildHeader];
    }];
}

- (void)moreTapped {
    PuzzleDownloadViewController *d = [[PuzzleDownloadViewController alloc] init];
    d.category = self.category;
    [self.navigationController pushViewController:d animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)ItemsInGroup(self.category).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *items = ItemsInGroup(self.category);
    NSInteger solved = 0;
    for (PuzzleItem *p in items) if ([[SettingsManager shared] isPuzzleSolved:p.fen]) solved++;
    return [NSString stringWithFormat:@"%ld van %lu opgelost", (long)solved, (unsigned long)items.count];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (self.category == 2)
        return @"Je speelt tegen de bot en moet winnen: zet mat binnen het aantal zetten. Remise of pat telt niet. "
               @"De ingebouwde eindspelen zijn gecontroleerd met de eindspel-database (tablebase) van lichess.";
    return @"Puzzels met ⬇ heb je zelf gedownload; veeg naar links om ze te verwijderen.";
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
    cell.backgroundColor = s.panelColor;
    cell.textLabel.textColor = s.textColor;
    cell.detailTextLabel.textColor = s.secondaryTextColor;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:[YFUI isPad] ? 19 : 16];
    NSArray *items = ItemsInGroup(self.category);
    PuzzleItem *p = items[indexPath.row];
    BOOL solved = [s isPuzzleSolved:p.fen];
    BOOL black = [p.fen rangeOfString:@" b "].location != NSNotFound;
    cell.textLabel.text = [NSString stringWithFormat:@"%ld. %@%@%@", (long)indexPath.row + 1,
                           p.downloaded ? @"⬇ " : @"", p.title, solved ? @"  ✓" : @""];
    NSString *who = black ? @"Zwart" : @"Wit";
    NSString *detail;
    if (p.type == CP_MATE) detail = [NSString stringWithFormat:@"%@ aan zet • mat in %d", who, p.n];
    else detail = [NSString stringWithFormat:@"Jij speelt %@ • win binnen %d zetten", black ? @"zwart" : @"wit", p.n];
    NSString *diff = DifficultyText(p.rating);
    if (diff) detail = [detail stringByAppendingFormat:@" • %@", diff];
    cell.detailTextLabel.text = detail;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *items = ItemsInGroup(self.category);
    return indexPath.row < (NSInteger)items.count && [items[indexPath.row] downloaded];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Verwijder";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
    forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;
    NSArray *items = ItemsInGroup(self.category);
    if (indexPath.row >= (NSInteger)items.count || ![items[indexPath.row] downloaded]) return;
    [PuzzleStore removeItemWithFEN:[items[indexPath.row] fen]];
    [tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *items = ItemsInGroup(self.category);
    if (indexPath.row >= (NSInteger)items.count) return;
    [self.navigationController pushViewController:[[PuzzleViewController alloc] initWithItems:items index:indexPath.row]
                                         animated:YES];
}

@end

#pragma mark - Puzzel oplossen

@interface PuzzleViewController () <ChessBoardViewDelegate>
@end

@implementation PuzzleViewController {
    NSArray *_items;
    NSUInteger _index;
    PuzzleItem *_puzzle;
    CEPosition _start;
    CEPosition _pos;
    CEPosition _beforeTry;
    NSMutableData *_hashes;
    int _userColor;
    int _movesLeft;      // mat: zetten tot mat; eindspel: zetten over
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

- (instancetype)initWithItems:(NSArray *)items index:(NSUInteger)index {
    self = [super init];
    if (self) {
        _items = items.count ? items : BuiltinItems();
        _index = index < _items.count ? index : 0;
        _puzzle = _items[_index];
    }
    return self;
}

- (instancetype)initWithPuzzleIndex:(int)index {
    NSArray *all = BuiltinItems();
    return [self initWithItems:all index:(index >= 0 && index < (int)all.count) ? (NSUInteger)index : 0];
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
    if (!ce_from_fen(&_start, _puzzle.fen.UTF8String)) ce_start(&_start);
    _pos = _start;
    _userColor = _start.side;
    _movesLeft = _puzzle.n;
    _busy = NO;
    _done = NO;
    _hintLevel = 0;
    _selected = -1;
    _lastFrom = _lastTo = -1;
    if (_puzzle.last.length >= 4) {
        const char *l = _puzzle.last.UTF8String;
        _lastFrom = SquareFromText(l);
        _lastTo = SquareFromText(l + 2);
    }
    _step = 0;
    _lineMoves = (_puzzle.type == CP_LINE && _puzzle.line.length) ? [_puzzle.line componentsSeparatedByString:@" "] : @[];
    _hashes = [NSMutableData dataWithBytes:&_pos.hash length:sizeof(uint64_t)];
    [_board setFlipped:_userColor == CE_BLACK animated:NO];
    NSArray *group = ItemsInGroup(_puzzle.group);
    NSUInteger number = [group indexOfObjectIdenticalTo:_puzzle];
    NSInteger g = _puzzle.group;
    NSString *kind = GroupName(g);
    self.title = number == NSNotFound ? kind : [NSString stringWithFormat:@"%@ • %lu", kind, (unsigned long)number + 1];
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
    if (_puzzle.type == CP_MATE) {
        if (_movesLeft == 1) t = [NSString stringWithFormat:@"%@ aan zet: geef mat in 1 zet.", [self colorName]];
        else t = [NSString stringWithFormat:@"%@ aan zet: geef mat in %d zetten.", [self colorName], _movesLeft];
    } else if (_puzzle.type == CP_LINE) {
        int mine = (int)(_step / 2) + 1;
        if (mine > _puzzle.n) mine = _puzzle.n;
        t = [NSString stringWithFormat:@"%@ • %@ aan zet: vind de beste zet (%d van %d).",
             _puzzle.title, [self colorName], mine, _puzzle.n];
    } else {
        t = [NSString stringWithFormat:@"%@ \u2022 %@ aan zet: win! Zet mat tegen de bot. Nog %d zetten over.",
             _puzzle.title, [self colorName], _movesLeft];
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
    [[SettingsManager shared] markPuzzleSolved:_puzzle.fen];
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
    [self setFeedback:@"Goed zo! De tegenstander antwoordt…" color:[SettingsManager shared].okColor];
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
    if (_puzzle.type == CP_LINE) {
        [self userLineMove:m];
        return;
    }
    if (_puzzle.type == CP_MATE) {
        if (!cb_move_mates_within(&_pos, m, _movesLeft)) {
            [self wrongMove:m];
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
    NSString *tip = _puzzle.hint.length ? _puzzle.hint : @"Zoek de sterkste zet.";
    if (_puzzle.type == CP_ENDGAME || _hintLevel == 0) {
        _hintLevel = 1;
        [self setFeedback:[@"Tip: " stringByAppendingString:tip] color:nil];
        return;
    }
    CEMove m;
    if (_puzzle.type == CP_LINE) {
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
    if (!_items.count) return;
    _index = (_index + 1) % _items.count;
    _puzzle = _items[_index];
    [self loadPuzzle];
}

- (void)flipTapped {
    [_board setFlipped:!_board.flipped animated:[SettingsManager shared].animations];
}

@end
