@import UIKit;

@class LBSettings, LBLedger, LBUndoStack, LBPersistence;

NS_ASSUME_NONNULL_BEGIN

/// Storyboard 檔名（不含副檔名）：Settings.storyboard。
extern NSString * const LBSettingsStoryboardName;
/// 設定頁場景的 Storyboard ID（Identity inspector → Storyboard ID），不是類別名。
extern NSString * const LBSettingsStoryboardIdentifier;
/// 設定頁 →「效能面板」那條 show segue 的 identifier。
extern NSString * const LBSettingsShowPerformanceSegue;

/// 設定頁（畫面 08）。M09 先用程式碼建 grouped table；M11 改成 Settings.storyboard 的 static cells。
@interface LBSettingsViewController : UITableViewController

/// 從 Settings.storyboard 用 Storyboard ID 取出設定頁本身。
+ (instancetype)instantiateFromStoryboard;

// TODO: M11 — Storyboard 只會呼叫 initWithCoder:，用不到這個初始化器：改完 storyboard 後刪掉，
// 相依性改成下面的屬性注入。
- (instancetype)initWithSettings:(LBSettings *)settings
                          ledger:(LBLedger *)ledger
                       undoStack:(LBUndoStack *)undoStack
                     persistence:(LBPersistence *)persistence NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
// TODO: M11 — Storyboard 建 VC 走的就是這個：NS_UNAVAILABLE 要換成 NS_DESIGNATED_INITIALIZER
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 沒注入就用 [LBSettings shared]。
@property (nonatomic, strong, null_resettable) LBSettings *settings;
@property (nonatomic, strong, nullable) LBLedger *ledger;
@property (nonatomic, strong, nullable) LBUndoStack *undoStack;
@property (nonatomic, strong, nullable) LBPersistence *persistence;

/// Storyboard 連線：outlet 在 viewDidLoad 之後才有值。
@property (nonatomic, weak, readonly, nullable) IBOutlet UILabel *currencyLabel;
@property (nonatomic, weak, readonly, nullable) IBOutlet UISwitch *centsSwitch;
@property (nonatomic, weak, readonly, nullable) IBOutlet UILabel *appearanceLabel;

- (IBAction)centsSwitchChanged:(UISwitch *)sender;
- (IBAction)unwindFromPerformance:(UIStoryboardSegue *)segue;

@end

NS_ASSUME_NONNULL_END
