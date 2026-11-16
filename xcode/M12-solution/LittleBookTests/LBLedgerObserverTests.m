#import <XCTest/XCTest.h>
#import "LBLedger.h"
#import "LBLedgerObserver.h"
#import "LBTransaction.h"

/// 只實作 required 方法的觀察者。
@interface LBTestMinimalObserver : NSObject <LBLedgerObserver>
@property (nonatomic, strong, readonly) NSMutableArray<LBTransaction *> *added;
@property (nonatomic, weak, nullable) LBLedger *lastLedger;
@end

@implementation LBTestMinimalObserver

- (instancetype)init {
    if ((self = [super init])) {
        _added = [NSMutableArray array];
    }
    return self;
}

- (void)ledger:(LBLedger *)ledger didAddTransaction:(LBTransaction *)transaction {
    self.lastLedger = ledger;
    [self.added addObject:transaction];
}

@end

/// 連 optional 方法也實作的觀察者。
@interface LBTestFullObserver : LBTestMinimalObserver
@property (nonatomic, assign) NSUInteger resetCount;
@end

@implementation LBTestFullObserver

- (void)ledgerDidReset:(LBLedger *)ledger {
    self.resetCount += 1;
}

@end

@interface LBLedgerObserverTests : XCTestCase
@end

@implementation LBLedgerObserverTests

- (LBTransaction *)anyTransaction {
    return [LBTransaction expenseWithAmount:[NSDecimalNumber decimalNumberWithString:@"120"]
                                       note:@"午餐"];
}

- (void)testDelegateCalledOnAdd {
    LBLedger *ledger = [[LBLedger alloc] init];
    __weak LBTestMinimalObserver *weakObserver = nil;
    @autoreleasepool {
        LBTestMinimalObserver *observer = [[LBTestMinimalObserver alloc] init];
        ledger.delegate = observer;

        LBTransaction *tx = [self anyTransaction];
        [ledger addTransaction:tx];
        XCTAssertEqual(observer.added.count, (NSUInteger)1);
        XCTAssertEqualObjects(observer.added.firstObject, tx);
        XCTAssertTrue(observer.lastLedger == ledger, @"第一個參數要是來源帳本");

        [ledger addTransaction:tx];   // 重複加入被忽略，不應再通知
        XCTAssertEqual(observer.added.count, (NSUInteger)1);
        weakObserver = observer;
    }

    // delegate 是 weak：觀察者釋放後自動歸零，帳本繼續運作不會 crash
    XCTAssertNil(weakObserver, @"帳本不該強持有 delegate");
    XCTAssertNil(ledger.delegate);
    [ledger addTransaction:[self anyTransaction]];
    XCTAssertEqual(ledger.transactions.count, (NSUInteger)2);
}

- (void)testOptionalMethodNotRequired {
    LBLedger *ledger = [[LBLedger alloc] init];
    [ledger addTransaction:[self anyTransaction]];

    // 沒實作 ledgerDidReset: 的觀察者：reset 不能 crash（要先 respondsToSelector:）
    LBTestMinimalObserver *minimal = [[LBTestMinimalObserver alloc] init];
    ledger.delegate = minimal;
    XCTAssertFalse([minimal respondsToSelector:@selector(ledgerDidReset:)]);
    XCTAssertNoThrow([ledger reset]);
    XCTAssertEqual(ledger.transactions.count, (NSUInteger)0);

    // 有實作的觀察者就要被通知
    LBTestFullObserver *full = [[LBTestFullObserver alloc] init];
    ledger.delegate = full;
    [ledger addTransaction:[self anyTransaction]];
    [ledger reset];
    XCTAssertEqual(full.resetCount, (NSUInteger)1);
    XCTAssertEqual(full.added.count, (NSUInteger)1);
    XCTAssertEqual(ledger.transactions.count, (NSUInteger)0);
}

@end
