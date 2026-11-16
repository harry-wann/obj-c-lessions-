#import "LBPerformanceViewController.h"
#import "LBFPSMonitor.h"
#import "LBRingBuffer.h"
#import "LBFrameHistoryView.h"
#import "LBImportService.h"
#import "LBSearchController.h"
#import "LBLockBenchmark.h"
#import "LBRateService.h"
#import "LBLedger.h"
#import "LBUndoStack.h"
#import "LBTransaction.h"

/// 並行請求壓力測試用的公開匯率 API（格式和 LBRateService 期待的一樣：{"base":…, "rates":{…}}）。
static NSString * const LBPerformanceRateBaseURL = @"https://api.frankfurter.app";
static const NSUInteger LBPerformanceRequestCount = 50;
static const NSUInteger LBPerformanceRequestLimit = 4;
static const NSUInteger LBPerformanceUndoRounds = 200;

/// 量測列的種類。
typedef NS_ENUM(NSInteger, LBMetric) {
    LBMetricFPS,
    LBMetricWorstFrame,
    LBMetricImport,
    LBMetricSearch,
    LBMetricRequests,
    LBMetricUndo,
    LBMetricLocks,
    LBMetricCount,
};

@interface LBPerformanceViewController ()
@property (nonatomic, strong, nullable) NSProgress *importProgress;
@property (nonatomic, strong, nullable) LBImportService *importService;
@property (nonatomic, strong, nullable) LBSearchController *searchController;
@property (nonatomic, strong, nullable) NSTimer *autoScrollTimer;
@end

@implementation LBPerformanceViewController {
    UILabel *_fpsLabel;
    UILabel *_frameDetailLabel;
    UIView *_statusDot;
    LBFrameHistoryView *_historyView;
    UILabel *_historyCaption;
    UIProgressView *_importProgressView;
    UILabel *_importStatusLabel;
    UIButton *_importButton;
    NSMutableArray<UILabel *> *_metricValueLabels;   // index = LBMetric
    BOOL _startedMonitor;                             // 是這頁開的 monitor，離開時才關
}

- (instancetype)initWithLedger:(LBLedger *)ledger {
    NSParameterAssert(ledger != nil);
    if ((self = [super initWithNibName:nil bundle:nil])) {
        [self lb_commonInitWithLedger:ledger];
    }
    return self;
}

/// M11：從 Settings.storyboard 的 showPerformance segue 建立時走這裡。
/// 先放一本空帳本讓 ledger 維持 nonnull；設定頁的 prepareForSegue: 會換成真正的帳本。
- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        [self lb_commonInitWithLedger:[[LBLedger alloc] init]];
    }
    return self;
}

- (void)lb_commonInitWithLedger:(LBLedger *)ledger {
    _ledger = ledger;
    _importCount = 100000;
    _metricValueLabels = [NSMutableArray array];
}

- (LBFPSMonitor *)monitor {
    return _monitor ?: [LBFPSMonitor shared];   // null_resettable：沒注入就用單例
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_importProgress cancel];
    [_autoScrollTimer invalidate];
}

#pragma mark - 生命週期

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"效能面板";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    [self lb_buildLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    LBFPSMonitor *monitor = self.monitor;
    if (!monitor.isRunning) {
        [monitor start];
        _startedMonitor = YES;
    }
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(lb_monitorDidUpdate:)
                                               name:LBFPSMonitorDidUpdateNotification
                                             object:monitor];
    [self lb_refreshMonitor];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:LBFPSMonitorDidUpdateNotification
                                                object:nil];
    if (_startedMonitor) {
        [self.monitor stop];
        _startedMonitor = NO;
    }
}

#pragma mark - 版面

- (void)lb_buildLayout {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.alwaysBounceVertical = YES;
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scrollView];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    stack.layoutMarginsRelativeArrangement = YES;
    stack.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(16, 16, 32, 16);
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:stack];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [stack.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],
    ]];

    [stack addArrangedSubview:[self lb_sectionTitle:@"即時"]];
    [stack addArrangedSubview:[self lb_cardWrapping:[self lb_makeFPSCard]]];
    [stack addArrangedSubview:[self lb_cardWrapping:[self lb_makeHistoryCard]]];
    [stack addArrangedSubview:[self lb_sectionTitle:@"壓力測試"]];
    [stack addArrangedSubview:[self lb_cardWrapping:[self lb_makeStressCard]]];
    [stack addArrangedSubview:[self lb_sectionTitle:@"量測與驗收目標"]];
    [stack addArrangedSubview:[self lb_cardWrapping:[self lb_makeMetricsCard]]];
}

- (UILabel *)lb_sectionTitle:(NSString *)title {
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    label.textColor = UIColor.secondaryLabelColor;
    return label;
}

/// 圓角卡片。圓角直接設在不透明的背景上、不開 masksToBounds：不會觸發離屏渲染。
- (UIView *)lb_cardWrapping:(UIView *)content {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    card.layer.cornerRadius = 12;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
        [content.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
        [content.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-12],
        [content.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [content.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
    ]];
    return card;
}

- (UIView *)lb_makeFPSCard {
    _fpsLabel = [[UILabel alloc] init];
    _fpsLabel.font = [UIFont monospacedDigitSystemFontOfSize:48 weight:UIFontWeightBold];
    _fpsLabel.text = @"--";

    UILabel *unit = [[UILabel alloc] init];
    unit.text = @"FPS";
    unit.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    unit.textColor = UIColor.secondaryLabelColor;

    _statusDot = [[UIView alloc] init];
    _statusDot.backgroundColor = UIColor.systemGrayColor;
    _statusDot.layer.cornerRadius = 6;
    [_statusDot.widthAnchor constraintEqualToConstant:12].active = YES;
    [_statusDot.heightAnchor constraintEqualToConstant:12].active = YES;

    UIStackView *top =
        [[UIStackView alloc] initWithArrangedSubviews:@[_fpsLabel, unit, _statusDot]];
    top.alignment = UIStackViewAlignmentFirstBaseline;
    top.spacing = 8;

    _frameDetailLabel = [[UILabel alloc] init];
    _frameDetailLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];
    _frameDetailLabel.textColor = UIColor.secondaryLabelColor;
    _frameDetailLabel.numberOfLines = 0;

    UIStackView *card = [[UIStackView alloc] initWithArrangedSubviews:@[top, _frameDetailLabel]];
    card.axis = UILayoutConstraintAxisVertical;
    card.spacing = 4;
    return card;
}

- (UIView *)lb_makeHistoryCard {
    _historyView = [[LBFrameHistoryView alloc] initWithFrame:CGRectZero];
    [_historyView.heightAnchor constraintEqualToConstant:96].active = YES;

    _historyCaption = [[UILabel alloc] init];
    _historyCaption.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    _historyCaption.textColor = UIColor.secondaryLabelColor;
    _historyCaption.text = @"最近 60 幀（虛線 = 16.7 ms 預算）";

    UIStackView *card = [[UIStackView alloc] initWithArrangedSubviews:@[_historyView,
                                                                        _historyCaption]];
    card.axis = UILayoutConstraintAxisVertical;
    card.spacing = 8;
    return card;
}

- (UIButton *)lb_buttonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeading;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;
    return button;
}

- (UIView *)lb_makeStressCard {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSString *count = [formatter stringFromNumber:@(self.importCount)] ?: @"";
    _importButton = [self lb_buttonWithTitle:[NSString stringWithFormat:@"匯入 %@ 筆測試資料", count]
                                      action:@selector(lb_importTapped)];
    _importProgressView =
        [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _importStatusLabel = [[UILabel alloc] init];
    _importStatusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    _importStatusLabel.textColor = UIColor.secondaryLabelColor;
    _importStatusLabel.text = @"匯入期間試著捲動、切分頁：UI 必須保持可操作。";
    _importStatusLabel.numberOfLines = 0;

    NSString *requestTitle = [NSString stringWithFormat:@"並行請求 %lu 個（限流 %lu）",
                              (unsigned long)LBPerformanceRequestCount,
                              (unsigned long)LBPerformanceRequestLimit];
    NSString *undoTitle = [NSString stringWithFormat:@"新增 + 復原 %lu 次",
                           (unsigned long)LBPerformanceUndoRounds];
    UIStackView *card = [[UIStackView alloc] initWithArrangedSubviews:@[
        _importButton,
        _importProgressView,
        _importStatusLabel,
        [self lb_buttonWithTitle:@"自動捲動帳本 5 秒" action:@selector(lb_autoScrollTapped)],
        [self lb_buttonWithTitle:@"搜尋「午餐」（全部交易）" action:@selector(lb_searchTapped)],
        [self lb_buttonWithTitle:requestTitle action:@selector(lb_requestsTapped)],
        [self lb_buttonWithTitle:undoTitle action:@selector(lb_undoTapped)],
        [self lb_buttonWithTitle:@"鎖 benchmark（四種）" action:@selector(lb_locksTapped)],
    ]];
    card.axis = UILayoutConstraintAxisVertical;
    card.spacing = 6;
    return card;
}

- (UIView *)lb_makeMetricsCard {
    NSArray<NSArray<NSString *> *> *rows = @[
        @[@"捲動 FPS", @"≥ 58"],
        @[@"最近 60 幀最長", @"< 16.7 ms"],
        @[@"匯入 10 萬筆", @"< 20 s"],
        @[@"搜尋", @"< 100 ms"],
        @[@"並行請求", @"限流 4、無執行緒爆炸"],
        @[@"新增 + 復原", @"UI 不卡"],
        @[@"鎖 benchmark", @"四種都有數字"],
    ];
    NSAssert(rows.count == (NSUInteger)LBMetricCount, @"量測列與 LBMetric 不一致");
    UIStackView *card = [[UIStackView alloc] init];
    card.axis = UILayoutConstraintAxisVertical;
    card.spacing = 10;
    for (NSArray<NSString *> *row in rows) {
        UILabel *title = [[UILabel alloc] init];
        title.text = row[0];
        title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

        UILabel *target = [[UILabel alloc] init];
        target.text = [NSString stringWithFormat:@"目標 %@", row[1]];
        target.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        target.textColor = UIColor.secondaryLabelColor;

        UIStackView *left = [[UIStackView alloc] initWithArrangedSubviews:@[title, target]];
        left.axis = UILayoutConstraintAxisVertical;
        left.spacing = 2;

        UILabel *value = [[UILabel alloc] init];
        value.text = @"—";
        value.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightSemibold];
        value.textAlignment = NSTextAlignmentRight;
        value.numberOfLines = 0;
        [value setContentCompressionResistancePriority:UILayoutPriorityRequired
                                               forAxis:UILayoutConstraintAxisHorizontal];
        [_metricValueLabels addObject:value];

        UIStackView *line = [[UIStackView alloc] initWithArrangedSubviews:@[left, value]];
        line.alignment = UIStackViewAlignmentCenter;
        line.spacing = 12;
        [card addArrangedSubview:line];
    }
    return card;
}

- (void)lb_setMetric:(LBMetric)metric text:(NSString *)text good:(BOOL)good {
    if ((NSUInteger)metric >= _metricValueLabels.count) {
        return;
    }
    UILabel *label = _metricValueLabels[(NSUInteger)metric];
    label.text = text;
    label.textColor = good ? UIColor.systemGreenColor : UIColor.systemRedColor;
}

#pragma mark - FPS

- (void)lb_monitorDidUpdate:(NSNotification *)notification {
    [self lb_refreshMonitor];
}

- (void)lb_refreshMonitor {
    if (!self.isViewLoaded) {
        return;
    }
    LBFPSMonitor *monitor = self.monitor;
    LBRingBuffer *history = monitor.history;
    double fps = monitor.fps;
    _fpsLabel.text = fps > 0 ? [NSString stringWithFormat:@"%.0f", fps] : @"--";
    _frameDetailLabel.text =
        [NSString stringWithFormat:@"上一幀 %.1f ms · 平均 %.1f ms · 最長 %.1f ms · 掉幀 %lu",
         monitor.lastFrameMilliseconds, history.average, history.max,
         (unsigned long)monitor.droppedFrameCount];
    switch ([LBFPSMonitor classifyFrameDuration:history.max]) {
        case LBFrameClassNormal:
            _statusDot.backgroundColor = UIColor.systemGreenColor;
            break;
        case LBFrameClassWarning:
            _statusDot.backgroundColor = UIColor.systemOrangeColor;
            break;
        default:
            _statusDot.backgroundColor = UIColor.systemRedColor;
            break;
    }
    _historyView.values = history.values;
    if (fps > 0) {
        [self lb_setMetric:LBMetricFPS
                      text:[NSString stringWithFormat:@"%.0f", fps]
                      good:fps >= 58];
        [self lb_setMetric:LBMetricWorstFrame
                      text:[NSString stringWithFormat:@"%.1f ms", history.max]
                      good:history.max < 16.7];
    }
}

#pragma mark - 壓力測試：匯入

- (void)lb_importTapped {
    if (self.importProgress != nil) {
        [self.importProgress cancel];   // 第二次按 = 取消
        return;
    }
    _importButton.enabled = NO;
    _importStatusLabel.text = @"產生測試資料中…";
    NSUInteger count = self.importCount;
    __weak typeof(self) weakSelf = self;
    // 產生 CSV 也是重活：丟背景，不卡主執行緒
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        NSURL *url = [LBImportService generateSampleCSVWithCount:count error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf lb_startImportFromURL:url error:error];
        });
    });
}

- (void)lb_startImportFromURL:(nullable NSURL *)url error:(nullable NSError *)error {
    _importButton.enabled = YES;
    if (url == nil) {
        _importStatusLabel.text = [NSString stringWithFormat:@"產生失敗：%@",
                                   error.localizedDescription ?: @"未知錯誤"];
        return;
    }
    [_importButton setTitle:@"取消匯入" forState:UIControlStateNormal];
    _importProgressView.progress = 0;
    self.importService = [[LBImportService alloc] initWithLedger:self.ledger];
    NSTimeInterval start = NSProcessInfo.processInfo.systemUptime;
    __weak typeof(self) weakSelf = self;
    self.importProgress = [self.importService importCSVAtURL:url
                                                   batchSize:500
                                                    progress:^(NSUInteger done, NSUInteger total) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil || total == 0) {
            return;
        }
        strongSelf->_importProgressView.progress = (float)done / (float)total;
        strongSelf->_importStatusLabel.text =
            [NSString stringWithFormat:@"%lu / %lu", (unsigned long)done, (unsigned long)total];
    } completion:^(NSError *importError) {
        typeof(self) strongSelf = weakSelf;
        [NSFileManager.defaultManager removeItemAtURL:url error:NULL];
        if (strongSelf == nil) {
            return;
        }
        NSTimeInterval elapsed = NSProcessInfo.processInfo.systemUptime - start;
        strongSelf.importProgress = nil;
        strongSelf.importService = nil;
        [strongSelf->_importButton setTitle:@"再匯入一次" forState:UIControlStateNormal];
        if (importError != nil) {
            strongSelf->_importStatusLabel.text = importError.localizedDescription;
            return;
        }
        strongSelf->_importStatusLabel.text =
            [NSString stringWithFormat:@"完成，帳本共 %lu 筆",
             (unsigned long)strongSelf.ledger.transactions.count];
        [strongSelf lb_setMetric:LBMetricImport
                            text:[NSString stringWithFormat:@"%.1f s", elapsed]
                            good:elapsed < 20];
    }];
}

#pragma mark - 壓力測試：自動捲動

- (void)lb_autoScrollTapped {
    // 切到「帳本」分頁，找到它的 table view，每 0.25 秒往下捲一段，5 秒後停
    UITabBarController *tabBar = self.tabBarController;
    UINavigationController *nav = (UINavigationController *)tabBar.viewControllers.firstObject;
    UIViewController *top = [nav isKindOfClass:[UINavigationController class]]
        ? nav.viewControllers.firstObject : nil;
    if (![top isKindOfClass:[UITableViewController class]]) {
        return;
    }
    UITableView *tableView = ((UITableViewController *)top).tableView;
    tabBar.selectedIndex = 0;
    [self.autoScrollTimer invalidate];
    __block NSUInteger ticks = 0;
    self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                           repeats:YES
                                                             block:^(NSTimer *timer) {
        ticks += 1;
        CGFloat maxOffset = MAX(tableView.contentSize.height - tableView.bounds.size.height, 0);
        CGPoint offset = tableView.contentOffset;
        offset.y = MIN(offset.y + 1200, maxOffset);
        [tableView setContentOffset:offset animated:YES];
        if (ticks >= 20 || offset.y >= maxOffset) {
            [timer invalidate];
        }
    }];
}

#pragma mark - 壓力測試：搜尋

- (void)lb_searchTapped {
    if (self.searchController == nil) {
        self.searchController = [[LBSearchController alloc] initWithLedger:self.ledger];
        self.searchController.debounceInterval = 0;
    }
    __weak typeof(self) weakSelf = self;
    [self.searchController search:@"午餐" results:^(NSArray<LBTransaction *> *results,
                                                    NSString *query) {
        typeof(self) strongSelf = weakSelf;
        NSTimeInterval ms = strongSelf.searchController.lastDuration * 1000;
        [strongSelf lb_setMetric:LBMetricSearch
                            text:[NSString stringWithFormat:@"%.0f ms（%lu 筆）", ms,
                                  (unsigned long)results.count]
                            good:ms < 100];
    }];
}

#pragma mark - 壓力測試：並行請求

- (void)lb_requestsTapped {
    NSArray<NSString *> *codes = @[@"USD", @"EUR", @"JPY", @"GBP", @"CNY"];
    NSMutableArray<NSString *> *bases = [NSMutableArray array];
    for (NSUInteger i = 0; i < LBPerformanceRequestCount; i++) {
        [bases addObject:codes[i % codes.count]];
    }
    LBRateService *service =
        [[LBRateService alloc] initWithSession:NSURLSession.sharedSession
                                       baseURL:[NSURL URLWithString:LBPerformanceRateBaseURL]];
    [self lb_setMetric:LBMetricRequests text:@"進行中…" good:YES];
    NSTimeInterval start = NSProcessInfo.processInfo.systemUptime;
    __weak typeof(self) weakSelf = self;
    [service fetchRatesForBases:bases
                  maxConcurrent:LBPerformanceRequestLimit
                     completion:^(NSDictionary<NSString *, NSDictionary *> *results,
                                  NSArray<NSError *> *errors) {
        NSTimeInterval elapsed = NSProcessInfo.processInfo.systemUptime - start;
        // 相同 base 會覆蓋，所以成功數用「總數 − 失敗數」
        NSUInteger succeeded = LBPerformanceRequestCount - MIN(errors.count,
                                                               LBPerformanceRequestCount);
        [weakSelf lb_setMetric:LBMetricRequests
                          text:[NSString stringWithFormat:@"%.1f s · 成功 %lu / 失敗 %lu",
                                elapsed, (unsigned long)succeeded, (unsigned long)errors.count]
                          good:errors.count == 0];
    }];
}

#pragma mark - 壓力測試：新增 + 復原

- (void)lb_undoTapped {
    // 用自己的 undo 堆疊，不污染帳本頁的「復原」
    LBUndoStack *stack = [[LBUndoStack alloc] init];
    LBLedger *ledger = self.ledger;
    NSTimeInterval start = NSProcessInfo.processInfo.systemUptime;
    for (NSUInteger i = 0; i < LBPerformanceUndoRounds; i++) {
        LBTransaction *tx = [LBTransaction expenseWithAmount:[NSDecimalNumber one]
                                                        note:@"壓力測試"];
        [ledger addTransaction:tx];
        [stack registerUndo:^{
            [ledger removeTransactionWithIdentifier:tx.identifier];
        } redo:^{
            [ledger addTransaction:tx];
        }];
    }
    while (stack.canUndo) {
        [stack undo];
    }
    NSTimeInterval ms = (NSProcessInfo.processInfo.systemUptime - start) * 1000;
    double perRound = ms / (double)LBPerformanceUndoRounds;
    [self lb_setMetric:LBMetricUndo
                  text:[NSString stringWithFormat:@"%.0f ms（每次 %.2f ms）", ms, perRound]
                  good:perRound < 8];
}

#pragma mark - 壓力測試：鎖

- (void)lb_locksTapped {
    [self lb_setMetric:LBMetricLocks text:@"量測中…" good:YES];
    __weak typeof(self) weakSelf = self;
    // benchmark 會把 CPU 吃滿好一陣子：一定在背景跑
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSDictionary<NSString *, NSNumber *> *times = [LBLockBenchmark runWithIterations:100000
                                                                                  threads:4];
        NSMutableArray<NSString *> *parts = [NSMutableArray array];
        for (NSString *key in [LBLockBenchmark allKeys]) {
            [parts addObject:[NSString stringWithFormat:@"%@ %.0f ms", key,
                              times[key].doubleValue * 1000]];
        }
        NSString *text = [parts componentsJoinedByString:@"\n"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf lb_setMetric:LBMetricLocks text:text good:times.count == 4];
        });
    });
}

@end
