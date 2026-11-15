@import UIKit;
#import <XCTest/XCTest.h>
#import "LBRouter.h"
#import "LBLedger.h"

@interface LBRouterTests : XCTestCase
@end

@implementation LBRouterTests

- (void)tearDown {
    [LBRouter removeAllAliases];
    [super tearDown];
}

- (void)testRouteCreatesViewControllerByName {
    UIViewController *vc = [LBRouter viewControllerForName:@"UITableViewController"];
    XCTAssertNotNil(vc);
    XCTAssertTrue([vc isKindOfClass:[UITableViewController class]]);

    // 別名：舊專案常把 URL 的 host 對應到類別名
    [LBRouter registerAlias:@"nav" forClassName:@"UINavigationController"];
    UIViewController *nav = [LBRouter viewControllerForName:@"nav"];
    XCTAssertTrue([nav isKindOfClass:[UINavigationController class]]);

    // 每次都是新的實例
    XCTAssertNotEqual(vc, [LBRouter viewControllerForName:@"UITableViewController"]);
}

- (void)testUnknownRouteReturnsNil {
    XCTAssertNil([LBRouter viewControllerForName:@"LBNoSuchViewController"]);
    XCTAssertNil([LBRouter viewControllerForName:@""]);
    // 別名指到不存在的類別也要回 nil，不能 crash
    [LBRouter registerAlias:@"ghost" forClassName:@"LBGhostViewController"];
    XCTAssertNil([LBRouter viewControllerForName:@"ghost"]);
}

- (void)testRouteRejectsNonViewControllerClass {
    // 類別存在，但不是 UIViewController 子類別：必須回 nil，而不是回一個沒有 view 的物件
    XCTAssertNil([LBRouter viewControllerForName:@"NSObject"]);
    XCTAssertNil([LBRouter viewControllerForName:NSStringFromClass([LBLedger class])]);
    XCTAssertNil([LBRouter viewControllerForName:@"UIView"]);
}

@end
