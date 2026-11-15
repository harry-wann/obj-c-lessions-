#import "LBTransaction.h"
#import "LBCategory.h"
#import "LBCategory+LBPath.h"

NSString * const LBTransactionKeyIdentifier = @"id";
NSString * const LBTransactionKeyAmount = @"amount";
NSString * const LBTransactionKeyKind = @"kind";
NSString * const LBTransactionKeyDate = @"date";
NSString * const LBTransactionKeyNote = @"note";
NSString * const LBTransactionKeyCategory = @"category";
NSString * const LBTransactionKeyFlags = @"flags";

@implementation LBTransaction

#pragma mark - 初始化

- (instancetype)initWithAmount:(NSDecimalNumber *)amount
                          kind:(LBTransactionKind)kind
                          date:(NSDate *)date
                          note:(NSString *)note
                      category:(LBCategory *)category
                         flags:(LBTransactionFlags)flags {
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
        _flags = flags;
    }
    return self;
}

- (instancetype)initWithAmount:(NSDecimalNumber *)amount
                          kind:(LBTransactionKind)kind
                          date:(NSDate *)date
                          note:(NSString *)note
                      category:(LBCategory *)category {
    // 便利初始化器一律轉呼叫指定初始化器
    return [self initWithAmount:amount
                           kind:kind
                           date:date
                           note:note
                       category:category
                          flags:LBTransactionFlagsNone];
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

#pragma mark - 字典表示法（M09）

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    // TODO: M09 — 只放 JSON 型別：identifier → UUIDString、amount → stringValue（十進位不失真）、
    //            kind / flags → NSNumber、date → timeIntervalSince1970、category → [category lb_path]
    //            （category 是 nil 時不要放 key，NSDictionary 放不了 nil）
    return @{};
}

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dictionary
                             error:(NSError **)error {
    // TODO: M09 — 每個欄位都要檢查型別（isKindOfClass:）；NSNull 當作沒有；
    //            必填（id / amount / kind / date）缺或錯 → *error = LBErrorDomain /
    //            LBErrorCodeUnexpectedType 並回 nil；error 可能是 NULL，寫入前要判斷。
    //            還原 identifier：在類別延伸宣告一個私有 init…，先呼叫指定初始化器再設 _identifier
    return nil;
}

#pragma mark - NSSecureCoding（M09）

+ (BOOL)supportsSecureCoding {
    return NO;   // TODO: M09 — 回 YES，否則 requiringSecureCoding:YES 會直接失敗
}

- (void)encodeWithCoder:(NSCoder *)coder {
    // TODO: M09 — encodeObject:forKey: / encodeInteger:forKey:，key 用 LBTransactionKeyXxx 常數
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    // TODO: M09 — decodeObjectOfClass:forKey:（不是 decodeObjectForKey:）逐欄位還原
    return nil;
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
