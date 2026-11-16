@import UIKit;

@class LBLedger, LBUndoStack, LBMonthSection;

NS_ASSUME_NONNULL_BEGIN

/// 交易列表（畫面 01 / 02 / 09）：insetGrouped、依月份分 section、滑動刪除 + 確認、復原、空狀態。
@interface LBTransactionListViewController : UITableViewController

@property (nonatomic, strong, readonly) LBLedger *ledger;
@property (nonatomic, strong, readonly) LBUndoStack *undoStack;

/// 目前顯示的 section（來自 ledger.transactionsGroupedByMonth 的快照），測試用。
@property (nonatomic, copy, readonly) NSArray<LBMonthSection *> *sections;

- (instancetype)initWithLedger:(LBLedger *)ledger undoStack:(LBUndoStack *)undoStack;

/// 不經確認直接刪除該列：從 ledger 移除、登記復原、performBatchUpdates:（該月最後一筆時連 section 一起刪）。
/// 滑動刪除的 UIAlertController 按「刪除」後呼叫的就是它；測試也直接呼叫它。
- (void)deleteTransactionAtIndexPath:(NSIndexPath *)indexPath;

/// 從 ledger 重新讀 sections 並 reloadData。
- (void)reloadFromLedger;

@end

NS_ASSUME_NONNULL_END
