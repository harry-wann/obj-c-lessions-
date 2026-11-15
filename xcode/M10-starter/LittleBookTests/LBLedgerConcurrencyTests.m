#import <XCTest/XCTest.h>
#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBMonthSection.h"

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

- (void)testBarrierWritesAreSerialized {
    LBLedger *ledger = [[LBLedger alloc] init];
    const NSUInteger batches = 40;
    const NSUInteger perBatch = 50;

    // 每一批的日期都和別批交錯（不是整批比較新或比較舊），逼帳本走「合併」而不是「接在後面」
    NSMutableArray<NSArray<LBTransaction *> *> *allBatches = [NSMutableArray array];
    for (NSUInteger b = 0; b < batches; b++) {
        NSMutableArray<LBTransaction *> *batch = [NSMutableArray array];
        for (NSUInteger k = 0; k < perBatch; k++) {
            NSTimeInterval seconds = (NSTimeInterval)(k * batches + b) * 3600;
            unsigned long long mantissa = b * perBatch + k + 1;
            NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithMantissa:mantissa
                                                                       exponent:0
                                                                     isNegative:NO];
            [batch addObject:[[LBTransaction alloc]
                              initWithAmount:amount
                                        kind:(k % 4 == 0) ? LBTransactionKindIncome
                                                          : LBTransactionKindExpense
                                        date:[NSDate dateWithTimeIntervalSince1970:seconds]
                                        note:@"批次"
                                    category:nil]];
        }
        [allBatches addObject:[batch copy]];
    }

    // 40 個批次從不同執行緒同時送進來，中間夾著讀取與單筆寫入
    LBTransaction *single = [LBTransaction expenseWithAmount:[NSDecimalNumber one] note:@"單筆"];
    dispatch_apply(batches, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^(size_t i) {
        [ledger performBatchImport:allBatches[i]];
        (void)ledger.transactions.count;
        (void)[ledger transactionsGroupedByMonth];
        if (i == batches / 2) {
            [ledger addTransaction:single];
        }
        [ledger performBatchImport:allBatches[(i + 1) % batches]];   // 重複送：要被略過
    });
    [ledger waitForPendingWrites];

    NSArray<LBTransaction *> *snapshot = ledger.transactions;
    XCTAssertEqual(snapshot.count, batches * perBatch + 1, @"每一筆剛好一次：沒有遺失、沒有重複");
    NSMutableSet<NSUUID *> *seen = [NSMutableSet set];
    for (NSUInteger i = 0; i < snapshot.count; i++) {
        XCTAssertFalse([seen containsObject:snapshot[i].identifier]);
        [seen addObject:snapshot[i].identifier];
        if (i > 0) {
            XCTAssertNotEqual([snapshot[i - 1].date compare:snapshot[i].date], NSOrderedAscending,
                              @"合併後仍依日期倒序");
        }
    }
    XCTAssertEqualObjects([ledger transactionWithIdentifier:single.identifier], single);

    // 月份分組和逐筆的結果一致：每個區段的筆數加起來 = 總筆數
    NSUInteger grouped = 0;
    for (LBMonthSection *section in [ledger transactionsGroupedByMonth]) {
        grouped += section.transactions.count;
    }
    XCTAssertEqual(grouped, snapshot.count);

    // 總額：通知丟回主佇列後，total 要等於收入 − 支出
    XCTestExpectation *settle = [self expectationWithDescription:@"main queue drained"];
    dispatch_async(dispatch_get_main_queue(), ^{ [settle fulfill]; });
    [self waitForExpectations:@[settle] timeout:2.0];
    NSDecimalNumber *income = NSDecimalNumber.zero;
    NSDecimalNumber *expense = NSDecimalNumber.zero;
    for (LBTransaction *tx in snapshot) {
        if (tx.kind == LBTransactionKindIncome) {
            income = [income decimalNumberByAdding:tx.amount];
        } else {
            expense = [expense decimalNumberByAdding:tx.amount];
        }
    }
    XCTAssertEqualObjects([ledger totalForKind:LBTransactionKindIncome], income);
    XCTAssertEqualObjects([ledger totalForKind:LBTransactionKindExpense], expense);
    XCTAssertEqualObjects(ledger.total, [income decimalNumberBySubtracting:expense]);
}

@end
