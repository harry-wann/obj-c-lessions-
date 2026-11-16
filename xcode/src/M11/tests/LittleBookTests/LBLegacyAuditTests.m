#import <XCTest/XCTest.h>

/// 11.1–11.6：LittleBook-Legacy 的六顆雷。這是「誠實制」：測試只讀 LegacyAudit.plist 的勾選，
/// 真正的驗收是 Legacy App 能跑、六個症狀都不再出現（見 LittleBook-Legacy/README.md）。
/// 主線的 LegacyAudit.plist 放在 LittleBookTests/（測試 bundle 的資源）：
/// 修完 Legacy 一顆就把這份對應的 <false/> 改成 <true/>。
@interface LBLegacyAuditTests : XCTestCase
@end

@implementation LBLegacyAuditTests

/// 每顆雷的 key：第一個是 LittleBook-Legacy/LegacyAudit.plist 的寫法（正式名稱），
/// 第二個是練習題 11.1 / 11.6 用的舊寫法；兩種都認，勾哪一個都算。
+ (NSArray<NSArray<NSString *> *> *)lb_checklist {
    return @[
        @[@"fixedOverRelease", @"overReleaseFixed"],                      // 雷 1 MRC over-release
        @[@"fixedSetterLeak", @"setterLeakFixed"],                        // 雷 2 setter 漏 release
        @[@"fixedBrokenOutlet", @"outletReconnected"],                    // 雷 3 IBOutlet 斷線
        @[@"fixedSegueIdentifier", @"segueIdentifierFixed"],              // 雷 4 segue 打錯字
        @[@"addedObjCLinkerFlag", @"objcLinkerFlagAdded"],                // 雷 5 -ObjC
        @[@"cancelsConnectionInDealloc", @"connectionCancelledInDealloc"],  // 雷 6 dealloc 取消
    ];
}

- (void)testLegacyChecklistComplete {
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"LegacyAudit"
                                                          withExtension:@"plist"];
    XCTAssertNotNil(url, @"LegacyAudit.plist 要在 LittleBookTests 的 Copy Bundle Resources 裡");
    if (url == nil) {
        return;
    }
    NSDictionary *audit = [NSDictionary dictionaryWithContentsOfURL:url];
    XCTAssertNotNil(audit, @"LegacyAudit.plist 不是合法的 plist 字典");

    NSMutableArray<NSString *> *pending = [NSMutableArray array];
    for (NSArray<NSString *> *aliases in [LBLegacyAuditTests lb_checklist]) {
        BOOL done = NO;
        for (NSString *key in aliases) {
            id value = audit[key];
            // 只認 <true/>：字串 "YES" 之類的不算（plist 型別防禦，同 9.4）
            if ([value isKindOfClass:[NSNumber class]] && [value boolValue]) {
                done = YES;
            }
        }
        if (!done) {
            [pending addObject:aliases.firstObject];
        }
    }
    XCTAssertEqual(pending.count, (NSUInteger)0, @"還沒勾的雷：%@",
                   [pending componentsJoinedByString:@"、"]);
}

@end
