// Online.m

#import "Online.h"
#import "LichessClient.h"
#import "ChessBoard.h"
#import "ChessPiece.h"
#import "SettingsManager.h"
#import "YFUI.h"
#include "ChessEngine.h"

static NSString *const kTokenURL =
    @"https://lichess.org/account/oauth/token/create?scopes%5B%5D=board:play&scopes%5B%5D=challenge:write&description=YF%20Schaak";

typedef NS_ENUM(NSInteger, OnlineState) {
    OnlineStateNoToken = 0,
    OnlineStateChecking,
    OnlineStateError,
    OnlineStateReady,
    OnlineStateSeeking,
    OnlineStateWaiting
};

static NSString *PlayerName(NSDictionary *p) {
    if (![p isKindOfClass:[NSDictionary class]]) return @"?";
    id ai = p[@"aiLevel"];
    if (ai && ai != [NSNull null]) return [NSString stringWithFormat:@"lichess-computer (niveau %@)", ai];
    NSString *name = p[@"name"] ?: p[@"username"] ?: p[@"id"] ?: @"?";
    id rating = p[@"rating"];
    if (rating && rating != [NSNull null]) {
        BOOL prov = [p[@"provisional"] boolValue];
        return [NSString stringWithFormat:@"%@ (%@%@)", name, rating, prov ? @"?" : @""];
    }
    return name;
}

#pragma mark - Lobby

@implementation OnlineViewController {
    UIScrollView *_scroll;
    UILabel *_info;
    UILabel *_account;
    UIActivityIndicatorView *_spinner;
    YFButton *_tokenButton;
    YFButton *_helpButton;
    YFButton *_retryButton;
    UILabel *_timeLabel;
    UISegmentedControl *_timeControl;
    UILabel *_ratedLabel;
    UISwitch *_ratedSwitch;
    YFButton *_seekButton;
    UILabel *_aiLabel;
    UISegmentedControl *_aiLevel;
    YFButton *_aiButton;
    YFButton *_friendButton;
    YFButton *_resumeButton;
    YFButton *_cancelButton;
    YFButton *_logoutButton;
    NSArray *_order;
    OnlineState _state;
    LichessStream *_events;
    LichessStream *_seek;
    NSString *_pendingChallengeId;
    NSArray *_playing;
    BOOL _openingGame;
    BOOL _visible;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Online spelen (lichess)";
    CGFloat fs = [YFUI isPad] ? 18 : 15;
    _scroll = [[UIScrollView alloc] init];
    _scroll.alwaysBounceVertical = YES;
    [self.view addSubview:_scroll];

    _info = [YFUI labelWithSize:fs bold:NO];
    _account = [YFUI labelWithSize:fs + 2 bold:YES];
    _account.textAlignment = NSTextAlignmentCenter;
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.hidesWhenStopped = YES;

    _tokenButton = [YFUI buttonWithTitle:@"Token invullen (inloggen)" target:self action:@selector(tokenTapped)];
    _tokenButton.primary = YES;
    _helpButton = [YFUI buttonWithTitle:@"Hoe krijg ik een token?" target:self action:@selector(helpTapped)];
    _retryButton = [YFUI buttonWithTitle:@"Opnieuw proberen" target:self action:@selector(refreshAccount)];

    _timeLabel = [YFUI labelWithSize:fs bold:YES];
    _timeLabel.text = @"Bedenktijd (minuten + seconden per zet):";
    _timeControl = [[UISegmentedControl alloc] initWithItems:@[@"10+0", @"10+5", @"15+10", @"30+0"]];
    _timeControl.selectedSegmentIndex = 0;
    _ratedLabel = [YFUI labelWithSize:fs bold:YES];
    _ratedLabel.text = @"Telt mee voor je rating";
    _ratedSwitch = [YFUI themedSwitch];
    _ratedSwitch.on = NO;
    _seekButton = [YFUI buttonWithTitle:@"▶ Zoek een tegenstander" target:self action:@selector(seekTapped)];
    _seekButton.primary = YES;
    _aiLabel = [YFUI labelWithSize:fs bold:YES];
    _aiLabel.text = @"Of speel tegen de lichess-computer (niveau 1 t/m 8):";
    _aiLevel = [[UISegmentedControl alloc] initWithItems:@[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8"]];
    _aiLevel.selectedSegmentIndex = 1;
    _aiButton = [YFUI buttonWithTitle:@"Speel tegen lichess-computer" target:self action:@selector(aiTapped)];
    _friendButton = [YFUI buttonWithTitle:@"Daag een vriend uit" target:self action:@selector(friendTapped)];
    _resumeButton = [YFUI buttonWithTitle:@"Lopende partij hervatten" target:self action:@selector(resumeTapped)];
    _resumeButton.primary = YES;
    _cancelButton = [YFUI buttonWithTitle:@"Annuleren" target:self action:@selector(cancelTapped)];
    _logoutButton = [YFUI buttonWithTitle:@"Uitloggen" target:self action:@selector(logoutTapped)];

    _order = @[ _account, _info, _spinner, _tokenButton, _helpButton, _retryButton, _resumeButton,
                _timeLabel, _timeControl, _ratedLabel, _seekButton, _cancelButton,
                _aiLabel, _aiLevel, _aiButton, _friendButton, _logoutButton ];
    for (UIView *v in _order) [_scroll addSubview:v];
    [_scroll addSubview:_ratedSwitch];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [YFUI applyThemeToController:self];
    SettingsManager *s = [SettingsManager shared];
    for (UILabel *l in @[_info, _timeLabel, _ratedLabel, _aiLabel]) l.textColor = s.textColor;
    _account.textColor = s.accentColor;
    _spinner.color = s.accentColor;
    _timeControl.tintColor = s.accentColor;
    _aiLevel.tintColor = s.accentColor;
    _ratedSwitch.onTintColor = s.accentColor;
    for (UIView *v in _order) if ([v isKindOfClass:[YFButton class]]) [(YFButton *)v applyTheme];
    _visible = YES;
    _openingGame = NO;
    [self refreshAccount];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _visible = NO;
    [self stopStreams];
    if (_state == OnlineStateSeeking || _state == OnlineStateWaiting) [self cancelTapped];
}

- (void)stopStreams {
    [_events cancel];
    _events = nil;
    [_seek cancel];
    _seek = nil;
}

#pragma mark - Toestand en opmaak

- (void)setState:(OnlineState)state info:(NSString *)info {
    _state = state;
    LichessClient *c = [LichessClient shared];
    _info.text = info;
    BOOL ready = state == OnlineStateReady;
    _account.hidden = !(c.username.length && state >= OnlineStateReady);
    if (!_account.hidden) _account.text = [NSString stringWithFormat:@"Ingelogd als %@", c.username];
    _tokenButton.hidden = !(state == OnlineStateNoToken);
    _helpButton.hidden = !(state == OnlineStateNoToken || state == OnlineStateError);
    _retryButton.hidden = !(state == OnlineStateError);
    _resumeButton.hidden = !(ready && _playing.count);
    for (UIView *v in @[_timeLabel, _timeControl, _ratedLabel, _ratedSwitch, _seekButton, _aiLabel, _aiLevel, _aiButton, _friendButton])
        v.hidden = !ready;
    _cancelButton.hidden = !(state == OnlineStateSeeking || state == OnlineStateWaiting);
    _logoutButton.hidden = !(state == OnlineStateReady || state == OnlineStateError) || ![c hasToken];
    if (state == OnlineStateChecking || state == OnlineStateSeeking || state == OnlineStateWaiting) [_spinner startAnimating];
    else [_spinner stopAnimating];
    [self.view setNeedsLayout];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width;
    _scroll.frame = self.view.bounds;
    CGFloat colW = MIN(W - 32, 560);
    CGFloat x = (W - colW) / 2.0;
    CGFloat y = self.topLayoutGuide.length + 16;
    CGFloat bh = [YFUI isPad] ? 60 : 50;
    for (UIView *v in _order) {
        if (v.hidden && v != _spinner) continue;
        if (v == _spinner) {
            if (!_spinner.isAnimating) continue;
            _spinner.center = CGPointMake(W / 2.0, y + 14);
            y += 36;
        } else if ([v isKindOfClass:[YFButton class]]) {
            v.frame = CGRectMake(x, y, colW, bh);
            y += bh + 12;
        } else if ([v isKindOfClass:[UISegmentedControl class]]) {
            v.frame = CGRectMake(x, y, colW, 36);
            y += 48;
        } else if (v == _ratedLabel) {
            v.frame = CGRectMake(x, y, colW - 64, 36);
            _ratedSwitch.frame = CGRectMake(x + colW - 51, y + 2, 51, 31);
            y += 46;
        } else {
            CGSize s = [(UILabel *)v sizeThatFits:CGSizeMake(colW, 2000)];
            v.frame = CGRectMake(x, y, colW, ceil(s.height));
            y += ceil(s.height) + 12;
        }
        if (v == _seekButton || v == _resumeButton) y += 12;
    }
    _scroll.contentSize = CGSizeMake(W, y + 20);
}

#pragma mark - Account

- (void)refreshAccount {
    LichessClient *c = [LichessClient shared];
    if (![c hasToken]) {
        [self setState:OnlineStateNoToken info:
         @"Speel online tegen echte mensen op lichess.org (gratis). Je hebt wifi nodig en een lichess-account.\n\n"
         @"Inloggen gaat met een token: een soort wachtwoord alleen voor deze app. "
         @"Tik op “Hoe krijg ik een token?” voor de stappen."];
        return;
    }
    [self setState:OnlineStateChecking info:@"Verbinden met lichess.org…"];
    __weak OnlineViewController *weakSelf = self;
    [c request:@"GET" path:@"/api/account" form:nil completion:^(NSInteger status, id json, NSString *errorText) {
        OnlineViewController *me = weakSelf;
        if (!me || !me->_visible) return;
        if (status == 401) {
            [[LichessClient shared] logout];
            [me setState:OnlineStateNoToken info:@"Je token is niet (meer) geldig. Maak een nieuw token en vul het opnieuw in."];
            return;
        }
        if (errorText || ![json isKindOfClass:[NSDictionary class]]) {
            [me setState:OnlineStateError info:errorText ?: @"Onverwacht antwoord van lichess."];
            return;
        }
        LichessClient *cl = [LichessClient shared];
        cl.username = json[@"username"];
        cl.userId = [json[@"id"] lowercaseString];
        NSDictionary *perfs = json[@"perfs"];
        NSMutableArray *ratings = [NSMutableArray array];
        for (NSString *k in @[@"rapid", @"classical", @"blitz"]) {
            NSDictionary *p = [perfs isKindOfClass:[NSDictionary class]] ? perfs[k] : nil;
            if ([p isKindOfClass:[NSDictionary class]] && p[@"rating"])
                [ratings addObject:[NSString stringWithFormat:@"%@ %@", k, p[@"rating"]]];
        }
        NSString *info = ratings.count ? [NSString stringWithFormat:@"Rating: %@.", [ratings componentsJoinedByString:@", "]]
                                       : @"Klaar om te spelen.";
        info = [info stringByAppendingString:@"\nLet op: online mag je geen hulp van een bot gebruiken (regels van lichess). De zetbeoordeling staat hier uit."];
        [me setState:OnlineStateReady info:info];
        [me startEventStream];
        [me loadPlaying];
    }];
}

- (void)loadPlaying {
    __weak OnlineViewController *weakSelf = self;
    [[LichessClient shared] request:@"GET" path:@"/api/account/playing" form:nil completion:^(NSInteger status, id json, NSString *errorText) {
        OnlineViewController *me = weakSelf;
        if (!me || errorText || ![json isKindOfClass:[NSDictionary class]]) return;
        NSArray *list = json[@"nowPlaying"];
        me->_playing = [list isKindOfClass:[NSArray class]] ? list : @[];
        if (me->_state == OnlineStateReady) [me setState:OnlineStateReady info:me->_info.text];
    }];
}

- (void)startEventStream {
    [_events cancel];
    __weak OnlineViewController *weakSelf = self;
    _events = [[LichessClient shared] streamPath:@"/api/stream/event" method:@"GET" form:nil
        onLine:^(NSDictionary *obj) {
            [weakSelf handleEvent:obj];
        } onEnd:^(NSInteger status, NSString *errorText) {
            OnlineViewController *me = weakSelf;
            if (!me || !me->_visible) return;
            me->_events = nil;
            // Verbinding weggevallen: na een paar seconden opnieuw.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                OnlineViewController *me2 = weakSelf;
                if (me2 && me2->_visible && !me2->_events && me2->_state >= OnlineStateReady) [me2 startEventStream];
            });
        }];
}

- (void)handleEvent:(NSDictionary *)obj {
    NSString *type = obj[@"type"];
    if ([type isEqualToString:@"gameStart"]) {
        NSDictionary *g = obj[@"game"];
        NSString *gid = g[@"gameId"] ?: g[@"id"];
        if (gid) [self openGame:gid];
    } else if ([type isEqualToString:@"challenge"]) {
        NSDictionary *ch = obj[@"challenge"];
        NSString *from = [ch[@"challenger"][@"id"] lowercaseString];
        if ([from isEqualToString:[LichessClient shared].userId]) return;
        [self showIncomingChallenge:ch];
    } else if ([type isEqualToString:@"challengeDeclined"]) {
        NSDictionary *ch = obj[@"challenge"];
        if ([ch[@"id"] isEqualToString:_pendingChallengeId]) {
            _pendingChallengeId = nil;
            [self setState:OnlineStateReady info:@"Je uitdaging is geweigerd."];
        }
    }
}

- (void)showIncomingChallenge:(NSDictionary *)ch {
    NSString *cid = ch[@"id"];
    NSString *variant = ch[@"variant"][@"key"];
    if (variant && ![variant isEqualToString:@"standard"] && ![variant isEqualToString:@"fromPosition"]) {
        [[LichessClient shared] request:@"POST" path:[NSString stringWithFormat:@"/api/challenge/%@/decline", cid]
                                   form:@{ @"reason": @"standard" } completion:nil];
        return;
    }
    NSDictionary *tc = ch[@"timeControl"];
    NSString *tcText = tc[@"show"] ?: ([tc[@"type"] isEqualToString:@"correspondence"] ? @"correspondentie" : @"onbeperkt");
    NSString *msg = [NSString stringWithFormat:@"%@ daagt je uit.\nBedenktijd: %@ • %@",
                     PlayerName(ch[@"challenger"]), tcText, [ch[@"rated"] boolValue] ? @"telt mee voor rating" : @"vriendschappelijk"];
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Uitdaging" message:msg
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Weigeren" style:UIAlertActionStyleCancel handler:^(UIAlertAction *act) {
        [[LichessClient shared] request:@"POST" path:[NSString stringWithFormat:@"/api/challenge/%@/decline", cid]
                                   form:nil completion:nil];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Accepteren" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        [[LichessClient shared] request:@"POST" path:[NSString stringWithFormat:@"/api/challenge/%@/accept", cid]
                                   form:nil completion:^(NSInteger status, id json, NSString *errorText) {
            if (errorText) [YFUI showMessage:errorText title:@"Accepteren lukte niet" from:self];
        }];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)openGame:(NSString *)gameId {
    if (_openingGame || !_visible) return;
    _openingGame = YES;
    _pendingChallengeId = nil;
    [_seek cancel];
    _seek = nil;
    _state = OnlineStateReady;
    if (self.presentedViewController) [self dismissViewControllerAnimated:NO completion:nil];
    OnlineGameViewController *g = [[OnlineGameViewController alloc] initWithGameId:gameId];
    [self.navigationController pushViewController:g animated:YES];
}

#pragma mark - Knoppen

- (NSArray *)chosenTime {
    NSArray *opts = @[ @[@10, @0], @[@10, @5], @[@15, @10], @[@30, @0] ];
    NSInteger i = _timeControl.selectedSegmentIndex;
    if (i < 0 || i >= (NSInteger)opts.count) i = 0;
    return opts[i];
}

- (void)tokenTapped {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Lichess-token"
                                                               message:@"Typ of plak het token dat je op lichess.org hebt gemaakt (begint meestal met lip_)."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"lip_...";
        tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
        tf.autocorrectionType = UITextAutocorrectionTypeNo;
        tf.spellCheckingType = UITextSpellCheckingTypeNo;
    }];
    __weak UIAlertController *weakAlert = a;
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Inloggen" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        NSString *t = weakAlert.textFields.firstObject.text;
        t = [t stringByReplacingOccurrencesOfString:@" " withString:@""];
        if (t.length < 8) {
            [YFUI showMessage:@"Dit token is te kort. Controleer het nog eens." title:@"Token" from:self];
            return;
        }
        [[LichessClient shared] saveToken:t];
        [self refreshAccount];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)helpTapped {
    NSString *msg =
        @"1. Ga op een computer (of telefoon) naar lichess.org en log in. Nog geen account? Maak er gratis een.\n"
        @"2. Ga naar: lichess.org/account/oauth/token\n"
        @"3. Maak een nieuw token. Vink aan: “Play games with the board API” en “Create, accept, decline challenges”.\n"
        @"4. Kopieer het token (begint met lip_) en typ het hier in bij “Token invullen”.\n\n"
        @"Het token wordt alleen op deze iPad bewaard. Je echte wachtwoord heeft de app niet nodig.";
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Zo krijg je een token" message:msg
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Open in Safari op deze iPad" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kTokenURL]];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)seekTapped {
    NSArray *t = [self chosenTime];
    NSDictionary *form = @{ @"rated": _ratedSwitch.on ? @"true" : @"false",
                            @"time": t[0], @"increment": t[1],
                            @"variant": @"standard", @"color": @"random" };
    [self setState:OnlineStateSeeking info:[NSString stringWithFormat:@"Tegenstander zoeken (%@+%@)… Dit kan even duren.", t[0], t[1]]];
    __weak OnlineViewController *weakSelf = self;
    _seek = [[LichessClient shared] streamPath:@"/api/board/seek" method:@"POST" form:form
        onLine:nil
        onEnd:^(NSInteger status, NSString *errorText) {
            OnlineViewController *me = weakSelf;
            if (!me) return;
            me->_seek = nil;
            if (me->_state != OnlineStateSeeking) return;
            if (errorText) {
                [me setState:OnlineStateReady info:errorText];
                return;
            }
            // Zoeken klaar: de partij komt via de gebeurtenissen binnen. Even wachten.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                OnlineViewController *me2 = weakSelf;
                if (me2 && me2->_state == OnlineStateSeeking && !me2->_openingGame)
                    [me2 setState:OnlineStateReady info:@"Geen tegenstander gevonden. Probeer het nog eens."];
            });
        }];
}

- (void)aiTapped {
    NSArray *t = [self chosenTime];
    NSDictionary *form = @{ @"level": @(_aiLevel.selectedSegmentIndex + 1),
                            @"clock.limit": @([t[0] integerValue] * 60), @"clock.increment": t[1],
                            @"color": @"random", @"variant": @"standard" };
    [self setState:OnlineStateWaiting info:@"Partij tegen de lichess-computer starten…"];
    __weak OnlineViewController *weakSelf = self;
    [[LichessClient shared] request:@"POST" path:@"/api/challenge/ai" form:form completion:^(NSInteger status, id json, NSString *errorText) {
        OnlineViewController *me = weakSelf;
        if (!me) return;
        if (errorText || ![json isKindOfClass:[NSDictionary class]] || !json[@"id"]) {
            [me setState:OnlineStateReady info:errorText ?: @"Starten lukte niet."];
            return;
        }
        [me openGame:json[@"id"]];
    }];
}

- (void)friendTapped {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Vriend uitdagen"
                                                               message:@"Vul de lichess-gebruikersnaam van je vriend in. Je vriend moet de uitdaging op lichess accepteren."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"Gebruikersnaam";
        tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
        tf.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    __weak UIAlertController *weakAlert = a;
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Uitdagen" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        NSString *name = [weakAlert.textFields.firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (!name.length) return;
        [self challengeUser:name];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)challengeUser:(NSString *)name {
    NSMutableCharacterSet *allowed = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [allowed addCharactersInString:@"-_"];
    NSString *safe = [name stringByAddingPercentEncodingWithAllowedCharacters:allowed];
    NSArray *t = [self chosenTime];
    NSDictionary *form = @{ @"rated": _ratedSwitch.on ? @"true" : @"false",
                            @"clock.limit": @([t[0] integerValue] * 60), @"clock.increment": t[1],
                            @"color": @"random", @"variant": @"standard" };
    [self setState:OnlineStateWaiting info:[NSString stringWithFormat:@"Uitdaging versturen naar %@…", name]];
    __weak OnlineViewController *weakSelf = self;
    [[LichessClient shared] request:@"POST" path:[NSString stringWithFormat:@"/api/challenge/%@", safe] form:form
                         completion:^(NSInteger status, id json, NSString *errorText) {
        OnlineViewController *me = weakSelf;
        if (!me) return;
        NSDictionary *ch = [json isKindOfClass:[NSDictionary class]] ? json : nil;
        if ([ch[@"challenge"] isKindOfClass:[NSDictionary class]]) ch = ch[@"challenge"];
        if (errorText || !ch[@"id"]) {
            [me setState:OnlineStateReady info:errorText ?: @"Uitdagen lukte niet."];
            return;
        }
        me->_pendingChallengeId = ch[@"id"];
        [me setState:OnlineStateWaiting info:[NSString stringWithFormat:@"Wachten tot %@ je uitdaging accepteert…", name]];
    }];
}

- (void)resumeTapped {
    NSDictionary *g = _playing.firstObject;
    NSString *gid = g[@"gameId"] ?: g[@"fullId"];
    if (gid.length > 8) gid = [gid substringToIndex:8];
    if (gid) [self openGame:gid];
}

- (void)cancelTapped {
    if (_state == OnlineStateSeeking) {
        [_seek cancel];
        _seek = nil;
    }
    if (_pendingChallengeId) {
        [[LichessClient shared] request:@"POST" path:[NSString stringWithFormat:@"/api/challenge/%@/cancel", _pendingChallengeId]
                                   form:nil completion:nil];
        _pendingChallengeId = nil;
    }
    if (_visible) [self setState:OnlineStateReady info:@"Geannuleerd."];
    else _state = OnlineStateReady;
}

- (void)logoutTapped {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Uitloggen?"
                                                               message:@"Het token wordt van deze iPad verwijderd."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Uitloggen" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *act) {
        [self stopStreams];
        [[LichessClient shared] logout];
        self->_playing = nil;
        [self refreshAccount];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

@end

#pragma mark - Online partij

@interface OnlineGameViewController () <ChessBoardViewDelegate>
@end

@implementation OnlineGameViewController {
    NSString *_gameId;
    LichessStream *_stream;
    NSTimer *_timer;
    ChessBoardView *_board;
    UIView *_panel;
    UILabel *_topLabel;
    UILabel *_statusLabel;
    UILabel *_bottomLabel;
    UITextView *_movesView;
    YFButton *_resignButton;
    YFButton *_drawButton;
    YFButton *_claimButton;
    UILabel *_actionLabel;
    BOOL _myDrawOffer;
    BOOL _oppDrawOffer;
    NSTimeInterval _claimAt;
    YFButton *_flipButton;

    CEPosition _initial;
    CEPosition _pos;
    NSArray *_serverMoves;   // zetten volgens lichess
    NSArray *_shownMoves;    // zetten op het bord (kan 1 verder zijn na een eigen zet)
    NSArray *_san;
    int _lastFrom, _lastTo;
    int _myColor;
    NSDictionary *_white, *_black;
    NSString *_status;
    NSString *_winner;
    double _wtime, _btime;
    NSTimeInterval _stateAt;
    BOOL _haveFull;
    BOOL _sending;
    BOOL _announced;
    BOOL _leaving;
    int _selected;
    NSInteger _drawAlertedAt;
    BOOL _opponentGone;
}

- (instancetype)initWithGameId:(NSString *)gameId {
    self = [super init];
    if (self) {
        _gameId = [gameId copy];
        _myColor = CE_WHITE;
        _selected = -1;
        _lastFrom = _lastTo = -1;
        _drawAlertedAt = -1;
        _serverMoves = @[];
        _shownMoves = @[];
        _san = @[];
        _status = @"started";
        ce_start(&_initial);
        _pos = _initial;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Online partij";
    _board = [[ChessBoardView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
    _board.delegate = self;
    [self.view addSubview:_board];
    _panel = [[UIView alloc] init];
    _panel.layer.cornerRadius = 10;
    [self.view addSubview:_panel];
    CGFloat fs = [YFUI isPad] ? 19 : 15;
    _topLabel = [YFUI labelWithSize:fs bold:NO];
    _bottomLabel = [YFUI labelWithSize:fs bold:NO];
    _statusLabel = [YFUI labelWithSize:fs + 1 bold:YES];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    for (UILabel *l in @[_topLabel, _bottomLabel, _statusLabel]) {
        l.numberOfLines = 2;
        l.adjustsFontSizeToFitWidth = YES;
        l.minimumScaleFactor = 0.6;
        [_panel addSubview:l];
    }
    _movesView = [[UITextView alloc] init];
    _movesView.editable = NO;
    _movesView.selectable = NO;
    _movesView.font = [UIFont systemFontOfSize:[YFUI isPad] ? 17 : 14];
    _movesView.layer.cornerRadius = 8;
    [_panel addSubview:_movesView];
    _resignButton = [YFUI buttonWithTitle:@"Opgeven" target:self action:@selector(resignTapped)];
    _drawButton = [YFUI buttonWithTitle:@"Remise aanbieden" target:self action:@selector(drawTapped)];
    _claimButton = [YFUI buttonWithTitle:@"\U0001F3C6 Winst opeisen" target:self action:@selector(claimTapped)];
    _claimButton.primary = YES;
    _claimButton.hidden = YES;
    _actionLabel = [YFUI labelWithSize:fs - 1 bold:NO];
    _actionLabel.textAlignment = NSTextAlignmentCenter;
    _actionLabel.numberOfLines = 2;
    _actionLabel.adjustsFontSizeToFitWidth = YES;
    _actionLabel.minimumScaleFactor = 0.6;
    [_panel addSubview:_actionLabel];
    _flipButton = [YFUI buttonWithTitle:@"⇅ Draai bord" target:self action:@selector(flipTapped)];
    for (UIView *b in @[_resignButton, _drawButton, _claimButton, _flipButton]) [_panel addSubview:b];
    [self render:-1 to:-1];
    [self connect];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    SettingsManager *s = [SettingsManager shared];
    [YFUI applyThemeToController:self];
    _panel.backgroundColor = s.panelColor;
    for (UILabel *l in @[_topLabel, _bottomLabel, _statusLabel]) l.textColor = s.textColor;
    _movesView.backgroundColor = s.backgroundColor;
    _movesView.textColor = s.textColor;
    for (YFButton *b in @[_resignButton, _drawButton, _claimButton, _flipButton]) [b applyTheme];
    _actionLabel.textColor = s.secondaryTextColor;
    _board.showCoordinates = s.showCoordinates;
    [_board refreshTheme];
    if (!_timer) {
        _timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(tick) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController) {
        _leaving = YES;
        [_stream cancel];
        _stream = nil;
        [_timer invalidate];
        _timer = nil;
    }
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
        CGFloat size = floor(MIN(W - 2 * m, availH * 0.62) / 8.0) * 8.0;
        _board.frame = CGRectMake((W - size) / 2.0, top, size, size);
        CGFloat py = CGRectGetMaxY(_board.frame) + m;
        pf = CGRectMake(m, py, W - 2 * m, H - bottom - py);
    }
    _panel.frame = pf;
    CGFloat pw = pf.size.width, pad = 10, lh = [YFUI isPad] ? 30 : 24;
    CGFloat y = pad;
    _topLabel.frame = CGRectMake(pad, y, pw - 2 * pad, lh * 1.5); y += lh * 1.5 + 4;
    _statusLabel.frame = CGRectMake(pad, y, pw - 2 * pad, lh * 1.6); y += lh * 1.6 + 4;
    _bottomLabel.frame = CGRectMake(pad, y, pw - 2 * pad, lh * 1.5); y += lh * 1.5 + 4;
    _actionLabel.frame = CGRectMake(pad, y, pw - 2 * pad, lh * 1.4); y += lh * 1.4 + 6;
    CGFloat bh = [YFUI isPad] ? 52 : 42;
    NSMutableArray *buttons = [NSMutableArray array];
    for (YFButton *b in @[_claimButton, _resignButton, _drawButton, _flipButton]) if (!b.hidden) [buttons addObject:b];
    y = [YFUI layoutViews:buttons x:pad y:y width:pw - 2 * pad itemHeight:bh
                  columns:(buttons.count == 3 ? 3 : 2) spacing:8] + 10;
    CGFloat mh = pf.size.height - y - pad;
    _movesView.hidden = mh < 30;
    _movesView.frame = CGRectMake(pad, y, pw - 2 * pad, MAX(0, mh));
}

#pragma mark - Verbinding

- (void)connect {
    if (_leaving) return;
    [_stream cancel];
    __weak OnlineGameViewController *weakSelf = self;
    _stream = [[LichessClient shared] streamPath:[NSString stringWithFormat:@"/api/board/game/stream/%@", _gameId]
                                          method:@"GET" form:nil
        onLine:^(NSDictionary *obj) {
            [weakSelf handleLine:obj];
        } onEnd:^(NSInteger status, NSString *errorText) {
            OnlineGameViewController *me = weakSelf;
            if (!me || me->_leaving) return;
            me->_stream = nil;
            if ([me isOver]) return;
            if (errorText) me->_statusLabel.text = [NSString stringWithFormat:@"%@ Opnieuw verbinden…", errorText];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf connect];
            });
        }];
}

- (void)handleLine:(NSDictionary *)obj {
    NSString *type = obj[@"type"];
    if ([type isEqualToString:@"gameFull"]) {
        NSString *fen = obj[@"initialFen"];
        if (![fen isKindOfClass:[NSString class]] || [fen isEqualToString:@"startpos"] || !ce_from_fen(&_initial, fen.UTF8String))
            ce_start(&_initial);
        _white = obj[@"white"];
        _black = obj[@"black"];
        NSString *me = [LichessClient shared].userId;
        if (me && [[_black[@"id"] lowercaseString] isEqualToString:me]) _myColor = CE_BLACK;
        else _myColor = CE_WHITE;
        if (!_haveFull) [_board setFlipped:_myColor == CE_BLACK animated:NO];
        _haveFull = YES;
        _shownMoves = @[];
        [self applyState:obj[@"state"]];
    } else if ([type isEqualToString:@"gameState"]) {
        [self applyState:obj];
    } else if ([type isEqualToString:@"opponentGone"]) {
        // Lichess meldt dat de tegenstander weg is, en na hoeveel seconden je de winst mag opeisen.
        _opponentGone = [obj[@"gone"] boolValue];
        if (_opponentGone) {
            id secs = obj[@"claimWinInSeconds"];
            double wait = [secs respondsToSelector:@selector(doubleValue)] ? [secs doubleValue] : 0;
            _claimAt = [NSDate timeIntervalSinceReferenceDate] + MAX(0, wait);
            _actionLabel.text = @"Je tegenstander is weg. Blijft hij weg, dan kun je straks de winst opeisen.";
        } else {
            _claimAt = 0;
            _actionLabel.text = @"Je tegenstander is terug.";
        }
        [self updateTexts];
    }
}

- (void)applyState:(NSDictionary *)st {
    if (![st isKindOfClass:[NSDictionary class]]) return;
    NSString *movesStr = st[@"moves"];
    NSArray *moves = ([movesStr isKindOfClass:[NSString class]] && movesStr.length)
                         ? [movesStr componentsSeparatedByString:@" "] : @[];
    _serverMoves = moves;
    _wtime = [st[@"wtime"] doubleValue];
    _btime = [st[@"btime"] doubleValue];
    _stateAt = [NSDate timeIntervalSinceReferenceDate];
    if ([st[@"status"] isKindOfClass:[NSString class]]) _status = st[@"status"];
    _winner = [st[@"winner"] isKindOfClass:[NSString class]] ? st[@"winner"] : nil;
    BOOL same = [moves isEqualToArray:_shownMoves];
    if (!same) {
        BOOL oneMore = moves.count == _shownMoves.count + 1 &&
                       [[moves subarrayWithRange:NSMakeRange(0, _shownMoves.count)] isEqualToArray:_shownMoves];
        [self showMoves:moves animate:oneMore];
    } else {
        [self updateTexts];
    }
    // Remiseaanbiedingen (van jou en van de tegenstander).
    BOOL oppOffers = _myColor == CE_WHITE ? [st[@"bdraw"] boolValue] : [st[@"wdraw"] boolValue];
    BOOL myOffer = _myColor == CE_WHITE ? [st[@"wdraw"] boolValue] : [st[@"bdraw"] boolValue];
    if (_myDrawOffer && !myOffer && ![self isOver]) _actionLabel.text = @"Je remiseaanbod is niet aangenomen. Speel verder.";
    _myDrawOffer = myOffer;
    _oppDrawOffer = oppOffers;
    [self updateTexts];
    if (oppOffers && ![self isOver] && _drawAlertedAt != (NSInteger)moves.count) {
        _drawAlertedAt = (NSInteger)moves.count;
        [self askDrawOffer];
    }
    if ([self isOver]) [self announce];
}

- (void)showMoves:(NSArray *)moves animate:(BOOL)animate {
    CEPosition p = _initial;
    NSMutableArray *san = [NSMutableArray array];
    NSMutableArray *ok = [NSMutableArray array];
    int lf = -1, lt = -1;
    for (NSString *u in moves) {
        CEMove m;
        if (!ce_parse_uci(&p, u.UTF8String, &m)) break;
        char buf[16];
        ce_move_to_san(&p, m, buf, sizeof buf);
        [san addObject:[NSString stringWithUTF8String:buf]];
        ce_make(&p, m);
        [ok addObject:u];
        lf = m.from;
        lt = m.to;
    }
    _pos = p;
    _san = san;
    _shownMoves = ok;
    _lastFrom = lf;
    _lastTo = lt;
    _selected = -1;
    [self render:animate ? lf : -1 to:lt];
}

- (BOOL)isOver {
    return !([_status isEqualToString:@"started"] || [_status isEqualToString:@"created"]);
}

#pragma mark - Weergave

- (void)render:(int)from to:(int)to {
    SettingsManager *s = [SettingsManager shared];
    _board.lastFrom = _lastFrom;
    _board.lastTo = _lastTo;
    _board.selectedSquare = _selected;
    _board.targetSquares = @[];
    _board.checkSquare = ce_in_check(&_pos, _pos.side) ? ce_king_square(&_pos, _pos.side) : -1;
    [_board setBoard:_pos.board animatedFrom:(s.animations && from >= 0) ? from : -1 to:to];
    NSMutableString *text = [NSMutableString string];
    int number = _initial.fullmove;
    NSUInteger i = 0;
    if (_initial.side == CE_BLACK && _san.count) {
        [text appendFormat:@"%d… %@\n", number, [ChessPiece figurineSAN:_san[0]]];
        number++;
        i = 1;
    }
    for (; i < _san.count; i += 2) {
        [text appendFormat:@"%d. %@", number, [ChessPiece figurineSAN:_san[i]]];
        if (i + 1 < _san.count) [text appendFormat:@"   %@", [ChessPiece figurineSAN:_san[i + 1]]];
        [text appendString:@"\n"];
        number++;
    }
    _movesView.text = text.length ? text : @"Nog geen zetten.";
    if (text.length) [_movesView scrollRangeToVisible:NSMakeRange(text.length - 1, 0)];
    [self updateTexts];
}

- (double)remainingMsFor:(int)color {
    double t = color == CE_WHITE ? _wtime : _btime;
    BOOL running = ![self isOver] && _serverMoves.count >= 2 && _pos.side == color && _shownMoves.count == _serverMoves.count;
    if (running) t -= ([NSDate timeIntervalSinceReferenceDate] - _stateAt) * 1000.0;
    return t < 0 ? 0 : t;
}

- (NSString *)formatMs:(double)ms {
    double t = ms / 1000.0;
    if (t < 10) return [NSString stringWithFormat:@"0:%04.1f", floor(t * 10) / 10.0];
    long s = (long)ceil(t);
    if (s >= 3600) return [NSString stringWithFormat:@"%ld:%02ld:%02ld", s / 3600, (s % 3600) / 60, s % 60];
    return [NSString stringWithFormat:@"%ld:%02ld", s / 60, s % 60];
}

- (void)tick {
    if (!_haveFull) return;
    SettingsManager *s = [SettingsManager shared];
    int opp = _myColor ^ 1;
    BOOL timed = _wtime > 0 || _btime > 0;
    NSDictionary *oppP = opp == CE_WHITE ? _white : _black;
    NSDictionary *meP = _myColor == CE_WHITE ? _white : _black;
    NSString *oppGlyph = [ChessPiece textGlyphForPiece:CE_PIECE(opp, CE_KING)];
    NSString *meGlyph = [ChessPiece textGlyphForPiece:CE_PIECE(_myColor, CE_KING)];
    NSString *oppClock = timed ? [NSString stringWithFormat:@"   ⏱ %@", [self formatMs:[self remainingMsFor:opp]]] : @"";
    NSString *meClock = timed ? [NSString stringWithFormat:@"   ⏱ %@", [self formatMs:[self remainingMsFor:_myColor]]] : @"";
    // Tegenstander weg: aftellen tot je de winst mag opeisen.
    BOOL live = ![self isOver];
    NSString *goneText = @"";
    BOOL canClaim = NO;
    if (_opponentGone && live) {
        double left = _claimAt - [NSDate timeIntervalSinceReferenceDate];
        if (left > 0.5) goneText = [NSString stringWithFormat:@"\n(tegenstander is weg — winst opeisen over %d s)", (int)ceil(left)];
        else { goneText = @"\n(tegenstander is weg — je mag de winst opeisen!)"; canClaim = YES; }
    }
    BOOL hideClaim = !(_opponentGone && live);
    if (_claimButton.hidden != hideClaim) {
        _claimButton.hidden = hideClaim;
        [self.view setNeedsLayout];
    }
    _claimButton.enabled = canClaim;
    _topLabel.text = [NSString stringWithFormat:@"%@ %@%@%@", oppGlyph, PlayerName(oppP), oppClock, goneText];
    _bottomLabel.text = [NSString stringWithFormat:@"%@ Jij: %@%@", meGlyph, PlayerName(meP), meClock];
    BOOL running = ![self isOver] && _serverMoves.count >= 2;
    _topLabel.textColor = (running && _pos.side == opp) ? s.accentColor : s.textColor;
    _bottomLabel.textColor = (running && _pos.side == _myColor) ? s.accentColor : s.textColor;
    _topLabel.font = (running && _pos.side == opp) ? [UIFont boldSystemFontOfSize:_topLabel.font.pointSize]
                                                   : [UIFont systemFontOfSize:_topLabel.font.pointSize];
    _bottomLabel.font = (running && _pos.side == _myColor) ? [UIFont boldSystemFontOfSize:_bottomLabel.font.pointSize]
                                                           : [UIFont systemFontOfSize:_bottomLabel.font.pointSize];
}

- (NSString *)resultText {
    NSString *reason;
    if ([_status isEqualToString:@"mate"]) reason = @"Schaakmat";
    else if ([_status isEqualToString:@"resign"]) reason = @"Opgegeven";
    else if ([_status isEqualToString:@"stalemate"]) reason = @"Pat";
    else if ([_status isEqualToString:@"outoftime"] || [_status isEqualToString:@"timeout"]) reason = @"Tijd op";
    else if ([_status isEqualToString:@"draw"]) reason = @"Remise";
    else if ([_status isEqualToString:@"aborted"]) return @"De partij is afgebroken.";
    else if ([_status isEqualToString:@"noStart"]) return @"De partij is niet begonnen.";
    else reason = @"Partij afgelopen";
    if (!_winner) return [NSString stringWithFormat:@"%@: remise.", reason];
    int w = [_winner isEqualToString:@"white"] ? CE_WHITE : CE_BLACK;
    return [NSString stringWithFormat:@"%@: %@", reason, w == _myColor ? @"jij wint!" : @"je verliest."];
}

- (void)updateTexts {
    if (!_haveFull) {
        _statusLabel.text = @"Partij laden…";
    } else if ([self isOver]) {
        _statusLabel.text = [self resultText];
    } else {
        NSString *t = _pos.side == _myColor ? @"Jij bent aan zet" : @"Tegenstander is aan zet";
        if (_sending) t = @"Zet versturen…";
        if (ce_in_check(&_pos, _pos.side)) t = [t stringByAppendingString:@" — Schaak!"];
        _statusLabel.text = t;
    }
    BOOL live = _haveFull && ![self isOver];
    BOOL early = _serverMoves.count < 2;   // lichess: zolang niet beide spelers gezet hebben, kan alleen afbreken
    [_resignButton setTitle:early ? @"✕ Afbreken" : @"⚑ Opgeven" forState:UIControlStateNormal];
    _resignButton.enabled = live;
    NSString *drawTitle = _oppDrawOffer ? @"½ Remise accepteren"
                        : (_myDrawOffer ? @"Remise aangeboden…" : @"½ Remise aanbieden");
    [_drawButton setTitle:drawTitle forState:UIControlStateNormal];
    if (_drawButton.primary != _oppDrawOffer) _drawButton.primary = _oppDrawOffer;
    _drawButton.enabled = live && !early && !_myDrawOffer;
    [self tick];
}

- (void)announce {
    if (_announced || !self.view.window) return;
    _announced = YES;
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Partij afgelopen" message:[self resultText]
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Bekijk bord" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Terug naar lobby" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

#pragma mark - Zetten

- (void)boardView:(ChessBoardView *)board didTapSquare:(int)sq {
    if (!_haveFull || [self isOver] || _sending || _pos.side != _myColor) return;
    if (_shownMoves.count != _serverMoves.count) return;
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
            else [self sendFrom:from to:sq promo:0];
            return;
        }
    }
    uint8_t pc = _pos.board[sq];
    if (pc && CE_COLOR(pc) == _myColor && sq != _selected) {
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
        NSString *title = [NSString stringWithFormat:@"%@  %@", [ChessPiece textGlyphForPiece:CE_PIECE(_myColor, t)],
                           [ChessPiece dutchNameForType:t]];
        [a addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
            [self sendFrom:from to:to promo:t];
        }]];
    }
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)sendFrom:(int)from to:(int)to promo:(int)promo {
    CEMove m;
    if (!ce_find_move(&_pos, from, to, promo ? promo : CE_QUEEN, &m)) return;
    char buf[8];
    ce_move_to_uci(m, buf, sizeof buf);
    NSString *uci = [NSString stringWithUTF8String:buf];
    // Meteen op het bord laten zien; lichess bevestigt via de verbinding.
    NSArray *local = [_shownMoves arrayByAddingObject:uci];
    [self showMoves:local animate:YES];
    _sending = YES;
    [self updateTexts];
    __weak OnlineGameViewController *weakSelf = self;
    [[LichessClient shared] request:@"POST" path:[NSString stringWithFormat:@"/api/board/game/%@/move/%@", _gameId, uci]
                               form:nil completion:^(NSInteger status, id json, NSString *errorText) {
        OnlineGameViewController *me = weakSelf;
        if (!me) return;
        me->_sending = NO;
        if (errorText) {
            [me showMoves:me->_serverMoves animate:NO];
            [YFUI showMessage:errorText title:@"Zet niet verstuurd" from:me];
        }
        [me updateTexts];
    }];
}

#pragma mark - Knoppen

// Stuurt een actie naar lichess. De uitkomst komt in de regel onder je naam (geen pop-ups over elkaar).
- (void)postAction:(NSString *)action busy:(NSString *)busy ok:(NSString *)ok fail:(NSString *)fail
              done:(void (^)(BOOL success))done {
    SettingsManager *s = [SettingsManager shared];
    _actionLabel.textColor = s.secondaryTextColor;
    _actionLabel.text = busy;
    __weak OnlineGameViewController *weakSelf = self;
    [[LichessClient shared] request:@"POST" path:[NSString stringWithFormat:@"/api/board/game/%@/%@", _gameId, action]
                               form:nil completion:^(NSInteger status, id json, NSString *errorText) {
        OnlineGameViewController *me = weakSelf;
        if (!me) return;
        SettingsManager *st = [SettingsManager shared];
        if (errorText) {
            me->_actionLabel.textColor = st.errorColor;
            me->_actionLabel.text = [NSString stringWithFormat:@"%@: %@", fail, errorText];
        } else if (ok) {
            me->_actionLabel.textColor = st.okColor;
            me->_actionLabel.text = ok;
        }
        if (done) done(errorText == nil);
        [me updateTexts];
    }];
}

- (void)resignTapped {
    if ([self isOver]) return;
    BOOL early = _serverMoves.count < 2;
    NSString *title = early ? @"Partij afbreken?" : @"Opgeven?";
    NSString *msg = early ? @"De partij is nog niet echt begonnen. Afbreken telt niet mee voor je rating."
                          : @"Je verliest dan deze partij.";
    UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:msg
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Annuleren" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:early ? @"Afbreken" : @"Opgeven" style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction *act) {
        if (early) [self postAction:@"abort" busy:@"Afbreken…" ok:@"De partij is afgebroken." fail:@"Afbreken lukte niet" done:nil];
        else [self postAction:@"resign" busy:@"Opgeven…" ok:@"Je hebt opgegeven." fail:@"Opgeven lukte niet" done:nil];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)drawTapped {
    if ([self isOver]) return;
    if (_oppDrawOffer) {
        [self postAction:@"draw/yes" busy:@"Remise accepteren…" ok:@"Remise aangenomen." fail:@"Accepteren lukte niet" done:nil];
        return;
    }
    _myDrawOffer = YES;   // meteen tonen; lichess bevestigt via de verbinding
    [self updateTexts];
    __weak OnlineGameViewController *weakSelf = self;
    [self postAction:@"draw/yes" busy:@"Remise aanbieden…"
                  ok:@"Remiseaanbod verstuurd. Wachten op je tegenstander…"
                fail:@"Remise aanbieden lukte niet" done:^(BOOL success) {
        OnlineGameViewController *me = weakSelf;
        if (me && !success) { me->_myDrawOffer = NO; [me updateTexts]; }
    }];
}

- (void)claimTapped {
    if ([self isOver] || !_opponentGone) return;
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Tegenstander is weg"
                                                               message:@"Je tegenstander is al een tijdje weg. Wat wil je doen?"
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"\U0001F3C6 Winst opeisen" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        [self postAction:@"claim-victory" busy:@"Winst opeisen…" ok:@"Winst opgeëist!" fail:@"Winst opeisen lukte niet" done:nil];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"½ Remise opeisen" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        [self postAction:@"claim-draw" busy:@"Remise opeisen…" ok:@"Remise opgeëist." fail:@"Remise opeisen lukte niet" done:nil];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Nog even wachten" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)askDrawOffer {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Remise?"
                                                               message:@"Je tegenstander biedt remise aan (gelijkspel)."
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Weigeren" style:UIAlertActionStyleCancel handler:^(UIAlertAction *act) {
        [self postAction:@"draw/no" busy:@"Weigeren…" ok:@"Remise geweigerd. Speel verder." fail:@"Weigeren lukte niet" done:nil];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"Accepteren" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        [self postAction:@"draw/yes" busy:@"Remise accepteren…" ok:@"Remise aangenomen." fail:@"Accepteren lukte niet" done:nil];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)flipTapped {
    [_board setFlipped:!_board.flipped animated:[SettingsManager shared].animations];
}

@end
