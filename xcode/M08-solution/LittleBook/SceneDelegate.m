#import "SceneDelegate.h"
#import "LBLedger.h"
#import "LBUndoStack.h"
#import "LBTransactionListViewController.h"

@interface SceneDelegate ()
// App 層的共用模型：這個 scene 活著它們就活著。M09 會由 LBPersistence 載入 / 儲存。
@property (nonatomic, strong) LBLedger *ledger;
@property (nonatomic, strong) LBUndoStack *undoStack;
@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    // 不用 Storyboard：自己建立 UIWindow 與根視圖控制器。
    UIWindowScene *windowScene = (UIWindowScene *)scene;

    self.ledger = [[LBLedger alloc] init];
    self.undoStack = [[LBUndoStack alloc] init];

    LBTransactionListViewController *list =
        [[LBTransactionListViewController alloc] initWithLedger:self.ledger
                                                      undoStack:self.undoStack];
    UIViewController *stats = [self lb_placeholderWithTitle:@"統計" message:@"M12 用 Swift 實作統計頁"];
    UIViewController *settings = [self lb_placeholderWithTitle:@"設定" message:@"M09 實作設定頁"];

    UITabBarController *tabBar = [[UITabBarController alloc] init];
    tabBar.viewControllers = @[
        [self lb_tabWrapping:list title:@"帳本" symbol:@"list.bullet.rectangle"],
        [self lb_tabWrapping:stats title:@"統計" symbol:@"chart.bar"],
        [self lb_tabWrapping:settings title:@"設定" symbol:@"gearshape"],
    ];

    UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
    window.rootViewController = tabBar;
    self.window = window;
    [window makeKeyAndVisible];
}

/// 每個 tab 各包一層 UINavigationController，開大標題。
- (UINavigationController *)lb_tabWrapping:(UIViewController *)root
                                     title:(NSString *)title
                                    symbol:(NSString *)symbol {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:root];
    nav.navigationBar.prefersLargeTitles = YES;
    nav.tabBarItem = [[UITabBarItem alloc] initWithTitle:title
                                                   image:[UIImage systemImageNamed:symbol]
                                                     tag:0];
    return nav;
}

/// 還沒做的頁面先放一個說明文字。
- (UIViewController *)lb_placeholderWithTitle:(NSString *)title message:(NSString *)message {
    UIViewController *vc = [[UIViewController alloc] init];
    vc.title = title;
    vc.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    UILabel *label = [[UILabel alloc] init];
    label.text = message;
    label.textColor = UIColor.secondaryLabelColor;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [vc.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:vc.view.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:vc.view.centerYAnchor],
        [label.leadingAnchor constraintGreaterThanOrEqualToAnchor:vc.view.leadingAnchor
                                                         constant:32],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:vc.view.trailingAnchor
                                                       constant:-32],
    ]];
    return vc;
}

@end
