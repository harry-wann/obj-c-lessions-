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

#pragma mark - 預設分類樹

+ (NSArray<LBCategory *> *)defaultTree {
    // TODO: M08 — 用 dispatch_once 建一次：飲食（早餐 / 午餐 / 晚餐 / 飲料）、交通（捷運 / 計程車）、
    //            居住（房租 / 水電）、娛樂（電影 / 遊戲）、收入（薪資）；symbolName 用 SF Symbols 名稱
    return @[];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p name=%@ depth=%lu children=%lu>",
            NSStringFromClass(self.class), self, _name,
            (unsigned long)self.depth, (unsigned long)_mutableChildren.count];
}

@end
