#import <XCTest/XCTest.h>
#import "LBSearchController.h"
#import "LBLedger.h"
#import "LBTransaction.h"

@interface LBSearchControllerTests : XCTestCase
@property (nonatomic, strong) LBLedger *ledger;
@property (nonatomic, strong) LBSearchController *search;
@end

@implementation LBSearchControllerTests

- (void)setUp {
    [super setUp];
    self.ledger = [[LBLedger alloc] init];
    NSArray<NSString *> *notes = @[@"早餐 蛋餅", @"午餐 便當", @"午餐 拉麵", @"晚餐", @"Coffee"];
    for (NSUInteger i = 0; i < notes.count; i++) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:1762300800 - (NSTimeInterval)i * 3600];
        [self.ledger addTransaction:[[LBTransaction alloc]
                                     initWithAmount:[NSDecimalNumber decimalNumberWithString:@"100"]
                                               kind:LBTransactionKindExpense
                                               date:date
                                               note:notes[i]
                                           category:nil]];
    }
    self.search = [[LBSearchController alloc] initWithLedger:self.ledger];
}

- (void)tearDown {
    [self.search cancel];
    self.search = nil;
    self.ledger = nil;
    [super tearDown];
}

/// 讓主執行緒的 run loop 轉 seconds 秒（等晚到的回呼，確認它們真的沒來）。
- (void)spinMainRunLoopFor:(NSTimeInterval)seconds {
    XCTestExpectation *wait = [self expectationWithDescription:@"spin"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [wait fulfill];
    });
    [self waitForExpectations:@[wait] timeout:seconds + 2.0];
}

- (void)testStaleResultsAreDropped {
    XCTAssertEqualWithAccuracy(self.search.debounceInterval, 0.25, 1e-9, @"預設 250 ms");
    self.search.debounceInterval = 0;

    NSMutableArray<NSString *> *delivered = [NSMutableArray array];
    XCTestExpectation *fresh = [self expectationWithDescription:@"fresh result"];

    // 第一個查詢很慢（模擬 10 萬筆）：0.1 秒後它還在背景跑
    self.search.simulatedLatency = 0.5;
    [self.search search:@"早餐" results:^(NSArray<LBTransaction *> *results, NSString *query) {
        [delivered addObject:query];
    }];
    NSUInteger firstGeneration = self.search.generation;
    [self spinMainRunLoopFor:0.1];

    // 第二個查詢很快：先回來；第一個晚到的結果必須被丟掉
    self.search.simulatedLatency = 0;
    [self.search search:@"午餐" results:^(NSArray<LBTransaction *> *results, NSString *query) {
        [delivered addObject:query];
        XCTAssertTrue(NSThread.isMainThread);
        XCTAssertEqual(results.count, (NSUInteger)2);
        for (LBTransaction *tx in results) {
            XCTAssertTrue([tx.note containsString:@"午餐"]);
        }
        [fresh fulfill];
    }];
    XCTAssertGreaterThan(self.search.generation, firstGeneration, @"每次 search: 世代 +1");
    [self waitForExpectations:@[fresh] timeout:2.0];

    [self spinMainRunLoopFor:0.8];   // 等到第一個查詢「本來」會回來的時間之後
    XCTAssertEqualObjects(delivered, @[@"午餐"], @"舊查詢的結果晚到也不能覆蓋新結果");

    // 不分大小寫；空白查詢回全部
    XCTestExpectation *caseless = [self expectationWithDescription:@"case insensitive"];
    [self.search search:@"coffee" results:^(NSArray<LBTransaction *> *results, NSString *query) {
        XCTAssertEqual(results.count, (NSUInteger)1);
        [caseless fulfill];
    }];
    [self waitForExpectations:@[caseless] timeout:2.0];
    XCTestExpectation *everything = [self expectationWithDescription:@"empty query"];
    [self.search search:@"  " results:^(NSArray<LBTransaction *> *results, NSString *query) {
        XCTAssertEqual(results.count, (NSUInteger)5);
        [everything fulfill];
    }];
    [self waitForExpectations:@[everything] timeout:2.0];
}

- (void)testDebounceCoalescesInput {
    self.search.debounceInterval = 0.1;
    NSMutableArray<NSString *> *delivered = [NSMutableArray array];
    XCTestExpectation *first = [self expectationWithDescription:@"debounced"];

    // 使用者連續打字：只有最後一次會真的去搜尋
    for (NSString *query in @[@"午", @"午餐", @"午餐 拉"]) {
        [self.search search:query results:^(NSArray<LBTransaction *> *results, NSString *q) {
            [delivered addObject:q];
            if (delivered.count == 1) {
                [first fulfill];
            }
        }];
    }
    [self waitForExpectations:@[first] timeout:2.0];
    [self spinMainRunLoopFor:0.3];
    XCTAssertEqualObjects(delivered, @[@"午餐 拉"], @"debounce 期間的輸入要合併成一次");

    // cancel：等待中的 debounce 也要作廢
    [self.search search:@"晚餐" results:^(NSArray<LBTransaction *> *results, NSString *q) {
        [delivered addObject:q];
    }];
    [self.search cancel];
    [self spinMainRunLoopFor:0.3];
    XCTAssertEqual(delivered.count, (NSUInteger)1, @"cancel 之後不能再回呼");
}

@end
