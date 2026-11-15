#import <XCTest/XCTest.h>
#import "LBTransaction.h"
#import "LBCategory.h"

@interface LBTransactionTests : XCTestCase
@end

@implementation LBTransactionTests

- (NSDecimalNumber *)decimal:(NSString *)string {
    return [NSDecimalNumber decimalNumberWithString:string];
}

- (void)testDesignatedInitializerSetsProperties {
    LBCategory *food = [[LBCategory alloc] initWithName:@"飲食" symbolName:@"fork.knife"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1700000000];
    LBTransaction *tx = [[LBTransaction alloc] initWithAmount:[self decimal:@"1280"]
                                                         kind:LBTransactionKindIncome
                                                         date:date
                                                         note:@"薪水"
                                                     category:food];
    XCTAssertNotNil(tx.identifier);
    XCTAssertEqualObjects(tx.amount, [self decimal:@"1280"]);
    XCTAssertEqual(tx.kind, LBTransactionKindIncome);
    XCTAssertEqualObjects(tx.date, date);
    XCTAssertEqualObjects(tx.note, @"薪水");
    XCTAssertEqual(tx.category, food);
    XCTAssertEqual(tx.flags, LBTransactionFlagsNone);

    // 負數金額會被轉正
    LBTransaction *negative = [[LBTransaction alloc] initWithAmount:[self decimal:@"-50"]
                                                               kind:LBTransactionKindExpense
                                                               date:date
                                                               note:@"測試"
                                                           category:nil];
    XCTAssertEqualObjects(negative.amount, [self decimal:@"50"]);

    // 每次建立都有新的 identifier
    LBTransaction *another = [LBTransaction expenseWithAmount:[self decimal:@"1"] note:@"x"];
    XCTAssertNotEqualObjects(tx.identifier, another.identifier);
    XCTAssertEqual(another.kind, LBTransactionKindExpense);
    XCTAssertNil(another.category);
}

- (void)testNoteIsCopied {
    NSMutableString *note = [NSMutableString stringWithString:@"午餐"];
    LBTransaction *tx = [LBTransaction expenseWithAmount:[self decimal:@"120"] note:note];
    [note appendString:@"（改掉了）"];
    XCTAssertEqualObjects(tx.note, @"午餐", @"屬性用 copy，外面改可變字串不應影響");
}

- (void)testPropertiesAreReadonlyFromOutside {
    LBTransaction *tx = [LBTransaction expenseWithAmount:[self decimal:@"120"] note:@"午餐"];
    // readonly 屬性不會合成 setter，所以物件不回應 setNote: 等訊息
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    XCTAssertFalse([tx respondsToSelector:@selector(setNote:)]);
    XCTAssertFalse([tx respondsToSelector:@selector(setAmount:)]);
    XCTAssertFalse([tx respondsToSelector:@selector(setKind:)]);
#pragma clang diagnostic pop
    XCTAssertTrue([tx respondsToSelector:@selector(note)]);
}

- (void)testEqualityAndHash {
    NSDate *date = [NSDate date];
    LBTransaction *a = [[LBTransaction alloc] initWithAmount:[self decimal:@"120"]
                                                        kind:LBTransactionKindExpense
                                                        date:date
                                                        note:@"午餐"
                                                    category:nil];
    LBTransaction *b = [[LBTransaction alloc] initWithAmount:[self decimal:@"120"]
                                                        kind:LBTransactionKindExpense
                                                        date:date
                                                        note:@"午餐"
                                                    category:nil];
    XCTAssertTrue([a isEqual:a]);
    XCTAssertFalse([a isEqual:b], @"內容相同但 identifier 不同，不算同一筆");
    XCTAssertFalse([a isEqual:nil]);
    XCTAssertFalse([a isEqual:@"not a transaction"]);

    LBTransaction *aCopy = [a copy];
    XCTAssertEqualObjects(a, aCopy);
    XCTAssertEqual(a.hash, aCopy.hash, @"isEqual: 為 YES 的兩個物件 hash 必須相同");

    // 可以放進 NSSet / 當字典鍵
    NSSet *set = [NSSet setWithObjects:a, aCopy, b, nil];
    XCTAssertEqual(set.count, (NSUInteger)2);
}

- (void)testCopyReturnsEqualObject {
    LBTransaction *tx = [LBTransaction expenseWithAmount:[self decimal:@"99.5"] note:@"咖啡"];
    LBTransaction *copy = [tx copy];
    XCTAssertNotNil(copy);
    XCTAssertTrue([copy isKindOfClass:[LBTransaction class]]);
    XCTAssertEqualObjects(copy, tx);
    XCTAssertEqualObjects(copy.identifier, tx.identifier);
    XCTAssertEqualObjects(copy.note, tx.note);
}

- (void)testDescriptionContainsAmount {
    LBTransaction *tx = [LBTransaction expenseWithAmount:[self decimal:@"1280"] note:@"房租"];
    NSString *description = tx.description;
    XCTAssertTrue([description containsString:@"1,280.00"], @"%@", description);
    XCTAssertTrue([description containsString:@"房租"], @"%@", description);
}

@end
