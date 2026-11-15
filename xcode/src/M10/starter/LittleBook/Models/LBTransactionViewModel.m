#import "LBTransactionViewModel.h"
#import "LBTransaction.h"
#import "LBCategory.h"
#import "LBSettings.h"
#import "NSDecimalNumber+LBFormatting.h"
#import "LBLRUCache.h"

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

/// M09：依設定決定要不要顯示到「分」。不顯示時先四捨五入到整數，再把 ".00" 拿掉。
static NSString *LBViewModelAmountString(NSDecimalNumber *amount, BOOL showsCents) {
    if (showsCents) {
        return [amount lb_currencyString];
    }
    static NSDecimalNumberHandler *roundToUnit = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        roundToUnit = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                             scale:0
                                                                  raiseOnExactness:NO
                                                                   raiseOnOverflow:NO
                                                                  raiseOnUnderflow:NO
                                                               raiseOnDivideByZero:NO];
    });
    NSString *text = [[amount decimalNumberByRoundingAccordingToBehavior:roundToUnit]
                      lb_currencyString];
    return [text hasSuffix:@".00"] ? [text substringToIndex:text.length - 3] : text;
}

static NSUInteger LBViewModelFormattingCount = 0;

@implementation LBTransactionViewModel

+ (instancetype)viewModelWithTransaction:(LBTransaction *)tx {
    // TODO: M10 — 先查 LBLRUCache（key = tx.identifier，容量 cacheCapacity），命中就直接回傳；
    //            沒有才 initWithTransaction: 並放進快取。快取與計數器要用同一把鎖保護
    //            （@synchronized 一個 static 物件），格式化本身在鎖外做。
    return [[self alloc] initWithTransaction:tx];
}

+ (NSUInteger)formattingCount {
    return LBViewModelFormattingCount;
}

+ (void)resetCache {
    // TODO: M10 — 清空快取
    LBViewModelFormattingCount = 0;
}

+ (NSUInteger)cacheCapacity {
    return 1000;
}

- (instancetype)initWithTransaction:(LBTransaction *)tx {
    NSParameterAssert(tx != nil);
    if ((self = [super init])) {
        LBViewModelFormattingCount += 1;
        NSString *categoryName = tx.category.name ?: @"未分類";
        _title = tx.note.length > 0 ? [tx.note copy] : categoryName;
        _subtitle = [NSString stringWithFormat:@"%@ · %@", categoryName,
                     [LBViewModelDateFormatter() stringFromDate:tx.date]];
        _isExpense = tx.kind == LBTransactionKindExpense;
        NSString *amount = LBViewModelAmountString(tx.amount, LBSettings.shared.showsCents);
        _amountText = [NSString stringWithFormat:@"%@%@", _isExpense ? @"-" : @"+", amount];
        _symbolName = [tx.category.symbolName copy] ?: @"questionmark.circle";
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %@ %@ %@>", NSStringFromClass(self.class),
            _title, _subtitle, _amountText];
}

@end
