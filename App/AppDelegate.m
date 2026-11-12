// AppDelegate.m

#import "AppDelegate.h"
#import "MainMenu.h"
#import "SettingsManager.h"
#import "ChessClock.h"
#include "ChessEngine.h"

// Navigatie die de statusbalk laat kleuren volgens het thema.
@interface YFNavigationController : UINavigationController
@end
@implementation YFNavigationController
- (UIStatusBarStyle)preferredStatusBarStyle {
    return [SettingsManager shared].darkTheme ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}
- (UIViewController *)childViewControllerForStatusBarStyle {
    return nil;
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    ce_init();
    [SettingsManager shared];
    [ChessClock shared];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [SettingsManager shared].backgroundColor;
    YFNavigationController *nav = [[YFNavigationController alloc] initWithRootViewController:[[MainMenuViewController alloc] init]];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[ChessClock shared] saveState];
    [[SettingsManager shared] save];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[ChessClock shared] saveState];
}

@end
