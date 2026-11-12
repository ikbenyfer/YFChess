// GameManager.h
// YF Schaak - één partij: zetten, geschiedenis, ongedaan maken, herstarten en de bot.

#import <Foundation/Foundation.h>
#include "ChessEngine.h"

typedef NS_ENUM(NSInteger, GameMode) {
    GameModeBot = 0,
    GameModeLocal = 1
};

@class GameManager;

@interface GameManager : NSObject

- (instancetype)initWithFEN:(NSString *)fen mode:(GameMode)mode humanColor:(int)humanColor botLevel:(NSInteger)level;

@property (nonatomic, readonly) CEPosition position;
@property (nonatomic, readonly) GameMode mode;
@property (nonatomic, readonly) int humanColor;
@property (nonatomic, readonly) NSInteger botLevel;
@property (nonatomic, readonly) CEStatus status;
@property (nonatomic, readonly) BOOL botThinking;
@property (nonatomic, readonly) int lastFrom;
@property (nonatomic, readonly) int lastTo;
@property (nonatomic, readonly) NSUInteger plyCount;
@property (nonatomic, readonly) int startFullmove;
@property (nonatomic, readonly) int startSide;

// Wordt aangeroepen na elke zet (from/to voor de animatie, -1 = geen animatie).
@property (nonatomic, copy) void (^onChange)(GameManager *game, int from, int to);
// Meegroeiende bot: adaptive = YES gebruikt adaptiveStrength (0-100) in plaats van botLevel.
@property (nonatomic) BOOL adaptive;
@property (nonatomic) NSInteger adaptiveStrength;
@property (nonatomic) BOOL resultCounted;   // uitslag al verwerkt voor de meegroeiende bot
// Opslaan van 1-tegen-1-partijen.
@property (nonatomic, copy) NSString *saveId;
@property (nonatomic, copy) NSString *saveName;
- (NSString *)initialFEN;
- (NSArray *)uciMoves;
- (void)loadMoves:(NSArray *)uciMoves;
// Zetbeoordeling aan of uit (kies je voor het potje begint).
@property (nonatomic) BOOL ratingEnabled;
// Wordt aangeroepen als een zetbeoordeling klaar is.
@property (nonatomic, copy) void (^onRatingChange)(GameManager *game);
// Wordt aangeroepen als de bot begint of stopt met denken.
@property (nonatomic, copy) void (^onThinkingChange)(GameManager *game);

- (NSArray *)sanMoves;
// Gegevens van halve zet i: @"rating" (CBRating), @"best" (betere zet), @"loss", @"color", @"pending".
- (NSDictionary *)recordAtPly:(NSUInteger)ply;
// Gemiddelde nauwkeurigheid (0-100) van een kleur; count = aantal beoordeelde zetten.
- (double)accuracyForColor:(int)color count:(int *)count;
- (NSArray *)capturedByColor:(int)color;   // stukken (NSNumber) die deze kleur heeft geslagen
- (NSArray *)legalTargetsFrom:(int)square;
- (BOOL)isPromotionFrom:(int)from to:(int)to;
- (BOOL)makeMoveFrom:(int)from to:(int)to promotion:(int)promoType;
- (BOOL)isHumanTurn;
- (BOOL)isGameOver;
- (BOOL)canUndo;
- (void)undo;
- (void)restart;
- (void)startBotIfNeeded;
- (void)stopBot;
- (NSString *)statusText;
- (NSString *)resultTitle;

@end
