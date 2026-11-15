@import UIKit;

@class LBLedger, LBTransaction, LBTransactionEditorViewController;

NS_ASSUME_NONNULL_BEGIN

/// 編輯頁往回傳值用 delegate（8.5）。儲存 / 刪除都不直接改 ledger，交給 delegate 決定，
/// 列表才能順便登記復原動作。
@protocol LBTransactionEditorDelegate <NSObject>

@required
- (void)editor:(LBTransactionEditorViewController *)editor
    didSaveTransaction:(LBTransaction *)transaction;
- (void)editorDidCancel:(LBTransactionEditorViewController *)editor;

@optional
/// 編輯模式按「刪除」且確認後呼叫；沒實作的話，編輯頁會自己從 ledger 移除再呼叫 editorDidCancel:。
- (void)editor:(LBTransactionEditorViewController *)editor
    didDeleteTransaction:(LBTransaction *)transaction;

@end

/// 新增 / 編輯交易（畫面 04）：UIScrollView + UIStackView 表單、鍵盤遮擋處理。
@interface LBTransactionEditorViewController : UIViewController

@property (nonatomic, strong, readonly) LBLedger *ledger;
/// 編輯中的原交易；nil 表示新增。
@property (nonatomic, strong, readonly, nullable) LBTransaction *transaction;
@property (nonatomic, weak, nullable) id<LBTransactionEditorDelegate> delegate;

/// nil = 新增。
- (instancetype)initWithLedger:(LBLedger *)ledger transaction:(nullable LBTransaction *)transaction;

/// 驗證並組出 LBTransaction，成功就呼叫 delegate 的 editor:didSaveTransaction: 並回 YES；
/// 金額不是正數回 NO，error 的 domain 是 LBErrorDomain、code 是 LBErrorCodeInvalidAmount。
- (BOOL)saveWithError:(NSError **)error;

// 表單控制項（測試與子類別可直接設值）
@property (nonatomic, strong) UITextField *amountField;
@property (nonatomic, strong, readonly) UISegmentedControl *kindControl;
@property (nonatomic, strong, readonly) UIDatePicker *datePicker;
@property (nonatomic, strong, readonly) UITextField *noteField;
@property (nonatomic, strong, readonly) UISwitch *reconciledSwitch;
@property (nonatomic, strong, readonly) UISwitch *recurringSwitch;

@end

NS_ASSUME_NONNULL_END
