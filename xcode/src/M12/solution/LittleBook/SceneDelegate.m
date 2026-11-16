#import "SceneDelegate.h"
#import "LBLedger.h"
#import "LBUndoStack.h"
#import "LBSettings.h"
#import "LBPersistence.h"
#import "LBTransactionListViewController.h"
#import "LBSettingsViewController.h"
#import "LBFPSMonitor.h"
// 12.2：編譯器自動產生的 Swift → ObjC 標頭（StatsViewController 等）。只能在 .m 裡 import：
// 放進 .h 會和橋接標頭形成循環，錯誤時有時無。
#import "LittleBook-Swift.h"

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
    // 主畫面不用 Storyboard：自己建立 UIWindow 與 tab bar（只有設定頁來自 Settings.storyboard）。
    UIWindowScene *windowScene = (UIWindowScene *)scene;

    self.settings = LBSettings.shared;
    NSURL *directory = [LBPersistence defaultDirectoryURL];
    self.persistence = [[LBPersistence alloc] initWithDirectoryURL:directory];
    self.ledger = [self lb_loadLedger];
    self.undoStack = [[LBUndoStack alloc] init];

    LBTransactionListViewController *list =
        [[LBTransactionListViewController alloc] initWithLedger:self.ledger
                                                      undoStack:self.undoStack];
    // M12：統計頁是 Swift 寫的（StatsViewController.swift），ObjC 端用起來跟一般類別一樣
    StatsViewController *stats = [[StatsViewController alloc] initWithLedger:self.ledger];
    // M11：設定頁改從 Settings.storyboard 載入（外層的 UINavigationController 也在 storyboard 裡）
    UIViewController *settingsTab = [self lb_makeSettingsTab];

    UITabBarController *tabBar = [[UITabBarController alloc] init];
    tabBar.viewControllers = @[
        [self lb_tabWrapping:list title:@"帳本" symbol:@"list.bullet.rectangle"],
        [self lb_tabWrapping:stats title:@"統計" symbol:@"chart.bar"],
        settingsTab,
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

/// 11.3：instantiateInitialViewController 回的是 storyboard 的 initial VC（包著設定頁的
/// UINavigationController）。Storyboard 建 VC 走 initWithCoder:，不能用 initWithSettings:…，
/// 所以相依性在這裡用屬性注入；一定要在 view 載入（第一次顯示）之前做完。
- (UIViewController *)lb_makeSettingsTab {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:LBSettingsStoryboardName
                                                         bundle:nil];
    UIViewController *initial = [storyboard instantiateInitialViewController];
    UINavigationController *nav = nil;
    UIViewController *root = initial;
    if ([initial isKindOfClass:[UINavigationController class]]) {
        nav = (UINavigationController *)initial;
        root = nav.topViewController;
    }
    if (![root isKindOfClass:[LBSettingsViewController class]]) {
        // storyboard 被改壞（initial VC 不是設定頁）：開發時立刻爆，正式版退回空白頁不要 crash
        NSAssert(NO, @"Settings.storyboard 的 initial VC 要是包著 LBSettingsViewController 的 nav");
        return [self lb_tabWrapping:[self lb_placeholderWithTitle:@"設定"
                                                          message:@"Settings.storyboard 載入失敗"]
                              title:@"設定"
                             symbol:@"gearshape"];
    }
    LBSettingsViewController *settings = (LBSettingsViewController *)root;
    settings.settings = self.settings;
    settings.ledger = self.ledger;
    settings.undoStack = self.undoStack;
    settings.persistence = self.persistence;
    if (nav == nil) {
        return [self lb_tabWrapping:settings title:@"設定" symbol:@"gearshape"];
    }
    nav.navigationBar.prefersLargeTitles = YES;
    nav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"設定"
                                                   image:[UIImage systemImageNamed:@"gearshape"]
                                                     tag:0];
    return nav;
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
