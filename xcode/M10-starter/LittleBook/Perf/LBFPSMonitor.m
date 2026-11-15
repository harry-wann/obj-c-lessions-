@import QuartzCore;
#import "LBFPSMonitor.h"
#import "LBRingBuffer.h"

NSNotificationName const LBFPSMonitorDidUpdateNotification = @"LBFPSMonitorDidUpdateNotification";

@implementation LBFPSMonitor

+ (instancetype)shared {
    static LBFPSMonitor *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[LBFPSMonitor alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if ((self = [super init])) {
        _history = [[LBRingBuffer alloc] initWithCapacity:60];
    }
    return self;
}

+ (NSInteger)classifyFrameDuration:(double)milliseconds {
    // TODO: M10 — < 16.7 → LBFrameClassNormal、< 33 → LBFrameClassWarning、其他 → LBFrameClassDropped
    return -1;
}

- (BOOL)isRunning {
    return NO;
}

- (void)start {
    // TODO: M10 — CADisplayLink（target 用只弱參考 self 的小物件，否則 link 會強持有 self），
    //            加到 mainRunLoop 的 NSRunLoopCommonModes（捲動時才量得到）；
    //            每幀算 (timestamp − 上一幀) × 1000 → lastFrameMilliseconds、history；
    //            每 0.5 秒算一次 fps 並送 LBFPSMonitorDidUpdateNotification
}

- (void)stop {
    // TODO: M10 — invalidate
}

@end
