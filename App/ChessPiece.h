// ChessPiece.h
// YF Schaak - stukken tekenen met Unicode-schaaktekens (zit in iOS zelf, geen internet nodig).

#import <UIKit/UIKit.h>
#include "ChessEngine.h"

@interface ChessPiece : NSObject
+ (NSString *)filledGlyphForType:(int)type;    // ♚♛♜♝♞♟
+ (NSString *)outlineGlyphForType:(int)type;   // ♔♕♖♗♘♙
+ (NSString *)textGlyphForPiece:(uint8_t)piece; // wit = open, zwart = dicht
+ (NSString *)dutchNameForType:(int)type;      // "dame"
+ (int)valueForType:(int)type;                 // 1, 3, 3, 5, 9
+ (NSString *)figurineSAN:(NSString *)san;     // Nf3 -> ♘f3
// Plaatje uit de gekozen stukkenset, of nil bij de klassieke tekens.
+ (UIImage *)imageForPiece:(uint8_t)piece;
@end

// Een stuk op het bord. Wit = witte vulling met zwarte rand, zwart = donkere vulling.
@interface PieceView : UIView
@property (nonatomic) uint8_t piece;
- (instancetype)initWithPiece:(uint8_t)piece;
@end
