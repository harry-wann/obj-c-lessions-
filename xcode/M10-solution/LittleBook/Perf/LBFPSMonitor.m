@import QuartzCore;
#import "LBFPSMonitor.h"
#import "LBRingBuffer.h"

NSNotificationName const LBFPSMonitorDidUpdateNotification = @"LBFPSMonitorDidUpdateNotification";

static const NSUInteger LBFPSHistoryCapacity = 60;
static const CFTimeInterval LBFPSUpdateInterval = 0.5;

@interface LBFPSMonitor ()
- (void)lb_tick:(CADisplayLink *)link;
@end

/// CADisplayLink 的 target：只弱參考 monitor，打斷 run loop → link → target → monitor 的強參考鏈。
@interface LBDisplayLinkTarget : NSObject
@property (nonatomic, weak, nullable) LBFPSMonitor *monitor;
@end

@implementation LBDisplayLinkTarget

- (void)tick:(CADisplayLink *)link {
    LBFPSMonitor *monitor = self.monitor;
    if (monitor == nil) {
        [link invalidate];   // 主人不在了：自己收掉
        return;
    }
    [monitor lb_tick:link];
}

@end

@implementation LBFPSMonitor {
    CADisplayLink *_link;
    CFTimeInterval _lastTimestamp;     // 上一幀的時間（0 = 還沒有）
    CFTimeInterval _windowStart;       // 這一段 FPS 統計的起點
    NSUInteger _framesInWindow;
}

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
        _history = [[LBRingBuffer alloc] initWithCapacity:LBFPSHistoryCapacity];
    }
    return self;
}

- (void)dealloc {
    [_link invalidate];
}

+ (NSInteger)classifyFrameDuration:(double)milliseconds {
    if (milliseconds < 16.7) {
        return LBFrameClassNormal;
    }
    if (milliseconds < 33.0) {
        return LBFrameClassWarning;
    }
    return LBFrameClassDropped;
}

- (BOOL)isRunning {
    return _link != nil;
}

- (void)start {
    NSAssert(NSThread.isMainThread, @"LBFPSMonitor 只能在主執行緒使用");
    if (_link != nil) {
        return;
    }
    LBDisplayLinkTarget *target = [[LBDisplayLinkTarget alloc] init];
    target.monitor = self;
    _link = [CADisplayLink displayLinkWithTarget:target selector:@selector(tick:)];
    // common modes：捲動時 run loop 切到 tracking mode，default mode 的 link 會停，量不到捲動
    [_link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    _lastTimestamp = 0;
    _windowStart = 0;
    _framesInWindow = 0;
    _droppedFrameCount = 0;
    [_history removeAllValues];
}

- (void)stop {
    [_link invalidate];   // invalidate 才會把 link 從 run loop 拿掉並放開 target
    _link = nil;
}

- (void)lb_tick:(CADisplayLink *)link {
    CFTimeInterval now = link.timestamp;
    if (_lastTimestamp > 0) {
        double milliseconds = (now - _lastTimestamp) * 1000.0;
        _lastFrameMilliseconds = milliseconds;
        [_history append:milliseconds];
        if ([LBFPSMonitor classifyFrameDuration:milliseconds] == LBFrameClassDropped) {
            _droppedFrameCount += 1;
        }
    }
    _lastTimestamp = now;

    if (_windowStart == 0) {
        _windowStart = now;
        _framesInWindow = 0;
        return;
    }
    _framesInWindow += 1;
    CFTimeInterval elapsed = now - _windowStart;
    if (elapsed >= LBFPSUpdateInterval) {
        _fps = (double)_framesInWindow / elapsed;
        _windowStart = now;
        _framesInWindow = 0;
        [NSNotificationCenter.defaultCenter postNotificationName:LBFPSMonitorDidUpdateNotification
                                                          object:self];
    }
}

@end
