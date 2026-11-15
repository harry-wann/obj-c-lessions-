#import <XCTest/XCTest.h>
#import "NSArray+LBFunctional.h"

@interface LBFunctionalTests : XCTestCase
@end

@implementation LBFunctionalTests

- (void)testMap {
    NSArray<NSNumber *> *numbers = @[@1, @2, @3];
    NSArray *doubled = [numbers lb_map:^id(NSNumber *number) {
        return @(number.integerValue * 2);
    }];
    XCTAssertEqualObjects(doubled, (@[@2, @4, @6]));

    NSArray *strings = [numbers lb_map:^id(NSNumber *number) {
        return [NSString stringWithFormat:@"#%@", number];
    }];
    XCTAssertEqualObjects(strings, (@[@"#1", @"#2", @"#3"]));
    XCTAssertEqualObjects(([@[] lb_map:^id(id object) { return object; }]), @[]);
}

- (void)testFilter {
    NSArray<NSNumber *> *numbers = @[@1, @2, @3, @4, @5, @6];
    NSArray<NSNumber *> *evens = [numbers lb_filter:^BOOL(NSNumber *number) {
        return number.integerValue % 2 == 0;
    }];
    XCTAssertEqualObjects(evens, (@[@2, @4, @6]));

    NSArray<NSNumber *> *none = [numbers lb_filter:^BOOL(NSNumber *number) {
        return number.integerValue > 100;
    }];
    XCTAssertEqualObjects(none, @[]);
    XCTAssertEqual(numbers.count, (NSUInteger)6, @"原陣列不變");
}

- (void)testReduce {
    NSArray<NSNumber *> *numbers = @[@1, @2, @3, @4];
    NSNumber *sum = [numbers lb_reduce:^id(NSNumber *accumulator, NSNumber *number) {
        return @(accumulator.integerValue + number.integerValue);
    } initial:@0];
    XCTAssertEqualObjects(sum, @10);

    NSArray<NSString *> *words = @[@"小", @"帳", @"本"];
    NSString *joined = [words lb_reduce:^id(NSString *accumulator, NSString *word) {
        return [accumulator stringByAppendingString:word];
    } initial:@""];
    XCTAssertEqualObjects(joined, @"小帳本");

    // 金額加總用 NSDecimalNumber
    NSArray<NSDecimalNumber *> *amounts = @[[NSDecimalNumber decimalNumberWithString:@"0.1"],
                                            [NSDecimalNumber decimalNumberWithString:@"0.2"]];
    NSDecimalNumber *total = [amounts lb_reduce:^id(NSDecimalNumber *acc, NSDecimalNumber *amount) {
        return [acc decimalNumberByAdding:amount];
    } initial:NSDecimalNumber.zero];
    XCTAssertEqualObjects(total, [NSDecimalNumber decimalNumberWithString:@"0.3"]);

    id untouched = [@[] lb_reduce:^id(id acc, id object) { return object; } initial:@"初始值"];
    XCTAssertEqualObjects(untouched, @"初始值");
}

@end
