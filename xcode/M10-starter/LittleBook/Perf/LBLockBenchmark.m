#import "LBLockBenchmark.h"
#include <os/lock.h>

NSString * const LBLockBenchmarkSynchronized = @"synchronized";
NSString * const LBLockBenchmarkNSLock = @"NSLock";
NSString * const LBLockBenchmarkUnfairLock = @"unfair_lock";
NSString * const LBLockBenchmarkSerialQueue = @"serialQueue";

@implementation LBLockBenchmark

+ (NSArray<NSString *> *)allKeys {
    return @[LBLockBenchmarkSynchronized, LBLockBenchmarkNSLock,
             LBLockBenchmarkUnfairLock, LBLockBenchmarkSerialQueue];
}

+ (NSDictionary<NSString *, NSNumber *> *)runWithIterations:(NSUInteger)n threads:(NSUInteger)t {
    return [self runWithIterations:n threads:t counts:NULL];
}

+ (NSDictionary<NSString *, NSNumber *> *)runWithIterations:(NSUInteger)n
                                                     threads:(NSUInteger)t
                                                      counts:(NSDictionary<NSString *, NSNumber *> *
                                                              _Nullable * _Nullable)outCounts {
    // TODO: M10 — 四種同步方式各跑一輪：dispatch_apply(t, 全域並行佇列) 每條各把共用計數器 +1 共 n 次，
    //            量秒數（NSProcessInfo.systemUptime）。@synchronized / NSLock / os_unfair_lock /
    //            串列佇列 dispatch_sync。計數器最後必須都等於 n × t（outCounts 回傳給測試檢查）。
    if (outCounts != NULL) {
        *outCounts = @{};
    }
    return @{};
}

@end
