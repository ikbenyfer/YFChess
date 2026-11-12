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
// Wordt aangeroepen als de bot begint of stopt met denken.
@property (nonatomic, copy) void (^onThinkingChange)(GameManager *game);

- (NSArray *)sanMoves;
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
