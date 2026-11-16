#import <XCTest/XCTest.h>
#import "NSDecimalNumber+LBFormatting.h"

@interface LBFormattingTests : XCTestCase
@end

@implementation LBFormattingTests

- (NSString *)format:(NSString *)decimalString {
    return [[NSDecimalNumber decimalNumberWithString:decimalString] lb_currencyString];
}

- (void)testCurrencyString {
    XCTAssertEqualObjects([self format:@"1280"], @"1,280.00");
    XCTAssertEqualObjects([self format:@"1280.5"], @"1,280.50");
    XCTAssertEqualObjects([self format:@"-1280.5"], @"-1,280.50");
    XCTAssertEqualObjects([self format:@"0"], @"0.00");
    XCTAssertEqualObjects([self format:@"0.05"], @"0.05");
    XCTAssertEqualObjects([self format:@"999"], @"999.00");
    XCTAssertEqualObjects([self format:@"1234567.891"], @"1,234,567.89", @"保留到分");
    XCTAssertEqualObjects([self format:@"2.005"], @"2.01", @"四捨五入");
    XCTAssertEqualObjects([NSDecimalNumber.zero lb_currencyString], @"0.00");
}

@end
