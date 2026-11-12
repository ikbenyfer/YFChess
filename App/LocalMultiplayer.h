// LocalMultiplayer.h
// YF Schaak - 1 tegen 1 op één iPad: keuzes en starten.

#import <UIKit/UIKit.h>

@interface LocalMultiplayerViewController : UIViewController
@end

// Lijst met opgeslagen 1-tegen-1-partijen. Vegen naar links = verwijderen.
@interface SavedGamesViewController : UITableViewController
@property (nonatomic, copy) void (^onPick)(NSDictionary *game);
@end
