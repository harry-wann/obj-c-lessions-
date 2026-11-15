#import "LBMonthSection.h"
#import "LBTransaction.h"

@implementation LBMonthSection

- (instancetype)initWithYear:(NSInteger)year
                       month:(NSInteger)month
                transactions:(NSArray<LBTransaction *> *)transactions {
    if ((self = [super init])) {
        // TODO: M03 — 存年月、copy 交易陣列，並用 NSDecimalNumber 把支出 / 收入合計算好
        _expenseTotal = NSDecimalNumber.zero;
        _incomeTotal = NSDecimalNumber.zero;
    }
    return self;
}

@end
