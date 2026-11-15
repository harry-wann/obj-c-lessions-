#import "LBTransaction.h"
#import "LBCategory.h"

@implementation LBTransaction

- (instancetype)initWithAmount:(NSDecimalNumber *)amount
                          kind:(LBTransactionKind)kind
                          date:(NSDate *)date
                          note:(NSString *)note
                      category:(LBCategory *)category {
    if ((self = [super init])) {
        // TODO: M02 — identifier 用 [NSUUID UUID]、amount 轉正、date / note 要 copy、flags 為 None
    }
    return self;
}

+ (instancetype)expenseWithAmount:(NSDecimalNumber *)amount note:(NSString *)note {
    // TODO: M02 — 呼叫指定初始化器：kind 支出、date 今天、category nil
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    // TODO: M02 — 不可變物件的 copy 慣例
    return nil;
}

- (BOOL)isEqual:(id)object {
    // TODO: M02 — 先比位址、再比類別、最後逐欄位比內容
    return [super isEqual:object];
}

- (NSUInteger)hash {
    // TODO: M02 — 與 isEqual: 一致
    return [super hash];
}

- (NSString *)description {
    // TODO: M02 — 包含格式化後的金額（用 LBFormatCents）
    return [super description];
}

@end
