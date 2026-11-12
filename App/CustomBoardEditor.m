// CustomBoardEditor.m

#import "CustomBoardEditor.h"
#import "ChessBoard.h"
#import "ChessPiece.h"
#import "GameManager.h"
#import "GameViewController.h"
#import "SettingsManager.h"
#import "YFUI.h"

typedef NS_ENUM(NSInteger, EditorTool) {
    EditorToolPiece = 0,
    EditorToolErase,
    EditorToolMove
};

@interface CustomBoardEditorViewController () <ChessBoardViewDelegate>
@end

@implementation CustomBoardEditorViewController {
    uint8_t _board[64];
    int _side;
    EditorTool _tool;
    uint8_t _toolPiece;
    int _moveFrom;
    ChessBoardView *_boardView;
    UIScrollView *_scroll;
    NSMutableArray *_paletteButtons;   // 12 stukken
    YFButton *_eraseButton;
    YFButton *_moveButton;
    UISegmentedControl *_sideControl;
    UILabel *_toolLabel;
    UILabel *_sideLabel;
    UILabel *_validLabel;
    UILabel *_ratingLabel;
    UISwitch *_ratingSwitch;
    NSArray *_actionButtons;
    YFButton *_playBotButton;
    YFButton *_playLocalButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Custom chess";
    ce_init();
    _moveFrom = -1;
    _tool = EditorToolPiece;
    _toolPiece = CE_PIECE(CE_WHITE, CE_QUEEN);

    // Laatste ontwerp terugzetten, anders de beginstelling.
    CEPosition p;
    NSString *draft = [SettingsManager shared].editorDraftFEN;
    if (!draft.length || !ce_from_fen(&p, draft.UTF8String)) ce_start(&p);
    memcpy(_board, p.board, 64);
    _side = p.side;

    _boardView = [[ChessBoardView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
    _boardView.delegate = self;
    [self.view addSubview:_boardView];

    _scroll = [[UIScrollView alloc] init];
    _scroll.alwaysBounceVertical = YES;
    [self.view addSubview:_scroll];

    CGFloat fs = [YFUI isPad] ? 18 : 15;
    _toolLabel = [YFUI labelWithSize:fs bold:YES];
    _toolLabel.text = @"1. Kies een stuk en tik op het bord (zo vaak je wilt):";
    [_scroll addSubview:_toolLabel];

    _paletteButtons = [NSMutableArray array];
    int types[6] = { CE_KING, CE_QUEEN, CE_ROOK, CE_BISHOP, CE_KNIGHT, CE_PAWN };
    for (int c = 0; c < 2; c++) {
        for (int i = 0; i < 6; i++) {
            uint8_t pc = CE_PIECE(c, types[i]);
            YFButton *b = [YFUI buttonWithTitle:@"" target:self action:@selector(paletteTapped:)];
            b.tag = pc;
            PieceView *pv = [[PieceView alloc] initWithPiece:pc];
            pv.tag = 99;
            [b addSubview:pv];
            [_scroll addSubview:b];
            [_paletteButtons addObject:b];
        }
    }
    _eraseButton = [YFUI buttonWithTitle:@"✕ Gum (weghalen)" target:self action:@selector(eraseTapped)];
    _moveButton = [YFUI buttonWithTitle:@"✥ Verplaatsen" target:self action:@selector(moveTapped)];
    [_scroll addSubview:_eraseButton];
    [_scroll addSubview:_moveButton];

    _sideLabel = [YFUI labelWithSize:fs bold:YES];
    _sideLabel.text = @"2. Wie begint?";
    [_scroll addSubview:_sideLabel];
    _sideControl = [[UISegmentedControl alloc] initWithItems:@[@"Wit begint", @"Zwart begint"]];
    _sideControl.selectedSegmentIndex = _side;
    [_sideControl addTarget:self action:@selector(sideChanged) forControlEvents:UIControlEventValueChanged];
    [_scroll addSubview:_sideControl];

    _validLabel = [YFUI labelWithSize:fs bold:NO];
    [_scroll addSubview:_validLabel];

    _ratingLabel = [YFUI labelWithSize:fs bold:YES];
    _ratingLabel.text = @"3. Zetbeoordeling tijdens het spelen";
    _ratingLabel.numberOfLines = 1;
    _ratingLabel.adjustsFontSizeToFitWidth = YES;
    _ratingLabel.minimumScaleFactor = 0.6;
    [_scroll addSubview:_ratingLabel];
    _ratingSwitch = [YFUI themedSwitch];
    [_ratingSwitch addTarget:self action:@selector(ratingChanged) forControlEvents:UIControlEventValueChanged];
    [_scroll addSubview:_ratingSwitch];

    YFButton *clear = [YFUI buttonWithTitle:@"Leeg bord" target:self action:@selector(clearTapped)];
    YFButton *start = [YFUI buttonWithTitle:@"Beginstelling" target:self action:@selector(startTapped)];
    YFButton *swap = [YFUI buttonWithTitle:@"Kanten wisselen" target:self action:@selector(swapTapped)];
    YFButton *save = [YFUI buttonWithTitle:@"Opslaan" target:self action:@selector(saveTapped)];
    YFButton *load = [YFUI buttonWithTitle:@"Openen" target:self action:@selector(loadTapped)];
    YFButton *kings = [YFUI buttonWithTitle:@"Alleen koningen" target:self action:@selector(kingsTapped)];
    _actionButtons = @[clear, start, kings, swap, save, load];
    for (UIView *v in _actionButtons) [_scroll addSubview:v];

    _playBotButton = [YFUI buttonWithTitle:@"▶ Spelen tegen bot" target:self action:@selector(playBotTapped)];
    _playLocalButton = [YFUI buttonWithTitle:@"▶ Spelen 1 tegen 1" target:self action:@selector(playLocalTapped)];
    _playBotButton.primary = YES;
    _playLocalButton.primary = YES;
    [_scroll addSubview:_playBotButton];
    [_scroll addSubview:_playLocalButton];

    [self refresh];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [YFUI applyThemeToController:self];
    SettingsManager *s = [SettingsManager shared];
    for (YFButton *b in _paletteButtons) {
        [b applyTheme];
        b.backgroundColor = s.lightSquareColor;
        [[b viewWithTag:99] setNeedsDisplay];
    }
    for (YFButton *b in _actionButtons) [b applyTheme];
    [_eraseButton applyTheme];
    [_moveButton applyTheme];
    [_playBotButton applyTheme];
    [_playLocalButton applyTheme];
    _toolLabel.textColor = s.textColor;
    _sideLabel.textColor = s.textColor;
    _ratingLabel.textColor = s.textColor;
    _ratingSwitch.onTintColor = s.accentColor;
    _ratingSwitch.on = s.moveRating;
    _sideControl.tintColor = s.accentColor;
    _boardView.showCoordinates = s.showCoordinates;
    [_boardView refreshTheme];
    [self refresh];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width, H = self.view.bounds.size.height;
    CGFloat top = self.topLayoutGuide.length + 10, bottom = self.bottomLayoutGuide.length;
    CGFloat m = 10;
    CGFloat availH = H - top - bottom - 10;
    if (W > H * 1.05) {
        CGFloat size = floor(MIN(availH, W * 0.58) / 8.0) * 8.0;
        _boardView.frame = CGRectMake(m, top, size, size);
        CGFloat x = CGRectGetMaxX(_boardView.frame) + m;
        _scroll.frame = CGRectMake(x, top - 10, W - x, H - top + 10 - bottom);
    } else {
        CGFloat size = floor(MIN(W - 2 * m, availH * 0.55) / 8.0) * 8.0;
        _boardView.frame = CGRectMake((W - size) / 2.0, top, size, size);
        CGFloat y = CGRectGetMaxY(_boardView.frame) + 4;
        _scroll.frame = CGRectMake(0, y, W, H - y - bottom);
    }
    CGFloat sw = _scroll.bounds.size.width;
    CGFloat pad = 10, w = sw - 2 * pad;
    CGFloat y = 10;
    CGFloat bh = [YFUI isPad] ? 52 : 44;
    _toolLabel.frame = CGRectMake(pad, y, w, [YFUI isPad] ? 46 : 40);
    y += _toolLabel.frame.size.height + 4;
    CGFloat pieceH = MIN(64, MAX(40, (w - 5 * 6) / 6.0));
    y = [YFUI layoutViews:_paletteButtons x:pad y:y width:w itemHeight:pieceH columns:6 spacing:6] + 8;
    for (YFButton *b in _paletteButtons) {
        UIView *pv = [b viewWithTag:99];
        pv.frame = b.bounds;
        [pv setNeedsDisplay];
    }
    y = [YFUI layoutViews:@[_eraseButton, _moveButton] x:pad y:y width:w itemHeight:bh columns:2 spacing:8] + 14;
    _sideLabel.frame = CGRectMake(pad, y, w, 24);
    y += 28;
    _sideControl.frame = CGRectMake(pad, y, w, 36);
    y += 46;
    _ratingLabel.frame = CGRectMake(pad, y, w - 64, 36);
    _ratingSwitch.frame = CGRectMake(pad + w - 51, y + 2, 51, 31);
    y += 46;
    CGSize vs = [_validLabel sizeThatFits:CGSizeMake(w, 1000)];
    _validLabel.frame = CGRectMake(pad, y, w, MAX(24, vs.height));
    y += _validLabel.frame.size.height + 10;
    y = [YFUI layoutViews:@[_playBotButton, _playLocalButton] x:pad y:y width:w itemHeight:bh columns:2 spacing:8] + 14;
    y = [YFUI layoutViews:_actionButtons x:pad y:y width:w itemHeight:bh columns:3 spacing:8] + 20;
    _scroll.contentSize = CGSizeMake(sw, y);
}

#pragma mark - Toestand

- (void)fillPosition:(CEPosition *)p {
    ce_clear(p);
    memcpy(p->board, _board, 64);
    p->side = _side;
    ce_auto_castling(p);
    p->hash = ce_compute_hash(p);
}

- (NSString *)currentFEN {
    CEPosition p;
    [self fillPosition:&p];
    char buf[128];
    ce_to_fen(&p, buf, sizeof buf);
    return [NSString stringWithUTF8String:buf];
}

- (BOOL)validate:(NSString **)error {
    CEPosition p;
    [self fillPosition:&p];
    char err[256];
    if (ce_validate(&p, err, sizeof err)) return YES;
    if (error) *error = [NSString stringWithUTF8String:err];
    return NO;
}

- (void)refresh {
    SettingsManager *s = [SettingsManager shared];
    _boardView.selectedSquare = _moveFrom;
    _boardView.targetSquares = @[];
    [_boardView setBoard:_board animatedFrom:-1 to:-1];
    for (YFButton *b in _paletteButtons) b.selected = (_tool == EditorToolPiece && b.tag == _toolPiece);
    _eraseButton.selected = _tool == EditorToolErase;
    _moveButton.selected = _tool == EditorToolMove;
    _sideControl.selectedSegmentIndex = _side;

    NSString *err = nil;
    int counts[16] = {0};
    for (int i = 0; i < 64; i++) counts[_board[i]]++;
    int whiteCount = 0, blackCount = 0;
    for (int t = 1; t <= 6; t++) { whiteCount += counts[CE_PIECE(CE_WHITE, t)]; blackCount += counts[CE_PIECE(CE_BLACK, t)]; }
    NSString *countText = [NSString stringWithFormat:@"Wit: %d stukken, zwart: %d stukken.", whiteCount, blackCount];
    if ([self validate:&err]) {
        _validLabel.text = [NSString stringWithFormat:@"✓ Deze stelling is geldig. %@", countText];
        _validLabel.textColor = s.okColor;
        _playBotButton.enabled = YES;
        _playLocalButton.enabled = YES;
    } else {
        _validLabel.text = [NSString stringWithFormat:@"⚠ %@", err];
        _validLabel.textColor = s.errorColor;
        _playBotButton.enabled = NO;
        _playLocalButton.enabled = NO;
    }
    s.editorDraftFEN = [self currentFEN];
    [s save];
    [self.view setNeedsLayout];
}

#pragma mark - Bord aantikken

- (void)boardView:(ChessBoardView *)board didTapSquare:(int)sq {
    switch (_tool) {
        case EditorToolPiece: {
            uint8_t pc = _toolPiece;
            if (_board[sq] == pc) {
                _board[sq] = 0;  // nog eens tikken = weghalen
                break;
            }
            if (CE_TYPE(pc) == CE_PAWN && (CE_RANK(sq) == 0 || CE_RANK(sq) == 7)) {
                [self flash:@"Een pion mag niet op de eerste of de laatste rij."];
                return;
            }
            if (CE_TYPE(pc) == CE_KING) {
                // Precies één koning per kant: de oude koning verhuist.
                for (int i = 0; i < 64; i++) if (_board[i] == pc) _board[i] = 0;
            }
            _board[sq] = pc;
            break;
        }
        case EditorToolErase:
            _board[sq] = 0;
            break;
        case EditorToolMove: {
            if (_moveFrom < 0) {
                if (_board[sq]) _moveFrom = sq;
            } else if (_moveFrom == sq) {
                _moveFrom = -1;
            } else {
                uint8_t pc = _board[_moveFrom];
                if (CE_TYPE(pc) == CE_PAWN && (CE_RANK(sq) == 0 || CE_RANK(sq) == 7)) {
                    [self flash:@"Een pion mag niet op de eerste of de laatste rij."];
                    return;
                }
                _board[sq] = pc;
                _board[_moveFrom] = 0;
                _moveFrom = -1;
            }
            break;
        }
    }
    [self refresh];
}

- (void)flash:(NSString *)text {
    _validLabel.text = [NSString stringWithFormat:@"⚠ %@", text];
    _validLabel.textColor = [SettingsManager shared].errorColor;
    _validLabel.alpha = 0.2;
    [UIView animateWithDuration:0.25 animations:^{ self->_validLabel.alpha = 1.0; }];
}

#pragma mark - Knoppen

- (void)paletteTapped:(YFButton *)b {
    _tool = EditorToolPiece;
    _toolPiece = (uint8_t)b.tag;
    _moveFrom = -1;
    [self refresh];
}

- (void)eraseTapped {
    _tool = EditorToolErase;
    _moveFrom = -1;
    [self refresh];
}

- (void)moveTapped {
    _tool = EditorToolMove;
    _moveFrom = -1;
    [self refresh];
}

- (void)ratingChanged {
    SettingsManager *s = [SettingsManager shared];
    s.moveRating = _ratingSwitch.on;
    [s save];
}

- (void)sideChanged {
    _side = (int)_sideControl.selectedSegmentIndex;
    [self refresh];
}

- (void)clearTapped {
    memset(_board, 0, 64);
    _moveFrom = -1;
    [self refresh];
}

- (void)kingsTapped {
    memset(_board, 0, 64);
    _board[4] = CE_PIECE(CE_WHITE, CE_KING);
    _board[60] = CE_PIECE(CE_BLACK, CE_KING);
    _moveFrom = -1;
    [self refresh];
}

- (void)startTapped {
    CEPosition p;
    ce_start(&p);
    memcpy(_board, p.board, 64);
    _side = CE_WHITE;
    _moveFrom = -1;
    [self refresh];
}

- (void)swapTapped {
    // Bord spiegelen en kleuren omdraaien: wit wordt zwart en andersom.
    uint8_t nb[64];
    memset(nb, 0, 64);
    for (int sq = 0; sq < 64; sq++) {
        uint8_t pc = _board[sq];
        if (!pc) continue;
        nb[sq ^ 56] = CE_PIECE(CE_COLOR(pc) ^ 1, CE_TYPE(pc));
    }
    memcpy(_board, nb, 64);
    _side ^= 1;
    _moveFrom = -1;
    [self refresh];
}

- (void)saveTapped {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Stelling opslaan"
                                                               message:@"Geef je stelling een naam."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"Bijv. drie dames";
        tf.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    }];
    __weak UIAlertController *weakAlert = a;
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Opslaan" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        NSString *name = [weakAlert.textFields[0].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (!name.length) {
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            df.dateFormat = @"d-M-yyyy HH:mm";
            name = [NSString stringWithFormat:@"Stelling %@", [df stringFromDate:[NSDate date]]];
        }
        [[SettingsManager shared] savePositionNamed:name fen:[self currentFEN]];
        [YFUI showMessage:[NSString stringWithFormat:@"“%@” is opgeslagen.", name] title:@"Opgeslagen" from:self];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)loadTapped {
    SavedPositionsViewController *list = [[SavedPositionsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    __weak CustomBoardEditorViewController *weakSelf = self;
    list.onPick = ^(NSString *name, NSString *fen) {
        [weakSelf loadFEN:fen];
    };
    [self.navigationController pushViewController:list animated:YES];
}

- (void)loadFEN:(NSString *)fen {
    CEPosition p;
    if (!ce_from_fen(&p, fen.UTF8String)) return;
    memcpy(_board, p.board, 64);
    _side = p.side;
    _moveFrom = -1;
    [self refresh];
}

- (void)startGameWithMode:(GameMode)mode humanColor:(int)color {
    NSString *err = nil;
    if (![self validate:&err]) {
        [YFUI showMessage:err title:@"Deze stelling kan niet" from:self];
        return;
    }
    GameManager *g = [[GameManager alloc] initWithFEN:[self currentFEN] mode:mode humanColor:color
                                             botLevel:[SettingsManager shared].botLevel];
    [self.navigationController pushViewController:[[GameViewController alloc] initWithGame:g] animated:YES];
}

- (void)playBotTapped {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Met welke kleur speel jij?"
                                                               message:[NSString stringWithFormat:@"De bot speelt op niveau %ld (aan te passen bij Instellingen).",
                                                                        (long)[SettingsManager shared].botLevel]
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Ik speel Wit" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        [self startGameWithMode:GameModeBot humanColor:CE_WHITE];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Ik speel Zwart" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        [self startGameWithMode:GameModeBot humanColor:CE_BLACK];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)playLocalTapped {
    [self startGameWithMode:GameModeLocal humanColor:CE_WHITE];
}

@end

#pragma mark - Opgeslagen posities

@implementation SavedPositionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Opgeslagen posities";
    self.tableView.rowHeight = [YFUI isPad] ? 60 : 50;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [YFUI applyThemeToController:self];
    SettingsManager *s = [SettingsManager shared];
    self.tableView.backgroundColor = s.backgroundColor;
    self.tableView.backgroundView = nil;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger n = [SettingsManager shared].savedPositions.count;
    return n ? n : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"Tik om te openen. Veeg naar links om te verwijderen.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pos"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"pos"];
    SettingsManager *s = [SettingsManager shared];
    cell.backgroundColor = s.panelColor;
    cell.textLabel.textColor = s.textColor;
    cell.detailTextLabel.textColor = s.secondaryTextColor;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:[YFUI isPad] ? 19 : 16];
    NSArray *items = s.savedPositions;
    if (!items.count) {
        cell.textLabel.text = @"Nog niets opgeslagen";
        cell.detailTextLabel.text = @"Maak een stelling bij Custom chess en tik op Opslaan.";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    }
    NSDictionary *item = items[indexPath.row];
    cell.textLabel.text = item[@"name"];
    NSString *fen = item[@"fen"];
    BOOL black = [fen rangeOfString:@" b "].location != NSNotFound;
    NSUInteger pieces = 0;
    NSString *boardPart = [fen componentsSeparatedByString:@" "].firstObject;
    for (NSUInteger i = 0; i < boardPart.length; i++) {
        unichar c = [boardPart characterAtIndex:i];
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) pieces++;
    }
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu stukken • %@ begint", (unsigned long)pieces, black ? @"zwart" : @"wit"];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [SettingsManager shared].savedPositions.count > 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Verwijder";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
    forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;
    [[SettingsManager shared] deletePositionAtIndex:indexPath.row];
    [tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *items = [SettingsManager shared].savedPositions;
    if (indexPath.row >= (NSInteger)items.count) return;
    NSDictionary *item = items[indexPath.row];
    void (^pick)(NSString *, NSString *) = self.onPick;
    [self.navigationController popViewControllerAnimated:YES];
    if (pick) pick(item[@"name"], item[@"fen"]);
}

@end
