#import <XCTest/XCTest.h>
#import "LBLedger.h"
#import "LBTransaction.h"

@interface LBLedgerConcurrencyTests : XCTestCase
@end

@implementation LBLedgerConcurrencyTests

- (NSArray<LBTransaction *> *)seedTransactions:(NSUInteger)count {
    NSMutableArray<LBTransaction *> *seeds = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:
                                   [NSString stringWithFormat:@"%lu", (unsigned long)(i + 1)]];
        // 日期分散到不同月份，讓 transactionsGroupedByMonth 有事做
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)i * 86400 * 7];
        LBTransactionKind kind = (i % 3 == 0) ? LBTransactionKindIncome : LBTransactionKindExpense;
        [seeds addObject:[[LBTransaction alloc] initWithAmount:amount
                                                          kind:kind
                                                          date:date
                                                          note:@"並行測試"
                                                      category:nil]];
    }
    return [seeds copy];
}

- (void)testConcurrentReadsAndWritesDoNotCrash {
    LBLedger *ledger = [[LBLedger alloc] init];
    NSArray<LBTransaction *> *seeds = [self seedTransactions:100];
    for (NSUInteger i = 0; i < 50; i++) {
        [ledger addTransaction:seeds[i]];
    }

    // dispatch_apply 在並行佇列上同時跑 1000 次：混合新增、移除、各種讀取。
    // 沒有保護的 NSMutableArray 幾乎一定會在這裡 crash（或 TSan 報 data race）。
    dispatch_queue_t concurrent = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
    dispatch_apply(1000, concurrent, ^(size_t i) {
        LBTransaction *tx = seeds[i % seeds.count];
        switch (i % 5) {
            case 0:
                [ledger addTransaction:tx];
                break;
            case 1:
                [ledger removeTransactionWithIdentifier:seeds[(i * 7) % seeds.count].identifier];
                break;
            case 2:
                (void)ledger.transactions.count;
                break;
            case 3:
                (void)[ledger transactionsGroupedByMonth];
                break;
            default:
                (void)[ledger totalForKind:LBTransactionKindExpense];
                (void)[ledger transactionWithIdentifier:tx.identifier];
                break;
        }
    });

    // 結束後資料仍一致：快照裡每一筆都能用 identifier 查到，而且沒有重複
    NSArray<LBTransaction *> *snapshot = ledger.transactions;
    XCTAssertLessThanOrEqual(snapshot.count, seeds.count);
    NSMutableSet<NSUUID *> *seen = [NSMutableSet set];
    for (LBTransaction *tx in snapshot) {
        XCTAssertFalse([seen containsObject:tx.identifier], @"同一筆不該出現兩次");
        [seen addObject:tx.identifier];
        XCTAssertEqualObjects([ledger transactionWithIdentifier:tx.identifier], tx);
    }
    // 倒序不變
    for (NSUInteger i = 1; i < snapshot.count; i++) {
        XCTAssertNotEqual([snapshot[i - 1].date compare:snapshot[i].date], NSOrderedAscending);
    }

    // 寫入在背景、KVO 通知丟回主佇列：轉一下 run loop 讓它們跑完，total 應該和快照一致
    XCTestExpectation *settle = [self expectationWithDescription:@"main queue drained"];
    dispatch_async(dispatch_get_main_queue(), ^{ [settle fulfill]; });
    [self waitForExpectations:@[settle] timeout:2.0];
    NSDecimalNumber *expected = [[ledger totalForKind:LBTransactionKindIncome]
                                 decimalNumberBySubtracting:[ledger totalForKind:LBTransactionKindExpense]];
    XCTAssertEqualObjects(ledger.total, expected);
}

@end
