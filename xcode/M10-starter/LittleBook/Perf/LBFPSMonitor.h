@import Foundation;

@class LBRingBuffer;

NS_ASSUME_NONNULL_BEGIN

/// classifyFrameDuration: 的回傳值。
typedef NS_ENUM(NSInteger, LBFrameClass) {
    LBFrameClassNormal = 0,    // < 16.7 ms：60 Hz 的一幀之內
    LBFrameClassWarning = 1,   // < 33 ms：吃掉快兩幀的預算
    LBFrameClassDropped = 2,   // ≥ 33 ms：掉幀（hitch）
};

/// FPS 每次更新（約每 0.5 秒）時在主執行緒送出；object 是 LBFPSMonitor。
extern NSNotificationName const LBFPSMonitorDidUpdateNotification;

/// 用 CADisplayLink 量幀間隔的 FPS 監視器（10.1，DEBUG 用）。只在主執行緒使用。
/// CADisplayLink 會強持有 target：這裡用一個只弱參考 monitor 的小物件當 target，
/// 所以 monitor 不會被 run loop 永遠留住（4.x 的 NSTimer 同一招）。
@interface LBFPSMonitor : NSObject

+ (instancetype)shared;

- (void)start;
- (void)stop;

@property (nonatomic, assign, readonly, getter=isRunning) BOOL running;
/// 最近約 0.5 秒的平均 FPS。
@property (nonatomic, assign, readonly) double fps;
/// 上一幀和這一幀的間隔（毫秒）。
@property (nonatomic, assign, readonly) double lastFrameMilliseconds;
/// 最近 60 幀的間隔（毫秒）。
@property (nonatomic, strong, readonly) LBRingBuffer *history;
/// start 之後累計的掉幀數（classify 為 LBFrameClassDropped 的幀）。
@property (nonatomic, assign, readonly) NSUInteger droppedFrameCount;

/// 0 正常（< 16.7）、1 警告（< 33）、2 掉幀；負數或 0 當正常。純函式，可單測。
+ (NSInteger)classifyFrameDuration:(double)milliseconds;

@end

NS_ASSUME_NONNULL_END
