#import <XCTest/XCTest.h>
#import "LBSettingsViewController.h"
#import "LBPerformanceViewController.h"
#import "LBSettings.h"
#import "LBLedger.h"
#import "LBFPSMonitor.h"

static NSString * const LBStoryboardTestsSuite = @"LBSettingsStoryboardTests";

/// 11.3：設定頁改走 Settings.storyboard。Storyboard 的 Class / Storyboard ID / outlet 名
/// 全是字串，打錯只在執行期爆，所以用測試把它們釘住。
@interface LBSettingsStoryboardTests : XCTestCase
@property (nonatomic, strong) NSUserDefaults *defaults;
@end

@implementation LBSettingsStoryboardTests

- (void)setUp {
    [super setUp];
    self.defaults = [[NSUserDefaults alloc] initWithSuiteName:LBStoryboardTestsSuite];
    [self.defaults removePersistentDomainForName:LBStoryboardTestsSuite];   // 上次殘留的清掉
}

- (void)tearDown {
    [self.defaults removePersistentDomainForName:LBStoryboardTestsSuite];
    self.defaults = nil;
    [super tearDown];
}

/// 測試裡 mainBundle 是 xctest runner，一定要用 bundleForClass: 找 App 的 bundle（11.4 Tip）。
- (UIStoryboard *)lb_storyboard {
    NSBundle *bundle = [NSBundle bundleForClass:[LBSettingsViewController class]];
    return [UIStoryboard storyboardWithName:@"Settings" bundle:bundle];
}

- (void)testStoryboardInstantiatesSettingsViewController {
    UIStoryboard *storyboard = [self lb_storyboard];

    // Storyboard ID「Settings」→ 設定頁本身
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Settings"];
    XCTAssertTrue([vc isKindOfClass:[LBSettingsViewController class]],
                  @"Identity inspector 的 Class 要填 LBSettingsViewController，實際是 %@", vc);

    // initial VC：Embed In → Navigation Controller，SceneDelegate 用 instantiateInitialViewController
    UIViewController *initial = [storyboard instantiateInitialViewController];
    XCTAssertTrue([initial isKindOfClass:[UINavigationController class]],
                  @"設定頁要 Embed In Navigation Controller，並把它設成 Is Initial View Controller");
    UIViewController *root = ((UINavigationController *)initial).topViewController;
    XCTAssertTrue([root isKindOfClass:[LBSettingsViewController class]]);

    // 類別方法包好的版本
    XCTAssertTrue([[LBSettingsViewController instantiateFromStoryboard]
                   isKindOfClass:[LBSettingsViewController class]]);
}

- (void)testOutletsConnectedAfterLoadView {
    LBSettingsViewController *vc =
        [[self lb_storyboard] instantiateViewControllerWithIdentifier:@"Settings"];
    XCTAssertTrue([vc isKindOfClass:[LBSettingsViewController class]]);
    vc.settings = [[LBSettings alloc] initWithUserDefaults:self.defaults];

    XCTAssertNil(vc.currencyLabel, @"view 還沒載入：outlet 一定是 nil");
    [vc loadViewIfNeeded];                 // 觸發 viewDidLoad，outlet 才有值
    XCTAssertNotNil(vc.currencyLabel);
    XCTAssertNotNil(vc.centsSwitch);
    XCTAssertNotNil(vc.appearanceLabel);

    // viewDidLoad 從 LBSettings 讀值填 outlet（全新的 suite = 預設值）
    XCTAssertEqualObjects(vc.currencyLabel.text, @"TWD");
    XCTAssertTrue(vc.centsSwitch.isOn);
    XCTAssertEqualObjects(vc.appearanceLabel.text, @"跟隨系統");

    // IBAction：切 Switch 後 LBSettings.showsCents 跟著變
    vc.centsSwitch.on = NO;
    [vc centsSwitchChanged:vc.centsSwitch];
    XCTAssertFalse(vc.settings.showsCents);
}

/// 補充：prepareForSegue: 把相依性帶給效能頁（目的地包在 nav 裡也要拿得到）。
- (void)testPrepareForSegueInjectsLedgerAndMonitor {
    LBSettingsViewController *vc =
        [[self lb_storyboard] instantiateViewControllerWithIdentifier:@"Settings"];
    LBLedger *ledger = [[LBLedger alloc] init];
    vc.settings = [[LBSettings alloc] initWithUserDefaults:self.defaults];
    vc.ledger = ledger;

    LBPerformanceViewController *performance =
        [[LBPerformanceViewController alloc] initWithLedger:[[LBLedger alloc] init]];
    UINavigationController *wrapped =
        [[UINavigationController alloc] initWithRootViewController:performance];
    UIStoryboardSegue *segue =
        [UIStoryboardSegue segueWithIdentifier:@"showPerformance"
                                        source:vc
                                   destination:wrapped
                                performHandler:^{}];
    [vc prepareForSegue:segue sender:nil];
    XCTAssertEqual(performance.ledger, ledger, @"要往下拿 topViewController 再注入");
    XCTAssertEqual(performance.monitor, [LBFPSMonitor shared]);
}

@end
