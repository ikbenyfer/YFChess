// GameViewController.m

#import "GameViewController.h"
#import "ChessBoard.h"
#import "ChessPiece.h"
#import "SettingsManager.h"
#import "YFUI.h"
#import "MoveRating.h"

@interface GameViewController () <ChessBoardViewDelegate>
@end

@implementation GameViewController {
    GameManager *_game;
    ChessBoardView *_board;
    UIView *_panel;
    UILabel *_statusLabel;
    UILabel *_ratingLabel;
    UILabel *_capturedWhite;
    UILabel *_capturedBlack;
    UITextView *_movesView;
    YFButton *_undoButton;
    YFButton *_restartButton;
    YFButton *_flipButton;
    YFButton *_saveButton;
    YFButton *_resignButton;
    UIActivityIndicatorView *_spinner;
    int _selected;
    NSUInteger _announcedPly;
    BOOL _announced;
}

- (instancetype)initWithGame:(GameManager *)game {
    self = [super init];
    if (self) {
        _game = game;
        _selected = -1;
        _game.ratingEnabled = [SettingsManager shared].moveRating;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    SettingsManager *s = [SettingsManager shared];
    [self updateTitle];

    _board = [[ChessBoardView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
    _board.delegate = self;
    [self.view addSubview:_board];
    BOOL flip;
    if (_game.mode == GameModeBot) flip = _game.humanColor == CE_BLACK;
    else flip = s.autoFlip && _game.position.side == CE_BLACK;
    [_board setFlipped:flip animated:NO];

    _panel = [[UIView alloc] init];
    _panel.layer.cornerRadius = 10;
    [self.view addSubview:_panel];

    CGFloat big = [YFUI isPad] ? 20 : 16;
    _statusLabel = [YFUI labelWithSize:big bold:YES];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.adjustsFontSizeToFitWidth = YES;
    _statusLabel.minimumScaleFactor = 0.6;
    [_panel addSubview:_statusLabel];

    _ratingLabel = [YFUI labelWithSize:[YFUI isPad] ? 17 : 14 bold:NO];
    _ratingLabel.numberOfLines = 2;
    _ratingLabel.textAlignment = NSTextAlignmentCenter;
    _ratingLabel.adjustsFontSizeToFitWidth = YES;
    _ratingLabel.minimumScaleFactor = 0.6;
    _ratingLabel.hidden = !_game.ratingEnabled;
    [_panel addSubview:_ratingLabel];

    _capturedWhite = [YFUI labelWithSize:big bold:NO];
    _capturedWhite.numberOfLines = 2;
    _capturedWhite.adjustsFontSizeToFitWidth = YES;
    _capturedWhite.minimumScaleFactor = 0.5;
    [_panel addSubview:_capturedWhite];
    _capturedBlack = [YFUI labelWithSize:big bold:NO];
    _capturedBlack.numberOfLines = 2;
    _capturedBlack.adjustsFontSizeToFitWidth = YES;
    _capturedBlack.minimumScaleFactor = 0.5;
    [_panel addSubview:_capturedBlack];

    _movesView = [[UITextView alloc] init];
    _movesView.editable = NO;
    _movesView.selectable = NO;
    _movesView.font = [UIFont systemFontOfSize:[YFUI isPad] ? 18 : 15];
    _movesView.layer.cornerRadius = 8;
    _movesView.textContainerInset = UIEdgeInsetsMake(8, 6, 8, 6);
    [_panel addSubview:_movesView];

    _undoButton = [YFUI buttonWithTitle:@"↶ Terug" target:self action:@selector(undoTapped)];
    _restartButton = [YFUI buttonWithTitle:@"↻ Opnieuw" target:self action:@selector(restartTapped)];
    _flipButton = [YFUI buttonWithTitle:@"⇅ Draai bord" target:self action:@selector(flipTapped)];
    [_panel addSubview:_undoButton];
    [_panel addSubview:_restartButton];
    [_panel addSubview:_flipButton];
    if (_game.mode == GameModeLocal) {
        _saveButton = [YFUI buttonWithTitle:@"⬇ Opslaan" target:self action:@selector(saveTapped)];
        [_panel addSubview:_saveButton];
    } else {
        _resignButton = [YFUI buttonWithTitle:@"⚑ Opgeven" target:self action:@selector(resignTapped)];
        [_panel addSubview:_resignButton];
    }
    if (_game.playKind == 3) {
        // Elo-test: niet terugnemen of opnieuw beginnen, dat zou de test oneerlijk maken.
        _undoButton.hidden = YES;
        _restartButton.hidden = YES;
    }

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.hidesWhenStopped = YES;
    [_panel addSubview:_spinner];

    __weak GameViewController *weakSelf = self;
    _game.onChange = ^(GameManager *g, int from, int to) {
        [weakSelf gameChangedFrom:from to:to];
    };
    _game.onThinkingChange = ^(GameManager *g) {
        [weakSelf updateTexts];
    };
    _game.onRatingChange = ^(GameManager *g) {
        [weakSelf updateTexts];
        [weakSelf updateBadge];
    };
    _announcedPly = NSNotFound;
    [self refreshAnimatedFrom:-1 to:-1];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self applyTheme];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_game startBotIfNeeded];
    [self announceIfOver];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController) [_game stopBot];
}

- (void)applyTheme {
    SettingsManager *s = [SettingsManager shared];
    [YFUI applyThemeToController:self];
    _panel.backgroundColor = s.panelColor;
    _statusLabel.textColor = s.textColor;
    _capturedWhite.textColor = s.textColor;
    _capturedBlack.textColor = s.textColor;
    _movesView.backgroundColor = s.backgroundColor;
    _movesView.textColor = s.textColor;
    _spinner.color = s.accentColor;
    for (YFButton *b in [self panelButtons]) [b applyTheme];
    _board.showCoordinates = s.showCoordinates;
    [_board refreshTheme];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width, H = self.view.bounds.size.height;
    CGFloat top = self.topLayoutGuide.length + 10;
    CGFloat bottom = self.bottomLayoutGuide.length + 10;
    CGFloat availH = H - top - bottom;
    CGFloat m = 10;
    CGRect panelFrame;
    if (W > H * 1.05) {
        CGFloat size = floor(MIN(availH, W * 0.62) / 8.0) * 8.0;
        _board.frame = CGRectMake(m, top + (availH - size) / 2.0, size, size);
        CGFloat px = CGRectGetMaxX(_board.frame) + m;
        panelFrame = CGRectMake(px, top, W - px - m, availH);
    } else {
        CGFloat size = floor(MIN(W - 2 * m, availH * 0.64) / 8.0) * 8.0;
        _board.frame = CGRectMake((W - size) / 2.0, top, size, size);
        CGFloat py = CGRectGetMaxY(_board.frame) + m;
        panelFrame = CGRectMake(m, py, W - 2 * m, H - bottom - py);
    }
    _panel.frame = panelFrame;
    CGFloat pw = panelFrame.size.width, ph = panelFrame.size.height;
    CGFloat pad = 10;
    CGFloat lineH = [YFUI isPad] ? 28 : 22;
    CGFloat y = pad;
    _statusLabel.frame = CGRectMake(pad + 26, y, pw - 2 * pad - 52, lineH * 1.6);
    _spinner.center = CGPointMake(pad + 12, y + lineH * 0.8);
    y += lineH * 1.6 + 4;
    if (_game.ratingEnabled) {
        _ratingLabel.frame = CGRectMake(pad, y, pw - 2 * pad, lineH * 1.8);
        y += lineH * 1.8 + 4;
    }
    _capturedWhite.frame = CGRectMake(pad, y, pw - 2 * pad, lineH);
    y += lineH + 2;
    _capturedBlack.frame = CGRectMake(pad, y, pw - 2 * pad, lineH);
    y += lineH + 8;
    CGFloat bh = [YFUI isPad] ? 56 : 46;
    NSArray *buttons = [self panelButtons];
    NSInteger cols = buttons.count == 3 ? 3 : 2;
    y = [YFUI layoutViews:buttons x:pad y:y width:pw - 2 * pad
               itemHeight:bh columns:cols spacing:8] + 10;
    CGFloat mh = ph - y - pad;
    _movesView.hidden = mh < 30;
    _movesView.frame = CGRectMake(pad, y, pw - 2 * pad, MAX(mh, 0));
}

#pragma mark - Bijwerken

- (void)gameChangedFrom:(int)from to:(int)to {
    _selected = -1;
    [self refreshAnimatedFrom:from to:to];
    SettingsManager *s = [SettingsManager shared];
    if (_game.mode == GameModeLocal && s.autoFlip && ![_game isGameOver]) {
        BOOL want = _game.position.side == CE_BLACK;
        if (want != _board.flipped) {
            double delay = s.animations && from >= 0 ? 0.3 : 0.0;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self->_board setFlipped:self->_game.position.side == CE_BLACK animated:s.animations];
            });
        }
    }
    if (_game.saveId) [self storeGameQuietly];
    [self announceIfOver];
}

- (NSArray *)panelButtons {
    if (_saveButton) return @[_undoButton, _restartButton, _flipButton, _saveButton];
    if (_game.playKind == 3) return @[_resignButton, _flipButton];
    if (_resignButton) return @[_undoButton, _restartButton, _resignButton, _flipButton];
    return @[_undoButton, _restartButton, _flipButton];
}

- (void)updateTitle {
    if (_game.mode != GameModeBot) { self.title = @"1 tegen 1"; return; }
    switch (_game.playKind) {
        case 1: self.title = [NSString stringWithFormat:@"Meegroeiende bot (sterkte %ld)", (long)_game.adaptiveStrength]; break;
        case 2: self.title = [NSString stringWithFormat:@"Tegen de bot (~%ld Elo)", (long)_game.opponentElo]; break;
        case 3: self.title = [NSString stringWithFormat:@"Elo-test: potje %lu van 3 (bot ~%ld Elo)",
                              (unsigned long)[SettingsManager shared].eloTestScores.count + 1, (long)_game.opponentElo]; break;
        default: self.title = [NSString stringWithFormat:@"Tegen de bot (niveau %ld)", (long)_game.botLevel]; break;
    }
}

- (void)resignTapped {
    if ([_game isGameOver]) return;
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Opgeven?" message:@"De bot wint dan deze partij."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Opgeven" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *act) {
        self->_selected = -1;
        [self->_game resign];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

// 1 = jij wint, 0.5 = remise, 0 = de bot wint.
- (double)humanScore {
    if (_game.resigned) return 0;
    if (_game.status == CE_CHECKMATE) {
        int winner = _game.position.side ^ 1;
        return winner == _game.humanColor ? 1.0 : 0.0;
    }
    return 0.5;
}

#pragma mark - Elo-test

// Verwerkt een testpotje en laat zien wat er volgt.
- (void)showEloTestResult {
    SettingsManager *s = [SettingsManager shared];
    if (!_game.resultCounted) {
        _game.resultCounted = YES;
        [s recordEloTestGame:_game.opponentElo score:[self humanScore]];
    }
    double score = [self humanScore];
    NSString *res = score > 0.75 ? @"gewonnen" : (score < 0.25 ? @"verloren" : @"remise");
    NSUInteger played = s.eloTestScores.count;
    UIAlertController *a;
    if (played < 3) {
        NSInteger next = [s nextEloTestOpponent];
        NSString *msg = [NSString stringWithFormat:@"%@\n\nPotje %lu van 3: %@.\nHet volgende potje speel je tegen een bot van ongeveer %ld Elo.",
                         [_game resultTitle], (unsigned long)played, res, (long)next];
        a = [UIAlertController alertControllerWithTitle:@"Elo-test" message:msg preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"Bekijk bord" style:UIAlertActionStyleCancel handler:nil]];
        [a addAction:[UIAlertAction actionWithTitle:@"▶ Volgend potje" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
            [self startNextEloTestGame];
        }]];
    } else {
        NSInteger elo = [s eloTestEstimate];
        s.lastEloEstimate = elo;
        s.playElo = elo;
        [s save];
        [s resetEloTest];
        NSString *msg = [NSString stringWithFormat:@"%@\n\nPotje 3 van 3: %@.\n\nJij bent ongeveer %ld Elo!\n\n"
                         @"Dit getal staat nu ingevuld bij “Speel tegen een Elo”. Het is een schatting na 3 potjes.",
                         [_game resultTitle], res, (long)elo];
        a = [UIAlertController alertControllerWithTitle:@"Elo-test klaar" message:msg preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"Bekijk bord" style:UIAlertActionStyleCancel handler:nil]];
        [a addAction:[UIAlertAction actionWithTitle:@"Terug naar het botmenu" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
    }
    [self presentViewController:a animated:YES completion:nil];
}

- (void)startNextEloTestGame {
    SettingsManager *s = [SettingsManager shared];
    NSInteger elo = [s nextEloTestOpponent];
    _game.opponentElo = elo;
    _game.adaptiveStrength = [SettingsManager strengthForElo:elo];
    _game.humanColor = (s.eloTestScores.count % 2 == 0) ? CE_WHITE : CE_BLACK;   // om en om wit en zwart
    [_board setFlipped:_game.humanColor == CE_BLACK animated:s.animations];
    _selected = -1;
    [self updateTitle];
    [_game restart];
}

#pragma mark - Opslaan (1 tegen 1)

- (void)storeGameQuietly {
    if (!_game.saveId) return;
    NSDictionary *g = @{ @"id": _game.saveId,
                         @"name": _game.saveName ?: @"Partij",
                         @"date": [NSDate date],
                         @"fen": [_game initialFEN],
                         @"moves": [_game uciMoves] };
    [[SettingsManager shared] storeGame:g];
}

- (void)saveTapped {
    if (_game.saveId) {
        [self storeGameQuietly];
        [YFUI showMessage:[NSString stringWithFormat:@"“%@” is bijgewerkt. Vanaf nu wordt deze partij na elke zet vanzelf bewaard.", _game.saveName]
                    title:@"Opgeslagen" from:self];
        return;
    }
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"d-M HH:mm";
    NSString *suggestion = [NSString stringWithFormat:@"Partij %@", [df stringFromDate:[NSDate date]]];
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Partij opslaan"
                                                               message:@"Geef de partij een naam. Later ga je verder via Lokaal 1 tegen 1 → Opgeslagen partij."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.text = suggestion;
        tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    __weak UIAlertController *weakAlert = a;
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Opslaan" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        NSString *name = [weakAlert.textFields.firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        self->_game.saveName = name.length ? name : suggestion;
        self->_game.saveId = [[NSUUID UUID] UUIDString];
        [self storeGameQuietly];
        [YFUI showMessage:@"Opgeslagen. Vanaf nu wordt deze partij na elke zet vanzelf bewaard." title:@"Opgeslagen" from:self];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

#pragma mark - Meegroeiende bot

// Verwerkt de uitslag: jij wint = bot sterker, bot wint = bot zwakker. Geeft uitleg terug.
- (NSString *)countAdaptiveResult {
    if (_game.playKind != 1 || _game.resultCounted) return nil;
    _game.resultCounted = YES;
    SettingsManager *s = [SettingsManager shared];
    NSInteger before = s.adaptiveStrength, after = before;
    double score = [self humanScore];
    NSString *text;
    if (score < 0.25 || score > 0.75) {
        if (score > 0.75) {
            after = MIN(100, before + (before < 30 ? 12 : 8));
            s.adaptiveWins++;
            text = @"Jij wint, dus de bot wordt sterker.";
        } else {
            after = MAX(0, before - (before < 30 ? 8 : 10));
            s.adaptiveLosses++;
            text = @"De bot wint, dus hij wordt wat makkelijker.";
        }
    } else {
        after = MIN(100, before + 3);
        s.adaptiveDraws++;
        text = @"Remise: de bot wordt een klein beetje sterker.";
    }
    s.adaptiveStrength = after;
    [s save];
    return [NSString stringWithFormat:@"%@\nSterkte: %ld → %ld (%@).", text, (long)before, (long)after,
            [SettingsManager strengthName:after]];
}

- (void)startNewGame {
    _selected = -1;
    if (_game.playKind == 1) _game.adaptiveStrength = [SettingsManager shared].adaptiveStrength;
    [self updateTitle];
    [_game restart];
}

- (void)refreshAnimatedFrom:(int)from to:(int)to {
    SettingsManager *s = [SettingsManager shared];
    CEPosition p = _game.position;
    BOOL hideLast = _game.mode == GameModeLocal && s.hideLastMove;
    _board.lastFrom = hideLast ? -1 : _game.lastFrom;
    _board.lastTo = hideLast ? -1 : _game.lastTo;
    _board.checkSquare = ce_in_check(&p, p.side) ? ce_king_square(&p, p.side) : -1;
    _board.selectedSquare = _selected;
    _board.targetSquares = @[];
    BOOL animate = s.animations && !hideLast && from >= 0;
    [_board setBoard:p.board animatedFrom:animate ? from : -1 to:to];
    [self updateBadge];
    [self updateTexts];
}

// Bolletje op het veld van de laatste zet (alleen als die al beoordeeld is).
- (void)updateBadge {
    BOOL hideLast = _game.mode == GameModeLocal && [SettingsManager shared].hideLastMove;
    NSUInteger n = _game.plyCount;
    NSDictionary *rec = n ? [_game recordAtPly:n - 1] : nil;
    NSNumber *rating = rec[@"rating"];
    if (!_game.ratingEnabled || hideLast || !rating) {
        [_board setBadgeSquare:-1 text:nil color:nil];
        return;
    }
    CBRating r = (CBRating)rating.intValue;
    [_board setBadgeSquare:[rec[@"to"] intValue] text:[MoveRating symbolFor:r] color:[MoveRating colorFor:r]];
}

- (NSString *)moveTextAtPly:(NSUInteger)i san:(NSString *)san {
    NSString *t = [ChessPiece figurineSAN:san];
    NSNumber *rating = [_game recordAtPly:i][@"rating"];
    if (rating && _game.ratingEnabled) t = [t stringByAppendingFormat:@" %@", [MoveRating symbolFor:(CBRating)rating.intValue]];
    return t;
}

- (void)updateRatingLabel {
    if (!_game.ratingEnabled) return;
    SettingsManager *s = [SettingsManager shared];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    UIFont *font = _ratingLabel.font;
    UIFont *bold = [UIFont boldSystemFontOfSize:font.pointSize];
    // De laatste zet die beoordeeld wordt of is.
    NSDictionary *rec = nil;
    for (NSInteger i = (NSInteger)_game.plyCount - 1; i >= 0; i--) {
        NSDictionary *r = [_game recordAtPly:(NSUInteger)i];
        if (r[@"rating"] || r[@"pending"]) { rec = r; break; }
    }
    if (!rec) {
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"Zetbeoordeling staat aan: na elke zet zie je hoe goed hij was."
                                                                     attributes:@{ NSFontAttributeName: font, NSForegroundColorAttributeName: s.secondaryTextColor }]];
    } else {
        int color = [rec[@"color"] intValue];
        NSString *who = _game.mode == GameModeBot ? @"Jouw zet" : (color == CE_WHITE ? @"Wit" : @"Zwart");
        NSString *san = [ChessPiece figurineSAN:rec[@"san"]];
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@: ", who, san]
                                                                     attributes:@{ NSFontAttributeName: font, NSForegroundColorAttributeName: s.textColor }]];
        NSNumber *rating = rec[@"rating"];
        if (!rating) {
            [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"wordt beoordeeld…"
                                                                         attributes:@{ NSFontAttributeName: font, NSForegroundColorAttributeName: s.secondaryTextColor }]];
        } else {
            CBRating r = (CBRating)rating.intValue;
            NSString *label = [NSString stringWithFormat:@"%@ %@", [MoveRating symbolFor:r], [MoveRating nameFor:r]];
            [text appendAttributedString:[[NSAttributedString alloc] initWithString:label
                                                                         attributes:@{ NSFontAttributeName: bold, NSForegroundColorAttributeName: [MoveRating colorFor:r] }]];
            NSString *best = rec[@"best"];
            if (best.length) {
                [text appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  •  beter was %@", [ChessPiece figurineSAN:best]]
                                                                             attributes:@{ NSFontAttributeName: font, NSForegroundColorAttributeName: s.secondaryTextColor }]];
            }
        }
    }
    // Nauwkeurigheid.
    int nw = 0, nb = 0;
    double aw = [_game accuracyForColor:CE_WHITE count:&nw];
    double ab = [_game accuracyForColor:CE_BLACK count:&nb];
    NSString *acc = nil;
    if (_game.mode == GameModeBot) {
        int n = _game.humanColor == CE_WHITE ? nw : nb;
        double a = _game.humanColor == CE_WHITE ? aw : ab;
        if (n) acc = [NSString stringWithFormat:@"\nJouw nauwkeurigheid: %.0f%%", a];
    } else if (nw || nb) {
        acc = [NSString stringWithFormat:@"\nNauwkeurigheid: Wit %@ • Zwart %@",
               nw ? [NSString stringWithFormat:@"%.0f%%", aw] : @"—",
               nb ? [NSString stringWithFormat:@"%.0f%%", ab] : @"—"];
    }
    if (acc) {
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:acc
                                                                     attributes:@{ NSFontAttributeName: font, NSForegroundColorAttributeName: s.secondaryTextColor }]];
    }
    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
    ps.alignment = NSTextAlignmentCenter;
    [text addAttribute:NSParagraphStyleAttributeName value:ps range:NSMakeRange(0, text.length)];
    _ratingLabel.attributedText = text;
}

- (NSString *)capturedString:(int)color {
    NSArray *caps = [_game capturedByColor:color];
    NSArray *sorted = [caps sortedArrayUsingComparator:^NSComparisonResult(NSNumber *a, NSNumber *b) {
        int va = [ChessPiece valueForType:CE_TYPE(a.intValue)], vb = [ChessPiece valueForType:CE_TYPE(b.intValue)];
        if (va == vb) return NSOrderedSame;
        return va > vb ? NSOrderedAscending : NSOrderedDescending;
    }];
    NSMutableString *str = [NSMutableString string];
    for (NSNumber *n in sorted) [str appendString:[ChessPiece textGlyphForPiece:n.intValue]];
    return str;
}

- (int)materialFor:(int)color {
    CEPosition p = _game.position;
    int total = 0;
    for (int sq = 0; sq < 64; sq++)
        if (p.board[sq] && CE_COLOR(p.board[sq]) == color) total += [ChessPiece valueForType:CE_TYPE(p.board[sq])];
    return total;
}

- (void)updateTexts {
    _statusLabel.text = [_game statusText];
    if (_game.botThinking) [_spinner startAnimating]; else [_spinner stopAnimating];

    int diff = [self materialFor:CE_WHITE] - [self materialFor:CE_BLACK];
    NSString *w = [self capturedString:CE_WHITE];
    NSString *b = [self capturedString:CE_BLACK];
    _capturedWhite.text = [NSString stringWithFormat:@"Wit sloeg: %@%@", w.length ? w : @"—",
                           diff > 0 ? [NSString stringWithFormat:@"  (+%d)", diff] : @""];
    _capturedBlack.text = [NSString stringWithFormat:@"Zwart sloeg: %@%@", b.length ? b : @"—",
                           diff < 0 ? [NSString stringWithFormat:@"  (+%d)", -diff] : @""];

    NSArray *moves = [_game sanMoves];
    NSMutableString *text = [NSMutableString string];
    int number = _game.startFullmove;
    NSUInteger i = 0;
    if (_game.startSide == CE_BLACK && moves.count) {
        [text appendFormat:@"%d… %@\n", number, [self moveTextAtPly:0 san:moves[0]]];
        number++;
        i = 1;
    }
    for (; i < moves.count; i += 2) {
        [text appendFormat:@"%d. %@", number, [self moveTextAtPly:i san:moves[i]]];
        if (i + 1 < moves.count) [text appendFormat:@"   %@", [self moveTextAtPly:i + 1 san:moves[i + 1]]];
        [text appendString:@"\n"];
        number++;
    }
    if (!moves.count) [text appendString:@"Nog geen zetten.\nTik op een stuk en dan op een veld."];
    _movesView.text = text;
    if (moves.count) [_movesView scrollRangeToVisible:NSMakeRange(text.length > 0 ? text.length - 1 : 0, 0)];

    _undoButton.enabled = [_game canUndo];
    [self updateRatingLabel];
}

- (void)announceIfOver {
    if (![_game isGameOver]) {
        _announced = NO;
        return;
    }
    if (_announced && _announcedPly == _game.plyCount) return;
    if (!self.view.window) return;
    _announced = YES;
    _announcedPly = _game.plyCount;
    if (_game.playKind == 3) {
        [self showEloTestResult];
        return;
    }
    NSString *msg = [_game resultTitle];
    NSString *adaptiveText = [self countAdaptiveResult];
    if (adaptiveText) msg = [NSString stringWithFormat:@"%@\n\n%@", msg, adaptiveText];
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Partij afgelopen"
                                                               message:msg
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Bekijk bord" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Nieuwe partij" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        [self startNewGame];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

#pragma mark - Bord

- (void)boardView:(ChessBoardView *)board didTapSquare:(int)sq {
    if ([_game isGameOver] || ![_game isHumanTurn] || _game.botThinking) return;
    CEPosition p = _game.position;
    if (_selected >= 0) {
        NSArray *targets = [_game legalTargetsFrom:_selected];
        if ([targets containsObject:@(sq)]) {
            int from = _selected;
            _selected = -1;
            _board.selectedSquare = -1;
            _board.targetSquares = @[];
            if ([_game isPromotionFrom:from to:sq]) [self askPromotionFrom:from to:sq];
            else [_game makeMoveFrom:from to:sq promotion:0];
            return;
        }
    }
    uint8_t pc = p.board[sq];
    if (pc && CE_COLOR(pc) == p.side && sq != _selected) {
        _selected = sq;
        _board.selectedSquare = sq;
        _board.targetSquares = [SettingsManager shared].showLegalMoves ? [_game legalTargetsFrom:sq] : @[];
    } else {
        _selected = -1;
        _board.selectedSquare = -1;
        _board.targetSquares = @[];
    }
}

- (void)askPromotionFrom:(int)from to:(int)to {
    int color = _game.position.side;
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Promotie"
                                                               message:@"Waar moet je pion in veranderen?"
                                                        preferredStyle:UIAlertControllerStyleAlert];
    int types[4] = { CE_QUEEN, CE_ROOK, CE_BISHOP, CE_KNIGHT };
    for (int i = 0; i < 4; i++) {
        int t = types[i];
        NSString *name = [ChessPiece dutchNameForType:t];
        name = [[[name substringToIndex:1] uppercaseString] stringByAppendingString:[name substringFromIndex:1]];
        NSString *title = [NSString stringWithFormat:@"%@  %@", [ChessPiece textGlyphForPiece:CE_PIECE(color, t)], name];
        [a addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
            [self->_game makeMoveFrom:from to:to promotion:t];
        }]];
    }
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

#pragma mark - Knoppen

- (void)undoTapped {
    _selected = -1;
    [_game undo];
}

- (void)restartTapped {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Opnieuw beginnen?"
                                                               message:@"De huidige partij gaat verloren."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Opnieuw" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *act) {
        [self startNewGame];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)flipTapped {
    [_board setFlipped:!_board.flipped animated:[SettingsManager shared].animations];
}

@end
