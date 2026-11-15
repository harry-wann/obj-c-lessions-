#import <XCTest/XCTest.h>
#import "LBImportService.h"
#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBTypes.h"

@interface LBImportServiceTests : XCTestCase
@property (nonatomic, strong, nullable) NSURL *csvURL;
@end

@implementation LBImportServiceTests

- (void)tearDown {
    if (self.csvURL != nil) {
        [NSFileManager.defaultManager removeItemAtURL:self.csvURL error:NULL];
    }
    [super tearDown];
}

- (void)testImportsInBatchesAndReportsProgress {
    NSError *error = nil;
    self.csvURL = [LBImportService generateSampleCSVWithCount:1000 error:&error];
    XCTAssertNotNil(self.csvURL, @"%@", error);
    NSString *csv = [NSString stringWithContentsOfURL:self.csvURL
                                             encoding:NSUTF8StringEncoding
                                                error:NULL];
    XCTAssertTrue([csv hasPrefix:LBImportCSVHeader]);

    LBLedger *ledger = [[LBLedger alloc] init];
    LBImportService *service = [[LBImportService alloc] initWithLedger:ledger];

    // 每一批都是一次 performBatchImport:，帳本會送一次通知
    __block NSUInteger batchNotifications = 0;
    __block NSUInteger importedByNotifications = 0;
    id token = [NSNotificationCenter.defaultCenter
        addObserverForName:LBLedgerDidImportBatchNotification
                    object:ledger
                     queue:nil
                usingBlock:^(NSNotification *note) {
        XCTAssertTrue(NSThread.isMainThread);
        batchNotifications += 1;
        importedByNotifications += [note.userInfo[LBLedgerImportedCountKey] unsignedIntegerValue];
    }];

    NSMutableArray<NSNumber *> *reports = [NSMutableArray array];
    XCTestExpectation *finished = [self expectationWithDescription:@"import"];
    NSProgress *progress = [service importCSVAtURL:self.csvURL
                                         batchSize:100
                                          progress:^(NSUInteger done, NSUInteger total) {
        XCTAssertTrue(NSThread.isMainThread, @"進度要在主執行緒回報");
        XCTAssertEqual(total, (NSUInteger)1000);
        [reports addObject:@(done)];
    } completion:^(NSError *importError) {
        XCTAssertTrue(NSThread.isMainThread);
        XCTAssertNil(importError);
        [finished fulfill];
    }];
    XCTAssertNotNil(progress);
    XCTAssertTrue(progress.isCancellable);
    [self waitForExpectations:@[finished] timeout:10.0];
    [NSNotificationCenter.defaultCenter removeObserver:token];

    XCTAssertEqual(ledger.transactions.count, (NSUInteger)1000, @"completion 時資料已全部寫入");
    XCTAssertEqual(batchNotifications, (NSUInteger)10, @"1000 筆 / 每批 100 = 10 次 barrier");
    XCTAssertEqual(importedByNotifications, (NSUInteger)1000);
    XCTAssertEqual(progress.completedUnitCount, (int64_t)1000);

    // 節流：不是每筆回報一次；最後一次一定是 100%；數字只增不減
    XCTAssertGreaterThan(reports.count, (NSUInteger)0);
    XCTAssertLessThan(reports.count, (NSUInteger)50, @"進度回報要節流（每 100 ms 最多一次）");
    XCTAssertEqualObjects(reports.lastObject, @1000);
    for (NSUInteger i = 1; i < reports.count; i++) {
        XCTAssertGreaterThanOrEqual(reports[i].unsignedIntegerValue,
                                    reports[i - 1].unsignedIntegerValue);
    }

    // 匯入後仍依日期倒序、total 和逐筆加總一致
    NSArray<LBTransaction *> *all = ledger.transactions;
    for (NSUInteger i = 1; i < all.count; i++) {
        XCTAssertNotEqual([all[i - 1].date compare:all[i].date], NSOrderedAscending);
    }
    XCTestExpectation *settle = [self expectationWithDescription:@"main drained"];
    dispatch_async(dispatch_get_main_queue(), ^{ [settle fulfill]; });
    [self waitForExpectations:@[settle] timeout:2.0];
    NSDecimalNumber *expected = [[ledger totalForKind:LBTransactionKindIncome]
        decimalNumberBySubtracting:[ledger totalForKind:LBTransactionKindExpense]];
    XCTAssertEqualObjects(ledger.total, expected);
}

- (void)testCancelStopsImport {
    NSError *error = nil;
    self.csvURL = [LBImportService generateSampleCSVWithCount:20000 error:&error];
    XCTAssertNotNil(self.csvURL, @"%@", error);

    LBLedger *ledger = [[LBLedger alloc] init];
    LBImportService *service = [[LBImportService alloc] initWithLedger:ledger];
    XCTestExpectation *finished = [self expectationWithDescription:@"cancelled"];
    __block NSError *result = nil;
    NSProgress *progress = [service importCSVAtURL:self.csvURL
                                         batchSize:500
                                          progress:nil
                                        completion:^(NSError *importError) {
        result = importError;
        [finished fulfill];
    }];
    [progress cancel];   // 解析在背景才剛開始：馬上取消
    [self waitForExpectations:@[finished] timeout:10.0];

    XCTAssertNotNil(result, @"取消要回錯誤，呼叫端才知道沒匯完");
    XCTAssertEqualObjects(result.domain, LBErrorDomain);
    XCTAssertEqual(result.code, (NSInteger)LBErrorCodeCancelled);
    XCTAssertLessThan(ledger.transactions.count, (NSUInteger)20000, @"取消後不能把全部匯完");
    XCTAssertTrue(progress.isCancelled);
}

@end
