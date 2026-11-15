@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// 固定容量的 double 環狀緩衝區（10.1：FPS 歷史）。滿了之後新值覆蓋最舊的值，
/// append 是 O(1)、不搬動任何元素、不配置記憶體。不是執行緒安全的：只在一條執行緒（主執行緒）用。
@interface LBRingBuffer : NSObject

- (instancetype)initWithCapacity:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, assign, readonly) NSUInteger capacity;

- (void)append:(double)value;

/// 目前元素的平均；空的時候回 0。
- (double)average;

/// 目前元素的最大值；空的時候回 0。
- (double)max;

/// 目前元素個數（≤ capacity）。
- (NSUInteger)count;

/// 由舊到新。
- (NSArray<NSNumber *> *)values;

- (void)removeAllValues;

@end

NS_ASSUME_NONNULL_END
