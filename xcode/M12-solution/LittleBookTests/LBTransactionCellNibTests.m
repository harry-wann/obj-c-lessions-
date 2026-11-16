#import <XCTest/XCTest.h>
#import "LBTransactionCell.h"
#import "LBTransactionViewModel.h"
#import "LBTransaction.h"

/// 11.4：LBTransactionCell 的 XIB 版。outlet 從 File's Owner 拖錯時，這裡會直接看到 nil。
@interface LBTransactionCellNibTests : XCTestCase
@end

@implementation LBTransactionCellNibTests

- (UINib *)lb_nib {
    // nil bundle = mainBundle，在測試裡是 xctest runner → Could not load NIB
    return [UINib nibWithNibName:@"LBTransactionCell"
                          bundle:[NSBundle bundleForClass:[LBTransactionCell class]]];
}

- (void)testNibLoadsCellWithOutlets {
    NSArray *objects = [[self lb_nib] instantiateWithOwner:nil options:nil];
    XCTAssertEqual(objects.count, (NSUInteger)1, @"XIB 只能有一個頂層物件（那個 cell）");

    LBTransactionCell *cell = objects.firstObject;
    XCTAssertTrue([cell isKindOfClass:[LBTransactionCell class]],
                  @"cell 的 Class 要設成 LBTransactionCell（設在 cell 上，不是 File's Owner）");
    XCTAssertEqualObjects(cell.reuseIdentifier, [LBTransactionCell defaultReuseIdentifier],
                          @"XIB 裡 cell 的 Identifier 要和 registerNib: 用的一字不差");

    XCTAssertNotNil(cell.iconView);
    XCTAssertNotNil(cell.titleLabel);
    XCTAssertNotNil(cell.subtitleLabel);
    XCTAssertNotNil(cell.amountLabel);
    XCTAssertTrue([cell.titleLabel isDescendantOfView:cell.contentView],
                  @"子 view 要放在 Content View 裡");

    // awakeFromNib 之後，示意文字已清掉；configure / prepareForReuse 和程式碼版行為一致
    XCTAssertNil(cell.titleLabel.text);
    LBTransaction *tx =
        [[LBTransaction alloc] initWithAmount:[NSDecimalNumber decimalNumberWithString:@"80"]
                                         kind:LBTransactionKindExpense
                                         date:[NSDate date]
                                         note:@"早餐"
                                     category:nil];
    LBTransactionViewModel *vm = [LBTransactionViewModel viewModelWithTransaction:tx];
    [cell configureWithViewModel:vm];
    XCTAssertEqualObjects(cell.titleLabel.text, vm.title);
    XCTAssertEqualObjects(cell.amountLabel.text, vm.amountText);
    XCTAssertEqualObjects(cell.amountLabel.textColor, UIColor.systemRedColor);
    [cell prepareForReuse];
    XCTAssertNil(cell.titleLabel.text);
    XCTAssertNil(cell.amountLabel.text);
    XCTAssertNil(cell.iconView.image);

    // registerNib: 之後 dequeue 拿到的也是 XIB 版
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)
                                                          style:UITableViewStylePlain];
    [tableView registerNib:[self lb_nib]
        forCellReuseIdentifier:[LBTransactionCell defaultReuseIdentifier]];
    UITableViewCell *dequeued =
        [tableView dequeueReusableCellWithIdentifier:[LBTransactionCell defaultReuseIdentifier]];
    XCTAssertTrue([dequeued isKindOfClass:[LBTransactionCell class]]);
    XCTAssertNotNil(((LBTransactionCell *)dequeued).amountLabel);
}

@end
