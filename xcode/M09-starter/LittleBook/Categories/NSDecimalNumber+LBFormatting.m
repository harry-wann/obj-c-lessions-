#import "NSDecimalNumber+LBFormatting.h"
#import "LBTypes.h"

@implementation NSDecimalNumber (LBFormatting)

- (NSString *)lb_currencyString {
    // 四捨五入到「分」的規則物件只建一次（dispatch_once 單例寫法）。
    static NSDecimalNumberHandler *roundToCents = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        roundToCents = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                              scale:0
                                                                   raiseOnExactness:NO
                                                                    raiseOnOverflow:NO
                                                                   raiseOnUnderflow:NO
                                                                raiseOnDivideByZero:NO];
    });

    // 乘 100 變成「分」、四捨五入成整數，再交給 M01 寫好的 C 函式。
    NSDecimalNumber *cents = [[self decimalNumberByMultiplyingByPowerOf10:2]
                              decimalNumberByRoundingAccordingToBehavior:roundToCents];
    return LBFormatCents(cents.longLongValue);
}

@end
