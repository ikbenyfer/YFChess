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
    if (_game.mode == GameModeBot) {
        self.title = [NSString stringWithFormat:@"Tegen de bot (niveau %ld)", (long)_game.botLevel];
    } else {
        self.title = @"1 tegen 1";
    }

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
    for (YFButton *b in @[_undoButton, _restartButton, _flipButton]) [b applyTheme];
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
    NSInteger cols = pw > 330 ? 3 : 3;
    y = [YFUI layoutViews:@[_undoButton, _restartButton, _flipButton] x:pad y:y width:pw - 2 * pad
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
    [self announceIfOver];
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
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Partij afgelopen"
                                                               message:[_game resultTitle]
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Bekijk bord" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Nieuwe partij" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        [self->_game restart];
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
        self->_selected = -1;
        [self->_game restart];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)flipTapped {
    [_board setFlipped:!_board.flipped animated:[SettingsManager shared].animations];
}

@end
