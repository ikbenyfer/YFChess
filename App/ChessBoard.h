// ChessBoard.h
// YF Schaak - het schaakbord op het scherm (tekenen, aantikken, animaties).

#import <UIKit/UIKit.h>
#include "ChessEngine.h"

@class ChessBoardView;

@protocol ChessBoardViewDelegate <NSObject>
- (void)boardView:(ChessBoardView *)board didTapSquare:(int)square;
@end

@interface ChessBoardView : UIView

@property (nonatomic, weak) id<ChessBoardViewDelegate> delegate;
@property (nonatomic, readonly) BOOL flipped;      // YES = zwart onderaan
@property (nonatomic) int selectedSquare;          // -1 = niets
@property (nonatomic, copy) NSArray *targetSquares; // NSNumber-velden voor legale zetten
@property (nonatomic) int lastFrom;
@property (nonatomic) int lastTo;
@property (nonatomic) int checkSquare;
@property (nonatomic) BOOL showCoordinates;

// from/to >= 0: het stuk schuift met een animatie.
- (void)setBoard:(const uint8_t *)board animatedFrom:(int)from to:(int)to;
- (void)setFlipped:(BOOL)flipped animated:(BOOL)animated;
- (CGRect)rectForSquare:(int)square;
- (void)refreshTheme;

@end
