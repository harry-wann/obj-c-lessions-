#import "LBTransactionViewModel.h"
#import "LBTransaction.h"
#import "LBCategory.h"
#import "NSDecimalNumber+LBFormatting.h"

@implementation LBTransactionViewModel

+ (instancetype)viewModelWithTransaction:(LBTransaction *)tx {
    return [[self alloc] initWithTransaction:tx];
}

- (instancetype)initWithTransaction:(LBTransaction *)tx {
    NSParameterAssert(tx != nil);
    if ((self = [super init])) {
        // TODO: M08 — 在這裡把顯示字串一次算好（cellForRowAtIndexPath: 只做賦值）：
        //   title      備註；備註是空字串就用分類名（沒有分類用 @"未分類"）
        //   subtitle   「分類 · 11/5」：日期格式器用 static + dispatch_once 只建一次
        //   amountText 支出前面加 "-"、收入加 "+"，數字用 lb_currencyString
        //   symbolName 分類的 SF Symbol；沒有分類用 @"questionmark.circle"
        //   isExpense  kind == LBTransactionKindExpense
        _title = @"";
        _subtitle = @"";
        _amountText = @"";
        _symbolName = @"questionmark.circle";
        _isExpense = YES;
    }
    return self;
}

@end
