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
                                  @"rates": @{@"TWD": @32.15, @"JPY": @149.5,
                                               @"EUR": [NSNull null]}}];

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

- (void)testConcurrentFetchLimitedBySemaphore {
    [LBStubURLProtocol stubPath:LBTestLatestPath
                     statusCode:200
                     JSONObject:@{@"base": @"USD", @"rates": @{@"TWD": @32.15}}];
    [LBStubURLProtocol setResponseDelay:0.1];   // 每個請求 100 ms，才看得出同時有幾個在飛
    [LBStubURLProtocol resetConcurrencyStats];

    NSArray<NSString *> *bases = @[@"USD", @"EUR", @"JPY", @"GBP", @"CNY", @"KRW", @"HKD", @"SGD"];
    NSTimeInterval start = NSProcessInfo.processInfo.systemUptime;
    XCTestExpectation *done = [self expectationWithDescription:@"all fetched"];
    [self.service fetchRatesForBases:bases
                       maxConcurrent:2
                          completion:^(NSDictionary<NSString *, NSDictionary *> *results,
                                       NSArray<NSError *> *errors) {
        XCTAssertTrue(NSThread.isMainThread, @"聚合後的回呼要在主佇列");
        XCTAssertEqual(results.count, bases.count);
        XCTAssertEqual(errors.count, (NSUInteger)0);
        XCTAssertEqualWithAccuracy([results[@"JPY"][@"TWD"] doubleValue], 32.15, 0.0001);
        [done fulfill];
    }];
    [self waitForExpectations:@[done] timeout:5.0];
    NSTimeInterval elapsed = NSProcessInfo.processInfo.systemUptime - start;

    XCTAssertEqual([LBStubURLProtocol totalRequests], bases.count);
    XCTAssertLessThanOrEqual([LBStubURLProtocol maxConcurrentRequests], (NSUInteger)2,
                             @"semaphore 限流 2：同時在飛的請求不能超過 2 個");
    XCTAssertGreaterThanOrEqual([LBStubURLProtocol maxConcurrentRequests], (NSUInteger)1);
    // 8 個、一次 2 個、每個 0.1 秒 → 至少約 0.4 秒；完全沒並行則要 0.8 秒
    XCTAssertGreaterThan(elapsed, 0.3, @"有限流就不可能全部同時完成");

    // 失敗也要聚合：伺服器回 500 → 每個 base 一個 error
    [LBStubURLProtocol setResponseDelay:0];
    [LBStubURLProtocol stubPath:LBTestLatestPath statusCode:500 JSONObject:@{@"error": @"boom"}];
    XCTestExpectation *failed = [self expectationWithDescription:@"all failed"];
    [self.service fetchRatesForBases:@[@"USD", @"EUR", @"JPY"]
                       maxConcurrent:0   // 0 當 1，不能卡死
                          completion:^(NSDictionary<NSString *, NSDictionary *> *results,
                                       NSArray<NSError *> *errors) {
        XCTAssertEqual(results.count, (NSUInteger)0);
        XCTAssertEqual(errors.count, (NSUInteger)3);
        XCTAssertEqual(errors.firstObject.code, (NSInteger)LBErrorCodeHTTPStatus);
        [failed fulfill];
    }];
    [self waitForExpectations:@[failed] timeout:5.0];

    // 空陣列：直接回空結果
    XCTestExpectation *empty = [self expectationWithDescription:@"empty"];
    [self.service fetchRatesForBases:@[]
                       maxConcurrent:4
                          completion:^(NSDictionary<NSString *, NSDictionary *> *results,
                                       NSArray<NSError *> *errors) {
        XCTAssertEqual(results.count + errors.count, (NSUInteger)0);
        [empty fulfill];
    }];
    [self waitForExpectations:@[empty] timeout:2.0];
}

@end
