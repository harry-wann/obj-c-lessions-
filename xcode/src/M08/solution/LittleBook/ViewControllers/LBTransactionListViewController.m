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

static const CGFloat LBTransactionRowHeight = 64;

/// 協定遵循寫在類別延伸：對外的標頭不用知道這些實作細節。
@interface LBTransactionListViewController () <LBLedgerObserver, LBTransactionEditorDelegate>
@property (nonatomic, strong) UIView *emptyStateView;
@end

@implementation LBTransactionListViewController

- (instancetype)initWithLedger:(LBLedger *)ledger undoStack:(LBUndoStack *)undoStack {
    NSParameterAssert(ledger != nil);
    NSParameterAssert(undoStack != nil);
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _ledger = ledger;
        _undoStack = undoStack;
        _sections = @[];
    }
    return self;
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
}

/// 空狀態與「復原」按鈕的啟用狀態。
- (void)lb_updateChrome {
    self.tableView.backgroundView.hidden = _sections.count > 0;
    self.navigationItem.leftBarButtonItem.enabled = self.undoStack.canUndo;
}

- (nullable LBTransaction *)lb_transactionAtIndexPath:(NSIndexPath *)indexPath {
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
    return (NSInteger)_sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)_sections[(NSUInteger)section].transactions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LBTransactionCell *cell =
        [tableView dequeueReusableCellWithIdentifier:[LBTransactionCell defaultReuseIdentifier]
                                        forIndexPath:indexPath];
    LBMonthSection *section = _sections[(NSUInteger)indexPath.section];
    LBTransaction *tx = section.transactions[(NSUInteger)indexPath.row];
    [cell configureWithViewModel:[LBTransactionViewModel viewModelWithTransaction:tx]];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
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
