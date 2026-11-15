#import <XCTest/XCTest.h>
#import "LBRateService.h"
#import "LBStubURLProtocol.h"

static NSString * const LBTestBaseURL = @"https://stub.littlebook.test/api";
static NSString * const LBTestLatestPath = @"/api/latest";

@interface LBRateServiceTests : XCTestCase
@property (nonatomic, strong) LBRateService *service;
@end

@implementation LBRateServiceTests

- (void)setUp {
    [super setUp];
    [LBStubURLProtocol removeAllStubs];
    self.service = [[LBRateService alloc] initWithSession:[LBStubURLProtocol stubbedSession]
                                                  baseURL:[NSURL URLWithString:LBTestBaseURL]];
}

- (void)tearDown {
    [LBStubURLProtocol removeAllStubs];
    self.service = nil;
    [super tearDown];
}

- (NSData *)dataFromString:(NSString *)string {
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)testParsesRatesFromStubJSON {
    [LBStubURLProtocol stubPath:LBTestLatestPath
                     statusCode:200
                     JSONObject:@{@"base": @"USD",
                                  @"rates": @{@"TWD": @32.15, @"JPY": @149.5, @"EUR": [NSNull null]}}];

    XCTestExpectation *done = [self expectationWithDescription:@"fetch"];
    [self.service fetchRatesForBase:@"USD"
                         completion:^(NSDictionary<NSString *, NSDecimalNumber *> *rates,
                                      NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(rates);
        XCTAssertEqual(rates.count, (NSUInteger)2, @"NSNull 的幣別要跳過");
        XCTAssertEqualWithAccuracy(rates[@"TWD"].doubleValue, 32.15, 0.0001);
        XCTAssertEqualWithAccuracy(rates[@"JPY"].doubleValue, 149.5, 0.0001);
        XCTAssertNil(rates[@"EUR"]);
        XCTAssertTrue([rates[@"TWD"] isKindOfClass:[NSDecimalNumber class]]);
        [done fulfill];
    }];
    [self waitForExpectations:@[done] timeout:2.0];
}

- (void)testReportsErrorOnMalformedJSON {
    // 純解析：壞 JSON
    NSError *error = nil;
    NSDictionary *rates = [LBRateService ratesFromJSONData:[self dataFromString:@"{not json"]
                                                     error:&error];
    XCTAssertNil(rates);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, LBErrorDomain);
    XCTAssertEqual(error.code, (NSInteger)LBErrorCodeMalformedJSON);

    // 結構不對：root 是陣列、或缺 rates
    error = nil;
    XCTAssertNil([LBRateService ratesFromJSONData:[self dataFromString:@"[1, 2, 3]"] error:&error]);
    XCTAssertEqual(error.code, (NSInteger)LBErrorCodeMalformedJSON);
    error = nil;
    XCTAssertNil([LBRateService ratesFromJSONData:[self dataFromString:@"{\"base\":\"USD\"}"]
                                            error:&error]);
    XCTAssertEqual(error.code, (NSInteger)LBErrorCodeMalformedJSON);

    // error 傳 NULL 也不能 crash
    XCTAssertNil([LBRateService ratesFromJSONData:[self dataFromString:@"oops"] error:NULL]);

    // 走網路（stub）：伺服器回 200 但 body 壞掉，錯誤要一路傳到 completion
    [LBStubURLProtocol stubPath:LBTestLatestPath
                     statusCode:200
                           data:[self dataFromString:@"<html>not json</html>"]];
    XCTestExpectation *done = [self expectationWithDescription:@"fetch malformed"];
    [self.service fetchRatesForBase:@"USD"
                         completion:^(NSDictionary<NSString *, NSDecimalNumber *> *rates,
                                      NSError *fetchError) {
        XCTAssertNil(rates);
        XCTAssertEqualObjects(fetchError.domain, LBErrorDomain);
        XCTAssertEqual(fetchError.code, (NSInteger)LBErrorCodeMalformedJSON);
        [done fulfill];
    }];
    [self waitForExpectations:@[done] timeout:2.0];
}

- (void)testReportsErrorWhenRateIsNotNumber {
    NSString *json = @"{\"base\":\"USD\",\"rates\":{\"TWD\":32.15,\"JPY\":\"abc\"}}";
    NSError *error = nil;
    NSDictionary *rates = [LBRateService ratesFromJSONData:[self dataFromString:json] error:&error];
    XCTAssertNil(rates, @"任何一個欄位型別不對就整批失敗");
    XCTAssertEqualObjects(error.domain, LBErrorDomain);
    XCTAssertEqual(error.code, (NSInteger)LBErrorCodeUnexpectedType);
    XCTAssertTrue([error.localizedDescription containsString:@"JPY"], @"錯誤訊息要指出是哪個欄位");

    // 布林、陣列、物件都不是數字
    error = nil;
    NSString *boolJSON = @"{\"rates\":{\"TWD\":true}}";
    XCTAssertNil([LBRateService ratesFromJSONData:[self dataFromString:boolJSON] error:&error]);
    XCTAssertEqual(error.code, (NSInteger)LBErrorCodeUnexpectedType);
    error = nil;
    NSString *arrayJSON = @"{\"rates\":{\"TWD\":[32.15]}}";
    XCTAssertNil([LBRateService ratesFromJSONData:[self dataFromString:arrayJSON] error:&error]);
    XCTAssertEqual(error.code, (NSInteger)LBErrorCodeUnexpectedType);

    // 數字字串是常見的「後端偷懶」，防禦性地接受
    error = nil;
    NSString *stringJSON = @"{\"rates\":{\"TWD\":\"32.15\"}}";
    NSDictionary *lenient = [LBRateService ratesFromJSONData:[self dataFromString:stringJSON]
                                                       error:&error];
    XCTAssertNil(error);
    XCTAssertEqualWithAccuracy([lenient[@"TWD"] doubleValue], 32.15, 0.0001);
}

- (void)testCompletionCalledOnMainQueue {
    [LBStubURLProtocol stubPath:LBTestLatestPath
                     statusCode:200
                     JSONObject:@{@"base": @"USD", @"rates": @{@"TWD": @32.15}}];
    XCTestExpectation *success = [self expectationWithDescription:@"success on main"];
    [self.service fetchRatesForBase:@"USD"
                         completion:^(NSDictionary<NSString *, NSDecimalNumber *> *rates,
                                      NSError *error) {
        XCTAssertTrue(NSThread.isMainThread, @"NSURLSession 回呼在背景，service 必須切回主佇列");
        XCTAssertNotNil(rates);
        [success fulfill];
    }];
    [self waitForExpectations:@[success] timeout:2.0];

    // 失敗路徑（HTTP 500）也要在主佇列，而且 NSURLSession 不會自動把 500 當錯誤，要自己判
    [LBStubURLProtocol stubPath:LBTestLatestPath
                     statusCode:500
                     JSONObject:@{@"error": @"boom"}];
    XCTestExpectation *failure = [self expectationWithDescription:@"failure on main"];
    [self.service fetchRatesForBase:@"USD"
                         completion:^(NSDictionary<NSString *, NSDecimalNumber *> *rates,
                                      NSError *error) {
        XCTAssertTrue(NSThread.isMainThread);
        XCTAssertNil(rates);
        XCTAssertEqualObjects(error.domain, LBErrorDomain);
        XCTAssertEqual(error.code, (NSInteger)LBErrorCodeHTTPStatus);
        XCTAssertEqualObjects(error.userInfo[LBRateServiceHTTPStatusCodeKey], @500);
        [failure fulfill];
    }];
    [self waitForExpectations:@[failure] timeout:2.0];
}

@end
