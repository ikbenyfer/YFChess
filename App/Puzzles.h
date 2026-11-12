// Puzzles.h
// YF Schaak - puzzels: mat in 1, mat in 2 en eindspel-oefeningen.

#import <UIKit/UIKit.h>

// Startscherm met drie vakjes: Mat in 1, Mat in 2 en Eindspel.
@interface PuzzleHomeViewController : UIViewController
@end

@interface PuzzleViewController : UIViewController
- (instancetype)initWithPuzzleIndex:(int)index;
@end
