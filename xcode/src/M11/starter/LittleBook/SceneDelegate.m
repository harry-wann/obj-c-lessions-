#import "SceneDelegate.h"
#import "LBLedger.h"
#import "LBUndoStack.h"
#import "LBSettings.h"
#import "LBPersistence.h"
#import "LBTransactionListViewController.h"
#import "LBSettingsViewController.h"
#import "LBFPSMonitor.h"

@interface SceneDelegate ()
// App 層的共用模型：這個 scene 活著它們就活著。
@property (nonatomic, strong) LBLedger *ledger;
@property (nonatomic, strong) LBUndoStack *undoStack;
@property (nonatomic, strong) LBSettings *settings;
@property (nonatomic, strong) LBPersistence *persistence;
@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    // 不用 Storyboard：自己建立 UIWindow 與根視圖控制器。
    UIWindowScene *windowScene = (UIWindowScene *)scene;

    self.settings = LBSettings.shared;
    NSURL *directory = [LBPersistence defaultDirectoryURL];
    self.persistence = [[LBPersistence alloc] initWithDirectoryURL:directory];
    self.ledger = [self lb_loadLedger];
    self.undoStack = [[LBUndoStack alloc] init];

    LBTransactionListViewController *list =
        [[LBTransactionListViewController alloc] initWithLedger:self.ledger
                                                      undoStack:self.undoStack];
    UIViewController *stats = [self lb_placeholderWithTitle:@"統計"
                                                    message:@"M12 用 Swift 實作統計頁"];
    // TODO: M11 — 改成從 Settings.storyboard 載入：
    //   [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateInitialViewController]
    //   拿到包著設定頁的 UINavigationController，取 topViewController 注入 settings / ledger /
    //   undoStack / persistence（一定要在 view 載入前），再設 tabBarItem 放進 tab。
    LBSettingsViewController *settings =
        [[LBSettingsViewController alloc] initWithSettings:self.settings
                                                    ledger:self.ledger
                                                 undoStack:self.undoStack
                                               persistence:self.persistence];

    UITabBarController *tabBar = [[UITabBarController alloc] init];
    tabBar.viewControllers = @[
        [self lb_tabWrapping:list title:@"帳本" symbol:@"list.bullet.rectangle"],
        [self lb_tabWrapping:stats title:@"統計" symbol:@"chart.bar"],
        [self lb_tabWrapping:settings title:@"設定" symbol:@"gearshape"],
    ];

    UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
    window.rootViewController = tabBar;
    self.window = window;
    [self lb_applyAppearance];
    [window makeKeyAndVisible];

#if DEBUG
    // M10：DEBUG 版一啟動就量 FPS，效能面板打開時已經有最近 60 幀的歷史
    [[LBFPSMonitor shared] start];
#endif

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(lb_settingsDidChange:)
                                               name:LBSettingsDidChangeNotification
                                             object:self.settings];
}

- (void)sceneDidDisconnect:(UIScene *)scene {
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:LBSettingsDidChangeNotification
                                                object:self.settings];
}

/// 進背景就存檔：之後 App 隨時可能被系統殺掉，不會再有機會。
- (void)sceneDidEnterBackground:(UIScene *)scene {
    if (self.ledger == nil) {
        return;
    }
    // 跟系統要一點背景時間，讓背景佇列的寫入跑完
    UIApplication *application = UIApplication.sharedApplication;
    __block UIBackgroundTaskIdentifier task = UIBackgroundTaskInvalid;
    task = [application beginBackgroundTaskWithName:@"SaveLedger" expirationHandler:^{
        [application endBackgroundTask:task];
        task = UIBackgroundTaskInvalid;
    }];
    [self.persistence saveLedger:self.ledger completion:^(NSError *error) {
        if (error != nil) {
            NSLog(@"[LittleBook] 存檔失敗：%@", error);
        }
        if (task != UIBackgroundTaskInvalid) {
            [application endBackgroundTask:task];
            task = UIBackgroundTaskInvalid;
        }
    }];
}

#pragma mark - 載入

- (LBLedger *)lb_loadLedger {
    NSError *error = nil;
    LBLedger *ledger = [self.persistence loadLedgerWithError:&error];
    if (ledger != nil) {
        return ledger;
    }
    // 壞檔：先把它改名留著（之後還能救），再從空帳本開始，不要讓 App 一開就 crash
    NSLog(@"[LittleBook] 讀檔失敗，改用空帳本：%@", error);
    NSURL *fileURL = self.persistence.fileURL;
    NSString *backupName = [NSString stringWithFormat:@"ledger-corrupt-%.0f.json",
                            [NSDate date].timeIntervalSince1970];
    NSURL *backupURL = [[fileURL URLByDeletingLastPathComponent]
                        URLByAppendingPathComponent:backupName];
    [NSFileManager.defaultManager moveItemAtURL:fileURL toURL:backupURL error:NULL];
    return [[LBLedger alloc] init];
}

#pragma mark - 外觀

- (void)lb_settingsDidChange:(NSNotification *)notification {
    [self lb_applyAppearance];
}

- (void)lb_applyAppearance {
    switch (self.settings.appearance) {
        case LBAppearanceLight:
            self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
            break;
        case LBAppearanceDark:
            self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
            break;
        default:
            self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
            break;
    }
}

#pragma mark - Tab

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
