// SettingsManager.h
// YF Schaak - instellingen, thema-kleuren en opgeslagen posities (NSUserDefaults).

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface SettingsManager : NSObject

+ (instancetype)shared;

@property (nonatomic) BOOL darkTheme;
@property (nonatomic) NSInteger pieceSet;   // 0 klassiek (tekens), 1 modern, 2 3D
@property (nonatomic) NSInteger boardTheme; // 0 bruin, 1 groen, 2 blauw, 3 grijs
@property (nonatomic) BOOL animations;
@property (nonatomic) BOOL showLegalMoves;
@property (nonatomic) BOOL showCoordinates;
@property (nonatomic) BOOL autoFlip;        // 1 tegen 1: bord draait mee
@property (nonatomic) BOOL hideLastMove;    // 1 tegen 1: vorige zet niet markeren
@property (nonatomic) NSInteger botLevel;   // 1 t/m 5
@property (nonatomic) NSInteger botColor;   // 0 wit, 1 zwart, 2 willekeurig
@property (nonatomic) NSInteger clockBaseSeconds;
@property (nonatomic) NSInteger clockIncrementSeconds;
@property (nonatomic, copy) NSString *editorDraftFEN;

- (void)save;
+ (NSArray *)pieceSetNames;
+ (NSArray *)boardThemeNames;

// Thema
- (UIColor *)backgroundColor;
- (UIColor *)panelColor;
- (UIColor *)textColor;
- (UIColor *)secondaryTextColor;
- (UIColor *)accentColor;
- (UIColor *)buttonColor;
- (UIColor *)buttonTextColor;
- (UIColor *)lightSquareColor;
- (UIColor *)darkSquareColor;
- (UIColor *)errorColor;
- (UIColor *)okColor;

// Opgeslagen posities: elk item is @{ @"name": ..., @"fen": ... }
- (NSArray *)savedPositions;
- (void)savePositionNamed:(NSString *)name fen:(NSString *)fen;
- (void)deletePositionAtIndex:(NSUInteger)index;

@end
