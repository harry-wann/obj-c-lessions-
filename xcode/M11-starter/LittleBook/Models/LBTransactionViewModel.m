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

static const NSUInteger LBViewModelCacheCapacity = 1000;

/// 快取與計數器共用一把鎖：viewModelWithTransaction: 理論上只在主執行緒呼叫，
/// 但 view model 也可能在背景預先算好（10.2），LBLRUCache 本身不是執行緒安全的。
static NSObject *LBViewModelLock(void) {
    static NSObject *lock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [[NSObject alloc] init];
    });
    return lock;
}

static LBLRUCache<NSUUID *, LBTransactionViewModel *> *LBViewModelCache = nil;
static NSUInteger LBViewModelFormattingCount = 0;

@implementation LBTransactionViewModel

+ (instancetype)viewModelWithTransaction:(LBTransaction *)tx {
    NSParameterAssert(tx != nil);
    @synchronized (LBViewModelLock()) {
        if (LBViewModelCache == nil) {
            LBViewModelCache = [[LBLRUCache alloc] initWithCapacity:LBViewModelCacheCapacity];
        }
        LBTransactionViewModel *cached = [LBViewModelCache objectForKey:tx.identifier];
        if (cached != nil) {
            return cached;   // 命中：零格式化
        }
    }
    // 格式化在鎖外做：不要拿著鎖做慢的事
    LBTransactionViewModel *created = [[self alloc] initWithTransaction:tx];
    @synchronized (LBViewModelLock()) {
        [LBViewModelCache setObject:created forKey:tx.identifier];
    }
    return created;
}

+ (NSUInteger)formattingCount {
    @synchronized (LBViewModelLock()) {
        return LBViewModelFormattingCount;
    }
}

+ (void)resetCache {
    @synchronized (LBViewModelLock()) {
        [LBViewModelCache removeAllObjects];
        LBViewModelFormattingCount = 0;
    }
}

+ (NSUInteger)cacheCapacity {
    return LBViewModelCacheCapacity;
}

- (instancetype)initWithTransaction:(LBTransaction *)tx {
    NSParameterAssert(tx != nil);
    if ((self = [super init])) {
        @synchronized (LBViewModelLock()) {
            LBViewModelFormattingCount += 1;
        }
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
