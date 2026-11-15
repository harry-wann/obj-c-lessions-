@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// 分類（category）：幫既有類別加方法。方法名加 lb_ 前綴，避免和別人的分類撞名。
@interface NSDecimalNumber (LBFormatting)

/// 千分位、固定兩位小數、負數前加 -。1280 → @"1,280.00"、-1280.5 → @"-1,280.50"。
- (NSString *)lb_currencyString;

@end

NS_ASSUME_NONNULL_END
