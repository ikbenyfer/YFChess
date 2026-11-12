// ChessClock.m

#import "ChessClock.h"
#import "SettingsManager.h"
#import "YFUI.h"

static NSTimeInterval Now(void) {
    // Echte kloktijd: loopt ook door als de iPad slaapt of de app op de achtergrond staat.
    return [[NSDate date] timeIntervalSince1970];
}

@implementation ChessClock {
    NSTimeInterval _remaining[2];   // tijd over op het moment dat de huidige klok startte
    NSTimeInterval _segmentStart;
    NSInteger _moves[2];
    int _pausedSide;
}

+ (instancetype)shared {
    static ChessClock *c = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        c = [[ChessClock alloc] init];
        SettingsManager *s = [SettingsManager shared];
        [c configureBase:s.clockBaseSeconds increment:s.clockIncrementSeconds];
        [c loadState];
    });
    return c;
}

- (void)configureBase:(NSTimeInterval)base increment:(NSTimeInterval)inc {
    _baseTime = base > 0 ? base : 60;
    _increment = inc >= 0 ? inc : 0;
    [self reset];
}

- (void)reset {
    _remaining[0] = _remaining[1] = _baseTime;
    _moves[0] = _moves[1] = 0;
    _running = -1;
    _pausedSide = -1;
    _paused = NO;
    _flagged = -1;
    _started = NO;
    [self saveState];
}

- (NSTimeInterval)remainingFor:(int)player {
    if (player < 0 || player > 1) return 0;
    NSTimeInterval r = _remaining[player];
    if (_running == player) r -= Now() - _segmentStart;
    return r < 0 ? 0 : r;
}

- (NSInteger)movesFor:(int)player {
    return (player == 0 || player == 1) ? _moves[player] : 0;
}

- (void)update {
    if (_running < 0) return;
    if ([self remainingFor:_running] <= 0) {
        _remaining[_running] = 0;
        _flagged = _running;
        _running = -1;
        [self saveState];
    }
}

- (void)tapPlayer:(int)player {
    [self update];
    if (_flagged >= 0 || _paused || player < 0 || player > 1) return;
    int other = 1 - player;
    if (!_started) {
        _started = YES;
        _running = other;
        _segmentStart = Now();
    } else if (_running == player) {
        _remaining[player] -= Now() - _segmentStart;
        _remaining[player] += _increment;
        _moves[player]++;
        _running = other;
        _segmentStart = Now();
    }
    [self saveState];
}

- (void)pause {
    [self update];
    if (_running < 0 || _paused) return;
    _remaining[_running] -= Now() - _segmentStart;
    _pausedSide = _running;
    _running = -1;
    _paused = YES;
    [self saveState];
}

- (void)resume {
    if (!_paused) return;
    _paused = NO;
    _running = _pausedSide;
    _pausedSide = -1;
    _segmentStart = Now();
    [self saveState];
}

- (void)saveState {
    NSDictionary *d = @{ @"base": @(_baseTime), @"inc": @(_increment),
                         @"r0": @(_remaining[0]), @"r1": @(_remaining[1]),
                         @"m0": @(_moves[0]), @"m1": @(_moves[1]),
                         @"running": @(_running), @"pausedSide": @(_pausedSide),
                         @"paused": @(_paused), @"flagged": @(_flagged),
                         @"started": @(_started), @"segStart": @(_segmentStart) };
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:@"clockState"];
}

- (void)loadState {
    NSDictionary *d = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"clockState"];
    if (!d[@"base"]) return;
    _baseTime = [d[@"base"] doubleValue];
    _increment = [d[@"inc"] doubleValue];
    _remaining[0] = [d[@"r0"] doubleValue];
    _remaining[1] = [d[@"r1"] doubleValue];
    _moves[0] = [d[@"m0"] integerValue];
    _moves[1] = [d[@"m1"] integerValue];
    _running = [d[@"running"] intValue];
    _pausedSide = [d[@"pausedSide"] intValue];
    _paused = [d[@"paused"] boolValue];
    _flagged = [d[@"flagged"] intValue];
    _started = [d[@"started"] boolValue];
    _segmentStart = [d[@"segStart"] doubleValue];
    if (_baseTime <= 0) [self configureBase:300 increment:0];
    [self update];
}

+ (NSString *)format:(NSTimeInterval)t {
    if (t < 0) t = 0;
    if (t < 10) {
        double tenths = floor(t * 10.0) / 10.0;
        return [NSString stringWithFormat:@"0:%04.1f", tenths];
    }
    long s = (long)ceil(t);
    long h = s / 3600, m = (s % 3600) / 60, sec = s % 60;
    if (h > 0) return [NSString stringWithFormat:@"%ld:%02ld:%02ld", h, m, sec];
    return [NSString stringWithFormat:@"%ld:%02ld", m, sec];
}

@end

#pragma mark - Klokvlak (groot tikvlak per speler)

@interface ClockFace : UIControl
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@end

@implementation ClockFace
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 16;
        self.clipsToBounds = YES;
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.adjustsFontSizeToFitWidth = YES;
        _timeLabel.minimumScaleFactor = 0.3;
        _timeLabel.userInteractionEnabled = NO;
        [self addSubview:_timeLabel];
        _infoLabel = [[UILabel alloc] init];
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.font = [UIFont boldSystemFontOfSize:[YFUI isPad] ? 22 : 16];
        _infoLabel.userInteractionEnabled = NO;
        [self addSubview:_infoLabel];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize s = self.bounds.size;
    CGFloat fontSize = MIN(s.height * 0.42, s.width * 0.24);
    _timeLabel.font = [UIFont monospacedDigitSystemFontOfSize:fontSize weight:UIFontWeightBold];
    _timeLabel.frame = CGRectMake(10, s.height * 0.12, s.width - 20, s.height * 0.6);
    _infoLabel.frame = CGRectMake(10, s.height * 0.72, s.width - 20, s.height * 0.2);
}
@end

#pragma mark - Klokscherm

@implementation ChessClockViewController {
    ClockFace *_faces[2];   // 0 = boven/links, 1 = onder/rechts
    YFButton *_pauseButton;
    YFButton *_resetButton;
    YFButton *_timeButton;
    UILabel *_presetLabel;
    NSTimer *_timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Schaakklok";
    for (int i = 0; i < 2; i++) {
        _faces[i] = [[ClockFace alloc] initWithFrame:CGRectZero];
        _faces[i].tag = i;
        [_faces[i] addTarget:self action:@selector(faceTouched:) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:_faces[i]];
    }
    _pauseButton = [YFUI buttonWithTitle:@"Pauze" target:self action:@selector(pauseTapped)];
    _resetButton = [YFUI buttonWithTitle:@"Reset" target:self action:@selector(resetTapped)];
    _timeButton = [YFUI buttonWithTitle:@"Tijd kiezen" target:self action:@selector(timeTapped)];
    [self.view addSubview:_pauseButton];
    [self.view addSubview:_resetButton];
    [self.view addSubview:_timeButton];
    _presetLabel = [YFUI labelWithSize:[YFUI isPad] ? 20 : 15 bold:YES];
    _presetLabel.textAlignment = NSTextAlignmentCenter;
    _presetLabel.numberOfLines = 1;
    _presetLabel.adjustsFontSizeToFitWidth = YES;
    [self.view addSubview:_presetLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [YFUI applyThemeToController:self];
    _presetLabel.textColor = [SettingsManager shared].textColor;
    for (YFButton *b in @[_pauseButton, _resetButton, _timeButton]) [b applyTheme];
    _timer = [NSTimer timerWithTimeInterval:0.05 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    [self tick];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_timer invalidate];
    _timer = nil;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[ChessClock shared] saveState];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width, H = self.view.bounds.size.height;
    CGFloat top = self.topLayoutGuide.length + 10, bottom = self.bottomLayoutGuide.length + 10;
    CGFloat m = 10;
    CGFloat barH = [YFUI isPad] ? 64 : 52;
    if (W > H) {
        // Liggend: links en rechts, knoppen onderaan.
        CGFloat faceH = H - top - bottom - barH - m;
        CGFloat faceW = (W - 3 * m) / 2.0;
        _faces[0].transform = CGAffineTransformIdentity;
        _faces[0].frame = CGRectMake(m, top, faceW, faceH);
        _faces[1].frame = CGRectMake(2 * m + faceW, top, faceW, faceH);
        CGFloat y = top + faceH + m;
        CGFloat labelW = 110;
        _presetLabel.frame = CGRectMake(m, y, labelW, barH);
        [YFUI layoutViews:@[_pauseButton, _resetButton, _timeButton] x:m * 2 + labelW y:y
                    width:W - 3 * m - labelW itemHeight:barH columns:3 spacing:8];
    } else {
        // Staand: boven (omgedraaid voor de speler aan de overkant) en onder.
        CGFloat faceH = (H - top - bottom - barH - 2 * m) / 2.0;
        _faces[0].transform = CGAffineTransformIdentity;
        _faces[0].frame = CGRectMake(m, top, W - 2 * m, faceH);
        _faces[0].transform = CGAffineTransformMakeRotation(M_PI);
        _faces[1].frame = CGRectMake(m, top + faceH + barH + 2 * m, W - 2 * m, faceH);
        CGFloat y = top + faceH + m;
        CGFloat labelW = [YFUI isPad] ? 110 : 64;
        _presetLabel.frame = CGRectMake(m, y, labelW, barH);
        [YFUI layoutViews:@[_pauseButton, _resetButton, _timeButton] x:m * 2 + labelW y:y
                    width:W - 3 * m - labelW itemHeight:barH columns:3 spacing:8];
    }
}

- (NSString *)presetName {
    ChessClock *c = [ChessClock shared];
    long base = (long)c.baseTime, inc = (long)c.increment;
    if (base % 60 == 0) return [NSString stringWithFormat:@"%ld+%ld", base / 60, inc];
    return [NSString stringWithFormat:@"%ld:%02ld+%ld", base / 60, base % 60, inc];
}

- (void)tick {
    ChessClock *c = [ChessClock shared];
    [c update];
    SettingsManager *s = [SettingsManager shared];
    for (int i = 0; i < 2; i++) {
        ClockFace *f = _faces[i];
        NSTimeInterval left = [c remainingFor:i];
        f.timeLabel.text = [ChessClock format:left];
        UIColor *bg, *fg;
        NSString *info;
        if (c.flagged == i) {
            bg = [UIColor colorWithRed:0.75 green:0.12 blue:0.10 alpha:1.0];
            fg = [UIColor whiteColor];
            info = @"TIJD OP! Verloren op tijd";
        } else if (c.running == i) {
            bg = [UIColor colorWithRed:0.18 green:0.55 blue:0.25 alpha:1.0];
            fg = [UIColor whiteColor];
            info = left < 10 ? @"Jouw klok loopt — schiet op!" : @"Jouw klok loopt — tik als je klaar bent";
        } else {
            bg = s.buttonColor;
            fg = s.buttonTextColor;
            if (c.paused && i == 0 && c.flagged < 0) info = @"Gepauzeerd";
            else if (c.paused && c.flagged < 0) info = @"Gepauzeerd";
            else if (!c.started) info = i == 1 ? @"Zwart: tik hier om de klok van Wit te starten" : @"Wacht op start";
            else if (c.flagged >= 0) info = @"Gewonnen op tijd";
            else info = @"Wacht";
        }
        info = [NSString stringWithFormat:@"%@   •   %@ zetten", info, @([c movesFor:i])];
        f.backgroundColor = bg;
        f.timeLabel.textColor = fg;
        f.infoLabel.textColor = fg;
        f.infoLabel.text = info;
    }
    [_pauseButton setTitle:c.paused ? @"▶ Verder" : @"⏸ Pauze" forState:UIControlStateNormal];
    _pauseButton.enabled = c.paused || c.running >= 0;
    _presetLabel.text = [self presetName];
    [UIApplication sharedApplication].idleTimerDisabled = (c.running >= 0);
}

- (void)faceTouched:(ClockFace *)face {
    [[ChessClock shared] tapPlayer:(int)face.tag];
    [self tick];
}

- (void)pauseTapped {
    ChessClock *c = [ChessClock shared];
    if (c.paused) [c resume]; else [c pause];
    [self tick];
}

- (void)resetTapped {
    ChessClock *c = [ChessClock shared];
    if (!c.started) { [c reset]; [self tick]; return; }
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Klok resetten?"
                                                               message:@"Beide klokken gaan terug naar de begintijd."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *act) {
        [[ChessClock shared] reset];
        [self tick];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)applyBase:(NSInteger)base increment:(NSInteger)inc {
    SettingsManager *s = [SettingsManager shared];
    s.clockBaseSeconds = base;
    s.clockIncrementSeconds = inc;
    [s save];
    [[ChessClock shared] configureBase:base increment:inc];
    [self tick];
}

- (void)timeTapped {
    ChessClock *c = [ChessClock shared];
    if (c.running >= 0) [c pause];
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Bedenktijd kiezen"
                                                               message:@"Minuten + seconden extra per zet. De klok wordt gereset."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    NSArray *presets = @[ @[@1, @0], @[@3, @2], @[@5, @0], @[@10, @5], @[@15, @10] ];
    for (NSArray *p in presets) {
        NSInteger mins = [p[0] integerValue], inc = [p[1] integerValue];
        NSString *title = [NSString stringWithFormat:@"%ld + %ld", (long)mins, (long)inc];
        [a addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
            [self applyBase:mins * 60 increment:inc];
        }]];
    }
    [a addAction:[UIAlertAction actionWithTitle:@"Eigen tijd…" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        [self askCustomTime];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)askCustomTime {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Eigen tijd"
                                                               message:@"Vul de minuten per speler en de seconden extra per zet in."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"Minuten (bijv. 7)";
        tf.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"Seconden extra per zet (bijv. 3)";
        tf.keyboardType = UIKeyboardTypeNumberPad;
    }];
    __weak UIAlertController *weakAlert = a;
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Gebruiken" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        NSString *minText = [weakAlert.textFields[0].text stringByReplacingOccurrencesOfString:@"," withString:@"."];
        double mins = [minText doubleValue];
        NSInteger inc = [weakAlert.textFields[1].text integerValue];
        if (mins <= 0 || mins > 600 || inc < 0 || inc > 600) {
            [YFUI showMessage:@"Kies 0,1 tot 600 minuten en 0 tot 600 seconden extra." title:@"Ongeldige tijd" from:self];
            return;
        }
        NSInteger base = (NSInteger)llround(mins * 60.0);
        if (base < 1) base = 1;
        [self applyBase:base increment:inc];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
