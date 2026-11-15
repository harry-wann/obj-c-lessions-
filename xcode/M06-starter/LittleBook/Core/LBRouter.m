#import "LBRouter.h"

@implementation LBRouter

+ (__kindof UIViewController *)viewControllerForName:(NSString *)name {
    NSParameterAssert(name != nil);
    // TODO: M06 — 1. 查別名表（沒有就用 name 本身）2. NSClassFromString
    //            3. isSubclassOfClass:[UIViewController class] 不成立回 nil 4. [[cls alloc] init]
    return nil;
}

+ (void)registerAlias:(NSString *)alias forClassName:(NSString *)className {
    NSParameterAssert(alias != nil);
    NSParameterAssert(className != nil);
    // TODO: M06 — 存進一張 static NSMutableDictionary（dispatch_once 建立、@synchronized 保護）
}

+ (void)removeAllAliases {
    // TODO: M06
}

@end
