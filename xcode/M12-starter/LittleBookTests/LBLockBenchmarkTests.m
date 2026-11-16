#import <XCTest/XCTest.h>
#import "LBLockBenchmark.h"

@interface LBLockBenchmarkTests : XCTestCase
@end

@implementation LBLockBenchmarkTests

- (void)testAllLocksProduceSameCount {
    const NSUInteger n = 20000;
    const NSUInteger t = 8;
    NSDictionary<NSString *, NSNumber *> *counts = nil;
    NSDictionary<NSString *, NSNumber *> *times = [LBLockBenchmark runWithIterations:n
                                                                              threads:t
                                                                               counts:&counts];
    NSArray<NSString *> *keys = @[@"synchronized", @"NSLock", @"unfair_lock", @"serialQueue"];
    XCTAssertEqualObjects([LBLockBenchmark allKeys], keys);
    XCTAssertEqual(times.count, (NSUInteger)4);
    XCTAssertEqual(counts.count, (NSUInteger)4);
    for (NSString *key in keys) {
        XCTAssertNotNil(times[key], @"缺少 %@ 的秒數", key);
        XCTAssertGreaterThan(times[key].doubleValue, 0.0);
        XCTAssertEqual(counts[key].unsignedLongLongValue, (unsigned long long)(n * t),
                       @"%@ 的計數器必須剛好是 n × t（少了就是有更新被覆蓋）", key);
    }

    // 兩參數版本（正式 API）一樣回四個秒數
    NSDictionary *quick = [LBLockBenchmark runWithIterations:1000 threads:4];
    XCTAssertEqualObjects([NSSet setWithArray:quick.allKeys], [NSSet setWithArray:keys]);
}

@end
