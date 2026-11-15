#import "SceneDelegate.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    // 不用 Storyboard：自己建立 UIWindow 與根視圖控制器。
    UIWindowScene *windowScene = (UIWindowScene *)scene;

    UIViewController *root = [[UIViewController alloc] init];
    root.view.backgroundColor = UIColor.systemBackgroundColor;

    UILabel *label = [[UILabel alloc] init];
    label.text = @"小帳本";
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [root.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:root.view.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:root.view.centerYAnchor]
    ]];

    UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
    window.rootViewController = root;
    self.window = window;
    [window makeKeyAndVisible];
}

@end
