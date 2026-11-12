// GameViewController.h
// YF Schaak - het speelscherm (tegen de bot of 1 tegen 1).

#import <UIKit/UIKit.h>
#import "GameManager.h"

@interface GameViewController : UIViewController
- (instancetype)initWithGame:(GameManager *)game;
@end
