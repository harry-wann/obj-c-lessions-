#import "LBLockBenchmark.h"
#include <os/lock.h>

NSString * const LBLockBenchmarkSynchronized = @"synchronized";
NSString * const LBLockBenchmarkNSLock = @"NSLock";
NSString * const LBLockBenchmarkUnfairLock = @"unfair_lock";
NSString * const LBLockBenchmarkSerialQueue = @"serialQueue";

/// 每一輪：t 條「執行緒」（dispatch_apply 的並行迭代）各做 n 次 body，回傳經過的秒數。
static NSTimeInterval LBMeasure(NSUInteger threads, NSUInteger iterations,
                                void (^body)(void)) {
    NSTimeInterval start = NSProcessInfo.processInfo.systemUptime;
    dispatch_apply(threads, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^(size_t i) {
        for (NSUInteger k = 0; k < iterations; k++) {
            body();
        }
    });
    return NSProcessInfo.processInfo.systemUptime - start;
}

@implementation LBLockBenchmark

+ (NSArray<NSString *> *)allKeys {
    return @[LBLockBenchmarkSynchronized, LBLockBenchmarkNSLock,
             LBLockBenchmarkUnfairLock, LBLockBenchmarkSerialQueue];
}

+ (NSDictionary<NSString *, NSNumber *> *)runWithIterations:(NSUInteger)n threads:(NSUInteger)t {
    NSDictionary<NSString *, NSNumber *> *counts = nil;
    NSDictionary<NSString *, NSNumber *> *times = [self runWithIterations:n
                                                                  threads:t
                                                                   counts:&counts];
    for (NSString *key in counts) {
        NSAssert(counts[key].unsignedLongLongValue == (unsigned long long)n * t,
                 @"%@ 的計數器不等於 n × t：鎖沒有保護好", key);
    }
    return times;
}

+ (NSDictionary<NSString *, NSNumber *> *)runWithIterations:(NSUInteger)n
                                                     threads:(NSUInteger)t
                                                      counts:(NSDictionary<NSString *, NSNumber *> *
                                                              _Nullable * _Nullable)outCounts {
    NSParameterAssert(t > 0);
    NSMutableDictionary<NSString *, NSNumber *> *times = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSNumber *> *counts = [NSMutableDictionary dictionary];

    // 計數器放在 heap（calloc）：block 抓的是指標，不必用 __block，也不會因為 block 被 copy 而搬家
    unsigned long long *counter = calloc(1, sizeof(unsigned long long));
    if (counter == NULL) {
        return @{};
    }

    // 1. @synchronized：最好寫，但每次都要查「物件 → 遞迴鎖」的全域表，最慢
    NSObject *token = [[NSObject alloc] init];
    *counter = 0;
    times[LBLockBenchmarkSynchronized] = @(LBMeasure(t, n, ^{
        @synchronized (token) {
            *counter += 1;
        }
    }));
    counts[LBLockBenchmarkSynchronized] = @(*counter);

    // 2. NSLock：pthread_mutex 包一層 ObjC，lock / unlock 成對
    NSLock *lock = [[NSLock alloc] init];
    *counter = 0;
    times[LBLockBenchmarkNSLock] = @(LBMeasure(t, n, ^{
        [lock lock];
        *counter += 1;
        [lock unlock];
    }));
    counts[LBLockBenchmarkNSLock] = @(*counter);

    // 3. os_unfair_lock：最輕量；不可遞迴，同一條執行緒鎖兩次會直接 crash
    os_unfair_lock_t unfair = calloc(1, sizeof(os_unfair_lock));   // 全 0 就是 OS_UNFAIR_LOCK_INIT
    if (unfair != NULL) {
        *counter = 0;
        times[LBLockBenchmarkUnfairLock] = @(LBMeasure(t, n, ^{
            os_unfair_lock_lock(unfair);
            *counter += 1;
            os_unfair_lock_unlock(unfair);
        }));
        counts[LBLockBenchmarkUnfairLock] = @(*counter);
        free(unfair);
    }

    // 4. 串列佇列 + dispatch_sync：不是鎖，但效果一樣（一次只有一個區塊在跑）
    dispatch_queue_t serial = dispatch_queue_create("com.littlebook.lockbench",
                                                   DISPATCH_QUEUE_SERIAL);
    *counter = 0;
    times[LBLockBenchmarkSerialQueue] = @(LBMeasure(t, n, ^{
        dispatch_sync(serial, ^{
            *counter += 1;
        });
    }));
    counts[LBLockBenchmarkSerialQueue] = @(*counter);

    free(counter);
    if (outCounts != NULL) {
        *outCounts = [counts copy];
    }
    return [times copy];
}

@end
