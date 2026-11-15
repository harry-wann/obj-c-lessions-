@import UIKit;

@class LBLedger;

NS_ASSUME_NONNULL_BEGIN

/// 效能面板（畫面 10，DEBUG）：FPS 卡片、最近 60 幀柱狀圖、壓力測試按鈕、量測指標與驗收目標。
/// 由設定頁 push 進來（M11 改成 Storyboard segue "showPerformance"）。
@interface LBPerformanceViewController : UIViewController

- (instancetype)initWithLedger:(LBLedger *)ledger NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) LBLedger *ledger;

/// 匯入壓力測試的筆數（預設 100,000）。
@property (nonatomic, assign) NSUInteger importCount;

@end

NS_ASSUME_NONNULL_END
