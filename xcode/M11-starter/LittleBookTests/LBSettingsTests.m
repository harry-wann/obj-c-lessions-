#import <XCTest/XCTest.h>
#import "LBSettings.h"

static NSString * const LBTestSuiteName = @"com.littlebook.tests.settings";

@interface LBSettingsTests : XCTestCase
@property (nonatomic, strong) NSUserDefaults *defaults;
@end

@implementation LBSettingsTests

- (void)setUp {
    [super setUp];
    // 測試用獨立的 suite：不碰 standardUserDefaults，也不受上一次測試殘留影響
    [[[NSUserDefaults alloc] initWithSuiteName:LBTestSuiteName]
        removePersistentDomainForName:LBTestSuiteName];
    self.defaults = [[NSUserDefaults alloc] initWithSuiteName:LBTestSuiteName];
}

- (void)tearDown {
    [self.defaults removePersistentDomainForName:LBTestSuiteName];
    self.defaults = nil;
    [super tearDown];
}

- (void)testDefaultsRegistered {
    LBSettings *settings = [[LBSettings alloc] initWithUserDefaults:self.defaults];
    XCTAssertEqualObjects(settings.currencyCode, @"TWD");
    XCTAssertTrue(settings.showsCents);
    XCTAssertEqual(settings.appearance, (NSInteger)LBAppearanceSystem);

    // registerDefaults: 不寫進持久網域：「沒設定過」時持久網域裡沒有這個 key
    NSDictionary *persistent = [self.defaults persistentDomainForName:LBTestSuiteName];
    XCTAssertNil(persistent[LBSettingsCurrencyCodeKey]);
    XCTAssertEqualObjects([self.defaults stringForKey:LBSettingsCurrencyCodeKey], @"TWD");

    XCTAssertTrue([[LBSettings supportedCurrencyCodes] containsObject:@"TWD"]);
    XCTAssertEqual([LBSettings shared], [LBSettings shared], @"shared 是單例");
}

- (void)testCurrencyCodePersists {
    LBSettings *settings = [[LBSettings alloc] initWithUserDefaults:self.defaults];
    XCTestExpectation *notified = [self expectationForNotification:LBSettingsDidChangeNotification
                                                            object:settings
                                                           handler:nil];
    settings.currencyCode = @"USD";
    settings.showsCents = NO;
    settings.appearance = LBAppearanceDark;
    [self waitForExpectations:@[notified] timeout:1.0];

    // 另一個實例（模擬重開 App）讀同一個 suite：值還在
    NSUserDefaults *reopened = [[NSUserDefaults alloc] initWithSuiteName:LBTestSuiteName];
    LBSettings *again = [[LBSettings alloc] initWithUserDefaults:reopened];
    XCTAssertEqualObjects(again.currencyCode, @"USD");
    XCTAssertFalse(again.showsCents, @"存成 NO 不能被預設值 YES 蓋掉");
    XCTAssertEqual(again.appearance, (NSInteger)LBAppearanceDark);
    XCTAssertEqualObjects([reopened stringForKey:LBSettingsCurrencyCodeKey], @"USD");

    // 超出範圍的外觀值當成跟隨系統
    [reopened setInteger:42 forKey:LBSettingsAppearanceKey];
    XCTAssertEqual(again.appearance, (NSInteger)LBAppearanceSystem);
}

@end
