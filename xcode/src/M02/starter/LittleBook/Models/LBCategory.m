#import "LBCategory.h"

// TODO: M02 — 用類別延伸把 parent 改成對內 readwrite
@interface LBCategory ()
@end

@implementation LBCategory

- (instancetype)initWithName:(NSString *)name symbolName:(NSString *)symbolName {
    if ((self = [super init])) {
        // TODO: M02 — identifier 用 NSUUID、name / symbolName 要 copy、準備可變的 children 容器
    }
    return self;
}

- (NSArray<LBCategory *> *)children {
    // TODO: M02 — 回傳內部可變陣列的不可變快照
    return @[];
}

- (void)addChild:(LBCategory *)child {
    // TODO: M02 — 設 child.parent = self 並加入容器（重複加入要忽略）
}

- (NSUInteger)depth {
    // TODO: M02 — 沿著 parent 往上數
    return 0;
}

- (NSArray<LBCategory *> *)flattened {
    // TODO: M02 — 深度優先，含自己
    return @[];
}

@end
