#import "LBPollingService.h"

@implementation LBPollingService {
    NSTimer *_timer;
}

- (void)start {
    if (_timer != nil) {
        return;
    }
    // 修正：用 block 版 timer + weakSelf。run loop 持有 timer、timer 持有 block、
    // block 只弱參考 self，所以 self 可以正常釋放。
    __weak LBPollingService *weakSelf = self;
    _timer = [NSTimer scheduledTimerWithTimeInterval:60.0
                                             repeats:YES
                                               block:^(NSTimer *timer) {
        [weakSelf tick];
    }];
}

- (void)stop {
    [_timer invalidate];   // 不 invalidate 的 timer 會被 run loop 永遠持有
    _timer = nil;
}

- (BOOL)isRunning {
    return _timer != nil;
}

- (void)tick {
    _tickCount += 1;
}

- (void)dealloc {
    // self 被釋放時順手把 timer 停掉（ARC 下不呼叫 [super dealloc]）
    [_timer invalidate];
}

@end
