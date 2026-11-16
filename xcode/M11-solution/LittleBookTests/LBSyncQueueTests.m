#import <XCTest/XCTest.h>
#import "LBSyncQueue.h"

@interface LBSyncQueueTests : XCTestCase
@end

@implementation LBSyncQueueTests

- (void)testFIFOOrder {
    LBSyncQueue *queue = [[LBSyncQueue alloc] init];
    NSMutableArray<NSNumber *> *log = [NSMutableArray array];

    // 越早排進去的任務延遲越久：如果佇列沒有「等前一個 done 才開始下一個」，順序就會亂掉。
    for (NSInteger i = 0; i < 5; i++) {
        int64_t delay = (int64_t)((5 - i) * 10) * NSEC_PER_MSEC;
        [queue enqueueTask:^(dispatch_block_t done) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay),
                           dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
                [log addObject:@(i)];
                done();
            });
        }];
    }
    XCTAssertEqual(queue.pendingCount, (NSUInteger)5);

    XCTestExpectation *flushed = [self expectationWithDescription:@"flush"];
    [queue flushWithCompletion:^{
        XCTAssertEqualObjects(log, (@[@0, @1, @2, @3, @4]));
        [flushed fulfill];
    }];
    [self waitForExpectations:@[flushed] timeout:3.0];
    XCTAssertEqual(queue.pendingCount, (NSUInteger)0);
}

- (void)testFlushWaitsForAll {
    LBSyncQueue *queue = [[LBSyncQueue alloc] init];

    // 空佇列：flush 要直接回呼（在主佇列）
    XCTestExpectation *emptyFlush = [self expectationWithDescription:@"empty flush"];
    [queue flushWithCompletion:^{
        XCTAssertTrue(NSThread.isMainThread);
        [emptyFlush fulfill];
    }];
    [self waitForExpectations:@[emptyFlush] timeout:1.0];

    __block NSInteger completed = 0;
    for (NSInteger i = 0; i < 3; i++) {
        [queue enqueueTask:^(dispatch_block_t done) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_MSEC)),
                           dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
                completed += 1;
                done();
                done();   // 重複呼叫 done 必須被忽略，不能讓 group 失衡
            });
        }];
    }
    XCTAssertEqual(queue.pendingCount, (NSUInteger)3);
    XCTAssertEqual(completed, (NSInteger)0, @"任務是非同步的，排進去時還沒完成");

    XCTestExpectation *flushed = [self expectationWithDescription:@"flush waits"];
    [queue flushWithCompletion:^{
        XCTAssertTrue(NSThread.isMainThread, @"flush 的回呼要在主佇列");
        XCTAssertEqual(completed, (NSInteger)3, @"flush 必須等全部任務 done");
        XCTAssertEqual(queue.pendingCount, (NSUInteger)0);
        [flushed fulfill];
    }];
    [self waitForExpectations:@[flushed] timeout:3.0];
}

@end
