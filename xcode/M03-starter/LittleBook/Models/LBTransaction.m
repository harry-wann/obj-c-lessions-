#import "LBTransaction.h"
#import "LBCategory.h"

@implementation LBTransaction

#pragma mark - 初始化

- (instancetype)initWithAmount:(NSDecimalNumber *)amount
                          kind:(LBTransactionKind)kind
                          date:(NSDate *)date
                          note:(NSString *)note
                      category:(LBCategory *)category {
    NSParameterAssert(amount != nil);
    NSParameterAssert(date != nil);
    NSParameterAssert(note != nil);
    if ((self = [super init])) {
        _identifier = [NSUUID UUID];
        // 金額永遠為正：負數就乘 -1
        if ([amount compare:NSDecimalNumber.zero] == NSOrderedAscending) {
            NSDecimalNumber *minusOne = [NSDecimalNumber decimalNumberWithString:@"-1"];
            amount = [amount decimalNumberByMultiplyingBy:minusOne];
        }
        _amount = amount;
        _kind = kind;
        _date = [date copy];
        _note = [note copy];      // 傳進來的可能是 NSMutableString，copy 斷開關係
        _category = category;
        _flags = LBTransactionFlagsNone;
    }
    return self;
}

+ (instancetype)expenseWithAmount:(NSDecimalNumber *)amount note:(NSString *)note {
    return [[self alloc] initWithAmount:amount
                                   kind:LBTransactionKindExpense
                                   date:[NSDate date]
                                   note:note
                               category:nil];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    // 不可變物件的慣例：copy 直接回傳自己（NSString、NSArray 也是這樣做）。
    return self;
}

#pragma mark - 相等與雜湊

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[LBTransaction class]]) {
        return NO;
    }
    LBTransaction *other = object;
    return [_identifier isEqual:other.identifier]
        && [_amount isEqual:other.amount]
        && _kind == other.kind
        && [_date isEqualToDate:other.date]
        && [_note isEqualToString:other.note]
        && (_category == other.category || [_category isEqual:other.category])
        && _flags == other.flags;
}

- (NSUInteger)hash {
    // 覆寫 isEqual: 就必須覆寫 hash；相等的物件 hash 一定相同。
    return _identifier.hash ^ (_amount.hash << 1) ^ (NSUInteger)_kind;
}

#pragma mark - 描述

- (NSString *)description {
    long long cents = [[_amount decimalNumberByMultiplyingByPowerOf10:2] longLongValue];
    NSString *kindLabel = (_kind == LBTransactionKindExpense) ? @"支出" : @"收入";
    return [NSString stringWithFormat:@"<%@: %p %@ %@ 「%@」 %@>",
            NSStringFromClass(self.class), self, kindLabel, LBFormatCents(cents), _note,
            _category.name ?: @"未分類"];
}

@end
