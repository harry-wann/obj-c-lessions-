#import "LBRouter.h"

/// 別名表只建一次（dispatch_once 單例寫法）；存取時用 @synchronized 保護。
static NSMutableDictionary<NSString *, NSString *> *LBRouterAliasTable(void) {
    static NSMutableDictionary<NSString *, NSString *> *table = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        table = [NSMutableDictionary dictionary];
    });
    return table;
}

@implementation LBRouter

+ (__kindof UIViewController *)viewControllerForName:(NSString *)name {
    NSParameterAssert(name != nil);
    NSString *className = nil;
    @synchronized (self) {
        className = LBRouterAliasTable()[name] ?: name;
    }

    // 1. 字串 → Class。找不到會回 Nil（Class 的「空」寫 Nil，物件的才寫 nil）。
    Class cls = NSClassFromString(className);
    if (cls == Nil) {
        return nil;
    }
    // 2. 防禦：不是 UIViewController 子類別就拒絕，不然 alloc/init 出來的東西沒有 view。
    if (![cls isSubclassOfClass:[UIViewController class]]) {
        return nil;
    }
    return [[cls alloc] init];
}

+ (void)registerAlias:(NSString *)alias forClassName:(NSString *)className {
    NSParameterAssert(alias != nil);
    NSParameterAssert(className != nil);
    @synchronized (self) {
        LBRouterAliasTable()[alias] = [className copy];
    }
}

+ (void)removeAllAliases {
    @synchronized (self) {
        [LBRouterAliasTable() removeAllObjects];
    }
}

@end
