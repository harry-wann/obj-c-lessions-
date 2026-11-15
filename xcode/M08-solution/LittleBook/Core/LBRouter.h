@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/// 以字串建立 ViewController 的小型路由（舊專案處理 URL scheme 常見的寫法）。
/// 重點：NSClassFromString 拿到的 Class 一定要先確認是 UIViewController 子類別，
/// 否則對一個 NSObject 呼叫 view 就是 unrecognized selector。
@interface LBRouter : NSObject

/// name 可以是類別名或已登記的別名；查無類別、或類別不是 UIViewController 子類別時回 nil。
+ (nullable __kindof UIViewController *)viewControllerForName:(NSString *)name;

/// 登記別名，例如 @"list" → @"LBTransactionListViewController"。
+ (void)registerAlias:(NSString *)alias forClassName:(NSString *)className;

/// 清掉所有別名（測試用）。
+ (void)removeAllAliases;

@end

NS_ASSUME_NONNULL_END
