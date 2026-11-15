#import "LBTransactionListViewController.h"
#import "LBTransactionEditorViewController.h"
#import "LBTransactionCell.h"
#import "LBMonthHeaderView.h"
#import "LBTransactionViewModel.h"
#import "LBLedger.h"
#import "LBLedgerObserver.h"
#import "LBUndoStack.h"
#import "LBTransaction.h"
#import "LBMonthSection.h"
#import "LBSearchController.h"
#import "LBSettings.h"

static const CGFloat LBTransactionRowHeight = 64;
/// 批次匯入時帳本每 500 筆通知一次：合併成最多每 0.5 秒重載一次，主執行緒才有空處理捲動。
static const NSTimeInterval LBTransactionReloadCoalesceInterval = 0.5;

/// 協定遵循寫在類別延伸：對外的標頭不用知道這些實作細節。
@interface LBTransactionListViewController () <LBLedgerObserver, LBTransactionEditorDelegate,
                                               UISearchResultsUpdating>
@property (nonatomic, strong) UIView *emptyStateView;
@property (nonatomic, strong) UISearchController *searchUI;
@property (nonatomic, strong) LBSearchController *searchController;
/// 非 nil 表示正在顯示搜尋結果（畫面 03）：單一 section、不分月份、不能滑動刪除。
@property (nonatomic, copy, nullable) NSArray<LBTransaction *> *searchResults;
@property (nonatomic, assign) BOOL reloadScheduled;
@end

@implementation LBTransactionListViewController

- (instancetype)initWithLedger:(LBLedger *)ledger undoStack:(LBUndoStack *)undoStack {
    NSParameterAssert(ledger != nil);
    NSParameterAssert(undoStack != nil);
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _ledger = ledger;
        _undoStack = undoStack;
        _sections = @[];
        _searchController = [[LBSearchController alloc] initWithLedger:ledger];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_searchController cancel];
}

#pragma mark - 生命週期

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"帳本";
    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"復原"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(lb_undoTapped)];
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                      target:self
                                                      action:@selector(lb_addTapped)];

    UITableView *tableView = self.tableView;
    [tableView registerClass:[LBTransactionCell class]
      forCellReuseIdentifier:[LBTransactionCell defaultReuseIdentifier]];
    [tableView registerClass:[LBMonthHeaderView class]
        forHeaderFooterViewReuseIdentifier:[LBMonthHeaderView defaultReuseIdentifier]];
    tableView.rowHeight = LBTransactionRowHeight;
    tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    tableView.estimatedSectionHeaderHeight = 56;
    tableView.backgroundView = [self lb_makeEmptyStateView];

    // 搜尋列（畫面 03）：輸入交給 LBSearchController 做 debounce + 背景過濾
    self.searchUI = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchUI.searchResultsUpdater = self;
    self.searchUI.obscuresBackgroundDuringPresentation = NO;
    self.searchUI.searchBar.placeholder = @"搜尋備註或分類";
    self.navigationItem.searchController = self.searchUI;
    self.definesPresentationContext = YES;

    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self
               selector:@selector(lb_ledgerDidImportBatch:)
                   name:LBLedgerDidImportBatchNotification
                 object:self.ledger];
    [center addObserver:self
               selector:@selector(lb_settingsDidChange:)
                   name:LBSettingsDidChangeNotification
                 object:nil];

    self.ledger.delegate = self;   // 帳本有變動（例如復原把交易加回來）就會通知我們
    [self reloadFromLedger];
}

#pragma mark - 資料

- (void)reloadFromLedger {
    _sections = [self.ledger transactionsGroupedByMonth];
    if (!self.isViewLoaded) {
        return;   // 還沒顯示過：只更新資料，第一次載入 view 時 viewDidLoad 會再讀一次
    }
    [self.tableView reloadData];
    [self lb_updateChrome];
    if (self.searchResults != nil) {
        [self updateSearchResultsForSearchController:self.searchUI];   // 帳本變了：重搜一次
    }
}

/// 匯入期間的通知很密：排一次延遲重載，期間再來的通知直接忽略。
- (void)lb_ledgerDidImportBatch:(NSNotification *)notification {
    if (self.reloadScheduled) {
        return;
    }
    self.reloadScheduled = YES;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(LBTransactionReloadCoalesceInterval * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        weakSelf.reloadScheduled = NO;
        [weakSelf reloadFromLedger];
    });
}

/// 顯示小數位等設定改了：快取裡的字串都過期了。
- (void)lb_settingsDidChange:(NSNotification *)notification {
    [LBTransactionViewModel resetCache];
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
}

- (BOOL)lb_isSearching {
    return self.searchResults != nil;
}

/// 空狀態與「復原」按鈕的啟用狀態。
- (void)lb_updateChrome {
    self.tableView.backgroundView.hidden = _sections.count > 0 || [self lb_isSearching];
    self.navigationItem.leftBarButtonItem.enabled = self.undoStack.canUndo;
}

- (nullable LBTransaction *)lb_transactionAtIndexPath:(NSIndexPath *)indexPath {
    if ([self lb_isSearching]) {
        NSArray<LBTransaction *> *results = self.searchResults;
        if (indexPath.section != 0 || indexPath.row < 0
            || (NSUInteger)indexPath.row >= results.count) {
            return nil;
        }
        return results[(NSUInteger)indexPath.row];
    }
    if (indexPath.section < 0 || (NSUInteger)indexPath.section >= _sections.count) {
        return nil;
    }
    NSArray<LBTransaction *> *rows = _sections[(NSUInteger)indexPath.section].transactions;
    if (indexPath.row < 0 || (NSUInteger)indexPath.row >= rows.count) {
        return nil;
    }
    return rows[(NSUInteger)indexPath.row];
}

#pragma mark - 空狀態（畫面 02）

- (UIView *)lb_makeEmptyStateView {
    UIView *container = [[UIView alloc] init];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"tray"]];
    icon.tintColor = UIColor.tertiaryLabelColor;
    icon.preferredSymbolConfiguration =
        [UIImageSymbolConfiguration configurationWithPointSize:44 weight:UIImageSymbolWeightLight];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"還沒有任何交易";
    title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    title.textColor = UIColor.secondaryLabelColor;

    UILabel *hint = [[UILabel alloc] init];
    hint.text = @"按右上角的 ＋，或下面的按鈕開始記帳。";
    hint.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    hint.textColor = UIColor.tertiaryLabelColor;
    hint.numberOfLines = 0;
    hint.textAlignment = NSTextAlignmentCenter;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"新增交易" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [button addTarget:self
               action:@selector(lb_addTapped)
     forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stack =
        [[UIStackView alloc] initWithArrangedSubviews:@[icon, title, hint, button]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 12;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:container.centerYAnchor constant:-40],
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:container.leadingAnchor
                                                         constant:32],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:container.trailingAnchor
                                                       constant:-32],
    ]];
    self.emptyStateView = container;
    return container;
}

#pragma mark - 動作

- (void)lb_addTapped {
    LBTransactionEditorViewController *editor =
        [[LBTransactionEditorViewController alloc] initWithLedger:self.ledger transaction:nil];
    editor.delegate = self;
    // 新增用 modal（包一層 navigation controller 才有導覽列放取消 / 儲存）
    UINavigationController *nav =
        [[UINavigationController alloc] initWithRootViewController:editor];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)lb_undoTapped {
    [self.undoStack undo];
    // 復原動作可能是「加回來」（有 delegate 回呼）或「再刪掉」（沒有），一律重載
    [self reloadFromLedger];
}

/// 收起編輯頁：modal 就 dismiss，push 進來的就 pop 回自己。
- (void)lb_dismissEditor {
    if (self.presentedViewController != nil) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popToViewController:self animated:YES];
    }
}

#pragma mark - 刪除（畫面 09）

- (void)lb_confirmDeleteAtIndexPath:(NSIndexPath *)indexPath {
    LBTransaction *tx = [self lb_transactionAtIndexPath:indexPath];
    if (tx == nil) {
        return;
    }
    NSString *message = [NSString stringWithFormat:@"「%@」刪除後可以用「復原」找回。",
                         tx.note.length > 0 ? tx.note : @"這筆交易"];
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"刪除這筆交易？"
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"刪除"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        [weakSelf deleteTransactionAtIndexPath:indexPath];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteTransactionAtIndexPath:(NSIndexPath *)indexPath {
    if ([self lb_isSearching]) {
        return;   // 搜尋結果不分月份，indexPath 對不到 sections；搜尋中不提供刪除
    }
    LBTransaction *tx = [self lb_transactionAtIndexPath:indexPath];
    if (tx == nil) {
        return;
    }
    LBMonthSection *section = _sections[(NSUInteger)indexPath.section];
    BOOL removesSection = section.transactions.count == 1;   // 該月最後一筆：連 section 一起刪
    LBLedger *ledger = self.ledger;
    if (![ledger removeTransactionWithIdentifier:tx.identifier]) {
        return;
    }

    // 登記復原：undo = 加回去（ledger 會透過 delegate 通知我們重載）、redo = 再刪一次（要自己重載）
    __weak typeof(self) weakSelf = self;
    [self.undoStack registerUndo:^{
        [ledger addTransaction:tx];
    } redo:^{
        [ledger removeTransactionWithIdentifier:tx.identifier];
        [weakSelf reloadFromLedger];
    }];

    if (!self.isViewLoaded) {
        _sections = [ledger transactionsGroupedByMonth];   // 沒有畫面就不用動畫
        return;
    }

    UITableView *tableView = self.tableView;
    [tableView performBatchUpdates:^{
        // 資料來源要在 update block 內一起改，UIKit 才能對得上刪除前後的筆數
        self->_sections = [ledger transactionsGroupedByMonth];
        if (removesSection) {
            NSIndexSet *set = [NSIndexSet indexSetWithIndex:(NSUInteger)indexPath.section];
            [tableView deleteSections:set withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    } completion:^(BOOL finished) {
        [weakSelf lb_updateChrome];
    }];

    if (!removesSection) {
        // 該月合計變了：直接更新現有的 header，不用 reloadSections（會和 deleteRows 打架）
        UITableViewHeaderFooterView *header = [tableView headerViewForSection:indexPath.section];
        if ([header isKindOfClass:[LBMonthHeaderView class]]) {
            LBMonthSection *updated = _sections[(NSUInteger)indexPath.section];
            [(LBMonthHeaderView *)header configureWithSection:updated];
        }
    }
    [self lb_updateChrome];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self lb_isSearching]) {
        return 1;
    }
    return (NSInteger)_sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self lb_isSearching]) {
        return (NSInteger)self.searchResults.count;
    }
    return (NSInteger)_sections[(NSUInteger)section].transactions.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (![self lb_isSearching]) {
        return nil;   // 月份 header 用 viewForHeaderInSection:
    }
    return [NSString stringWithFormat:@"找到 %lu 筆 · %.0f ms",
            (unsigned long)self.searchResults.count, self.searchController.lastDuration * 1000];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LBTransactionCell *cell =
        [tableView dequeueReusableCellWithIdentifier:[LBTransactionCell defaultReuseIdentifier]
                                        forIndexPath:indexPath];
    LBTransaction *tx = [self lb_transactionAtIndexPath:indexPath];
    if (tx != nil) {
        // view model 有快取：捲回來的列零格式化（10.2）
        [cell configureWithViewModel:[LBTransactionViewModel viewModelWithTransaction:tx]];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return ![self lb_isSearching];
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self lb_confirmDeleteAtIndexPath:indexPath];
    }
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self lb_isSearching]) {
        return nil;   // 交給 titleForHeaderInSection:
    }
    LBMonthHeaderView *header = [tableView
        dequeueReusableHeaderFooterViewWithIdentifier:[LBMonthHeaderView defaultReuseIdentifier]];
    [header configureWithSection:_sections[(NSUInteger)section]];
    return header;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LBTransaction *tx = [self lb_transactionAtIndexPath:indexPath];
    if (tx == nil) {
        return;
    }
    LBTransactionEditorViewController *editor =
        [[LBTransactionEditorViewController alloc] initWithLedger:self.ledger transaction:tx];
    editor.delegate = self;
    [self.navigationController pushViewController:editor animated:YES];   // 編輯用 push
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *text = searchController.searchBar.text ?: @"";
    NSString *trimmed =
        [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!searchController.isActive || trimmed.length == 0) {
        [self.searchController cancel];   // 晚到的結果一律作廢
        if (self.searchResults != nil) {
            self.searchResults = nil;
            [self.tableView reloadData];
            [self lb_updateChrome];
        }
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.searchController search:trimmed results:^(NSArray<LBTransaction *> *results,
                                                    NSString *query) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil || !strongSelf.searchUI.isActive) {
            return;
        }
        strongSelf.searchResults = results;
        [strongSelf.tableView reloadData];
        [strongSelf lb_updateChrome];
    }];
}

#pragma mark - LBLedgerObserver

- (void)ledger:(LBLedger *)ledger didAddTransaction:(LBTransaction *)transaction {
    [self reloadFromLedger];
}

- (void)ledgerDidReset:(LBLedger *)ledger {
    [self reloadFromLedger];
}

#pragma mark - LBTransactionEditorDelegate

- (void)editor:(LBTransactionEditorViewController *)editor
    didSaveTransaction:(LBTransaction *)transaction {
    LBTransaction *old = editor.transaction;   // 編輯模式：用新的取代舊的（LBTransaction 不可變）
    LBLedger *ledger = self.ledger;
    __weak typeof(self) weakSelf = self;

    if (old != nil) {
        [ledger removeTransactionWithIdentifier:old.identifier];
    }
    [ledger addTransaction:transaction];
    [self.undoStack registerUndo:^{
        [ledger removeTransactionWithIdentifier:transaction.identifier];
        if (old != nil) {
            [ledger addTransaction:old];
        } else {
            [weakSelf reloadFromLedger];
        }
    } redo:^{
        if (old != nil) {
            [ledger removeTransactionWithIdentifier:old.identifier];
        }
        [ledger addTransaction:transaction];
    }];
    [self lb_updateChrome];
    [self lb_dismissEditor];
}

- (void)editorDidCancel:(LBTransactionEditorViewController *)editor {
    [self lb_dismissEditor];
}

- (void)editor:(LBTransactionEditorViewController *)editor
    didDeleteTransaction:(LBTransaction *)transaction {
    LBLedger *ledger = self.ledger;
    __weak typeof(self) weakSelf = self;
    if ([ledger removeTransactionWithIdentifier:transaction.identifier]) {
        [self.undoStack registerUndo:^{
            [ledger addTransaction:transaction];
        } redo:^{
            [ledger removeTransactionWithIdentifier:transaction.identifier];
            [weakSelf reloadFromLedger];
        }];
    }
    [self reloadFromLedger];
    [self lb_dismissEditor];
}

@end
