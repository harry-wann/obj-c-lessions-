#import <XCTest/XCTest.h>
#import "LBTransactionListViewController.h"
#import "LBTransactionCell.h"
#import "LBTransactionViewModel.h"
#import "LBLedger.h"
#import "LBUndoStack.h"
#import "LBTransaction.h"
#import "LBCategory.h"
#import "LBMonthSection.h"

@interface LBTransactionListViewControllerTests : XCTestCase
@property (nonatomic, strong) LBLedger *ledger;
@property (nonatomic, strong) LBUndoStack *undoStack;
@property (nonatomic, strong) LBTransactionListViewController *viewController;
@property (nonatomic, strong) UIWindow *window;
@end

@implementation LBTransactionListViewControllerTests

/// 固定時區的日期，避免在不同時區的機器上跨月。
- (NSDate *)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day {
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    components.day = day;
    components.hour = 12;
    return [calendar dateFromComponents:components];
}

- (LBTransaction *)expense:(NSString *)amount note:(NSString *)note date:(NSDate *)date {
    return [[LBTransaction alloc] initWithAmount:[NSDecimalNumber decimalNumberWithString:amount]
                                            kind:LBTransactionKindExpense
                                            date:date
                                            note:note
                                        category:nil];
}

- (void)setUp {
    [super setUp];
    self.ledger = [[LBLedger alloc] init];
    self.undoStack = [[LBUndoStack alloc] init];
    // 11 月 2 筆、10 月 1 筆、9 月 2 筆
    [self.ledger addTransaction:[self expense:@"120" note:@"午餐"
                                         date:[self dateWithYear:2025 month:11 day:5]]];
    [self.ledger addTransaction:[self expense:@"60" note:@"飲料"
                                         date:[self dateWithYear:2025 month:11 day:2]]];
    [self.ledger addTransaction:[self expense:@"300" note:@"電影"
                                         date:[self dateWithYear:2025 month:10 day:20]]];
    [self.ledger addTransaction:[self expense:@"40" note:@"捷運"
                                         date:[self dateWithYear:2025 month:9 day:8]]];
    [self.ledger addTransaction:[self expense:@"80" note:@"早餐"
                                         date:[self dateWithYear:2025 month:9 day:1]]];

    self.viewController = [[LBTransactionListViewController alloc] initWithLedger:self.ledger
                                                                         undoStack:self.undoStack];
    // 放進一個 window 並排版一次，讓 table view 真的載入資料（performBatchUpdates 需要「更新前」的狀態）
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 390, 844)];
    self.window.rootViewController = self.viewController;
    self.window.hidden = NO;
    [self.viewController loadViewIfNeeded];
    [self.viewController.view layoutIfNeeded];
}

- (void)tearDown {
    self.window.hidden = YES;
    self.window = nil;
    self.viewController = nil;
    self.ledger = nil;
    self.undoStack = nil;
    [super tearDown];
}

- (void)testSectionsMatchMonths {
    LBTransactionListViewController *vc = self.viewController;
    NSArray<LBMonthSection *> *expected = [self.ledger transactionsGroupedByMonth];
    XCTAssertEqual(vc.sections.count, (NSUInteger)3);
    XCTAssertEqual(vc.sections.count, expected.count);

    UITableView *tableView = vc.tableView;
    XCTAssertEqual([vc numberOfSectionsInTableView:tableView], (NSInteger)3);
    XCTAssertEqual(tableView.numberOfSections, (NSInteger)3);
    for (NSUInteger i = 0; i < expected.count; i++) {
        XCTAssertEqual(vc.sections[i].year, expected[i].year);
        XCTAssertEqual(vc.sections[i].month, expected[i].month);
        XCTAssertEqual([vc tableView:tableView numberOfRowsInSection:(NSInteger)i],
                       (NSInteger)expected[i].transactions.count);
    }
    // 月份倒序：11 → 10 → 9
    XCTAssertEqual(vc.sections[0].month, (NSInteger)11);
    XCTAssertEqual(vc.sections[1].month, (NSInteger)10);
    XCTAssertEqual(vc.sections[2].month, (NSInteger)9);

    // cell 必須是自訂的 LBTransactionCell，顯示的就是 view model 的字串
    NSIndexPath *first = [NSIndexPath indexPathForRow:0 inSection:0];
    [tableView layoutIfNeeded];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:first];   // 畫面上看得到的列
    XCTAssertNotNil(cell);
    XCTAssertTrue([cell isKindOfClass:[LBTransactionCell class]]);
    LBTransactionViewModel *vm =
        [LBTransactionViewModel viewModelWithTransaction:expected[0].transactions[0]];
    XCTAssertEqualObjects(((LBTransactionCell *)cell).titleLabel.text, vm.title);
    XCTAssertEqualObjects(((LBTransactionCell *)cell).amountLabel.text, vm.amountText);
}

- (void)testCellResetsAllFields {
    LBCategory *food = [[LBCategory alloc] initWithName:@"飲食" symbolName:@"fork.knife"];
    LBTransaction *expense =
        [[LBTransaction alloc] initWithAmount:[NSDecimalNumber decimalNumberWithString:@"1280"]
                                         kind:LBTransactionKindExpense
                                         date:[self dateWithYear:2025 month:11 day:5]
                                         note:@"聚餐"
                                     category:food];
    LBTransaction *income =
        [[LBTransaction alloc] initWithAmount:[NSDecimalNumber decimalNumberWithString:@"50000"]
                                         kind:LBTransactionKindIncome
                                         date:[self dateWithYear:2025 month:11 day:1]
                                         note:@""
                                     category:nil];
    LBTransactionViewModel *expenseVM = [LBTransactionViewModel viewModelWithTransaction:expense];
    LBTransactionViewModel *incomeVM = [LBTransactionViewModel viewModelWithTransaction:income];

    // view model 本身：字串預先算好
    XCTAssertEqualObjects(expenseVM.title, @"聚餐");
    XCTAssertTrue(expenseVM.isExpense);
    XCTAssertTrue([expenseVM.amountText hasPrefix:@"-"]);
    XCTAssertTrue([expenseVM.amountText containsString:@"1,280"]);
    XCTAssertTrue([expenseVM.subtitle containsString:@"飲食"]);
    XCTAssertEqualObjects(expenseVM.symbolName, @"fork.knife");
    XCTAssertEqualObjects(incomeVM.title, @"未分類", @"沒有備註時用分類名");
    XCTAssertFalse(incomeVM.isExpense);
    XCTAssertTrue([incomeVM.amountText hasPrefix:@"+"]);

    LBTransactionCell *cell =
        [[LBTransactionCell alloc] initWithStyle:UITableViewCellStyleDefault
                                 reuseIdentifier:[LBTransactionCell defaultReuseIdentifier]];
    XCTAssertEqualObjects(cell.reuseIdentifier, @"LBTransactionCell");

    [cell configureWithViewModel:expenseVM];
    XCTAssertEqualObjects(cell.titleLabel.text, expenseVM.title);
    XCTAssertEqualObjects(cell.subtitleLabel.text, expenseVM.subtitle);
    XCTAssertEqualObjects(cell.amountLabel.text, expenseVM.amountText);
    XCTAssertEqualObjects(cell.amountLabel.textColor, UIColor.systemRedColor);
    XCTAssertNotNil(cell.iconView.image);

    // 重用：prepareForReuse 之後每個欄位都要清乾淨
    [cell prepareForReuse];
    XCTAssertNil(cell.titleLabel.text);
    XCTAssertNil(cell.subtitleLabel.text);
    XCTAssertNil(cell.amountLabel.text);
    XCTAssertNil(cell.iconView.image);
    XCTAssertNotEqualObjects(cell.amountLabel.textColor, UIColor.systemRedColor,
                             @"上一列的紅字不能殘留");

    // 換成收入：顏色與文字都要跟著換
    [cell configureWithViewModel:incomeVM];
    XCTAssertEqualObjects(cell.titleLabel.text, incomeVM.title);
    XCTAssertEqualObjects(cell.amountLabel.text, incomeVM.amountText);
    XCTAssertEqualObjects(cell.amountLabel.textColor, UIColor.systemGreenColor);
}

- (void)testDeletingLastRowRemovesSection {
    LBTransactionListViewController *vc = self.viewController;
    UITableView *tableView = vc.tableView;
    XCTAssertEqual(tableView.numberOfSections, (NSInteger)3);

    // 10 月只有一筆：刪掉它，section 也要一起消失
    NSIndexPath *october = [NSIndexPath indexPathForRow:0 inSection:1];
    XCTAssertEqual(vc.sections[1].month, (NSInteger)10);
    [vc deleteTransactionAtIndexPath:october];

    XCTAssertEqual(self.ledger.transactions.count, (NSUInteger)4);
    XCTAssertEqual(vc.sections.count, (NSUInteger)2);
    XCTAssertEqual(tableView.numberOfSections, (NSInteger)2, @"table view 的 section 要同步減少");
    XCTAssertEqual(vc.sections[1].month, (NSInteger)9);
    XCTAssertTrue(self.undoStack.canUndo, @"刪除要登記復原");

    // 刪一般列：section 數不變、列數 -1
    [vc deleteTransactionAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    XCTAssertEqual(vc.sections.count, (NSUInteger)2);
    XCTAssertEqual([tableView numberOfRowsInSection:0], (NSInteger)1);

    // 復原兩次：資料與 section 都回來
    [self.undoStack undo];
    [self.undoStack undo];
    [vc reloadFromLedger];
    XCTAssertEqual(self.ledger.transactions.count, (NSUInteger)5);
    XCTAssertEqual(vc.sections.count, (NSUInteger)3);
    XCTAssertEqual(tableView.numberOfSections, (NSInteger)3);

    // 越界的 indexPath 不能 crash
    [vc deleteTransactionAtIndexPath:[NSIndexPath indexPathForRow:99 inSection:99]];
    XCTAssertEqual(self.ledger.transactions.count, (NSUInteger)5);
}

@end
