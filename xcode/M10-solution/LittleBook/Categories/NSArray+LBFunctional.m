#import "NSArray+LBFunctional.h"

@implementation NSArray (LBFunctional)

- (NSArray *)lb_map:(id (^)(id object))transform {
    NSParameterAssert(transform != nil);
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    for (id object in self) {
        id mapped = transform(object);
        NSAssert(mapped != nil, @"lb_map: 的 transform 不可回傳 nil");
        [result addObject:mapped];
    }
    return [result copy];
}

- (NSArray *)lb_filter:(BOOL (^)(id object))predicate {
    NSParameterAssert(predicate != nil);
    NSMutableArray *result = [NSMutableArray array];
    for (id object in self) {
        if (predicate(object)) {
            [result addObject:object];
        }
    }
    return [result copy];
}

- (id)lb_reduce:(id (^)(id accumulator, id object))reducer initial:(id)initial {
    NSParameterAssert(reducer != nil);
    id accumulator = initial;
    for (id object in self) {
        accumulator = reducer(accumulator, object);
    }
    return accumulator;
}

@end
