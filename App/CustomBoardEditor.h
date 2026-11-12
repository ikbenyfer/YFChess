// CustomBoardEditor.h
// YF Schaak - eigen stelling maken: stukken plaatsen, weghalen en verplaatsen.

#import <UIKit/UIKit.h>

@interface CustomBoardEditorViewController : UIViewController
@end

// Lijst met opgeslagen posities. Kiezen roept de block aan; vegen naar links = verwijderen.
@interface SavedPositionsViewController : UITableViewController
@property (nonatomic, copy) void (^onPick)(NSString *name, NSString *fen);
@end
