#import <XCTest/XCTest.h>
#import "LBPersistence.h"
#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBCategory+LBPath.h"
#import "LBTypes.h"

@interface LBPersistenceTests : XCTestCase
@property (nonatomic, strong) NSURL *directoryURL;
@property (nonatomic, strong) LBPersistence *persistence;
@end

@implementation LBPersistenceTests

- (void)setUp {
    [super setUp];
    // 每個測試一個獨立子資料夾（還不存在），不污染真正的存檔
    NSString *name = [NSString stringWithFormat:@"LBPersistenceTests-%@", NSUUID.UUID.UUIDString];
    NSURL *tmp = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    self.directoryURL = [[tmp URLByAppendingPathComponent:name isDirectory:YES]
                         URLByAppendingPathComponent:@"nested" isDirectory:YES];
    self.persistence = [[LBPersistence alloc] initWithDirectoryURL:self.directoryURL];
}

- (void)tearDown {
    [NSFileManager.defaultManager removeItemAtURL:[self.directoryURL URLByDeletingLastPathComponent]
                                            error:NULL];
    self.persistence = nil;
    [super tearDown];
}

- (LBLedger *)sampleLedger {
    LBLedger *ledger = [[LBLedger alloc] init];
    for (NSInteger i = 0; i < 5; i++) {
        NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:
                                   [NSString stringWithFormat:@"%ld.25", (long)(i + 1) * 100]];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:1760000000 + i * 86400 * 9];
        LBTransactionKind kind = (i == 2) ? LBTransactionKindIncome : LBTransactionKindExpense;
        LBCategory *category = (i % 2 == 0) ? [LBCategory lb_categoryWithPath:@"交通/捷運"] : nil;
        [ledger addTransaction:[[LBTransaction alloc] initWithAmount:amount
                                                                kind:kind
                                                                date:date
                                                                note:@"測試，含 \"引號\" 與換行\n"
                                                            category:category
                                                               flags:LBTransactionFlagsRecurring]];
    }
    return ledger;
}

- (void)testRoundTripJSON {
    LBLedger *ledger = [self sampleLedger];
    NSError *error = nil;
    XCTAssertTrue([self.persistence saveLedger:ledger error:&error]);
    XCTAssertNil(error);

    // 檔案真的是 JSON
    NSData *data = [NSData dataWithContentsOfURL:self.persistence.fileURL];
    id root = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    XCTAssertTrue([root isKindOfClass:[NSDictionary class]]);
    XCTAssertEqual([root[@"transactions"] count], (NSUInteger)5);

    LBLedger *loaded = [self.persistence loadLedgerWithError:&error];
    XCTAssertNotNil(loaded);
    XCTAssertNil(error);
    XCTAssertEqualObjects(loaded.transactions, ledger.transactions, @"順序、identifier、欄位全部一致");
    XCTAssertEqualObjects(loaded.total, ledger.total);

    // 背景存檔：主佇列回呼
    [ledger addTransaction:[LBTransaction expenseWithAmount:[NSDecimalNumber one] note:@"再一筆"]];
    XCTestExpectation *saved = [self expectationWithDescription:@"async save"];
    [self.persistence saveLedger:ledger completion:^(NSError *saveError) {
        XCTAssertTrue(NSThread.isMainThread);
        XCTAssertNil(saveError);
        [saved fulfill];
    }];
    [self waitForExpectations:@[saved] timeout:2.0];
    XCTAssertEqual([self.persistence loadLedgerWithError:NULL].transactions.count, (NSUInteger)6);
}

- (void)testWritesAtomicallyToDirectory {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    XCTAssertFalse([fileManager fileExistsAtPath:self.directoryURL.path], @"前提：資料夾還不存在");
    XCTAssertEqualObjects(self.persistence.fileURL.URLByDeletingLastPathComponent.path,
                          self.directoryURL.path);
    XCTAssertEqualObjects(self.persistence.fileURL.lastPathComponent, LBPersistenceFileName);

    NSError *error = nil;
    XCTAssertTrue([self.persistence saveLedger:[self sampleLedger] error:&error], @"%@", error);
    XCTAssertTrue([fileManager fileExistsAtPath:self.persistence.fileURL.path], @"要自動建立資料夾");

    // 再存一次（覆寫）：資料夾裡只有正式檔，原子寫入的暫存檔不能留下來
    XCTAssertTrue([self.persistence saveLedger:[[LBLedger alloc] init] error:&error]);
    NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:self.directoryURL.path
                                                                     error:NULL];
    XCTAssertEqualObjects(contents, @[LBPersistenceFileName]);
    XCTAssertEqual([self.persistence loadLedgerWithError:NULL].transactions.count, (NSUInteger)0);

    // App 預設資料夾不能寫死：要在沙盒的 Application Support 底下
    NSURL *defaultURL = [LBPersistence defaultDirectoryURL];
    XCTAssertTrue(defaultURL.isFileURL);
    XCTAssertTrue([defaultURL.path containsString:@"Application Support"]);
}

- (void)testCorruptFileReturnsError {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    [fileManager createDirectoryAtURL:self.directoryURL
          withIntermediateDirectories:YES
                           attributes:nil
                                error:NULL];

    // 1. 根本不是 JSON
    [[@"{not json" dataUsingEncoding:NSUTF8StringEncoding] writeToURL:self.persistence.fileURL
                                                            atomically:YES];
    NSError *error = nil;
    XCTAssertNil([self.persistence loadLedgerWithError:&error]);
    XCTAssertEqualObjects(error.domain, LBErrorDomain);
    XCTAssertEqual(error.code, (NSInteger)LBErrorCodeMalformedJSON);

    // 2. 是 JSON 但結構不對
    [[@"[1, 2, 3]" dataUsingEncoding:NSUTF8StringEncoding] writeToURL:self.persistence.fileURL
                                                            atomically:YES];
    error = nil;
    XCTAssertNil([self.persistence loadLedgerWithError:&error]);
    XCTAssertEqual(error.code, (NSInteger)LBErrorCodeMalformedJSON);

    // 3. 某筆交易欄位型別錯
    NSString *badItem = @"{\"version\":1,\"transactions\":[{\"id\":\"nope\",\"amount\":\"1\"}]}";
    [[badItem dataUsingEncoding:NSUTF8StringEncoding] writeToURL:self.persistence.fileURL
                                                       atomically:YES];
    error = nil;
    XCTAssertNil([self.persistence loadLedgerWithError:&error]);
    XCTAssertEqualObjects(error.domain, LBErrorDomain);
    XCTAssertEqual(error.code, (NSInteger)LBErrorCodeUnexpectedType);

    // error 傳 NULL 也不能 crash
    XCTAssertNil([self.persistence loadLedgerWithError:NULL]);
}

- (void)testMissingFileReturnsEmptyLedger {
    XCTAssertFalse([NSFileManager.defaultManager fileExistsAtPath:self.persistence.fileURL.path]);
    NSError *error = nil;
    LBLedger *ledger = [self.persistence loadLedgerWithError:&error];
    XCTAssertNotNil(ledger, @"第一次啟動沒有檔案不是錯誤");
    XCTAssertNil(error);
    XCTAssertEqual(ledger.transactions.count, (NSUInteger)0);
    XCTAssertEqualObjects(ledger.total, NSDecimalNumber.zero);
}

@end
