@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// 結果字典的 key。
extern NSString * const LBLockBenchmarkSynchronized;   // @"synchronized"
extern NSString * const LBLockBenchmarkNSLock;         // @"NSLock"
extern NSString * const LBLockBenchmarkUnfairLock;     // @"unfair_lock"
extern NSString * const LBLockBenchmarkSerialQueue;    // @"serialQueue"

/// 四種同步方式的 benchmark（10.4）：t 條執行緒各把共用計數器 +1 共 n 次。
/// 正確性比速度重要：每一種的計數器最後都必須剛好等於 n × t，少一次就是鎖沒鎖好。
/// 會阻塞呼叫端，請在背景佇列呼叫（效能面板就是這樣做）。
@interface LBLockBenchmark : NSObject

/// key → 秒數（NSNumber double）。
+ (NSDictionary<NSString *, NSNumber *> *)runWithIterations:(NSUInteger)n threads:(NSUInteger)t;

/// 同上；counts 不為 NULL 時另外回傳每種鎖的最終計數（NSNumber unsigned long long），測試用。
+ (NSDictionary<NSString *, NSNumber *> *)runWithIterations:(NSUInteger)n
                                                     threads:(NSUInteger)t
                                                      counts:(NSDictionary<NSString *, NSNumber *> *
                                                              _Nullable * _Nullable)counts;

/// 依固定順序列出的 key（顯示用）。
+ (NSArray<NSString *> *)allKeys;

@end

NS_ASSUME_NONNULL_END
