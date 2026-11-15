#import <XCTest/XCTest.h>
#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBStatsObserver.h"

/// 手寫的 KVO 觀察者：把每次收到的新值記下來。
@interface LBTestTotalRecorder : NSObject
@property (nonatomic, strong, readonly) NSMutableArray<NSDecimalNumber *> *received;
@property (nonatomic, strong, readonly) NSMutableArray<NSNumber *> *onMainThread;
- (instancetype)initObserving:(LBLedger *)ledger;
- (void)stopObserving:(LBLedger *)ledger;
@end

static void *LBTestTotalRecorderContext = &LBTestTotalRecorderContext;

@implementation LBTestTotalRecorder

- (instancetype)initObserving:(LBLedger *)ledger {
    if ((self = [super init])) {
        _received = [NSMutableArray array];
        _onMainThread = [NSMutableArray array];
        [ledger addObserver:self
                 forKeyPath:@"total"
                    options:NSKeyValueObservingOptionNew
                    context:LBTestTotalRecorderContext];
    }
    return self;
}

- (void)stopObserving:(LBLedger *)ledger {
    [ledger removeObserver:self forKeyPath:@"total" context:LBTestTotalRecorderContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
    if (context != LBTestTotalRecorderContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    [self.received addObject:change[NSKeyValueChangeNewKey]];
    [self.onMainThread addObject:@(NSThread.isMainThread)];
}

@end

@interface LBLedgerKVOTests : XCTestCase
@end

@implementation LBLedgerKVOTests

- (NSDecimalNumber *)decimal:(NSString *)string {
    return [NSDecimalNumber decimalNumberWithString:string];
}

- (LBTransaction *)transactionWithAmount:(NSString *)amount kind:(LBTransactionKind)kind {
    return [[LBTransaction alloc] initWithAmount:[self decimal:amount]
                                            kind:kind
                                            date:[NSDate date]
                                            note:@"測試"
                                        category:nil];
}

- (void)testTotalChangesNotifyObserver {
    LBLedger *ledger = [[LBLedger alloc] init];
    XCTAssertEqualObjects(ledger.total, NSDecimalNumber.zero);

    LBTestTotalRecorder *recorder = [[LBTestTotalRecorder alloc] initObserving:ledger];

    // XCTest 內建的 KVO 期望：total 變成 200 時自動 fulfill
    XCTKVOExpectation *reaches200 = [[XCTKVOExpectation alloc] initWithKeyPath:@"total"
                                                                        object:ledger
                                                                 expectedValue:[self decimal:@"200"]];

    LBTransaction *expense = [self transactionWithAmount:@"100" kind:LBTransactionKindExpense];
    [ledger addTransaction:expense];                                    // −100
    [ledger addTransaction:[self transactionWithAmount:@"300"
                                                  kind:LBTransactionKindIncome]];   // 200
    [self waitForExpectations:@[reaches200] timeout:1.0];
    XCTAssertEqualObjects(ledger.total, [self decimal:@"200"]);

    [ledger removeTransactionWithIdentifier:expense.identifier];        // 300
    XCTAssertEqualObjects(ledger.total, [self decimal:@"300"]);
    [ledger reset];                                                     // 0
    XCTAssertEqualObjects(ledger.total, NSDecimalNumber.zero);

    NSArray *expected = @[[self decimal:@"-100"], [self decimal:@"200"],
                          [self decimal:@"300"], NSDecimalNumber.zero];
    XCTAssertEqualObjects(recorder.received, expected, @"add / remove / reset 都要通知");
    for (NSNumber *flag in recorder.onMainThread) {
        XCTAssertTrue(flag.boolValue, @"KVO 通知必須在主執行緒");
    }
    [recorder stopObserving:ledger];
}

- (void)testObserverRemovedOnDealloc {
    LBLedger *ledger = [[LBLedger alloc] init];
    __weak LBStatsObserver *weakObserver = nil;
    @autoreleasepool {
        LBStatsObserver *observer = [[LBStatsObserver alloc] initWithLedger:ledger];
        __block NSDecimalNumber *fromBlock = nil;
        observer.onChange = ^(NSDecimalNumber *total) { fromBlock = total; };

        [ledger addTransaction:[self transactionWithAmount:@"50" kind:LBTransactionKindIncome]];
        XCTAssertEqual(observer.changeCount, (NSUInteger)1);
        XCTAssertEqualObjects(observer.lastTotal, [self decimal:@"50"]);
        XCTAssertEqualObjects(fromBlock, [self decimal:@"50"]);
        weakObserver = observer;
    }
    XCTAssertNil(weakObserver, @"觀察者離開 autoreleasepool 後應被釋放");

    // 觀察者已釋放：若 dealloc 忘了 removeObserver:，這一行會對殭屍物件送訊息而 crash。
    // 建議開 Edit Scheme → Diagnostics → Zombie Objects 再跑一次。
    XCTAssertNoThrow([ledger addTransaction:[self transactionWithAmount:@"10"
                                                                   kind:LBTransactionKindExpense]]);
    XCTAssertEqualObjects(ledger.total, [self decimal:@"40"]);
}

@end
