#import <XCTest/XCTest.h>
#import "LBRingBuffer.h"

@interface LBRingBufferTests : XCTestCase
@end

@implementation LBRingBufferTests

- (void)testOverwritesOldest {
    LBRingBuffer *buffer = [[LBRingBuffer alloc] initWithCapacity:3];
    XCTAssertEqual(buffer.capacity, (NSUInteger)3);
    XCTAssertEqual(buffer.count, (NSUInteger)0);
    XCTAssertEqualObjects(buffer.values, @[]);

    [buffer append:1];
    [buffer append:2];
    XCTAssertEqual(buffer.count, (NSUInteger)2);
    XCTAssertEqualObjects(buffer.values, (@[@1, @2]));

    [buffer append:3];
    [buffer append:4];   // 滿了：覆蓋最舊的 1
    [buffer append:5];   // 再覆蓋 2
    XCTAssertEqual(buffer.count, (NSUInteger)3, @"count 不會超過容量");
    XCTAssertEqualObjects(buffer.values, (@[@3, @4, @5]), @"由舊到新");

    // 繞很多圈之後順序仍然正確
    for (NSInteger i = 6; i <= 100; i++) {
        [buffer append:(double)i];
    }
    XCTAssertEqualObjects(buffer.values, (@[@98, @99, @100]));

    [buffer removeAllValues];
    XCTAssertEqual(buffer.count, (NSUInteger)0);
    [buffer append:7];
    XCTAssertEqualObjects(buffer.values, @[@7]);
}

- (void)testAverageAndMax {
    LBRingBuffer *buffer = [[LBRingBuffer alloc] initWithCapacity:4];
    XCTAssertEqual(buffer.average, 0.0, @"空的回 0，不能除以 0");
    XCTAssertEqual(buffer.max, 0.0);

    [buffer append:16.7];
    [buffer append:33.4];
    XCTAssertEqualWithAccuracy(buffer.average, 25.05, 1e-9);
    XCTAssertEqualWithAccuracy(buffer.max, 33.4, 1e-9);

    // 全是負數時 max 也要對（初始值不能用 0）
    LBRingBuffer *negative = [[LBRingBuffer alloc] initWithCapacity:2];
    [negative append:-5];
    [negative append:-2];
    XCTAssertEqualWithAccuracy(negative.max, -2, 1e-9);

    // 被覆蓋掉的值不能再算進平均與最大值
    LBRingBuffer *window = [[LBRingBuffer alloc] initWithCapacity:3];
    for (NSNumber *value in @[@100, @1, @2, @3]) {
        [window append:value.doubleValue];
    }
    XCTAssertEqualWithAccuracy(window.average, 2.0, 1e-9);
    XCTAssertEqualWithAccuracy(window.max, 3.0, 1e-9, @"100 已經被擠出去了");
}

@end
