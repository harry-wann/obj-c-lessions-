#import <XCTest/XCTest.h>
#import "LBPollingService.h"
#import "LBReportBuilder.h"
#import "LBRateFetcher.h"

/// 模擬「持有 builder 並擔任它 delegate 的物件」（實務上通常是 ViewController）。
@interface LBTestReportOwner : NSObject <LBReportBuilderDelegate>
@property (nonatomic, strong, readonly) LBReportBuilder *builder;
@property (nonatomic, copy, nullable) NSString *lastReport;
@end

@implementation LBTestReportOwner

- (instancetype)init {
    if ((self = [super init])) {
        _builder = [[LBReportBuilder alloc] init];
        _builder.delegate = self;
    }
    return self;
}

- (void)reportBuilder:(LBReportBuilder *)builder didBuildReport:(NSString *)report {
    self.lastReport = report;
}

@end

/// 洩漏測試的樣板：建立 → 弱參考 → 離開 autoreleasepool → 弱參考應為 nil。
@interface LBLeakTests : XCTestCase
@end

@implementation LBLeakTests

- (void)testTimerTargetReleased {
    __weak LBPollingService *weakService = nil;
    @autoreleasepool {
        LBPollingService *service = [[LBPollingService alloc] init];
        [service start];
        XCTAssertTrue(service.isRunning);
        weakService = service;
    }
    XCTAssertNil(weakService, @"NSTimer 不該強持有 service；改用 block 版 timer + weakSelf");
}

- (void)testDelegateDoesNotRetain {
    __weak LBTestReportOwner *weakOwner = nil;
    __weak LBReportBuilder *weakBuilder = nil;
    @autoreleasepool {
        LBTestReportOwner *owner = [[LBTestReportOwner alloc] init];
        [owner.builder build];
        XCTAssertNotNil(owner.lastReport, @"delegate 方法應該被呼叫");
        weakOwner = owner;
        weakBuilder = owner.builder;
    }
    XCTAssertNil(weakOwner, @"delegate 應為 weak，否則 owner ↔ builder 互相持有");
    XCTAssertNil(weakBuilder);
}

- (void)testBlockDoesNotRetainSelf {
    __weak LBRateFetcher *weakFetcher = nil;
    @autoreleasepool {
        LBRateFetcher *fetcher = [[LBRateFetcher alloc] initWithCurrencyCode:@"USD"];
        __block NSDecimalNumber *received = nil;
        [fetcher fetchWithCompletion:^(NSDecimalNumber *rate) {
            received = rate;
        }];
        XCTAssertNotNil(received, @"completion 應該被呼叫");
        XCTAssertEqualObjects(fetcher.lastRate, received);
        weakFetcher = fetcher;
    }
    XCTAssertNil(weakFetcher, @"block 捕獲 self 又被 self 持有會形成循環參考；用 weakSelf");
}

@end
