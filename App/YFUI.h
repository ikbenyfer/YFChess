// YFUI.h
// YF Schaak - kleine hulpjes voor knoppen, opmaak en meldingen.

#import <UIKit/UIKit.h>

// Grote knop die oplicht bij aanraken en een rand krijgt als hij "gekozen" is.
@interface YFButton : UIButton
@property (nonatomic) BOOL primary;
- (void)applyTheme;
@end

@interface YFUI : NSObject
+ (BOOL)isPad;
+ (YFButton *)buttonWithTitle:(NSString *)title target:(id)target action:(SEL)action;
// Zet knoppen in rijen van `columns` naast elkaar. Geeft de y onder de laatste rij terug.
+ (CGFloat)layoutViews:(NSArray *)views x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width
            itemHeight:(CGFloat)h columns:(NSInteger)columns spacing:(CGFloat)spacing;
+ (void)applyThemeToController:(UIViewController *)vc;
+ (void)showMessage:(NSString *)message title:(NSString *)title from:(UIViewController *)vc;
+ (UILabel *)labelWithSize:(CGFloat)size bold:(BOOL)bold;
+ (UISwitch *)themedSwitch;
@end
