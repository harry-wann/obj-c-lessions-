#import <XCTest/XCTest.h>
#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBSearchController.h"

// 12.2：App target 產生的 Swift → ObjC 標頭。project.yml 把它所在的 DerivedSources 加進
// 測試 target 的 HEADER_SEARCH_PATHS；萬一 Xcode 版本換了位置找不到，退回 runtime 查類別，
// 測試本身照樣能編、照樣能抓到「Swift 類別沒露給 ObjC」的問題。
#if __has_include("LittleBook-Swift.h")
#import "LittleBook-Swift.h"
#define LB_HAS_SWIFT_HEADER 1
#else
#define LB_HAS_SWIFT_HEADER 0
#endif

/// 12.1 / 12.2：ObjC ↔ Swift 的邊界。
@interface LBBridgingTests : XCTestCase
@end

@implementation LBBridgingTests

- (void)testObjCCanInstantiateSwiftStatsViewController {
    LBLedger *ledger = [[LBLedger alloc] init];
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:@"120"];
    [ledger addTransaction:[LBTransaction expenseWithAmount:amount note:@"午餐"]];

    // @objc(StatsViewController) 讓 runtime 名字沒有模組前綴（LBRouter / Storyboard 都靠它）
    Class statsClass = NSClassFromString(@"StatsViewController");
    XCTAssertNotNil(statsClass, @"Swift 端要加 @objc(StatsViewController)");
    XCTAssertTrue([statsClass isSubclassOfClass:[UIViewController class]]);

#if LB_HAS_SWIFT_HEADER
    StatsViewController *vc = [[StatsViewController alloc] initWithLedger:ledger];
#else
    UIViewController *vc = statsClass != Nil ? [(id)[statsClass alloc] initWithLedger:ledger] : nil;
#endif
    XCTAssertNotNil(vc);
    [vc loadViewIfNeeded];
    XCTAssertNotNil(vc.view);
    XCTAssertEqualObjects(vc.title, @"統計");
}

/// 每個 ObjC 標頭都要包 NS_ASSUME_NONNULL_BEGIN / END，且至少兩處 NS_SWIFT_NAME（12.1）。
/// 執行期讀不到 bundle 裡的原始碼，所以從這個檔案的編譯路徑（__FILE__）往上找專案的 LittleBook/：
/// 模擬器跑測試時看得到 Mac 上的原始碼。實機跑（路徑不存在）就跳過。
/// 只算「程式碼」：// 之後的註解先切掉，免得 TODO 註解裡寫到巨集名就算數。
- (void)testNullabilityAnnotationsPresent {
    NSString *testsDirectory = [@(__FILE__) stringByDeletingLastPathComponent];
    NSString *appDirectory = [[testsDirectory stringByDeletingLastPathComponent]
                              stringByAppendingPathComponent:@"LittleBook"];
    BOOL isDirectory = NO;
    if (![NSFileManager.defaultManager fileExistsAtPath:appDirectory isDirectory:&isDirectory] ||
        !isDirectory) {
        XCTSkip(@"找不到原始碼目錄 %@（實機測試時正常）", appDirectory);
        return;
    }

    NSMutableArray<NSString *> *missing = [NSMutableArray array];
    NSUInteger headerCount = 0;
    NSUInteger swiftNameCount = 0;
    for (NSString *relativePath in [NSFileManager.defaultManager enumeratorAtPath:appDirectory]) {
        if (![relativePath.pathExtension isEqualToString:@"h"] ||
            [relativePath hasSuffix:@"-Bridging-Header.h"]) {
            continue;   // 橋接標頭只有 #import，不宣告任何東西
        }
        NSString *path = [appDirectory stringByAppendingPathComponent:relativePath];
        NSString *text = [NSString stringWithContentsOfFile:path
                                                   encoding:NSUTF8StringEncoding
                                                      error:NULL];
        if (text == nil) {
            [missing addObject:relativePath];
            continue;
        }
        headerCount++;
        BOOL hasBegin = NO;
        BOOL hasEnd = NO;
        for (NSString *rawLine in [text componentsSeparatedByString:@"\n"]) {
            NSString *line = rawLine;
            NSRange comment = [line rangeOfString:@"//" options:0];
            if (comment.location != NSNotFound) {
                line = [line substringToIndex:comment.location];
            }
            hasBegin = hasBegin || [line containsString:@"NS_ASSUME_NONNULL_BEGIN"];
            hasEnd = hasEnd || [line containsString:@"NS_ASSUME_NONNULL_END"];
            swiftNameCount += [line componentsSeparatedByString:@"NS_SWIFT_NAME("].count - 1;
        }
        if (!hasBegin || !hasEnd) {
            [missing addObject:relativePath];
        }
    }

    XCTAssertGreaterThan(headerCount, (NSUInteger)20, @"應該掃到專案裡全部的 .h");
    XCTAssertEqual(missing.count, (NSUInteger)0, @"沒包 NS_ASSUME_NONNULL 的標頭：%@",
                   [missing componentsJoinedByString:@"、"]);
    XCTAssertGreaterThanOrEqual(swiftNameCount, (NSUInteger)2,
                                @"至少兩處 NS_SWIFT_NAME（建議 LBTransaction.Kind 與 init(amount:note:)）");
}

@end
