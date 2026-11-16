#import <XCTest/XCTest.h>
#import "LBTypes.h"

@interface LBTypesTests : XCTestCase
@end

@implementation LBTypesTests

- (void)testTransactionKindValues {
    XCTAssertEqual((NSInteger)LBTransactionKindExpense, (NSInteger)0);
    XCTAssertEqual((NSInteger)LBTransactionKindIncome, (NSInteger)1);

    // enum 可以直接 switch，而且是整數
    LBTransactionKind kind = LBTransactionKindIncome;
    NSString *label = nil;
    switch (kind) {
        case LBTransactionKindExpense: label = @"支出"; break;
        case LBTransactionKindIncome: label = @"收入"; break;
    }
    XCTAssertEqualObjects(label, @"收入");
}

- (void)testFlagsCombine {
    LBTransactionFlags flags = LBTransactionFlagsReconciled | LBTransactionFlagsRecurring;
    XCTAssertEqual((NSUInteger)flags, (NSUInteger)3);
    XCTAssertTrue(flags & LBTransactionFlagsReconciled);
    XCTAssertTrue(flags & LBTransactionFlagsRecurring);

    // 清掉一個旗標
    flags &= ~LBTransactionFlagsRecurring;
    XCTAssertTrue(flags & LBTransactionFlagsReconciled);
    XCTAssertFalse(flags & LBTransactionFlagsRecurring);
    XCTAssertEqual((NSUInteger)LBTransactionFlagsNone, (NSUInteger)0);
}

- (void)testErrorDomainConstant {
    XCTAssertEqualObjects(LBErrorDomain, @"com.littlebook.error");

    NSError *error = [NSError errorWithDomain:LBErrorDomain code:42 userInfo:nil];
    XCTAssertEqualObjects(error.domain, LBErrorDomain);
    XCTAssertEqual(error.code, (NSInteger)42);
}

- (void)testFormatCents {
    XCTAssertEqualObjects(LBFormatCents(128000), @"1,280.00");
    XCTAssertEqualObjects(LBFormatCents(0), @"0.00");
    XCTAssertEqualObjects(LBFormatCents(5), @"0.05");
    XCTAssertEqualObjects(LBFormatCents(100), @"1.00");
    XCTAssertEqualObjects(LBFormatCents(99999), @"999.99");
    XCTAssertEqualObjects(LBFormatCents(100000), @"1,000.00");
    XCTAssertEqualObjects(LBFormatCents(123456789), @"1,234,567.89");
    XCTAssertEqualObjects(LBFormatCents(-5), @"-0.05");
    XCTAssertEqualObjects(LBFormatCents(-128050), @"-1,280.50");
}

@end
