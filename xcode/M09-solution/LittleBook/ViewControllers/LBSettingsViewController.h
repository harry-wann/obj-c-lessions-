@import UIKit;

@class LBSettings, LBLedger, LBUndoStack, LBPersistence;

NS_ASSUME_NONNULL_BEGIN

/// 設定頁（畫面 08）。M09 先用程式碼建 grouped table，M11 改成 Settings.storyboard。
/// 區段：一般（主幣別 / 顯示小數位 / 外觀）、資料（匯出 JSON …）、清除全部資料（二次確認）。
@interface LBSettingsViewController : UITableViewController

- (instancetype)initWithSettings:(LBSettings *)settings
                          ledger:(LBLedger *)ledger
                       undoStack:(LBUndoStack *)undoStack
                     persistence:(LBPersistence *)persistence NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) LBSettings *settings;
@property (nonatomic, strong, readonly) LBLedger *ledger;
@property (nonatomic, strong, readonly) LBUndoStack *undoStack;
@property (nonatomic, strong, readonly) LBPersistence *persistence;

@end

NS_ASSUME_NONNULL_END
