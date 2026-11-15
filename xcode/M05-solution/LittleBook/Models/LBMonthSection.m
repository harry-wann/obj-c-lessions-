#import "LBMonthSection.h"
#import "LBTransaction.h"

@implementation LBMonthSection

- (instancetype)initWithYear:(NSInteger)year
                       month:(NSInteger)month
                transactions:(NSArray<LBTransaction *> *)transactions {
    NSParameterAssert(transactions != nil);
    if ((self = [super init])) {
        _year = year;
        _month = month;
        _transactions = [transactions copy];

        // 建立時就把合計算好，之後讀取不用再算。
        NSDecimalNumber *expense = NSDecimalNumber.zero;
        NSDecimalNumber *income = NSDecimalNumber.zero;
        for (LBTransaction *tx in _transactions) {
            if (tx.kind == LBTransactionKindExpense) {
                expense = [expense decimalNumberByAdding:tx.amount];
            } else {
                income = [income decimalNumberByAdding:tx.amount];
            }
        }
        _expenseTotal = expense;
        _incomeTotal = income;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %ld/%02ld 共 %lu 筆 支出 %@ 收入 %@>",
            NSStringFromClass(self.class), (long)_year, (long)_month,
            (unsigned long)_transactions.count, _expenseTotal, _incomeTotal];
}

@end
