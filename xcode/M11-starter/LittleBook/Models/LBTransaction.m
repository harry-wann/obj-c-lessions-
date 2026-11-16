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

/// 目前認得的旗標；其他位元（新版 App 寫的）讀進來時丟掉。
static const LBTransactionFlags LBTransactionKnownFlags =
    LBTransactionFlagsReconciled | LBTransactionFlagsRecurring;

/// 類別延伸：還原用的私有初始化器（名稱以 init 開頭才屬於 init 家族，ARC 才允許 self = …）。
@interface LBTransaction ()
- (instancetype)initWithIdentifier:(NSUUID *)identifier
                            amount:(NSDecimalNumber *)amount
                              kind:(LBTransactionKind)kind
                              date:(NSDate *)date
                              note:(NSString *)note
                          category:(nullable LBCategory *)category
                             flags:(LBTransactionFlags)flags;
@end

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

/// 還原用：先走指定初始化器，再把存檔裡的 identifier 蓋回去（只有類別自己能碰 ivar）。
- (instancetype)initWithIdentifier:(NSUUID *)identifier
                            amount:(NSDecimalNumber *)amount
                              kind:(LBTransactionKind)kind
                              date:(NSDate *)date
                              note:(NSString *)note
                          category:(nullable LBCategory *)category
                             flags:(LBTransactionFlags)flags {
    if ((self = [self initWithAmount:amount
                                kind:kind
                                date:date
                                note:note
                            category:category
                               flags:flags])) {
        _identifier = [identifier copy];
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    // 不可變物件的慣例：copy 直接回傳自己（NSString、NSArray 也是這樣做）。
    return self;
}

#pragma mark - 驗證工具（字典與 NSCoder 共用）

static NSError *LBTransactionDecodeError(NSString *key, id value) {
    NSString *message = [NSString stringWithFormat:@"交易欄位 %@ 缺少或型別不正確：%@",
                         key, value ?: @"(nil)"];
    return [NSError errorWithDomain:LBErrorDomain
                               code:LBErrorCodeUnexpectedType
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

/// 字串或數字 → 正的 NSDecimalNumber；NaN、0、負數回 nil。
static NSDecimalNumber *_Nullable LBPositiveDecimalFromValue(id _Nullable value) {
    NSString *text = nil;
    if ([value isKindOfClass:[NSString class]]) {
        text = value;
    } else if ([value isKindOfClass:[NSNumber class]]
               && value != (id)kCFBooleanTrue && value != (id)kCFBooleanFalse) {
        text = [value stringValue];
    } else {
        return nil;
    }
    NSLocale *posix = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:text locale:posix];
    NSDecimal decimal = number.decimalValue;
    if (NSDecimalIsNotANumber(&decimal)
        || [number compare:NSDecimalNumber.zero] != NSOrderedDescending) {
        return nil;
    }
    return number;
}

/// 只接受 NSNumber（布林不算）。
static NSNumber *_Nullable LBNumberFromValue(id _Nullable value) {
    if (![value isKindOfClass:[NSNumber class]]
        || value == (id)kCFBooleanTrue || value == (id)kCFBooleanFalse) {
        return nil;
    }
    return value;
}

#pragma mark - 字典表示法（M09）

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    NSMutableDictionary<NSString *, id> *dict = [NSMutableDictionary dictionaryWithCapacity:7];
    dict[LBTransactionKeyIdentifier] = _identifier.UUIDString;
    dict[LBTransactionKeyAmount] = _amount.stringValue;   // 字串：十進位不失真
    dict[LBTransactionKeyKind] = @(_kind);
    dict[LBTransactionKeyDate] = @(_date.timeIntervalSince1970);
    dict[LBTransactionKeyNote] = _note;
    dict[LBTransactionKeyFlags] = @(_flags);
    if (_category != nil) {
        dict[LBTransactionKeyCategory] = [_category lb_path];   // nil 不能放進字典，所以分開判斷
    }
    return [dict copy];
}

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dictionary
                             error:(NSError **)error {
    NSParameterAssert(dictionary != nil);
    // 從 JSON 來的東西一律不信任：每個欄位都檢查型別，NSNull 視同缺欄位。
    id rawIdentifier = dictionary[LBTransactionKeyIdentifier];
    NSUUID *identifier = [rawIdentifier isKindOfClass:[NSString class]]
        ? [[NSUUID alloc] initWithUUIDString:rawIdentifier] : nil;
    if (identifier == nil) {
        if (error != NULL) {
            *error = LBTransactionDecodeError(LBTransactionKeyIdentifier, rawIdentifier);
        }
        return nil;
    }

    id rawAmount = dictionary[LBTransactionKeyAmount];
    NSDecimalNumber *amount = LBPositiveDecimalFromValue(rawAmount);
    if (amount == nil) {
        if (error != NULL) {
            *error = LBTransactionDecodeError(LBTransactionKeyAmount, rawAmount);
        }
        return nil;
    }

    id rawKind = dictionary[LBTransactionKeyKind];
    NSNumber *kindNumber = LBNumberFromValue(rawKind);
    NSInteger kindValue = kindNumber.integerValue;
    if (kindNumber == nil
        || (kindValue != LBTransactionKindExpense && kindValue != LBTransactionKindIncome)) {
        if (error != NULL) {
            *error = LBTransactionDecodeError(LBTransactionKeyKind, rawKind);
        }
        return nil;
    }

    id rawDate = dictionary[LBTransactionKeyDate];
    NSNumber *dateNumber = LBNumberFromValue(rawDate);
    if (dateNumber == nil || !isfinite(dateNumber.doubleValue)) {
        if (error != NULL) {
            *error = LBTransactionDecodeError(LBTransactionKeyDate, rawDate);
        }
        return nil;
    }
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:dateNumber.doubleValue];

    // 選填欄位：缺或 NSNull 用預設值；型別錯一樣報錯
    id rawNote = dictionary[LBTransactionKeyNote];
    NSString *note = @"";
    if ([rawNote isKindOfClass:[NSString class]]) {
        note = rawNote;
    } else if (rawNote != nil && rawNote != [NSNull null]) {
        if (error != NULL) {
            *error = LBTransactionDecodeError(LBTransactionKeyNote, rawNote);
        }
        return nil;
    }

    id rawFlags = dictionary[LBTransactionKeyFlags];
    LBTransactionFlags flags = LBTransactionFlagsNone;
    if (rawFlags != nil && rawFlags != [NSNull null]) {
        NSNumber *flagsNumber = LBNumberFromValue(rawFlags);
        if (flagsNumber == nil) {
            if (error != NULL) {
                *error = LBTransactionDecodeError(LBTransactionKeyFlags, rawFlags);
            }
            return nil;
        }
        flags = flagsNumber.unsignedIntegerValue & LBTransactionKnownFlags;
    }

    id rawCategory = dictionary[LBTransactionKeyCategory];
    LBCategory *category = nil;
    if ([rawCategory isKindOfClass:[NSString class]]) {
        category = [LBCategory lb_categoryWithPath:rawCategory];   // 找不到（分類被改名）就當未分類
    }

    return [self initWithIdentifier:identifier
                             amount:amount
                               kind:(LBTransactionKind)kindValue
                               date:date
                               note:note
                           category:category
                              flags:flags];
}

#pragma mark - NSSecureCoding（M09）

+ (BOOL)supportsSecureCoding {
    return YES;   // 少了這個，requiringSecureCoding:YES 的 archive / unarchive 會直接失敗
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_identifier forKey:LBTransactionKeyIdentifier];
    [coder encodeObject:_amount forKey:LBTransactionKeyAmount];
    [coder encodeInteger:_kind forKey:LBTransactionKeyKind];
    [coder encodeObject:_date forKey:LBTransactionKeyDate];
    [coder encodeObject:_note forKey:LBTransactionKeyNote];
    [coder encodeInteger:(NSInteger)_flags forKey:LBTransactionKeyFlags];
    if (_category != nil) {
        [coder encodeObject:[_category lb_path] forKey:LBTransactionKeyCategory];
    }
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    // decodeObjectOfClass:forKey: 會檢查類別，型別不符時回 nil（並在 coder 上記錄錯誤）
    NSUUID *identifier = [coder decodeObjectOfClass:[NSUUID class]
                                             forKey:LBTransactionKeyIdentifier];
    NSDecimalNumber *amount = [coder decodeObjectOfClass:[NSDecimalNumber class]
                                                  forKey:LBTransactionKeyAmount];
    NSDate *date = [coder decodeObjectOfClass:[NSDate class] forKey:LBTransactionKeyDate];
    NSString *note = [coder decodeObjectOfClass:[NSString class] forKey:LBTransactionKeyNote];
    NSString *path = [coder decodeObjectOfClass:[NSString class] forKey:LBTransactionKeyCategory];
    NSInteger kind = [coder decodeIntegerForKey:LBTransactionKeyKind];
    NSInteger flags = [coder decodeIntegerForKey:LBTransactionKeyFlags];

    if (identifier == nil || amount == nil || date == nil
        || [amount compare:NSDecimalNumber.zero] != NSOrderedDescending
        || (kind != LBTransactionKindExpense && kind != LBTransactionKindIncome)) {
        NSError *error = LBTransactionDecodeError(@"NSCoder", nil);
        [coder failWithError:error];
        return nil;
    }
    LBCategory *category = path != nil ? [LBCategory lb_categoryWithPath:path] : nil;
    return [self initWithIdentifier:identifier
                             amount:amount
                               kind:(LBTransactionKind)kind
                               date:date
                               note:note ?: @""
                           category:category
                              flags:(LBTransactionFlags)flags & LBTransactionKnownFlags];
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
