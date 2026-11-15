#import "LBTransactionEditorViewController.h"
#import "LBCategoryPickerViewController.h"
#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBCategory.h"
#import "LBTypes.h"

@implementation LBTransactionEditorViewController

- (instancetype)initWithLedger:(LBLedger *)ledger transaction:(LBTransaction *)transaction {
    NSParameterAssert(ledger != nil);
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _ledger = ledger;
        _transaction = transaction;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.title = self.transaction ? @"編輯交易" : @"新增交易";
    // TODO: M08 — 導覽列取消 / 儲存；UIScrollView + UIStackView 表單（金額、種類、日期、分類、
    //            幣別、備註、已對帳 / 定期）；點空白收鍵盤；viewWillAppear 註冊鍵盤通知、
    //            viewWillDisappear 移除；編輯模式填入原值並顯示「刪除」按鈕
    _amountField = [[UITextField alloc] init];
}

- (BOOL)saveWithError:(NSError **)error {
    // TODO: M08 — 解析 amountField.text（去掉千分位逗號、en_US_POSIX、NaN 視為非法）；
    //            不是正數 → error = LBErrorDomain / LBErrorCodeInvalidAmount 並回 NO；
    //            否則組出 LBTransaction（含 flags）、呼叫 delegate 的 editor:didSaveTransaction: 回 YES
    return NO;
}

@end
