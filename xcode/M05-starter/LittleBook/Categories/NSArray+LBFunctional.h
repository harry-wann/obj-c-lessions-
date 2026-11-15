@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// 補上 Swift / Kotlin / TS 的 map / filter / reduce 直覺。方法名一律 lb_ 前綴。
@interface NSArray<ObjectType> (LBFunctional)

/// 逐一轉換成新陣列；transform 不可回傳 nil（NSArray 放不了 nil）。
- (NSArray *)lb_map:(id (^)(ObjectType object))transform;

/// 保留 predicate 回 YES 的元素。
- (NSArray<ObjectType> *)lb_filter:(BOOL (^)(ObjectType object))predicate;

/// 從 initial 開始，依序把元素折疊進累加值。
- (id)lb_reduce:(id (^)(id accumulator, ObjectType object))reducer initial:(id)initial;

@end

NS_ASSUME_NONNULL_END
