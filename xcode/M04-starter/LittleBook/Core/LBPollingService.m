#import "LBPollingService.h"

@interface LBPollingService ()
- (void)tick;
@end

@implementation LBPollingService {
    NSTimer *_timer;
}

- (void)start {
    if (_timer != nil) {
        return;
    }
    // TODO: M04 — 這裡有循環參考：run loop → timer → target(self)，而 self 又持有 timer。
    // 用 Memory Graph 看持有鏈，改成 block 版 timer + weakSelf，並在 dealloc 裡 invalidate。
    _timer = [NSTimer scheduledTimerWithTimeInterval:60.0
                                              target:self
                                            selector:@selector(tick)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)stop {
    [_timer invalidate];
    _timer = nil;
}

- (BOOL)isRunning {
    return _timer != nil;
}

- (void)tick {
    _tickCount += 1;
}

@end
