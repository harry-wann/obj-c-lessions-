#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBMonthSection.h"

@implementation LBLedger {
    // TODO: M03 — 內部用 NSMutableArray（依日期倒序）與 NSMutableDictionary（identifier 索引）
}

- (instancetype)init {
    if ((self = [super init])) {
        // TODO: M03 — 建立容器與 NSCalendar
    }
    return self;
}

- (NSArray<LBTransaction *> *)transactions {
    // TODO: M03 — 回傳不可變快照（copy）
    return @[];
}

- (LBTransaction *)transactionWithIdentifier:(NSUUID *)identifier {
    // TODO: M03 — 從索引字典查
    return nil;
}

- (void)addTransaction:(LBTransaction *)tx {
    // TODO: M03 — 找到正確位置插入以維持日期倒序，並更新索引
}

- (BOOL)removeTransactionWithIdentifier:(NSUUID *)identifier {
    // TODO: M03 — 從陣列與索引都移除
    return NO;
}

- (NSArray<LBMonthSection *> *)transactionsGroupedByMonth {
    // TODO: M03 — 用 NSCalendar 取年月，相鄰同月份收成一個 LBMonthSection
    return @[];
}

- (NSDecimalNumber *)totalForKind:(LBTransactionKind)kind {
    // TODO: M03 — 用 decimalNumberByAdding: 加總
    return NSDecimalNumber.zero;
}

@end
