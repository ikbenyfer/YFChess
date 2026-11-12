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
#import "Online.h"
#import "Puzzles.h"

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
    _subtitle.text = @"Klassiek schaken — offline en online";
    _subtitle.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_subtitle];

    NSArray *titles = @[ @"♚  Spelen tegen bot", @"♛  Custom chess", @"♞  Lokaal 1 tegen 1",
                         @"🧩  Puzzels", @"🌐  Online spelen (lichess)", @"⏱  Schaakklok", @"⚙  Instellingen" ];
    SEL actions[7] = { @selector(botTapped), @selector(customTapped), @selector(localTapped), @selector(puzzlesTapped), @selector(onlineTapped),
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
    CGFloat bh = pad ? 60 : 50;
    CGFloat sp = pad ? 14 : 9;
    CGFloat logo = pad ? 120 : (H < 600 ? 56 : 84);
    CGFloat titleH = pad ? 52 : 40, subH = pad ? 26 : 20;
    CGFloat n = (CGFloat)_buttons.count;
    CGFloat contentH = logo + titleH + subH + 20 + n * bh + (n - 1) * sp;
    if (contentH > H - 30) {
        // Te weinig ruimte (bijv. liggend): kleiner logo en lagere knoppen.
        logo = pad ? 70 : 44;
        titleH = pad ? 44 : 34;
        contentH = logo + titleH + subH + 20 + n * bh + (n - 1) * sp;
        if (contentH > H - 30) {
            bh = MAX(40, (H - 30 - logo - titleH - subH - 20 - (n - 1) * sp) / n);
            contentH = logo + titleH + subH + 20 + n * bh + (n - 1) * sp;
        }
    }
    CGFloat y = MAX(24, (H - contentH) / 2.0);
    CGFloat colW = MIN(W - 40, pad ? 460 : 380);
    CGFloat x = (W - colW) / 2.0;
    _logo.transform = CGAffineTransformIdentity;
    _logo.frame = CGRectMake((W - logo) / 2.0, y, logo, logo);
    y += logo;
    _titleLabel.frame = CGRectMake(x, y, colW, titleH);
    y += titleH;
    _subtitle.frame = CGRectMake(x, y, colW, subH);
    y += subH + 20;
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

- (void)puzzlesTapped {
    [self.navigationController pushViewController:[[PuzzleHomeViewController alloc] init] animated:YES];
}

- (void)onlineTapped {
    [self.navigationController pushViewController:[[OnlineViewController alloc] init] animated:YES];
}

- (void)settingsTapped {
    [self.navigationController pushViewController:[[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped]
                                         animated:YES];
}

@end

#pragma mark - Tegen de bot: keuzes

@implementation BotSetupViewController {
    UIScrollView *_scroll;
    UILabel *_adaptiveTitle;
    UILabel *_adaptiveInfo;
    YFButton *_adaptiveButton;
    YFButton *_adaptiveReset;
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
    _scroll = [[UIScrollView alloc] init];
    _scroll.alwaysBounceVertical = YES;
    [self.view addSubview:_scroll];
    _adaptiveTitle = [YFUI labelWithSize:fs bold:YES];
    _adaptiveTitle.text = @"Meegroeiende bot";
    [_scroll addSubview:_adaptiveTitle];
    _adaptiveInfo = [YFUI labelWithSize:fs - 3 bold:NO];
    [_scroll addSubview:_adaptiveInfo];
    _adaptiveButton = [YFUI buttonWithTitle:@"" target:self action:@selector(adaptiveTapped)];
    _adaptiveButton.primary = YES;
    [_scroll addSubview:_adaptiveButton];
    _adaptiveReset = [YFUI buttonWithTitle:@"Terugzetten naar ultra slecht" target:self action:@selector(adaptiveResetTapped)];
    _adaptiveReset.titleLabel.font = [UIFont systemFontOfSize:fs - 3];
    [_scroll addSubview:_adaptiveReset];
    _colorLabel = [YFUI labelWithSize:fs bold:YES];
    _colorLabel.text = @"Met welke kleur speel jij?";
    [_scroll addSubview:_colorLabel];
    _colorControl = [[UISegmentedControl alloc] initWithItems:@[@"Wit", @"Zwart", @"Willekeurig"]];
    _colorControl.selectedSegmentIndex = s.botColor;
    [_colorControl addTarget:self action:@selector(changed) forControlEvents:UIControlEventValueChanged];
    [_scroll addSubview:_colorControl];
    _levelLabel = [YFUI labelWithSize:fs bold:YES];
    _levelLabel.text = @"Of kies zelf een vast niveau:";
    [_scroll addSubview:_levelLabel];
    _levelControl = [[UISegmentedControl alloc] initWithItems:@[@"0", @"1", @"2", @"3", @"4", @"5"]];
    _levelControl.selectedSegmentIndex = s.botLevel;
    [_levelControl addTarget:self action:@selector(changed) forControlEvents:UIControlEventValueChanged];
    [_scroll addSubview:_levelControl];
    _levelInfo = [YFUI labelWithSize:fs - 2 bold:NO];
    [_scroll addSubview:_levelInfo];
    _ratingLabel = [YFUI labelWithSize:fs bold:YES];
    _ratingLabel.text = @"Zetbeoordeling (beste zet … blunder)";
    _ratingLabel.adjustsFontSizeToFitWidth = YES;
    _ratingLabel.minimumScaleFactor = 0.6;
    _ratingLabel.numberOfLines = 1;
    [_scroll addSubview:_ratingLabel];
    _ratingSwitch = [YFUI themedSwitch];
    [_ratingSwitch addTarget:self action:@selector(ratingChanged) forControlEvents:UIControlEventValueChanged];
    [_scroll addSubview:_ratingSwitch];
    _startButton = [YFUI buttonWithTitle:@"▶ Start op dit niveau" target:self action:@selector(startTapped)];
    _savedButton = [YFUI buttonWithTitle:@"Start vanaf opgeslagen positie" target:self action:@selector(savedTapped)];
    _customButton = [YFUI buttonWithTitle:@"Eigen stelling maken (Custom)" target:self action:@selector(customTapped)];
    [_scroll addSubview:_startButton];
    [_scroll addSubview:_savedButton];
    [_scroll addSubview:_customButton];
    [self changed];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [YFUI applyThemeToController:self];
    SettingsManager *s = [SettingsManager shared];
    for (UILabel *l in @[_colorLabel, _levelLabel, _ratingLabel, _adaptiveTitle]) l.textColor = s.textColor;
    _adaptiveInfo.textColor = s.secondaryTextColor;
    [_adaptiveButton applyTheme];
    [_adaptiveReset applyTheme];
    [self updateAdaptive];
    _ratingSwitch.onTintColor = s.accentColor;
    _ratingSwitch.on = s.moveRating;
    _levelInfo.textColor = s.secondaryTextColor;
    _colorControl.tintColor = s.accentColor;
    _levelControl.tintColor = s.accentColor;
    _levelControl.selectedSegmentIndex = s.botLevel;
    for (YFButton *b in @[_startButton, _savedButton, _customButton]) [b applyTheme];
    [self changed];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width;
    _scroll.frame = self.view.bounds;
    CGFloat colW = MIN(W - 40, 520);
    CGFloat x = (W - colW) / 2.0;
    CGFloat y = self.topLayoutGuide.length + 20;
    CGFloat bh = [YFUI isPad] ? 60 : 50;
    _colorLabel.frame = CGRectMake(x, y, colW, 28); y += 34;
    _colorControl.frame = CGRectMake(x, y, colW, 40); y += 56;
    _adaptiveTitle.frame = CGRectMake(x, y, colW, 28); y += 30;
    CGSize ai = [_adaptiveInfo sizeThatFits:CGSizeMake(colW, 400)];
    _adaptiveInfo.frame = CGRectMake(x, y, colW, ceil(ai.height)); y += ceil(ai.height) + 8;
    _adaptiveButton.frame = CGRectMake(x, y, colW, bh); y += bh + 8;
    _adaptiveReset.frame = CGRectMake(x + colW * 0.25, y, colW * 0.5, 36); y += 36 + 26;
    _levelLabel.frame = CGRectMake(x, y, colW, 28); y += 34;
    _levelControl.frame = CGRectMake(x, y, colW, 40); y += 48;
    _levelInfo.frame = CGRectMake(x, y, colW, 48); y += 56;
    _ratingLabel.frame = CGRectMake(x, y, colW - 64, 40);
    _ratingSwitch.frame = CGRectMake(x + colW - 51, y + 4, 51, 31); y += 56;
    _startButton.frame = CGRectMake(x, y, colW, bh); y += bh + 12;
    _savedButton.frame = CGRectMake(x, y, colW, bh); y += bh + 12;
    _customButton.frame = CGRectMake(x, y, colW, bh);
    _scroll.contentSize = CGSizeMake(W, y + bh + 24);
}

- (void)updateAdaptive {
    SettingsManager *s = [SettingsManager shared];
    NSInteger st = s.adaptiveStrength;
    [_adaptiveButton setTitle:[NSString stringWithFormat:@"▶ Meegroeiende bot (sterkte %ld · %@)", (long)st,
                               [SettingsManager strengthName:st]] forState:UIControlStateNormal];
    _adaptiveInfo.text = [NSString stringWithFormat:
        @"Begint ultra slecht. Win je, dan wordt hij sterker. Wint hij, dan wordt hij weer makkelijker. "
        @"Tot nu toe: %ld gewonnen, %ld verloren, %ld remise.",
        (long)s.adaptiveWins, (long)s.adaptiveLosses, (long)s.adaptiveDraws];
    _adaptiveReset.hidden = st == 0 && s.adaptiveWins + s.adaptiveLosses + s.adaptiveDraws == 0;
    [self.view setNeedsLayout];
}

- (void)adaptiveTapped {
    SettingsManager *s = [SettingsManager shared];
    GameManager *g = [[GameManager alloc] initWithFEN:nil mode:GameModeBot humanColor:[self chosenColor] botLevel:1];
    g.adaptive = YES;
    g.adaptiveStrength = s.adaptiveStrength;
    [self.navigationController pushViewController:[[GameViewController alloc] initWithGame:g] animated:YES];
}

- (void)adaptiveResetTapped {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Terugzetten?"
                                                               message:@"De meegroeiende bot begint weer ultra slecht en de telling gaat naar 0."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Terugzetten" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *act) {
        SettingsManager *s = [SettingsManager shared];
        s.adaptiveStrength = 0;
        s.adaptiveWins = 0;
        s.adaptiveLosses = 0;
        s.adaptiveDraws = 0;
        [s save];
        [self updateAdaptive];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)changed {
    SettingsManager *s = [SettingsManager shared];
    s.botColor = _colorControl.selectedSegmentIndex;
    s.botLevel = _levelControl.selectedSegmentIndex;
    [s save];
    NSArray *info = @[ @"0 — Super makkelijk: doet meestal zomaar een zet en geeft vaak stukken weg. Goed om mee te beginnen!",
                       @"1 — Beginner: kijkt maar één zet vooruit en maakt bewust foutjes.",
                       @"2 — Makkelijk: kijkt twee zetten vooruit, af en toe een foutje.",
                       @"3 — Gemiddeld: kijkt drie zetten vooruit.",
                       @"4 — Sterk: kijkt vier zetten vooruit.",
                       @"5 — Sterkst: denkt tot ongeveer 7 seconden na." ];
    _levelInfo.text = info[MAX(0, MIN(5, s.botLevel))];
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
