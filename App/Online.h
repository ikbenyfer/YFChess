// Online.h
// YF Schaak - online spelen op lichess.org: lobby (inloggen, zoeken, uitdagen) en het online speelscherm.

#import <UIKit/UIKit.h>

@interface OnlineViewController : UIViewController
@end

@interface OnlineGameViewController : UIViewController
- (instancetype)initWithGameId:(NSString *)gameId;
@end
