@import UIKit;

@class LBLedger, LBFPSMonitor;

NS_ASSUME_NONNULL_BEGIN

/// 效能面板（畫面 10，DEBUG）：FPS 卡片、最近 60 幀柱狀圖、壓力測試按鈕、量測指標與驗收目標。
/// M10 由設定頁 push 進來；M11 改成 Settings.storyboard 的 show segue "showPerformance"，
/// 相依性由設定頁的 prepareForSegue: 注入（ledger、monitor）。
@interface LBPerformanceViewController : UIViewController

- (instancetype)initWithLedger:(LBLedger *)ledger NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
/// M11：Storyboard 建立走這裡（ledger 先是一本空帳本，等 prepareForSegue: 換掉）。
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// M11 改成 readwrite：segue 建立的 VC 沒辦法走 initWithLedger:，只能事後注入（view 載入前）。
@property (nonatomic, strong) LBLedger *ledger;

/// 11.3：prepareForSegue: 塞 [LBFPSMonitor shared] 進來；沒注入（設 nil）也回 shared。
@property (nonatomic, strong, null_resettable) LBFPSMonitor *monitor;

/// 匯入壓力測試的筆數（預設 100,000）。
@property (nonatomic, assign) NSUInteger importCount;

@end

NS_ASSUME_NONNULL_END
