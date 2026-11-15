#import <XCTest/XCTest.h>
#import "LBCategoryPickerViewController.h"
#import "LBCategory.h"

@interface LBCategoryPickerViewControllerTests : XCTestCase
@end

@implementation LBCategoryPickerViewControllerTests

- (nullable LBCategory *)rootNamed:(NSString *)name in:(NSArray<LBCategory *> *)roots {
    for (LBCategory *root in roots) {
        if ([root.name isEqualToString:name]) {
            return root;
        }
    }
    return nil;
}

- (void)testRowsRespectExpansion {
    NSArray<LBCategory *> *roots = [LBCategory defaultTree];
    XCTAssertEqual(roots.count, (NSUInteger)5, @"飲食 / 交通 / 居住 / 娛樂 / 收入");
    XCTAssertEqual(roots, [LBCategory defaultTree], @"defaultTree 只建一次，回同一個陣列");
    LBCategory *food = [self rootNamed:@"飲食" in:roots];
    LBCategory *transport = [self rootNamed:@"交通" in:roots];
    XCTAssertNotNil(food);
    XCTAssertNotNil(transport);
    XCTAssertEqual(food.children.count, (NSUInteger)4);

    LBCategoryPickerViewController *picker =
        [[LBCategoryPickerViewController alloc] initWithRootCategories:roots selected:nil];
    // 一開始全部收合：只看得到根節點
    XCTAssertEqualObjects(picker.visibleRows, roots);

    // 展開飲食：子分類緊接在後面，深度優先
    [picker toggleExpansionOf:food];
    XCTAssertEqual(picker.visibleRows.count, roots.count + food.children.count);
    XCTAssertEqual(picker.visibleRows[0], food);
    for (NSUInteger i = 0; i < food.children.count; i++) {
        XCTAssertEqual(picker.visibleRows[1 + i], food.children[i]);
        XCTAssertEqual(picker.visibleRows[1 + i].depth, (NSUInteger)1);
    }
    XCTAssertEqual(picker.visibleRows[1 + food.children.count], transport);

    // 再展開交通：兩個都展開
    [picker toggleExpansionOf:transport];
    XCTAssertEqual(picker.visibleRows.count,
                   roots.count + food.children.count + transport.children.count);

    // 葉節點沒有子分類：toggle 什麼都不做
    NSUInteger before = picker.visibleRows.count;
    [picker toggleExpansionOf:food.children.firstObject];
    XCTAssertEqual(picker.visibleRows.count, before);

    // 收合飲食：它的子分類消失，交通的還在
    [picker toggleExpansionOf:food];
    XCTAssertEqual(picker.visibleRows.count, roots.count + transport.children.count);
    XCTAssertFalse([picker.visibleRows containsObject:food.children.firstObject]);

    // view 載入後 toggle 走 insert / delete rows，table 的列數要和 visibleRows 一致
    [picker loadViewIfNeeded];
    picker.view.frame = CGRectMake(0, 0, 390, 844);
    [picker.tableView reloadData];
    [picker.tableView layoutIfNeeded];
    [picker toggleExpansionOf:food];
    XCTAssertEqual([picker.tableView numberOfRowsInSection:0], (NSInteger)picker.visibleRows.count);

    // 已選的分類：祖先一進來就展開
    LBCategory *lunch = food.children[1];
    LBCategoryPickerViewController *preselected =
        [[LBCategoryPickerViewController alloc] initWithRootCategories:roots selected:lunch];
    XCTAssertTrue([preselected.visibleRows containsObject:lunch]);
    XCTAssertEqual(preselected.selectedCategory, lunch);
}

@end
