#import <XCTest/XCTest.h>
#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBMonthSection.h"

@interface LBLedgerTests : XCTestCase
@end

@implementation LBLedgerTests {
    LBLedger *_ledger;
    NSCalendar *_calendar;
}

- (void)setUp {
    [super setUp];
    _ledger = [[LBLedger alloc] init];
    _calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
}

- (NSDate *)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    components.day = day;
    components.hour = 12;   // 中午，避開時區造成的跨日
    return [_calendar dateFromComponents:components];
}

- (NSDecimalNumber *)decimal:(NSString *)string {
    return [NSDecimalNumber decimalNumberWithString:string];
}

- (LBTransaction *)transactionWithAmount:(NSString *)amount
                                    kind:(LBTransactionKind)kind
                                    date:(NSDate *)date
                                    note:(NSString *)note {
    return [[LBTransaction alloc] initWithAmount:[self decimal:amount]
                                            kind:kind
                                            date:date
                                            note:note
                                        category:nil];
}

- (LBTransaction *)expense:(NSString *)amount
                      year:(NSInteger)y month:(NSInteger)m day:(NSInteger)d {
    return [self transactionWithAmount:amount
                                  kind:LBTransactionKindExpense
                                  date:[self dateWithYear:y month:m day:d]
                                  note:amount];
}

- (void)testAddAndRemove {
    LBTransaction *lunch = [LBTransaction expenseWithAmount:[self decimal:@"120"] note:@"午餐"];
    XCTAssertEqual(_ledger.transactions.count, (NSUInteger)0);

    [_ledger addTransaction:lunch];
    XCTAssertEqual(_ledger.transactions.count, (NSUInteger)1);
    XCTAssertEqualObjects([_ledger transactionWithIdentifier:lunch.identifier], lunch);

    [_ledger addTransaction:lunch];   // 同一筆重複加入要忽略
    XCTAssertEqual(_ledger.transactions.count, (NSUInteger)1);

    XCTAssertTrue([_ledger removeTransactionWithIdentifier:lunch.identifier]);
    XCTAssertEqual(_ledger.transactions.count, (NSUInteger)0);
    XCTAssertNil([_ledger transactionWithIdentifier:lunch.identifier]);
    XCTAssertFalse([_ledger removeTransactionWithIdentifier:lunch.identifier], @"已移除再移除回 NO");
    XCTAssertFalse([_ledger removeTransactionWithIdentifier:[NSUUID UUID]]);
}

- (void)testTransactionsSortedByDateDescending {
    LBTransaction *jan = [self expense:@"1" year:2026 month:1 day:5];
    LBTransaction *mar = [self expense:@"2" year:2026 month:3 day:5];
    LBTransaction *feb = [self expense:@"3" year:2026 month:2 day:5];
    [_ledger addTransaction:jan];
    [_ledger addTransaction:mar];
    [_ledger addTransaction:feb];

    NSArray<LBTransaction *> *expected = @[mar, feb, jan];
    XCTAssertEqualObjects(_ledger.transactions, expected, @"最新的在最前面");
}

- (void)testGroupedByMonth {
    [_ledger addTransaction:[self transactionWithAmount:@"100"
                                                   kind:LBTransactionKindExpense
                                                   date:[self dateWithYear:2026 month:1 day:3]
                                                   note:@"a"]];
    [_ledger addTransaction:[self transactionWithAmount:@"50"
                                                   kind:LBTransactionKindIncome
                                                   date:[self dateWithYear:2026 month:1 day:20]
                                                   note:@"b"]];
    [_ledger addTransaction:[self transactionWithAmount:@"7"
                                                   kind:LBTransactionKindExpense
                                                   date:[self dateWithYear:2025 month:12 day:31]
                                                   note:@"c"]];
    [_ledger addTransaction:[self transactionWithAmount:@"300"
                                                   kind:LBTransactionKindExpense
                                                   date:[self dateWithYear:2026 month:3 day:1]
                                                   note:@"d"]];

    NSArray<LBMonthSection *> *sections = [_ledger transactionsGroupedByMonth];
    XCTAssertEqual(sections.count, (NSUInteger)3);

    // 月份倒序：2026/3、2026/1、2025/12
    XCTAssertEqual(sections[0].year, (NSInteger)2026);
    XCTAssertEqual(sections[0].month, (NSInteger)3);
    XCTAssertEqual(sections[1].year, (NSInteger)2026);
    XCTAssertEqual(sections[1].month, (NSInteger)1);
    XCTAssertEqual(sections[2].year, (NSInteger)2025);
    XCTAssertEqual(sections[2].month, (NSInteger)12);

    // 區段內也倒序，合計正確
    LBMonthSection *january = sections[1];
    XCTAssertEqual(january.transactions.count, (NSUInteger)2);
    XCTAssertEqualObjects(january.transactions[0].note, @"b");
    XCTAssertEqualObjects(january.transactions[1].note, @"a");
    XCTAssertEqualObjects(january.expenseTotal, [self decimal:@"100"]);
    XCTAssertEqualObjects(january.incomeTotal, [self decimal:@"50"]);
    XCTAssertEqualObjects(sections[2].expenseTotal, [self decimal:@"7"]);
    XCTAssertEqualObjects(sections[2].incomeTotal, NSDecimalNumber.zero);
}

- (void)testTotalForKind {
    NSDate *today = [NSDate date];
    LBTransactionKind expense = LBTransactionKindExpense;
    LBTransactionKind income = LBTransactionKindIncome;
    [_ledger addTransaction:[self transactionWithAmount:@"0.1" kind:expense date:today note:@"a"]];
    [_ledger addTransaction:[self transactionWithAmount:@"0.2" kind:expense date:today note:@"b"]];
    [_ledger addTransaction:[self transactionWithAmount:@"1000" kind:income date:today note:@"c"]];

    // NSDecimalNumber 沒有 0.1 + 0.2 != 0.3 的問題
    XCTAssertEqualObjects([_ledger totalForKind:LBTransactionKindExpense], [self decimal:@"0.3"]);
    XCTAssertEqualObjects([_ledger totalForKind:LBTransactionKindIncome], [self decimal:@"1000"]);

    LBLedger *empty = [[LBLedger alloc] init];
    XCTAssertEqualObjects([empty totalForKind:LBTransactionKindExpense], NSDecimalNumber.zero);
}

- (void)testTransactionsReturnsImmutableSnapshot {
    [_ledger addTransaction:[LBTransaction expenseWithAmount:[NSDecimalNumber one] note:@"a"]];
    NSArray<LBTransaction *> *snapshot = _ledger.transactions;
    XCTAssertFalse([snapshot isKindOfClass:[NSMutableArray class]], @"不能把內部可變陣列交出去");

    [_ledger addTransaction:[LBTransaction expenseWithAmount:[NSDecimalNumber one] note:@"b"]];
    XCTAssertEqual(snapshot.count, (NSUInteger)1, @"快照不會跟著變");
    XCTAssertEqual(_ledger.transactions.count, (NSUInteger)2);
}

@end
