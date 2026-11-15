#import "NSArray+LBFunctional.h"

@implementation NSArray (LBFunctional)

- (NSArray *)lb_map:(id (^)(id object))transform {
    // TODO: M05 — 快速列舉每個元素，呼叫 transform 放進新陣列
    return @[];
}

- (NSArray *)lb_filter:(BOOL (^)(id object))predicate {
    // TODO: M05 — predicate 回 YES 才保留
    return @[];
}

- (id)lb_reduce:(id (^)(id accumulator, id object))reducer initial:(id)initial {
    // TODO: M05 — accumulator 從 initial 開始，每個元素 accumulator = reducer(accumulator, obj)
    return initial;
}

@end
