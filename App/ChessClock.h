// ChessClock.h
// YF Schaak - losse schaakklok. Tijd wordt gemeten met tijdstempels (datum/tijd),
// zodat de klok ook klopt als de app even op de achtergrond staat.

#import <UIKit/UIKit.h>

@interface ChessClock : NSObject

+ (instancetype)shared;

@property (nonatomic, readonly) NSTimeInterval baseTime;
@property (nonatomic, readonly) NSTimeInterval increment;
@property (nonatomic, readonly) int running;      // 0 of 1 = die klok loopt, -1 = geen
@property (nonatomic, readonly) BOOL paused;
@property (nonatomic, readonly) int flagged;      // 0 of 1 = tijd op, -1 = niemand
@property (nonatomic, readonly) BOOL started;

- (void)configureBase:(NSTimeInterval)base increment:(NSTimeInterval)inc;
- (NSTimeInterval)remainingFor:(int)player;
- (NSInteger)movesFor:(int)player;
- (void)tapPlayer:(int)player;   // speler is klaar met zijn zet: de klok van de ander gaat lopen
- (void)pause;
- (void)resume;
- (void)reset;
- (void)update;                  // controleert of iemand door zijn tijd heen is
- (void)saveState;
- (void)loadState;

+ (NSString *)format:(NSTimeInterval)t;

@end

@interface ChessClockViewController : UIViewController
@end
