// MoveRating.h
// YF Schaak - namen, tekens en kleuren voor de zetbeoordeling.

#import <UIKit/UIKit.h>
#include "ChessBot.h"

@interface MoveRating : NSObject
+ (NSString *)nameFor:(CBRating)r;      // "Beste zet"
+ (NSString *)symbolFor:(CBRating)r;    // "★", "??"
+ (UIColor *)colorFor:(CBRating)r;
@end
