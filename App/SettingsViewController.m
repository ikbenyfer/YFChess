// SettingsViewController.m

#import "SettingsViewController.h"
#import "SettingsManager.h"
#import "CustomBoardEditor.h"
#import "YFUI.h"

enum { RowDark = 0, RowAnim, RowLegal, RowCoords, RowFlip, RowHide, RowCount };

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Instellingen";
    self.tableView.rowHeight = [YFUI isPad] ? 60 : 50;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self applyTheme];
}

- (void)applyTheme {
    [YFUI applyThemeToController:self];
    self.tableView.backgroundColor = [SettingsManager shared].backgroundColor;
    self.tableView.backgroundView = nil;
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return RowCount;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"Weergave en spelen";
        case 1: return @"Bot";
        default: return @"Posities";
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1) return @"1 = beginner, 5 = sterkst. Je kunt dit ook kiezen bij Spelen tegen bot.";
    if (section == 2) return @"YF Schaak werkt helemaal offline. Alles wordt alleen op dit apparaat bewaard.";
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]])
        ((UITableViewHeaderFooterView *)view).textLabel.textColor = [SettingsManager shared].secondaryTextColor;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]])
        ((UITableViewHeaderFooterView *)view).textLabel.textColor = [SettingsManager shared].secondaryTextColor;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SettingsManager *s = [SettingsManager shared];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.backgroundColor = s.panelColor;
    cell.textLabel.textColor = s.textColor;
    cell.textLabel.font = [UIFont systemFontOfSize:[YFUI isPad] ? 19 : 16];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumScaleFactor = 0.7;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (indexPath.section == 0) {
        NSArray *titles = @[ @"Donker thema", @"Animaties", @"Legale zetten tonen", @"Coördinaten op het bord",
                             @"1 tegen 1: bord draait mee", @"1 tegen 1: vorige zet verbergen" ];
        BOOL values[RowCount] = { s.darkTheme, s.animations, s.showLegalMoves, s.showCoordinates, s.autoFlip, s.hideLastMove };
        cell.textLabel.text = titles[indexPath.row];
        UISwitch *sw = [YFUI themedSwitch];
        sw.on = values[indexPath.row];
        sw.tag = indexPath.row;
        [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
    } else if (indexPath.section == 1) {
        cell.textLabel.text = @"Niveau";
        UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"1", @"2", @"3", @"4", @"5"]];
        seg.frame = CGRectMake(0, 0, [YFUI isPad] ? 300 : 200, 32);
        seg.selectedSegmentIndex = s.botLevel - 1;
        seg.tintColor = s.accentColor;
        [seg addTarget:self action:@selector(levelChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = seg;
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"Opgeslagen posities (%lu)", (unsigned long)s.savedPositions.count];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 2) {
        SavedPositionsViewController *list = [[SavedPositionsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.navigationController pushViewController:list animated:YES];
    }
}

- (void)switchChanged:(UISwitch *)sw {
    SettingsManager *s = [SettingsManager shared];
    switch (sw.tag) {
        case RowDark: s.darkTheme = sw.on; break;
        case RowAnim: s.animations = sw.on; break;
        case RowLegal: s.showLegalMoves = sw.on; break;
        case RowCoords: s.showCoordinates = sw.on; break;
        case RowFlip: s.autoFlip = sw.on; break;
        case RowHide: s.hideLastMove = sw.on; break;
    }
    [s save];
    if (sw.tag == RowDark) {
        [UIView transitionWithView:self.navigationController.view duration:0.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{ [self applyTheme]; }
                        completion:nil];
    }
}

- (void)levelChanged:(UISegmentedControl *)seg {
    SettingsManager *s = [SettingsManager shared];
    s.botLevel = seg.selectedSegmentIndex + 1;
    [s save];
}

@end
