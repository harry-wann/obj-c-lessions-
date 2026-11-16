#import "LBSettingsViewController.h"
#import "LBSettings.h"
#import "LBLedger.h"
#import "LBUndoStack.h"
#import "LBPersistence.h"
#import "LBImportService.h"
#import "LBPerformanceViewController.h"
#import "LBFPSMonitor.h"

// TODO: M11 — 這個檔案還是 M10 的「程式碼版」設定頁。11.3 要做的事：
//   1. 建 Settings.storyboard（放在 LittleBook/Resources/）：static cells、Storyboard ID「Settings」、
//      Embed In Navigation Controller 並設成 initial VC、
//      segue「showPerformance」→ LBPerformanceViewController
//   2. 標頭把 initWithCoder: 的 NS_UNAVAILABLE 換成 NS_DESIGNATED_INITIALIZER，刪掉 initWithSettings:…
//   3. 刪掉下面用程式碼建 UI 的部分（lb_sections / cellForRowAtIndexPath: …），改成 IBOutlet 填值
//   4. prepareForSegue: 把 ledger 與 [LBFPSMonitor shared] 塞給效能頁；SceneDelegate 改從 storyboard 載入
// 跑 LBSettingsStoryboardTests 的三個測試確認。

NSString * const LBSettingsStoryboardName = @"Settings";
NSString * const LBSettingsStoryboardIdentifier = @"Settings";
NSString * const LBSettingsShowPerformanceSegue = @"showPerformance";

static const NSUInteger LBSettingsSampleCount = 100000;

/// 每一列代表的功能。table 的結構由 lb_sections 決定，dataSource / delegate 只看這個表。
typedef NS_ENUM(NSInteger, LBSettingsRow) {
    LBSettingsRowCurrency,
    LBSettingsRowShowsCents,
    LBSettingsRowAppearance,
    LBSettingsRowExportJSON,
    LBSettingsRowImportSample,   // M10
    LBSettingsRowPerformance,    // M10
    LBSettingsRowClearAll,
};

@interface LBSettingsSection : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *footer;
@property (nonatomic, copy) NSArray<NSNumber *> *rows;   // LBSettingsRow
@end

@implementation LBSettingsSection
@end

@interface LBSettingsViewController ()
// TODO: M11 — 從 storyboard 拉 outlet 到這裡（weak、IBOutlet）；目前沒有 storyboard，所以一直是 nil
@property (nonatomic, weak, readwrite, nullable) IBOutlet UILabel *currencyLabel;
@property (nonatomic, weak, readwrite, nullable) IBOutlet UISwitch *centsSwitch;
@property (nonatomic, weak, readwrite, nullable) IBOutlet UILabel *appearanceLabel;
@end

@implementation LBSettingsViewController {
    NSArray<LBSettingsSection *> *_sections;
    UISwitch *_codeCentsSwitch;        // 程式碼版的開關（M11 改由 storyboard 的 centsSwitch 取代）
    LBImportService *_importService;   // M10：匯入進行中才有值
    NSProgress *_importProgress;
    NSString *_importStatus;           // 顯示在匯入那一列的右側
}

@synthesize settings = _settings;

+ (instancetype)instantiateFromStoryboard {
    // 還沒有 Settings.storyboard 時這裡會丟 NSInvalidArgumentException（Could not find a storyboard）
    NSBundle *bundle = [NSBundle bundleForClass:[LBSettingsViewController class]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:LBSettingsStoryboardName
                                                         bundle:bundle];
    return [storyboard instantiateViewControllerWithIdentifier:LBSettingsStoryboardIdentifier];
}

- (LBSettings *)settings {
    return _settings ?: LBSettings.shared;
}

- (instancetype)initWithSettings:(LBSettings *)settings
                          ledger:(LBLedger *)ledger
                       undoStack:(LBUndoStack *)undoStack
                     persistence:(LBPersistence *)persistence {
    NSParameterAssert(settings != nil);
    NSParameterAssert(ledger != nil);
    NSParameterAssert(undoStack != nil);
    NSParameterAssert(persistence != nil);
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _settings = settings;
        _ledger = ledger;
        _undoStack = undoStack;
        _persistence = persistence;
        _sections = @[];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_importProgress cancel];
}

#pragma mark - 生命週期

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"設定";

    _codeCentsSwitch = [[UISwitch alloc] init];
    [_codeCentsSwitch addTarget:self
                         action:@selector(centsSwitchChanged:)
               forControlEvents:UIControlEventValueChanged];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(lb_settingsDidChange:)
                                               name:LBSettingsDidChangeNotification
                                             object:self.settings];
    [self lb_rebuildSections];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self lb_rebuildSections];   // 交易筆數可能在別的分頁變了
    [self.tableView reloadData];
}

#pragma mark - 結構

- (void)lb_rebuildSections {
    LBSettingsSection *general = [[LBSettingsSection alloc] init];
    general.title = @"一般";
    general.rows = @[@(LBSettingsRowCurrency), @(LBSettingsRowShowsCents),
                     @(LBSettingsRowAppearance)];

    LBSettingsSection *data = [[LBSettingsSection alloc] init];
    data.title = @"資料";
    data.footer = [NSString stringWithFormat:@"目前共 %lu 筆交易，存在 App 的沙盒裡。",
                   (unsigned long)self.ledger.transactions.count];
    data.rows = @[@(LBSettingsRowExportJSON), @(LBSettingsRowImportSample),
                  @(LBSettingsRowPerformance)];

    LBSettingsSection *danger = [[LBSettingsSection alloc] init];
    danger.title = @"";
    danger.footer = @"清除後無法復原。";
    danger.rows = @[@(LBSettingsRowClearAll)];

    _sections = @[general, data, danger];
}

- (LBSettingsRow)lb_rowAtIndexPath:(NSIndexPath *)indexPath {
    return (LBSettingsRow)_sections[(NSUInteger)indexPath.section]
        .rows[(NSUInteger)indexPath.row].integerValue;
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)_sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)_sections[(NSUInteger)section].rows.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = _sections[(NSUInteger)section].title;
    return title.length > 0 ? title : nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return _sections[(NSUInteger)section].footer;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 列數很少而且每列長得不一樣：直接建新的 cell，省掉重用時要重設 accessoryView 的麻煩
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                                   reuseIdentifier:nil];
    switch ([self lb_rowAtIndexPath:indexPath]) {
        case LBSettingsRowCurrency:
            cell.textLabel.text = @"主幣別";
            cell.detailTextLabel.text = self.settings.currencyCode;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case LBSettingsRowShowsCents:
            cell.textLabel.text = @"顯示小數位";
            _codeCentsSwitch.on = self.settings.showsCents;
            cell.accessoryView = _codeCentsSwitch;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        case LBSettingsRowAppearance:
            cell.textLabel.text = @"外觀";
            cell.detailTextLabel.text =
                [LBSettingsViewController lb_titleForAppearance:self.settings.appearance];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case LBSettingsRowExportJSON:
            cell.textLabel.text = @"匯出 JSON";
            cell.textLabel.textColor = UIColor.systemBlueColor;
            break;
        case LBSettingsRowImportSample:
            cell.textLabel.text = _importProgress != nil ? @"取消匯入" : @"匯入 100,000 筆測試資料";
            cell.textLabel.textColor = UIColor.systemBlueColor;
            cell.detailTextLabel.text = _importStatus;
            break;
        case LBSettingsRowPerformance:
            cell.textLabel.text = @"效能面板";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case LBSettingsRowClearAll:
            cell.textLabel.text = @"清除全部資料";
            cell.textLabel.textColor = UIColor.systemRedColor;
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            break;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIView *sourceView = [tableView cellForRowAtIndexPath:indexPath] ?: tableView;
    switch ([self lb_rowAtIndexPath:indexPath]) {
        case LBSettingsRowCurrency:
            [self lb_pickCurrencyFrom:sourceView];
            break;
        case LBSettingsRowAppearance:
            [self lb_pickAppearanceFrom:sourceView];
            break;
        case LBSettingsRowExportJSON:
            [self lb_exportFrom:sourceView];
            break;
        case LBSettingsRowImportSample:
            [self lb_importSampleTapped];
            break;
        case LBSettingsRowPerformance:
            [self.navigationController
                pushViewController:[[LBPerformanceViewController alloc] initWithLedger:self.ledger]
                          animated:YES];
            break;
        case LBSettingsRowClearAll:
            [self lb_confirmClearAll];
            break;
        case LBSettingsRowShowsCents:
            break;   // 用開關操作
    }
}

#pragma mark - 一般

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
            settings.currencyCode = code;   // 送出 LBSettingsDidChangeNotification
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

- (IBAction)centsSwitchChanged:(UISwitch *)sender {
    self.settings.showsCents = sender.isOn;
}

#pragma mark - Segue（M11）

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender {
    [super prepareForSegue:segue sender:sender];
    // TODO: M11 — identifier 是 showPerformance 時，拿到 LBPerformanceViewController
    // （包在 UINavigationController 裡要取 topViewController），注入 ledger 與 [LBFPSMonitor shared]
}

- (IBAction)unwindFromPerformance:(UIStoryboardSegue *)segue {
    // TODO: M11（選做）— 效能頁按鈕拖到 Exit 選這個方法，回來時印出 fps
}

- (void)lb_settingsDidChange:(NSNotification *)notification {
    [self lb_rebuildSections];
    [self.tableView reloadData];
}

/// action sheet 在 iPad 一定要有 popover 來源，不然會 crash；iPhone 設了也無害。
- (void)lb_presentSheet:(UIViewController *)sheet from:(UIView *)sourceView {
    sheet.popoverPresentationController.sourceView = sourceView;
    sheet.popoverPresentationController.sourceRect = sourceView.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - 資料

- (void)lb_exportFrom:(UIView *)sourceView {
    // 先存一次最新的內容（背景寫、主佇列回呼），再把檔案交給系統分享面板
    __weak typeof(self) weakSelf = self;
    [self.persistence saveLedger:self.ledger completion:^(NSError *error) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        if (error != nil) {
            [strongSelf lb_showMessage:error.localizedDescription title:@"匯出失敗"];
            return;
        }
        NSArray *items = @[strongSelf.persistence.fileURL];
        UIActivityViewController *share =
            [[UIActivityViewController alloc] initWithActivityItems:items
                                              applicationActivities:nil];
        [strongSelf lb_presentSheet:share from:sourceView];
    }];
}

#pragma mark - 匯入測試資料（M10）

- (void)lb_reloadImportRow {
    for (NSUInteger s = 0; s < _sections.count; s++) {
        NSUInteger row = [_sections[s].rows indexOfObject:@(LBSettingsRowImportSample)];
        if (row != NSNotFound) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:(NSInteger)row inSection:(NSInteger)s];
            [self.tableView reloadRowsAtIndexPaths:@[path]
                                  withRowAnimation:UITableViewRowAnimationNone];
            return;
        }
    }
}

- (void)lb_importSampleTapped {
    if (_importProgress != nil) {
        [_importProgress cancel];   // 進行中再按一次 = 取消
        return;
    }
    _importStatus = @"產生資料中…";
    _importProgress = [NSProgress discreteProgressWithTotalUnitCount:1];   // 先佔位，避免連按
    [self lb_reloadImportRow];
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
    if (url == nil || cancelledEarly) {
        _importProgress = nil;
        _importStatus = url == nil ? @"產生失敗" : @"已取消";
        if (url != nil) {
            [NSFileManager.defaultManager removeItemAtURL:url error:NULL];
        }
        [self lb_reloadImportRow];
        if (error != nil) {
            [self lb_showMessage:error.localizedDescription title:@"無法產生測試資料"];
        }
        return;
    }
    _importService = [[LBImportService alloc] initWithLedger:self.ledger];
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
        [strongSelf lb_reloadImportRow];
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
        [strongSelf lb_rebuildSections];
        [strongSelf.tableView reloadData];
    }];
    [self lb_reloadImportRow];
}

#pragma mark - 清除

- (void)lb_confirmClearAll {
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
    [self.ledger reset];                 // delegate（列表）會收到 ledgerDidReset:
    [self.undoStack removeAllActions];   // 復原堆疊裡的 block 抓著舊交易，一起清掉
    __weak typeof(self) weakSelf = self;
    [self.persistence saveLedger:self.ledger completion:^(NSError *error) {
        typeof(self) strongSelf = weakSelf;
        [strongSelf lb_rebuildSections];
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
