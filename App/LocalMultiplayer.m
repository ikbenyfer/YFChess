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
    for (YFButton *b in @[_startButton, _savedButton, _customButton]) [b applyTheme];
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

- (void)customTapped {
    [self.navigationController pushViewController:[[CustomBoardEditorViewController alloc] init] animated:YES];
}

@end
