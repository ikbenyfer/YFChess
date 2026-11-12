// SettingsViewController.m

#import "SettingsViewController.h"
#import "SettingsManager.h"
#import "CustomBoardEditor.h"
#import "ChessPiece.h"
#import "YFUI.h"

enum { RowDark = 0, RowAnim, RowLegal, RowCoords, RowFlip, RowHide, RowCount };
enum { SecDisplay = 0, SecLook, SecBot, SecPositions, SecCount };

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Instellingen";
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
    return SecCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == SecDisplay) return RowCount;
    if (section == SecLook) return 3;
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SecLook && indexPath.row == 2) return [YFUI isPad] ? 96 : 72;
    return [YFUI isPad] ? 60 : 50;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SecDisplay: return @"Weergave en spelen";
        case SecLook: return @"Stukken en bord";
        case SecBot: return @"Bot";
        default: return @"Posities";
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == SecLook)
        return @"Klassiek = de oude schaaktekens. Modern: stukken van Colin M.L. Burnett (GPLv2+). "
               @"3D: “Staunty” van sadsnake1 (CC BY-NC-SA 4.0). Beide sets komen van lichess.org en zitten in de app (geen internet nodig).";
    if (section == SecBot) return @"1 = beginner, 5 = sterkst. Je kunt dit ook kiezen bij Spelen tegen bot.";
    if (section == SecPositions) return @"YF Schaak werkt helemaal offline. Alles wordt alleen op dit apparaat bewaard.";
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

- (UISegmentedControl *)segmentWithItems:(NSArray *)items selected:(NSInteger)sel action:(SEL)action {
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:items];
    CGFloat w = [YFUI isPad] ? 70 * items.count : 54 * items.count;
    seg.frame = CGRectMake(0, 0, w, 32);
    seg.selectedSegmentIndex = sel;
    seg.tintColor = [SettingsManager shared].accentColor;
    [seg addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    return seg;
}

// Een rijtje velden met stukken, zodat je meteen ziet hoe het eruitziet.
- (UIView *)previewView {
    SettingsManager *s = [SettingsManager shared];
    CGFloat sq = [YFUI isPad] ? 76 : 36;
    uint8_t pieces[6] = { CE_PIECE(CE_WHITE, CE_KING), CE_PIECE(CE_BLACK, CE_QUEEN), CE_PIECE(CE_WHITE, CE_ROOK),
                          CE_PIECE(CE_BLACK, CE_BISHOP), CE_PIECE(CE_WHITE, CE_KNIGHT), CE_PIECE(CE_BLACK, CE_PAWN) };
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, sq * 6, sq)];
    v.layer.cornerRadius = 4;
    v.clipsToBounds = YES;
    v.userInteractionEnabled = NO;
    for (int i = 0; i < 6; i++) {
        UIView *cell = [[UIView alloc] initWithFrame:CGRectMake(i * sq, 0, sq, sq)];
        cell.backgroundColor = (i % 2 == 0) ? s.lightSquareColor : s.darkSquareColor;
        PieceView *pv = [[PieceView alloc] initWithPiece:pieces[i]];
        pv.frame = cell.bounds;
        [cell addSubview:pv];
        [v addSubview:cell];
    }
    return v;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SettingsManager *s = [SettingsManager shared];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.backgroundColor = s.panelColor;
    cell.textLabel.textColor = s.textColor;
    cell.textLabel.font = [UIFont systemFontOfSize:[YFUI isPad] ? 19 : 16];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumScaleFactor = 0.6;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (indexPath.section == SecDisplay) {
        NSArray *titles = @[ @"Donker thema", @"Animaties", @"Legale zetten tonen", @"Coördinaten op het bord",
                             @"1 tegen 1: bord draait mee", @"1 tegen 1: vorige zet verbergen" ];
        BOOL values[RowCount] = { s.darkTheme, s.animations, s.showLegalMoves, s.showCoordinates, s.autoFlip, s.hideLastMove };
        cell.textLabel.text = titles[indexPath.row];
        UISwitch *sw = [YFUI themedSwitch];
        sw.on = values[indexPath.row];
        sw.tag = indexPath.row;
        [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
    } else if (indexPath.section == SecLook) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Stukken";
            cell.accessoryView = [self segmentWithItems:[SettingsManager pieceSetNames] selected:s.pieceSet
                                                 action:@selector(pieceSetChanged:)];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Bordkleur";
            cell.accessoryView = [self segmentWithItems:[SettingsManager boardThemeNames] selected:s.boardTheme
                                                 action:@selector(boardThemeChanged:)];
        } else {
            cell.textLabel.text = @"Voorbeeld";
            cell.accessoryView = [self previewView];
        }
    } else if (indexPath.section == SecBot) {
        cell.textLabel.text = @"Niveau";
        cell.accessoryView = [self segmentWithItems:@[@"1", @"2", @"3", @"4", @"5"] selected:s.botLevel - 1
                                             action:@selector(levelChanged:)];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"Opgeslagen posities (%lu)", (unsigned long)s.savedPositions.count];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == SecPositions) {
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

- (void)reloadPreview {
    NSIndexPath *ip = [NSIndexPath indexPathForRow:2 inSection:SecLook];
    [self.tableView reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)pieceSetChanged:(UISegmentedControl *)seg {
    SettingsManager *s = [SettingsManager shared];
    s.pieceSet = seg.selectedSegmentIndex;
    [s save];
    [self reloadPreview];
}

- (void)boardThemeChanged:(UISegmentedControl *)seg {
    SettingsManager *s = [SettingsManager shared];
    s.boardTheme = seg.selectedSegmentIndex;
    [s save];
    [self reloadPreview];
}

- (void)levelChanged:(UISegmentedControl *)seg {
    SettingsManager *s = [SettingsManager shared];
    s.botLevel = seg.selectedSegmentIndex + 1;
    [s save];
}

@end
