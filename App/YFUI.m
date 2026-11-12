// YFUI.m

#import "YFUI.h"
#import "SettingsManager.h"

@implementation YFButton

- (void)applyTheme {
    SettingsManager *s = [SettingsManager shared];
    self.backgroundColor = self.primary ? s.accentColor : s.buttonColor;
    UIColor *tc = self.primary ? [UIColor whiteColor] : s.buttonTextColor;
    if (self.primary && s.darkTheme) tc = [UIColor colorWithWhite:0.1 alpha:1.0];
    [self setTitleColor:tc forState:UIControlStateNormal];
    [self setTitleColor:tc forState:UIControlStateSelected];
    self.layer.borderColor = s.accentColor.CGColor;
    self.layer.borderWidth = self.selected ? 3.0 : 0.0;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.alpha = highlighted ? 0.6 : (self.enabled ? 1.0 : 0.4);
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.alpha = enabled ? 1.0 : 0.4;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.layer.borderWidth = selected ? 3.0 : 0.0;
}

- (void)setPrimary:(BOOL)primary {
    _primary = primary;
    [self applyTheme];
}

@end

@implementation YFUI

+ (BOOL)isPad {
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

+ (YFButton *)buttonWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    YFButton *b = [YFButton buttonWithType:UIButtonTypeCustom];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:[self isPad] ? 19 : 16];
    b.titleLabel.adjustsFontSizeToFitWidth = YES;
    b.titleLabel.minimumScaleFactor = 0.6;
    b.titleLabel.numberOfLines = 2;
    b.titleLabel.textAlignment = NSTextAlignmentCenter;
    b.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 6);
    b.layer.cornerRadius = 10;
    b.clipsToBounds = YES;
    [b applyTheme];
    if (target && action) [b addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}

+ (CGFloat)layoutViews:(NSArray *)views x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width
            itemHeight:(CGFloat)h columns:(NSInteger)columns spacing:(CGFloat)spacing {
    if (columns < 1) columns = 1;
    CGFloat w = floor((width - spacing * (columns - 1)) / columns);
    NSInteger i = 0;
    CGFloat bottom = y;
    for (UIView *v in views) {
        NSInteger row = i / columns, col = i % columns;
        v.frame = CGRectMake(x + col * (w + spacing), y + row * (h + spacing), w, h);
        bottom = CGRectGetMaxY(v.frame);
        i++;
    }
    return bottom;
}

+ (void)applyThemeToController:(UIViewController *)vc {
    SettingsManager *s = [SettingsManager shared];
    vc.view.backgroundColor = s.backgroundColor;
    UINavigationBar *bar = vc.navigationController.navigationBar;
    if (bar) {
        bar.barStyle = s.darkTheme ? UIBarStyleBlack : UIBarStyleDefault;
        bar.barTintColor = s.panelColor;
        bar.tintColor = s.accentColor;
        bar.translucent = NO;
        bar.titleTextAttributes = @{ NSForegroundColorAttributeName: s.textColor,
                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:18] };
    }
}

+ (void)showMessage:(NSString *)message title:(NSString *)title from:(UIViewController *)vc {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:message
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [vc presentViewController:a animated:YES completion:nil];
}

+ (UILabel *)labelWithSize:(CGFloat)size bold:(BOOL)bold {
    UILabel *l = [[UILabel alloc] init];
    l.font = bold ? [UIFont boldSystemFontOfSize:size] : [UIFont systemFontOfSize:size];
    l.textColor = [SettingsManager shared].textColor;
    l.numberOfLines = 0;
    l.backgroundColor = [UIColor clearColor];
    return l;
}

+ (UISwitch *)themedSwitch {
    UISwitch *sw = [[UISwitch alloc] init];
    sw.onTintColor = [SettingsManager shared].accentColor;
    return sw;
}

@end
