// MainMenu.m

#import "MainMenu.h"
#import "YFUI.h"
#import "SettingsManager.h"
#import "ChessPiece.h"
#import "GameManager.h"
#import "GameViewController.h"
#import "CustomBoardEditor.h"
#import "LocalMultiplayer.h"
#import "ChessClock.h"
#import "SettingsViewController.h"

@implementation MainMenuViewController {
    PieceView *_logo;
    UILabel *_titleLabel;
    UILabel *_subtitle;
    NSArray *_buttons;
    BOOL _didAnimate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Menu";
    _logo = [[PieceView alloc] initWithPiece:CE_PIECE(CE_WHITE, CE_KNIGHT)];
    [self.view addSubview:_logo];
    _titleLabel = [YFUI labelWithSize:[YFUI isPad] ? 44 : 32 bold:YES];
    _titleLabel.text = @"YF Schaak";
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_titleLabel];
    _subtitle = [YFUI labelWithSize:[YFUI isPad] ? 18 : 14 bold:NO];
    _subtitle.text = @"Klassiek schaken — helemaal offline";
    _subtitle.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_subtitle];

    NSArray *titles = @[ @"♚  Spelen tegen bot", @"♛  Custom chess", @"♞  Lokaal 1 tegen 1",
                         @"⏱  Schaakklok", @"⚙  Instellingen" ];
    SEL actions[5] = { @selector(botTapped), @selector(customTapped), @selector(localTapped),
                       @selector(clockTapped), @selector(settingsTapped) };
    NSMutableArray *bs = [NSMutableArray array];
    for (NSUInteger i = 0; i < titles.count; i++) {
        YFButton *b = [YFUI buttonWithTitle:titles[i] target:self action:actions[i]];
        b.titleLabel.font = [UIFont boldSystemFontOfSize:[YFUI isPad] ? 24 : 19];
        if (i == 0) b.primary = YES;
        [self.view addSubview:b];
        [bs addObject:b];
    }
    _buttons = bs;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [YFUI applyThemeToController:self];
    SettingsManager *s = [SettingsManager shared];
    _titleLabel.textColor = s.textColor;
    _subtitle.textColor = s.secondaryTextColor;
    [_logo setNeedsDisplay];
    for (YFButton *b in _buttons) [b applyTheme];
    [self setNeedsStatusBarAppearanceUpdate];
    if (!_didAnimate && s.animations) {
        for (UIView *v in _buttons) {
            v.alpha = 0.0;
        }
        _logo.alpha = 0.0;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [SettingsManager shared].darkTheme ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_didAnimate) return;
    _didAnimate = YES;
    if (![SettingsManager shared].animations) return;
    // Lichte animatie: het paard springt erin, de knoppen schuiven één voor één omhoog.
    _logo.transform = CGAffineTransformMakeScale(0.4, 0.4);
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0.8 options:0 animations:^{
        self->_logo.alpha = 1.0;
        self->_logo.transform = CGAffineTransformIdentity;
    } completion:nil];
    NSUInteger i = 0;
    for (UIView *v in _buttons) {
        v.transform = CGAffineTransformMakeTranslation(0, 24);
        [UIView animateWithDuration:0.35 delay:0.08 * i + 0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
            v.alpha = 1.0;
            v.transform = CGAffineTransformIdentity;
        } completion:nil];
        i++;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width, H = self.view.bounds.size.height;
    BOOL pad = [YFUI isPad];
    CGFloat bh = pad ? 70 : 54;
    CGFloat sp = pad ? 16 : 10;
    CGFloat logo = pad ? 130 : (H < 500 ? 60 : 90);
    CGFloat titleH = pad ? 56 : 40, subH = pad ? 26 : 20;
    CGFloat contentH = logo + titleH + subH + 24 + 5 * bh + 4 * sp;
    CGFloat y = MAX(24, (H - contentH) / 2.0);
    CGFloat colW = MIN(W - 40, pad ? 460 : 380);
    CGFloat x = (W - colW) / 2.0;
    _logo.transform = CGAffineTransformIdentity;
    _logo.frame = CGRectMake((W - logo) / 2.0, y, logo, logo);
    y += logo;
    _titleLabel.frame = CGRectMake(x, y, colW, titleH);
    y += titleH;
    _subtitle.frame = CGRectMake(x, y, colW, subH);
    y += subH + 24;
    for (UIView *v in _buttons) {
        CGAffineTransform t = v.transform;
        v.transform = CGAffineTransformIdentity;
        v.frame = CGRectMake(x, y, colW, bh);
        v.transform = t;
        y += bh + sp;
    }
}

- (void)botTapped {
    [self.navigationController pushViewController:[[BotSetupViewController alloc] init] animated:YES];
}

- (void)customTapped {
    [self.navigationController pushViewController:[[CustomBoardEditorViewController alloc] init] animated:YES];
}

- (void)localTapped {
    [self.navigationController pushViewController:[[LocalMultiplayerViewController alloc] init] animated:YES];
}

- (void)clockTapped {
    [self.navigationController pushViewController:[[ChessClockViewController alloc] init] animated:YES];
}

- (void)settingsTapped {
    [self.navigationController pushViewController:[[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped]
                                         animated:YES];
}

@end

#pragma mark - Tegen de bot: keuzes

@implementation BotSetupViewController {
    UILabel *_colorLabel;
    UISegmentedControl *_colorControl;
    UILabel *_levelLabel;
    UISegmentedControl *_levelControl;
    UILabel *_levelInfo;
    UILabel *_ratingLabel;
    UISwitch *_ratingSwitch;
    YFButton *_startButton;
    YFButton *_savedButton;
    YFButton *_customButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Spelen tegen bot";
    SettingsManager *s = [SettingsManager shared];
    CGFloat fs = [YFUI isPad] ? 20 : 16;
    _colorLabel = [YFUI labelWithSize:fs bold:YES];
    _colorLabel.text = @"Met welke kleur speel jij?";
    [self.view addSubview:_colorLabel];
    _colorControl = [[UISegmentedControl alloc] initWithItems:@[@"Wit", @"Zwart", @"Willekeurig"]];
    _colorControl.selectedSegmentIndex = s.botColor;
    [_colorControl addTarget:self action:@selector(changed) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_colorControl];
    _levelLabel = [YFUI labelWithSize:fs bold:YES];
    _levelLabel.text = @"Hoe sterk is de bot?";
    [self.view addSubview:_levelLabel];
    _levelControl = [[UISegmentedControl alloc] initWithItems:@[@"1", @"2", @"3", @"4", @"5"]];
    _levelControl.selectedSegmentIndex = s.botLevel - 1;
    [_levelControl addTarget:self action:@selector(changed) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_levelControl];
    _levelInfo = [YFUI labelWithSize:fs - 2 bold:NO];
    [self.view addSubview:_levelInfo];
    _ratingLabel = [YFUI labelWithSize:fs bold:YES];
    _ratingLabel.text = @"Zetbeoordeling (beste zet … blunder)";
    _ratingLabel.adjustsFontSizeToFitWidth = YES;
    _ratingLabel.minimumScaleFactor = 0.6;
    _ratingLabel.numberOfLines = 1;
    [self.view addSubview:_ratingLabel];
    _ratingSwitch = [YFUI themedSwitch];
    [_ratingSwitch addTarget:self action:@selector(ratingChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_ratingSwitch];
    _startButton = [YFUI buttonWithTitle:@"▶ Start (normale opstelling)" target:self action:@selector(startTapped)];
    _startButton.primary = YES;
    _savedButton = [YFUI buttonWithTitle:@"Start vanaf opgeslagen positie" target:self action:@selector(savedTapped)];
    _customButton = [YFUI buttonWithTitle:@"Eigen stelling maken (Custom)" target:self action:@selector(customTapped)];
    [self.view addSubview:_startButton];
    [self.view addSubview:_savedButton];
    [self.view addSubview:_customButton];
    [self changed];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [YFUI applyThemeToController:self];
    SettingsManager *s = [SettingsManager shared];
    for (UILabel *l in @[_colorLabel, _levelLabel, _ratingLabel]) l.textColor = s.textColor;
    _ratingSwitch.onTintColor = s.accentColor;
    _ratingSwitch.on = s.moveRating;
    _levelInfo.textColor = s.secondaryTextColor;
    _colorControl.tintColor = s.accentColor;
    _levelControl.tintColor = s.accentColor;
    _levelControl.selectedSegmentIndex = s.botLevel - 1;
    for (YFButton *b in @[_startButton, _savedButton, _customButton]) [b applyTheme];
    [self changed];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width;
    CGFloat colW = MIN(W - 40, 520);
    CGFloat x = (W - colW) / 2.0;
    CGFloat y = self.topLayoutGuide.length + 24;
    CGFloat bh = [YFUI isPad] ? 64 : 52;
    _colorLabel.frame = CGRectMake(x, y, colW, 28); y += 34;
    _colorControl.frame = CGRectMake(x, y, colW, 40); y += 58;
    _levelLabel.frame = CGRectMake(x, y, colW, 28); y += 34;
    _levelControl.frame = CGRectMake(x, y, colW, 40); y += 48;
    _levelInfo.frame = CGRectMake(x, y, colW, 48); y += 56;
    _ratingLabel.frame = CGRectMake(x, y, colW - 64, 40);
    _ratingSwitch.frame = CGRectMake(x + colW - 51, y + 4, 51, 31); y += 56;
    _startButton.frame = CGRectMake(x, y, colW, bh); y += bh + 12;
    _savedButton.frame = CGRectMake(x, y, colW, bh); y += bh + 12;
    _customButton.frame = CGRectMake(x, y, colW, bh);
}

- (void)changed {
    SettingsManager *s = [SettingsManager shared];
    s.botColor = _colorControl.selectedSegmentIndex;
    s.botLevel = _levelControl.selectedSegmentIndex + 1;
    [s save];
    NSArray *info = @[ @"1 — Beginner: kijkt maar één zet vooruit en maakt bewust foutjes.",
                       @"2 — Makkelijk: kijkt twee zetten vooruit, af en toe een foutje.",
                       @"3 — Gemiddeld: kijkt drie zetten vooruit.",
                       @"4 — Sterk: kijkt vier zetten vooruit.",
                       @"5 — Sterkst: denkt tot ongeveer 7 seconden na." ];
    _levelInfo.text = info[s.botLevel - 1];
}

- (void)ratingChanged {
    SettingsManager *s = [SettingsManager shared];
    s.moveRating = _ratingSwitch.on;
    [s save];
}

- (int)chosenColor {
    NSInteger c = _colorControl.selectedSegmentIndex;
    if (c == 2) return (int)arc4random_uniform(2);
    return (int)c;
}

- (void)startWithFEN:(NSString *)fen {
    GameManager *g = [[GameManager alloc] initWithFEN:fen mode:GameModeBot humanColor:[self chosenColor]
                                             botLevel:[SettingsManager shared].botLevel];
    [self.navigationController pushViewController:[[GameViewController alloc] initWithGame:g] animated:YES];
}

- (void)startTapped {
    [self startWithFEN:nil];
}

- (void)savedTapped {
    SavedPositionsViewController *list = [[SavedPositionsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    __weak BotSetupViewController *weakSelf = self;
    list.onPick = ^(NSString *name, NSString *fen) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf startCheckedFEN:fen];
        });
    };
    [self.navigationController pushViewController:list animated:YES];
}

- (void)startCheckedFEN:(NSString *)fen {
    CEPosition p;
    char err[256];
    if (!ce_from_fen(&p, fen.UTF8String) || !ce_validate(&p, err, sizeof err)) {
        [YFUI showMessage:@"Deze opgeslagen stelling is niet geldig. Pas hem aan bij Custom chess." title:@"Kan niet starten" from:self];
        return;
    }
    [self startWithFEN:fen];
}

- (void)customTapped {
    [self.navigationController pushViewController:[[CustomBoardEditorViewController alloc] init] animated:YES];
}

@end
