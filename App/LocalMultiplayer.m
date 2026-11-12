// LocalMultiplayer.m

#import "LocalMultiplayer.h"
#import "YFUI.h"
#import "SettingsManager.h"
#import "GameManager.h"
#import "GameViewController.h"
#import "CustomBoardEditor.h"

@implementation LocalMultiplayerViewController {
    UILabel *_intro;
    UILabel *_flipLabel;
    UISwitch *_flipSwitch;
    UILabel *_hideLabel;
    UISwitch *_hideSwitch;
    UILabel *_ratingLabel;
    UISwitch *_ratingSwitch;
    YFButton *_startButton;
    YFButton *_savedButton;
    YFButton *_customButton;
    YFButton *_continueButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Lokaal 1 tegen 1";
    CGFloat fs = [YFUI isPad] ? 19 : 16;
    _intro = [YFUI labelWithSize:fs bold:NO];
    _intro.text = @"Twee spelers op één iPad. Om de beurt een zet doen.";
    [self.view addSubview:_intro];
    _flipLabel = [YFUI labelWithSize:fs bold:YES];
    _flipLabel.text = @"Bord draait mee na elke zet";
    [self.view addSubview:_flipLabel];
    _flipSwitch = [YFUI themedSwitch];
    [_flipSwitch addTarget:self action:@selector(switchChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_flipSwitch];
    _hideLabel = [YFUI labelWithSize:fs bold:YES];
    _hideLabel.text = @"Vorige zet verbergen (geen markering)";
    [self.view addSubview:_hideLabel];
    _hideSwitch = [YFUI themedSwitch];
    [_hideSwitch addTarget:self action:@selector(switchChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_hideSwitch];
    _ratingLabel = [YFUI labelWithSize:fs bold:YES];
    _ratingLabel.text = @"Zetbeoordeling (beste zet … blunder)";
    [self.view addSubview:_ratingLabel];
    _ratingSwitch = [YFUI themedSwitch];
    [_ratingSwitch addTarget:self action:@selector(switchChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_ratingSwitch];
    _startButton = [YFUI buttonWithTitle:@"▶ Start (normale opstelling)" target:self action:@selector(startTapped)];
    _startButton.primary = YES;
    _savedButton = [YFUI buttonWithTitle:@"Start vanaf opgeslagen positie" target:self action:@selector(savedTapped)];
    _customButton = [YFUI buttonWithTitle:@"Eigen stelling maken (Custom)" target:self action:@selector(customTapped)];
    [self.view addSubview:_startButton];
    [self.view addSubview:_savedButton];
    [self.view addSubview:_customButton];
    _continueButton = [YFUI buttonWithTitle:@"⬆ Opgeslagen partij verder spelen" target:self action:@selector(continueTapped)];
    [self.view addSubview:_continueButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [YFUI applyThemeToController:self];
    SettingsManager *s = [SettingsManager shared];
    _intro.textColor = s.secondaryTextColor;
    _flipLabel.textColor = s.textColor;
    _hideLabel.textColor = s.textColor;
    _ratingLabel.textColor = s.textColor;
    _ratingSwitch.onTintColor = s.accentColor;
    _ratingSwitch.on = s.moveRating;
    _flipSwitch.onTintColor = s.accentColor;
    _hideSwitch.onTintColor = s.accentColor;
    _flipSwitch.on = s.autoFlip;
    _hideSwitch.on = s.hideLastMove;
    for (YFButton *b in @[_startButton, _savedButton, _customButton, _continueButton]) [b applyTheme];
    NSUInteger saved = s.savedGames.count;
    [_continueButton setTitle:[NSString stringWithFormat:@"⬆ Opgeslagen partij verder spelen (%lu)", (unsigned long)saved]
                     forState:UIControlStateNormal];
    _continueButton.enabled = saved > 0;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width;
    CGFloat colW = MIN(W - 40, 520);
    CGFloat x = (W - colW) / 2.0;
    CGFloat y = self.topLayoutGuide.length + 24;
    CGFloat bh = [YFUI isPad] ? 64 : 52;
    _intro.frame = CGRectMake(x, y, colW, 48); y += 64;
    CGFloat swW = 60;
    _flipLabel.frame = CGRectMake(x, y, colW - swW - 10, 44);
    _flipSwitch.frame = CGRectMake(x + colW - 51, y + 6, 51, 31); y += 60;
    _hideLabel.frame = CGRectMake(x, y, colW - swW - 10, 44);
    _hideSwitch.frame = CGRectMake(x + colW - 51, y + 6, 51, 31); y += 60;
    _ratingLabel.frame = CGRectMake(x, y, colW - swW - 10, 44);
    _ratingSwitch.frame = CGRectMake(x + colW - 51, y + 6, 51, 31); y += 72;
    _startButton.frame = CGRectMake(x, y, colW, bh); y += bh + 12;
    _continueButton.frame = CGRectMake(x, y, colW, bh); y += bh + 12;
    _savedButton.frame = CGRectMake(x, y, colW, bh); y += bh + 12;
    _customButton.frame = CGRectMake(x, y, colW, bh);
}

- (void)switchChanged {
    SettingsManager *s = [SettingsManager shared];
    s.autoFlip = _flipSwitch.on;
    s.hideLastMove = _hideSwitch.on;
    s.moveRating = _ratingSwitch.on;
    [s save];
}

- (void)startWithFEN:(NSString *)fen {
    GameManager *g = [[GameManager alloc] initWithFEN:fen mode:GameModeLocal humanColor:0 botLevel:1];
    [self.navigationController pushViewController:[[GameViewController alloc] initWithGame:g] animated:YES];
}

- (void)startTapped {
    [self startWithFEN:nil];
}

- (void)savedTapped {
    SavedPositionsViewController *list = [[SavedPositionsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    __weak LocalMultiplayerViewController *weakSelf = self;
    list.onPick = ^(NSString *name, NSString *fen) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            LocalMultiplayerViewController *me = weakSelf;
            if (!me) return;
            CEPosition p;
            char err[256];
            if (!ce_from_fen(&p, fen.UTF8String) || !ce_validate(&p, err, sizeof err)) {
                [YFUI showMessage:@"Deze opgeslagen stelling is niet geldig. Pas hem aan bij Custom chess." title:@"Kan niet starten" from:me];
                return;
            }
            [me startWithFEN:fen];
        });
    };
    [self.navigationController pushViewController:list animated:YES];
}

- (void)continueTapped {
    SavedGamesViewController *list = [[SavedGamesViewController alloc] initWithStyle:UITableViewStyleGrouped];
    __weak LocalMultiplayerViewController *weakSelf = self;
    list.onPick = ^(NSDictionary *game) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf resumeGame:game];
        });
    };
    [self.navigationController pushViewController:list animated:YES];
}

- (void)resumeGame:(NSDictionary *)game {
    GameManager *g = [[GameManager alloc] initWithFEN:game[@"fen"] mode:GameModeLocal humanColor:0 botLevel:1];
    NSArray *moves = game[@"moves"];
    if ([moves isKindOfClass:[NSArray class]]) [g loadMoves:moves];
    g.saveId = game[@"id"];
    g.saveName = game[@"name"];
    [self.navigationController pushViewController:[[GameViewController alloc] initWithGame:g] animated:YES];
}

- (void)customTapped {
    [self.navigationController pushViewController:[[CustomBoardEditorViewController alloc] init] animated:YES];
}

@end

#pragma mark - Opgeslagen partijen

@implementation SavedGamesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Opgeslagen partijen";
    self.tableView.rowHeight = [YFUI isPad] ? 64 : 54;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [YFUI applyThemeToController:self];
    self.tableView.backgroundColor = [SettingsManager shared].backgroundColor;
    self.tableView.backgroundView = nil;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger n = [SettingsManager shared].savedGames.count;
    return n ? n : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"Tik om verder te spelen. Veeg naar links om te verwijderen.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"game"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"game"];
    SettingsManager *s = [SettingsManager shared];
    cell.backgroundColor = s.panelColor;
    cell.textLabel.textColor = s.textColor;
    cell.detailTextLabel.textColor = s.secondaryTextColor;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:[YFUI isPad] ? 19 : 16];
    NSArray *games = s.savedGames;
    if (!games.count) {
        cell.textLabel.text = @"Nog geen opgeslagen partijen";
        cell.detailTextLabel.text = @"Tik tijdens een 1-tegen-1-partij op Opslaan.";
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    NSDictionary *g = games[indexPath.row];
    cell.textLabel.text = g[@"name"];
    NSArray *moves = g[@"moves"];
    NSUInteger plies = [moves isKindOfClass:[NSArray class]] ? moves.count : 0;
    NSString *dateText = @"";
    if ([g[@"date"] isKindOfClass:[NSDate class]]) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"d-M-yyyy HH:mm";
        dateText = [df stringFromDate:g[@"date"]];
    }
    NSString *fen = g[@"fen"];
    BOOL blackStarts = [fen rangeOfString:@" b "].location != NSNotFound;
    BOOL whiteToMove = ((plies % 2) == 0) != blackStarts;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu zetten \u2022 %@ aan zet \u2022 %@",
                                 (unsigned long)((plies + 1) / 2), whiteToMove ? @"wit" : @"zwart", dateText];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [SettingsManager shared].savedGames.count > 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Verwijder";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
    forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;
    NSArray *games = [SettingsManager shared].savedGames;
    if (indexPath.row >= (NSInteger)games.count) return;
    [[SettingsManager shared] deleteGameWithId:games[indexPath.row][@"id"]];
    [tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *games = [SettingsManager shared].savedGames;
    if (indexPath.row >= (NSInteger)games.count) return;
    NSDictionary *g = games[indexPath.row];
    void (^pick)(NSDictionary *) = self.onPick;
    [self.navigationController popViewControllerAnimated:YES];
    if (pick) pick(g);
}

@end
