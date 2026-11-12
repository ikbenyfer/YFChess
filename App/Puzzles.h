// Puzzles.h
// YF Schaak - puzzels: mat in 1, mat in 2 en eindspel-oefeningen.

#import <UIKit/UIKit.h>

@interface PuzzleListViewController : UITableViewController
@end

@interface PuzzleViewController : UIViewController
- (instancetype)initWithPuzzleIndex:(int)index;
@end
