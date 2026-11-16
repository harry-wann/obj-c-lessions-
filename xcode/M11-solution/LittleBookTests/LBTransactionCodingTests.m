#import <XCTest/XCTest.h>
#import "LBTransaction.h"
#import "LBCategory.h"
#import "LBCategory+LBPath.h"
#import "LBTypes.h"

@interface LBTransactionCodingTests : XCTestCase
@end

@implementation LBTransactionCodingTests

/// defaultTree 裡的「飲食/午餐」：存檔只存路徑，讀回來要找回同一個節點。
- (LBCategory *)lunch {
    LBCategory *lunch = [LBCategory lb_categoryWithPath:@"飲食/午餐"];
    XCTAssertNotNil(lunch);
    return lunch;
}

- (LBTransaction *)sampleTransaction {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1762300800];   // 整數秒
    return [[LBTransaction alloc] initWithAmount:[NSDecimalNumber decimalNumberWithString:@"1280.5"]
                                            kind:LBTransactionKindExpense
                                            date:date
                                            note:@"聚餐"
                                        category:[self lunch]
                                           flags:LBTransactionFlagsReconciled];
}

- (void)testDictionaryRoundTrip {
    LBTransaction *original = [self sampleTransaction];
    NSDictionary<NSString *, id> *dict = [original dictionaryRepresentation];

    // 只能有 JSON 型別：丟得進 NSJSONSerialization
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:dict]);
    XCTAssertEqualObjects(dict[LBTransactionKeyIdentifier], original.identifier.UUIDString);
    XCTAssertEqualObjects(dict[LBTransactionKeyCategory], @"飲食/午餐");

    NSError *error = nil;
    LBTransaction *restored = [[LBTransaction alloc] initWithDictionary:dict error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(restored, original, @"identifier 也要一起還原，才會 isEqual:");
    XCTAssertEqual(restored.category, original.category, @"分類要找回 defaultTree 裡的同一個節點");
    XCTAssertEqual(restored.flags, LBTransactionFlagsReconciled);

    // 沒有分類：不放 key，讀回來是 nil
    NSDecimalNumber *sixty = [NSDecimalNumber decimalNumberWithString:@"60"];
    LBTransaction *plain = [LBTransaction expenseWithAmount:sixty note:@""];
    NSDictionary *plainDict = [plain dictionaryRepresentation];
    XCTAssertNil(plainDict[LBTransactionKeyCategory]);
    LBTransaction *plainBack = [[LBTransaction alloc] initWithDictionary:plainDict error:NULL];
    XCTAssertNotNil(plainBack);
    XCTAssertNil(plainBack.category);

    // 防禦：NSNull、型別錯、缺欄位
    NSMutableDictionary *bad = [dict mutableCopy];
    bad[LBTransactionKeyAmount] = [NSNull null];
    error = nil;
    XCTAssertNil([[LBTransaction alloc] initWithDictionary:bad error:&error]);
    XCTAssertEqualObjects(error.domain, LBErrorDomain);
    XCTAssertEqual(error.code, (NSInteger)LBErrorCodeUnexpectedType);

    bad = [dict mutableCopy];
    bad[LBTransactionKeyDate] = @"昨天";
    error = nil;
    XCTAssertNil([[LBTransaction alloc] initWithDictionary:bad error:&error]);
    XCTAssertEqual(error.code, (NSInteger)LBErrorCodeUnexpectedType);

    bad = [dict mutableCopy];
    bad[LBTransactionKeyKind] = @7;
    XCTAssertNil([[LBTransaction alloc] initWithDictionary:bad error:NULL],
                 @"error 傳 NULL 不能 crash");

    bad = [dict mutableCopy];
    [bad removeObjectForKey:LBTransactionKeyIdentifier];
    XCTAssertNil([[LBTransaction alloc] initWithDictionary:bad error:NULL]);

    bad = [dict mutableCopy];
    bad[LBTransactionKeyAmount] = @"abc";
    XCTAssertNil([[LBTransaction alloc] initWithDictionary:bad error:NULL]);

    // 選填欄位是 NSNull：用預設值，不算錯
    NSMutableDictionary *lenient = [dict mutableCopy];
    lenient[LBTransactionKeyNote] = [NSNull null];
    lenient[LBTransactionKeyFlags] = [NSNull null];
    lenient[LBTransactionKeyCategory] = [NSNull null];
    error = nil;
    LBTransaction *lenientBack = [[LBTransaction alloc] initWithDictionary:lenient error:&error];
    XCTAssertNotNil(lenientBack);
    XCTAssertNil(error);
    XCTAssertEqualObjects(lenientBack.note, @"");
    XCTAssertEqual(lenientBack.flags, LBTransactionFlagsNone);
    XCTAssertNil(lenientBack.category);
}

- (void)testSecureCodingRoundTrip {
    XCTAssertTrue([LBTransaction supportsSecureCoding]);
    LBTransaction *original = [self sampleTransaction];

    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:original
                                         requiringSecureCoding:YES
                                                         error:&error];
    XCTAssertNotNil(data);
    XCTAssertNil(error);

    LBTransaction *restored = [NSKeyedUnarchiver unarchivedObjectOfClass:[LBTransaction class]
                                                                fromData:data
                                                                   error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([restored isKindOfClass:[LBTransaction class]]);
    XCTAssertEqualObjects(restored, original);
    XCTAssertEqualObjects(restored.amount, [NSDecimalNumber decimalNumberWithString:@"1280.5"]);
    XCTAssertEqual(restored.category, [self lunch]);

    // 陣列也可以：允許的類別要列出容器與元素
    NSArray *list = @[original, [self sampleTransaction]];
    NSData *listData = [NSKeyedArchiver archivedDataWithRootObject:list
                                             requiringSecureCoding:YES
                                                             error:&error];
    XCTAssertNotNil(listData);
    NSSet *classes = [NSSet setWithObjects:[NSArray class], [LBTransaction class], nil];
    NSArray *listBack = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes
                                                            fromData:listData
                                                               error:&error];
    XCTAssertEqualObjects(listBack, list);
}

@end
