@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/// 最近 N 幀的柱狀圖（畫面 10）：每根柱子一幀、高度是毫秒，顏色依 LBFPSMonitor 的分類，
/// 虛線是 16.7 ms 預算。只在 values 改變時 setNeedsDisplay，drawRect: 裡不配置物件以外的東西。
@interface LBFrameHistoryView : UIView

/// 由舊到新的幀間隔（毫秒）。
@property (nonatomic, copy) NSArray<NSNumber *> *values;

/// 縱軸上限（毫秒），超過的柱子會被截平。預設 50。
@property (nonatomic, assign) double maximumMilliseconds;

/// 固定要畫幾根（不足的留白），預設 60。
@property (nonatomic, assign) NSUInteger slotCount;

@end

NS_ASSUME_NONNULL_END
