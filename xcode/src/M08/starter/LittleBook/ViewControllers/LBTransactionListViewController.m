#import "LBTransactionListViewController.h"
#import "LBTransactionEditorViewController.h"
#import "LBTransactionCell.h"
#import "LBMonthHeaderView.h"
#import "LBTransactionViewModel.h"
#import "LBLedger.h"
#import "LBUndoStack.h"
#import "LBTransaction.h"
#import "LBMonthSection.h"

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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"帳本";
    // TODO: M08 — 導覽列「復原」「＋」；registerClass: cell 與 header；列高 64；空狀態 backgroundView；
    //            ledger.delegate = self（遵循 LBLedgerObserver）；最後 reloadFromLedger
}

- (void)reloadFromLedger {
    // TODO: M08 — _sections = [self.ledger transactionsGroupedByMonth]，reloadData，更新空狀態 / 復原按鈕
}

- (void)deleteTransactionAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: M08 — 從 ledger 移除、registerUndo:redo:、performBatchUpdates:
    //            （資料來源在 block 內一起改；該月最後一筆要 deleteSections:，否則 deleteRows）
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;   // TODO: M08
}

@end
