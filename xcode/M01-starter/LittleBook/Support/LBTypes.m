#import "LBTypes.h"

// TODO: M01 — 全域常數的標準寫法：.h 用 extern 宣告、.m 給值 @"com.littlebook.error"
NSString * const LBErrorDomain = @"TODO";

NSString *LBFormatCents(long long cents) {
    // TODO: M01 — 128000 → @"1,280.00"、-5 → @"-0.05"
    // 提示：先處理負號，再用 / 100 與 % 100 拆出元與分，最後每三位插一個逗號。
    return @"";
}
