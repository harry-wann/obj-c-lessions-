#import "LBTransactionViewModel.h"
#import "LBTransaction.h"
#import "LBCategory.h"
#import "NSDecimalNumber+LBFormatting.h"

/// 日期格式器很貴，只建一次。
static NSDateFormatter *LBViewModelDateFormatter(void) {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = NSLocale.currentLocale;
        [formatter setLocalizedDateFormatFromTemplate:@"Md"];   // 11/5
    });
    return formatter;
}

@implementation LBTransactionViewModel

+ (instancetype)viewModelWithTransaction:(LBTransaction *)tx {
    return [[self alloc] initWithTransaction:tx];
}

- (instancetype)initWithTransaction:(LBTransaction *)tx {
    NSParameterAssert(tx != nil);
    if ((self = [super init])) {
        NSString *categoryName = tx.category.name ?: @"未分類";
        _title = tx.note.length > 0 ? [tx.note copy] : categoryName;
        _subtitle = [NSString stringWithFormat:@"%@ · %@", categoryName,
                     [LBViewModelDateFormatter() stringFromDate:tx.date]];
        _isExpense = tx.kind == LBTransactionKindExpense;
        _amountText = [NSString stringWithFormat:@"%@%@", _isExpense ? @"-" : @"+",
                       [tx.amount lb_currencyString]];
        _symbolName = [tx.category.symbolName copy] ?: @"questionmark.circle";
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %@ %@ %@>", NSStringFromClass(self.class),
            _title, _subtitle, _amountText];
}

@end
