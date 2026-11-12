// SettingsManager.m

#import "SettingsManager.h"

static UIColor *RGB(unsigned int hex) {
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                           green:((hex >> 8) & 0xFF) / 255.0
                            blue:(hex & 0xFF) / 255.0
                           alpha:1.0];
}

@implementation SettingsManager

+ (instancetype)shared {
    static SettingsManager *s = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        s = [[SettingsManager alloc] init];
    });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
        [d registerDefaults:@{
            @"darkTheme": @NO,
            @"pieceSet": @2,
            @"boardTheme": @0,
            @"animations": @YES,
            @"showLegalMoves": @YES,
            @"moveRating": @YES,
            @"showCoordinates": @YES,
            @"autoFlip": @NO,
            @"hideLastMove": @NO,
            @"botLevel": @2,
            @"botColor": @0,
            @"clockBase": @300,
            @"clockIncrement": @0,
            @"adaptiveStrength": @0,
        }];
        _darkTheme = [d boolForKey:@"darkTheme"];
        _pieceSet = [d integerForKey:@"pieceSet"];
        if (_pieceSet < 0 || _pieceSet > 2) _pieceSet = 2;
        _boardTheme = [d integerForKey:@"boardTheme"];
        if (_boardTheme < 0 || _boardTheme > 3) _boardTheme = 0;
        _animations = [d boolForKey:@"animations"];
        _showLegalMoves = [d boolForKey:@"showLegalMoves"];
        _moveRating = [d boolForKey:@"moveRating"];
        _showCoordinates = [d boolForKey:@"showCoordinates"];
        _autoFlip = [d boolForKey:@"autoFlip"];
        _hideLastMove = [d boolForKey:@"hideLastMove"];
        _botLevel = [d integerForKey:@"botLevel"];
        if (_botLevel < 0 || _botLevel > 5) _botLevel = 2;
        _botColor = [d integerForKey:@"botColor"];
        if (_botColor < 0 || _botColor > 2) _botColor = 0;
        _clockBaseSeconds = [d integerForKey:@"clockBase"];
        if (_clockBaseSeconds < 1) _clockBaseSeconds = 300;
        _clockIncrementSeconds = [d integerForKey:@"clockIncrement"];
        if (_clockIncrementSeconds < 0) _clockIncrementSeconds = 0;
        _editorDraftFEN = [d stringForKey:@"editorDraft"];
        _adaptiveStrength = [d integerForKey:@"adaptiveStrength"];
        if (_adaptiveStrength < 0 || _adaptiveStrength > 100) _adaptiveStrength = 0;
        _adaptiveWins = [d integerForKey:@"adaptiveWins"];
        _adaptiveLosses = [d integerForKey:@"adaptiveLosses"];
        _adaptiveDraws = [d integerForKey:@"adaptiveDraws"];
    }
    return self;
}

- (void)save {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setBool:_darkTheme forKey:@"darkTheme"];
    [d setInteger:_pieceSet forKey:@"pieceSet"];
    [d setInteger:_boardTheme forKey:@"boardTheme"];
    [d setBool:_animations forKey:@"animations"];
    [d setBool:_showLegalMoves forKey:@"showLegalMoves"];
    [d setBool:_moveRating forKey:@"moveRating"];
    [d setBool:_showCoordinates forKey:@"showCoordinates"];
    [d setBool:_autoFlip forKey:@"autoFlip"];
    [d setBool:_hideLastMove forKey:@"hideLastMove"];
    [d setInteger:_botLevel forKey:@"botLevel"];
    [d setInteger:_botColor forKey:@"botColor"];
    [d setInteger:_clockBaseSeconds forKey:@"clockBase"];
    [d setInteger:_clockIncrementSeconds forKey:@"clockIncrement"];
    [d setInteger:_adaptiveStrength forKey:@"adaptiveStrength"];
    [d setInteger:_adaptiveWins forKey:@"adaptiveWins"];
    [d setInteger:_adaptiveLosses forKey:@"adaptiveLosses"];
    [d setInteger:_adaptiveDraws forKey:@"adaptiveDraws"];
    if (_editorDraftFEN) [d setObject:_editorDraftFEN forKey:@"editorDraft"];
    else [d removeObjectForKey:@"editorDraft"];
    [d synchronize];
}

#pragma mark - Thema

- (UIColor *)backgroundColor { return _darkTheme ? RGB(0x1E1B18) : RGB(0xF4EFE6); }
- (UIColor *)panelColor { return _darkTheme ? RGB(0x2A2622) : RGB(0xFFFDF8); }
- (UIColor *)textColor { return _darkTheme ? RGB(0xEEE6DA) : RGB(0x2B2118); }
- (UIColor *)secondaryTextColor { return _darkTheme ? RGB(0xA89A88) : RGB(0x7A6A58); }
- (UIColor *)accentColor { return _darkTheme ? RGB(0xC89B5E) : RGB(0x8B5A2B); }
- (UIColor *)buttonColor { return _darkTheme ? RGB(0x3A342D) : RGB(0xE6D8C3); }
- (UIColor *)buttonTextColor { return _darkTheme ? RGB(0xEEE6DA) : RGB(0x2B2118); }
+ (NSArray *)pieceSetNames { return @[ @"Klassiek", @"Modern", @"3D" ]; }
+ (NSArray *)boardThemeNames { return @[ @"Bruin", @"Groen", @"Blauw", @"Grijs" ]; }

- (UIColor *)lightSquareColor {
    switch (_boardTheme) {
        case 1: return RGB(0xEEEED2);
        case 2: return RGB(0xDEE3E6);
        case 3: return RGB(0xDCDCDC);
        default: return _darkTheme ? RGB(0xD9C4A0) : RGB(0xF0D9B5);
    }
}
- (UIColor *)darkSquareColor {
    switch (_boardTheme) {
        case 1: return RGB(0x769656);
        case 2: return RGB(0x8CA2AD);
        case 3: return RGB(0x9A9A9A);
        default: return _darkTheme ? RGB(0x8E6A47) : RGB(0xB58863);
    }
}
- (UIColor *)errorColor { return _darkTheme ? RGB(0xFF7A6B) : RGB(0xB3261E); }
- (UIColor *)okColor { return _darkTheme ? RGB(0x8FD18F) : RGB(0x2E7D32); }

+ (NSString *)strengthName:(NSInteger)s {
    if (s < 10) return @"ultra slecht";
    if (s < 30) return @"beginner";
    if (s < 50) return @"makkelijk";
    if (s < 70) return @"gemiddeld";
    if (s < 85) return @"sterk";
    return @"heel sterk";
}

#pragma mark - Partijen

- (NSArray *)savedGames {
    NSArray *a = [[NSUserDefaults standardUserDefaults] arrayForKey:@"savedGames"];
    return a ? a : @[];
}

- (void)storeGame:(NSDictionary *)game {
    NSMutableArray *a = [[self savedGames] mutableCopy];
    for (NSUInteger i = 0; i < a.count; i++) {
        if ([a[i][@"id"] isEqualToString:game[@"id"]]) { [a removeObjectAtIndex:i]; break; }
    }
    [a insertObject:game atIndex:0];
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:@"savedGames"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)deleteGameWithId:(NSString *)gameId {
    NSMutableArray *a = [[self savedGames] mutableCopy];
    for (NSUInteger i = 0; i < a.count; i++) {
        if ([a[i][@"id"] isEqualToString:gameId]) { [a removeObjectAtIndex:i]; break; }
    }
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:@"savedGames"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Puzzels

- (BOOL)isPuzzleSolved:(NSString *)fen {
    NSArray *a = [[NSUserDefaults standardUserDefaults] arrayForKey:@"solvedPuzzles"];
    return [a containsObject:fen];
}

- (void)markPuzzleSolved:(NSString *)fen {
    if (!fen || [self isPuzzleSolved:fen]) return;
    NSArray *a = [[NSUserDefaults standardUserDefaults] arrayForKey:@"solvedPuzzles"];
    NSMutableArray *m = a ? [a mutableCopy] : [NSMutableArray array];
    [m addObject:fen];
    [[NSUserDefaults standardUserDefaults] setObject:m forKey:@"solvedPuzzles"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Posities

- (NSArray *)savedPositions {
    NSArray *a = [[NSUserDefaults standardUserDefaults] arrayForKey:@"savedPositions"];
    return a ? a : @[];
}

- (void)savePositionNamed:(NSString *)name fen:(NSString *)fen {
    if (!fen.length) return;
    if (!name.length) name = @"Naamloos";
    NSMutableArray *a = [[self savedPositions] mutableCopy];
    // Zelfde naam: overschrijven.
    for (NSUInteger i = 0; i < a.count; i++) {
        NSDictionary *item = a[i];
        if ([item[@"name"] isEqualToString:name]) {
            [a removeObjectAtIndex:i];
            break;
        }
    }
    [a insertObject:@{ @"name": name, @"fen": fen } atIndex:0];
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:@"savedPositions"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)deletePositionAtIndex:(NSUInteger)index {
    NSMutableArray *a = [[self savedPositions] mutableCopy];
    if (index >= a.count) return;
    [a removeObjectAtIndex:index];
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:@"savedPositions"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
