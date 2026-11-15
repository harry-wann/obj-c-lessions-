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

/// 建一個根分類並掛上子分類；children 是 (名稱, SF Symbol) 成對的陣列。
static LBCategory *LBMakeCategory(NSString *name, NSString *symbol,
                                  NSArray<NSArray<NSString *> *> *children) {
    LBCategory *root = [[LBCategory alloc] initWithName:name symbolName:symbol];
    for (NSArray<NSString *> *pair in children) {
        [root addChild:[[LBCategory alloc] initWithName:pair[0] symbolName:pair[1]]];
    }
    return root;
}

+ (NSArray<LBCategory *> *)defaultTree {
    static NSArray<LBCategory *> *tree = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tree = @[
            LBMakeCategory(@"飲食", @"fork.knife", @[
                @[@"早餐", @"cup.and.saucer.fill"],
                @[@"午餐", @"takeoutbag.and.cup.and.straw.fill"],
                @[@"晚餐", @"moon.stars.fill"],
                @[@"飲料", @"mug.fill"],
            ]),
            LBMakeCategory(@"交通", @"car.fill", @[
                @[@"捷運", @"tram.fill"],
                @[@"計程車", @"car.side.fill"],
            ]),
            LBMakeCategory(@"居住", @"house.fill", @[
                @[@"房租", @"key.fill"],
                @[@"水電", @"bolt.fill"],
            ]),
            LBMakeCategory(@"娛樂", @"gamecontroller.fill", @[
                @[@"電影", @"film.fill"],
                @[@"遊戲", @"gamecontroller.fill"],
            ]),
            LBMakeCategory(@"收入", @"banknote.fill", @[
                @[@"薪資", @"briefcase.fill"],
            ]),
        ];
    });
    return tree;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p name=%@ depth=%lu children=%lu>",
            NSStringFromClass(self.class), self, _name,
            (unsigned long)self.depth, (unsigned long)_mutableChildren.count];
}

@end
