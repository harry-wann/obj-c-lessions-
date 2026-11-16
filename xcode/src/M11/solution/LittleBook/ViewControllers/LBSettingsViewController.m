#import "LBSettingsViewController.h"
#import "LBSettings.h"
#import "LBLedger.h"
#import "LBUndoStack.h"
#import "LBPersistence.h"
#import "LBImportService.h"
#import "LBFPSMonitor.h"
#import "LBPerformanceViewController.h"

NSString * const LBSettingsStoryboardName = @"Settings";
NSString * const LBSettingsStoryboardIdentifier = @"Settings";
NSString * const LBSettingsShowPerformanceSegue = @"showPerformance";

static const NSUInteger LBSettingsSampleCount = 100000;
/// Storyboard 裡「資料」區段的位置（footer 要顯示交易筆數）。
static const NSInteger LBSettingsDataSection = 1;

@interface LBSettingsViewController ()
// Storyboard 連線：weak 是慣例，view 階層已經強持有這些子 view
@property (nonatomic, weak, readwrite, nullable) IBOutlet UILabel *currencyLabel;
@property (nonatomic, weak, readwrite, nullable) IBOutlet UISwitch *centsSwitch;
@property (nonatomic, weak, readwrite, nullable) IBOutlet UILabel *appearanceLabel;
// 用來辨識「點了哪一列」：static cells 不用自己算 indexPath 對照表，比對 cell 本身就好
@property (nonatomic, weak, nullable) IBOutlet UITableViewCell *currencyCell;
@property (nonatomic, weak, nullable) IBOutlet UITableViewCell *appearanceCell;
@property (nonatomic, weak, nullable) IBOutlet UITableViewCell *exportCell;
@property (nonatomic, weak, nullable) IBOutlet UITableViewCell *importCell;
@property (nonatomic, weak, nullable) IBOutlet UITableViewCell *clearAllCell;
@end

@implementation LBSettingsViewController {
    LBImportService *_importService;   // M10：匯入進行中才有值
    NSProgress *_importProgress;
    NSString *_importStatus;           // 顯示在匯入那一列的右側
}

@synthesize settings = _settings;

+ (instancetype)instantiateFromStoryboard {
    // 測試與 App 都用 bundleForClass:：測試時 mainBundle 是 xctest runner，找不到 storyboard
    NSBundle *bundle = [NSBundle bundleForClass:[LBSettingsViewController class]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:LBSettingsStoryboardName
                                                         bundle:bundle];
    UIViewController *vc =
        [storyboard instantiateViewControllerWithIdentifier:LBSettingsStoryboardIdentifier];
    NSAssert([vc isKindOfClass:[LBSettingsViewController class]],
             @"Storyboard ID %@ 的 Class 要設成 LBSettingsViewController",
             LBSettingsStoryboardIdentifier);
    return (LBSettingsViewController *)vc;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    // outlet 還沒連上：這裡只能設純資料，碰 self.currencyLabel 一律是對 nil 送訊息（11.3 Pitfall）。
    // 相依性（ledger 等）也還沒注入：要用它們的事一律放到 viewDidLoad 之後。
    self = [super initWithCoder:coder];
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_importProgress cancel];
}

- (LBSettings *)settings {
    return _settings ?: LBSettings.shared;
}

- (void)setSettings:(nullable LBSettings *)settings {
    NSAssert(!self.isViewLoaded, @"settings 要在 view 載入前注入（通知是在 viewDidLoad 註冊的）");
    _settings = settings;
}

#pragma mark - 生命週期

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"設定";
    // 顏色寫在程式碼：storyboard 裡的 system color 在不同 Xcode 版本存法不同，容易製造 diff
    self.exportCell.textLabel.textColor = UIColor.systemBlueColor;
    self.importCell.textLabel.textColor = UIColor.systemBlueColor;
    self.clearAllCell.textLabel.textColor = UIColor.systemRedColor;

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(lb_settingsDidChange:)
                                               name:LBSettingsDidChangeNotification
                                             object:self.settings];
    [self lb_reloadValues];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self lb_reloadValues];        // 交易筆數可能在別的分頁變了
    [self.tableView reloadData];   // footer 跟著更新；static cells 會留著，不會重建
}

/// 把設定值填進 outlet。只在 viewDidLoad 之後呼叫才有意義。
- (void)lb_reloadValues {
    LBSettings *settings = self.settings;
    self.currencyLabel.text = settings.currencyCode;
    self.centsSwitch.on = settings.showsCents;
    self.appearanceLabel.text =
        [LBSettingsViewController lb_titleForAppearance:settings.appearance];
    self.importCell.textLabel.text =
        _importProgress != nil ? @"取消匯入" : @"匯入 100,000 筆測試資料";
    self.importCell.detailTextLabel.text = _importStatus;
}

+ (NSString *)lb_titleForAppearance:(NSInteger)appearance {
    switch (appearance) {
        case LBAppearanceLight:
            return @"淺色";
        case LBAppearanceDark:
            return @"深色";
        default:
            return @"跟隨系統";
    }
}

#pragma mark - UITableViewDataSource（static cells：只補動態的 footer）

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section != LBSettingsDataSection) {
        return [super tableView:tableView titleForFooterInSection:section];
    }
    if (self.ledger == nil) {
        return @"沒有帳本：資料功能停用。";
    }
    return [NSString stringWithFormat:@"目前共 %lu 筆交易，存在 App 的沙盒裡。清除後無法復原。",
            (unsigned long)self.ledger.transactions.count];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == nil) {
        return;
    }
    // 「效能面板」那列不在這裡：storyboard 的 show segue 會自己觸發，資料在 prepareForSegue: 帶
    if (cell == self.currencyCell) {
        [self lb_pickCurrencyFrom:cell];
    } else if (cell == self.appearanceCell) {
        [self lb_pickAppearanceFrom:cell];
    } else if (cell == self.exportCell) {
        [self lb_exportFrom:cell];
    } else if (cell == self.importCell) {
        [self lb_importSampleTapped];
    } else if (cell == self.clearAllCell) {
        [self lb_confirmClearAll];
    }
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender {
    [super prepareForSegue:segue sender:sender];
    if (![segue.identifier isEqualToString:LBSettingsShowPerformanceSegue]) {
        NSLog(@"[LittleBook] 設定頁沒處理的 segue：%@", segue.identifier);
        return;
    }
    // 目的地若被包在 UINavigationController 裡（例如改成 Present Modally），要往下拿 topViewController
    UIViewController *destination = segue.destinationViewController;
    if ([destination isKindOfClass:[UINavigationController class]]) {
        destination = ((UINavigationController *)destination).topViewController;
    }
    if (![destination isKindOfClass:[LBPerformanceViewController class]]) {
        NSAssert(NO, @"showPerformance 的目的地要是 LBPerformanceViewController，實際是 %@",
                 destination);
        return;
    }
    LBPerformanceViewController *performance = (LBPerformanceViewController *)destination;
    performance.monitor = [LBFPSMonitor shared];
    if (self.ledger != nil) {
        performance.ledger = self.ledger;
    }
}

- (IBAction)unwindFromPerformance:(UIStoryboardSegue *)segue {
    UIViewController *source = segue.sourceViewController;
    if ([source isKindOfClass:[LBPerformanceViewController class]]) {
        NSLog(@"[LittleBook] 從效能面板回來，fps = %.1f",
              ((LBPerformanceViewController *)source).monitor.fps);
    }
}

#pragma mark - 一般

- (IBAction)centsSwitchChanged:(UISwitch *)sender {
    self.settings.showsCents = sender.isOn;   // 送出 LBSettingsDidChangeNotification
}

- (void)lb_pickCurrencyFrom:(UIView *)sourceView {
    UIAlertController *sheet =
        [UIAlertController alertControllerWithTitle:@"主幣別"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];
    LBSettings *settings = self.settings;
    for (NSString *code in [LBSettings supportedCurrencyCodes]) {
        [sheet addAction:[UIAlertAction actionWithTitle:code
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            settings.currencyCode = code;
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self lb_presentSheet:sheet from:sourceView];
}

- (void)lb_pickAppearanceFrom:(UIView *)sourceView {
    UIAlertController *sheet =
        [UIAlertController alertControllerWithTitle:@"外觀"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];
    LBSettings *settings = self.settings;
    for (NSInteger value = LBAppearanceSystem; value <= LBAppearanceDark; value++) {
        NSString *title = [LBSettingsViewController lb_titleForAppearance:value];
        [sheet addAction:[UIAlertAction actionWithTitle:title
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            settings.appearance = value;   // SceneDelegate 收到通知後改 window 的外觀
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self lb_presentSheet:sheet from:sourceView];
}

- (void)lb_settingsDidChange:(NSNotification *)notification {
    [self lb_reloadValues];
}

/// action sheet 在 iPad 一定要有 popover 來源，不然會 crash；iPhone 設了也無害。
- (void)lb_presentSheet:(UIViewController *)sheet from:(UIView *)sourceView {
    sheet.popoverPresentationController.sourceView = sourceView;
    sheet.popoverPresentationController.sourceRect = sourceView.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - 資料

/// 資料功能需要的相依性都注入了才回 YES；否則跳提示。
- (BOOL)lb_requireDataDependencies {
    if (self.ledger != nil && self.persistence != nil) {
        return YES;
    }
    [self lb_showMessage:@"這個設定頁沒有注入帳本，資料功能停用。" title:@"無法執行"];
    return NO;
}

- (void)lb_exportFrom:(UIView *)sourceView {
    if (![self lb_requireDataDependencies]) {
        return;
    }
    LBLedger *ledger = self.ledger;
    LBPersistence *persistence = self.persistence;
    // 先存一次最新的內容（背景寫、主佇列回呼），再把檔案交給系統分享面板
    __weak typeof(self) weakSelf = self;
    [persistence saveLedger:ledger completion:^(NSError *error) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        if (error != nil) {
            [strongSelf lb_showMessage:error.localizedDescription title:@"匯出失敗"];
            return;
        }
        NSArray *items = @[persistence.fileURL];
        UIActivityViewController *share =
            [[UIActivityViewController alloc] initWithActivityItems:items
                                              applicationActivities:nil];
        [strongSelf lb_presentSheet:share from:sourceView];
    }];
}

#pragma mark - 匯入測試資料（M10）

- (void)lb_importSampleTapped {
    if (_importProgress != nil) {
        [_importProgress cancel];   // 進行中再按一次 = 取消
        return;
    }
    if (self.ledger == nil) {
        [self lb_showMessage:@"這個設定頁沒有注入帳本，資料功能停用。" title:@"無法執行"];
        return;
    }
    _importStatus = @"產生資料中…";
    _importProgress = [NSProgress discreteProgressWithTotalUnitCount:1];   // 先佔位，避免連按
    [self lb_reloadValues];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        NSURL *url = [LBImportService generateSampleCSVWithCount:LBSettingsSampleCount
                                                           error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf lb_importFromURL:url error:error];
        });
    });
}

- (void)lb_importFromURL:(nullable NSURL *)url error:(nullable NSError *)error {
    BOOL cancelledEarly = _importProgress.isCancelled;
    LBLedger *ledger = self.ledger;
    if (url == nil || cancelledEarly || ledger == nil) {
        _importProgress = nil;
        _importStatus = url == nil ? @"產生失敗" : @"已取消";
        if (url != nil) {
            [NSFileManager.defaultManager removeItemAtURL:url error:NULL];
        }
        [self lb_reloadValues];
        if (error != nil) {
            [self lb_showMessage:error.localizedDescription title:@"無法產生測試資料"];
        }
        return;
    }
    _importService = [[LBImportService alloc] initWithLedger:ledger];
    NSTimeInterval start = NSProcessInfo.processInfo.systemUptime;
    __weak typeof(self) weakSelf = self;
    _importProgress = [_importService importCSVAtURL:url
                                           batchSize:500
                                            progress:^(NSUInteger done, NSUInteger total) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil || total == 0) {
            return;
        }
        strongSelf->_importStatus = [NSString stringWithFormat:@"%.0f%%",
                                     100.0 * (double)done / (double)total];
        [strongSelf lb_reloadValues];
    } completion:^(NSError *importError) {
        [NSFileManager.defaultManager removeItemAtURL:url error:NULL];
        typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        strongSelf->_importService = nil;
        strongSelf->_importProgress = nil;
        if (importError != nil) {
            strongSelf->_importStatus = importError.localizedDescription;
        } else {
            NSTimeInterval elapsed = NSProcessInfo.processInfo.systemUptime - start;
            strongSelf->_importStatus = [NSString stringWithFormat:@"完成（%.1f s）", elapsed];
        }
        [strongSelf lb_reloadValues];
        [strongSelf.tableView reloadData];
    }];
    [self lb_reloadValues];
}

#pragma mark - 清除

- (void)lb_confirmClearAll {
    if (![self lb_requireDataDependencies]) {
        return;
    }
    // 二次確認：連問兩次，第二次把筆數講清楚
    UIAlertController *first =
        [UIAlertController alertControllerWithTitle:@"清除全部資料？"
                                            message:@"所有交易都會被刪除，也不能復原。"
                                     preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [first addAction:[UIAlertAction actionWithTitle:@"繼續"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        [weakSelf lb_confirmClearAllAgain];
    }]];
    [first addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:first animated:YES completion:nil];
}

- (void)lb_confirmClearAllAgain {
    NSString *message = [NSString stringWithFormat:@"真的要刪除 %lu 筆交易嗎？",
                         (unsigned long)self.ledger.transactions.count];
    UIAlertController *second =
        [UIAlertController alertControllerWithTitle:@"最後確認"
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [second addAction:[UIAlertAction actionWithTitle:@"全部刪除"
                                               style:UIAlertActionStyleDestructive
                                             handler:^(UIAlertAction *action) {
        [weakSelf lb_clearAll];
    }]];
    [second addAction:[UIAlertAction actionWithTitle:@"取消"
                                               style:UIAlertActionStyleCancel
                                             handler:nil]];
    [self presentViewController:second animated:YES completion:nil];
}

- (void)lb_clearAll {
    LBLedger *ledger = self.ledger;
    LBPersistence *persistence = self.persistence;
    if (ledger == nil || persistence == nil) {
        return;
    }
    [ledger reset];                      // delegate（列表）會收到 ledgerDidReset:
    [self.undoStack removeAllActions];   // 復原堆疊裡的 block 抓著舊交易，一起清掉
    __weak typeof(self) weakSelf = self;
    [persistence saveLedger:ledger completion:^(NSError *error) {
        typeof(self) strongSelf = weakSelf;
        [strongSelf.tableView reloadData];
        if (error != nil) {
            [strongSelf lb_showMessage:error.localizedDescription title:@"儲存失敗"];
        }
    }];
}

- (void)lb_showMessage:(NSString *)message title:(NSString *)title {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
