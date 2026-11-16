#import "LBTypes.h"

NSString * const LBErrorDomain = @"com.littlebook.error";

NSString *LBFormatCents(long long cents) {
    BOOL negative = cents < 0;
    // 用無號運算取絕對值，避免 LLONG_MIN 取負號溢位。
    unsigned long long magnitude = negative ? 0ULL - (unsigned long long)cents
                                           : (unsigned long long)cents;
    unsigned long long whole = magnitude / 100;
    unsigned long long fraction = magnitude % 100;

    // 手寫千分位：從左到右，每逢剩餘位數是 3 的倍數就插一個逗號。
    NSString *digits = [NSString stringWithFormat:@"%llu", whole];
    NSMutableString *grouped = [NSMutableString stringWithCapacity:digits.length + 4];
    NSUInteger length = digits.length;
    for (NSUInteger i = 0; i < length; i++) {
        if (i > 0 && (length - i) % 3 == 0) {
            [grouped appendString:@","];
        }
        [grouped appendString:[digits substringWithRange:NSMakeRange(i, 1)]];
    }

    return [NSString stringWithFormat:@"%@%@.%02llu", negative ? @"-" : @"", grouped, fraction];
}
