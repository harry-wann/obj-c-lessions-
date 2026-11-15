#import "LBPerformanceViewController.h"
#import "LBFPSMonitor.h"
#import "LBRingBuffer.h"
#import "LBFrameHistoryView.h"
#import "LBImportService.h"
#import "LBSearchController.h"
#import "LBLockBenchmark.h"
#import "LBRateService.h"
#import "LBLedger.h"

@implementation LBPerformanceViewController

- (instancetype)initWithLedger:(LBLedger *)ledger {
    NSParameterAssert(ledger != nil);
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _ledger = ledger;
        _importCount = 100000;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"效能面板";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    // TODO: M10 — 畫面 10：
    //   1. FPS 卡片：觀察 LBFPSMonitorDidUpdateNotification，顯示 fps / lastFrameMilliseconds /
    //      droppedFrameCount（viewWillAppear 開 monitor、viewWillDisappear 關）
    //   2. LBFrameHistoryView 顯示 history.values（最近 60 幀）
    //   3. 壓力測試：匯入 importCount 筆（LBImportService，可取消）、自動捲動、搜尋、
    //      並行請求 50 個限流 4（fetchRatesForBases:maxConcurrent:）、新增 + 復原、鎖 benchmark
    //      （LBLockBenchmark 一定要在背景跑）
    //   4. 量測列：每一項的目標值與實測值
}

@end
