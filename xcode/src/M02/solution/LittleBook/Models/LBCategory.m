#import "LBCategory.h"

// 類別延伸：對外 readonly，對內 readwrite。
@interface LBCategory ()
@property (nonatomic, weak, readwrite, nullable) LBCategory *parent;
@end

@implementation LBCategory {
    NSMutableArray<LBCategory *> *_mutableChildren;   // 內部持有可變版本
}

- (instancetype)initWithName:(NSString *)name symbolName:(NSString *)symbolName {
    NSParameterAssert(name != nil);
    NSParameterAssert(symbolName != nil);
    if ((self = [super init])) {
        _identifier = [[NSUUID UUID] UUIDString];
        _name = [name copy];               // init 裡直接用 ivar，不走 setter
        _symbolName = [symbolName copy];
        _mutableChildren = [NSMutableArray array];
    }
    return self;
}

#pragma mark - 子分類

- (NSArray<LBCategory *> *)children {
    return [_mutableChildren copy];        // 回傳不可變快照，呼叫端改不到內部狀態
}

- (void)addChild:(LBCategory *)child {
    NSParameterAssert(child != nil);
    if ([_mutableChildren containsObject:child]) {
        return;
    }
    child.parent = self;
    [_mutableChildren addObject:child];
}

- (NSUInteger)depth {
    NSUInteger depth = 0;
    LBCategory *node = self.parent;
    while (node != nil) {
        depth += 1;
        node = node.parent;
    }
    return depth;
}

- (NSArray<LBCategory *> *)flattened {
    NSMutableArray<LBCategory *> *result = [NSMutableArray arrayWithObject:self];
    for (LBCategory *child in _mutableChildren) {
        [result addObjectsFromArray:[child flattened]];   // 遞迴：深度優先
    }
    return [result copy];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p name=%@ depth=%lu children=%lu>",
            NSStringFromClass(self.class), self, _name,
            (unsigned long)self.depth, (unsigned long)_mutableChildren.count];
}

@end
