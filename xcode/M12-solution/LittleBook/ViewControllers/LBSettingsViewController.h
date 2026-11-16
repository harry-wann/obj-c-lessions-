@import UIKit;

@class LBSettings, LBLedger, LBUndoStack, LBPersistence;

NS_ASSUME_NONNULL_BEGIN

/// Storyboard 檔名（不含副檔名）：Settings.storyboard。
extern NSString * const LBSettingsStoryboardName;
/// 設定頁場景的 Storyboard ID（Identity inspector → Storyboard ID），不是類別名。
extern NSString * const LBSettingsStoryboardIdentifier;
/// 設定頁 →「效能面板」那條 show segue 的 identifier。
extern NSString * const LBSettingsShowPerformanceSegue;

/// 設定頁（畫面 08）。M09 用程式碼建 grouped table；M11 改成 Settings.storyboard 的 static cells：
///   區段 0「一般」：主幣別 / 顯示小數位（Switch）/ 外觀
///   區段 1「資料」：效能面板（segue showPerformance）/ 匯出 JSON / 匯入測試資料 / 清除全部資料
/// Storyboard 建立 VC 一律走 initWithCoder:，所以 M09 的 initWithSettings:… 不能再用：
/// 相依性改成屬性注入，必須在 view 載入前設好（SceneDelegate 建立 tab 時就塞進去）。
@interface LBSettingsViewController : UITableViewController

/// 從 Settings.storyboard 用 Storyboard ID 取出設定頁本身（不含外層的 UINavigationController）。
+ (instancetype)instantiateFromStoryboard;

/// 唯一的建立路徑：Storyboard 解碼時呼叫。M10 把它標成 NS_UNAVAILABLE，M11 改回指定初始化器。
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 沒注入就用 [LBSettings shared]（null_resettable：設 nil 也會回到 shared）。
@property (nonatomic, strong, null_resettable) LBSettings *settings;
/// 沒注入時「資料」區段的功能（匯出 / 匯入 / 清除）會停用，效能面板改用空帳本。
@property (nonatomic, strong, nullable) LBLedger *ledger;
@property (nonatomic, strong, nullable) LBUndoStack *undoStack;
@property (nonatomic, strong, nullable) LBPersistence *persistence;

/// Storyboard 連線（11.3）：outlet 在 viewDidLoad 之後才有值，init 階段全是 nil。
/// 對外 readonly 給測試檢查；類別延伸裡是 readwrite，UIKit 載入時用 KVC 設進來。
@property (nonatomic, weak, readonly, nullable) IBOutlet UILabel *currencyLabel;
@property (nonatomic, weak, readonly, nullable) IBOutlet UISwitch *centsSwitch;
@property (nonatomic, weak, readonly, nullable) IBOutlet UILabel *appearanceLabel;

/// Switch 的 Value Changed（Storyboard 連的 IBAction）。
- (IBAction)centsSwitchChanged:(UISwitch *)sender;

/// unwind segue 的目的地（11.3 範例）：效能頁的按鈕拖到 Exit 選這個方法就能一路回到設定頁。
- (IBAction)unwindFromPerformance:(UIStoryboardSegue *)segue;

@end

NS_ASSUME_NONNULL_END
