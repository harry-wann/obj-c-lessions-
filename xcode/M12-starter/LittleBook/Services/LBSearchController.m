#import "LBSearchController.h"
#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBCategory.h"

/// 每過濾這麼多筆檢查一次 isCancelled：太頻繁浪費、太稀疏取消不及時。
static const NSUInteger LBSearchCancelCheckStride = 512;

@implementation LBSearchController {
    NSOperationQueue *_queue;   // maxConcurrentOperationCount = 1：同時只跑一個過濾
}

- (instancetype)initWithLedger:(LBLedger *)ledger {
    NSParameterAssert(ledger != nil);
    if ((self = [super init])) {
        _ledger = ledger;
        _debounceInterval = 0.25;
        _queue = [[NSOperationQueue alloc] init];
        _queue.name = @"com.littlebook.search";
        _queue.maxConcurrentOperationCount = 1;
        _queue.qualityOfService = NSQualityOfServiceUserInitiated;
    }
    return self;
}

- (void)dealloc {
    [_queue cancelAllOperations];
}

#pragma mark - 對外

- (void)search:(NSString *)query results:(LBSearchResultsBlock)results {
    NSAssert(NSThread.isMainThread, @"LBSearchController 只能在主執行緒使用");
    NSParameterAssert(query != nil);
    NSParameterAssert(results != nil);
    _generation += 1;
    NSUInteger generation = _generation;
    [_queue cancelAllOperations];   // 舊的過濾不必跑完

    NSString *copiedQuery = [query copy];
    LBSearchResultsBlock copiedResults = [results copy];
    NSTimeInterval latency = self.simulatedLatency;
    NSTimeInterval delay = MAX(self.debounceInterval, 0);

    // debounce：等 delay 秒；這段時間內又有新的 search:，世代就變了，這次直接作廢
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil || strongSelf->_generation != generation) {
            return;
        }
        [strongSelf lb_startFilteringQuery:copiedQuery
                                generation:generation
                                   latency:latency
                                   results:copiedResults];
    });
}

- (void)cancel {
    _generation += 1;   // 讓等待中的 debounce 與晚到的結果全部作廢
    [_queue cancelAllOperations];
}

#pragma mark - 過濾

+ (BOOL)lb_transaction:(LBTransaction *)tx matches:(NSString *)query {
    NSStringCompareOptions options = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch
                                   | NSWidthInsensitiveSearch;
    if ([tx.note rangeOfString:query options:options].location != NSNotFound) {
        return YES;
    }
    NSString *categoryName = tx.category.name;
    return categoryName != nil
        && [categoryName rangeOfString:query options:options].location != NSNotFound;
}

- (void)lb_startFilteringQuery:(NSString *)query
                    generation:(NSUInteger)generation
                       latency:(NSTimeInterval)latency
                       results:(LBSearchResultsBlock)results {
    LBLedger *ledger = self.ledger;
    NSString *trimmed =
        [query stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSTimeInterval startedAt = NSProcessInfo.processInfo.systemUptime;

    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakOperation = operation;   // block 不能強持有自己所屬的 operation
    __weak typeof(self) weakSelf = self;
    [operation addExecutionBlock:^{
        NSBlockOperation *op = weakOperation;
        if (op == nil || op.isCancelled) {
            return;
        }
        if (latency > 0) {
            // 模擬慢查詢：分段睡，途中被取消就提早離開
            NSTimeInterval deadline = NSProcessInfo.processInfo.systemUptime + latency;
            while (NSProcessInfo.processInfo.systemUptime < deadline) {
                if (op.isCancelled) {
                    return;
                }
                [NSThread sleepForTimeInterval:0.01];
            }
        }
        NSArray<LBTransaction *> *all = ledger.transactions;   // 帳本的快照，背景讀是安全的
        NSArray<LBTransaction *> *matched = all;
        if (trimmed.length > 0) {
            NSMutableArray<LBTransaction *> *found = [NSMutableArray array];
            NSUInteger index = 0;
            for (LBTransaction *tx in all) {
                if (index % LBSearchCancelCheckStride == 0 && op.isCancelled) {
                    return;   // 有新的查詢了：剩下的不用算
                }
                index += 1;
                if ([LBSearchController lb_transaction:tx matches:trimmed]) {
                    [found addObject:tx];
                }
            }
            matched = [found copy];
        }
        if (op.isCancelled) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) strongSelf = weakSelf;
            // 世代檢查：取消來不及攔住（例如已經算完、正在排隊回主執行緒）時的最後一道防線
            if (strongSelf == nil || strongSelf->_generation != generation) {
                return;
            }
            strongSelf->_lastDuration = NSProcessInfo.processInfo.systemUptime - startedAt;
            results(matched, query);
        });
    }];
    [_queue addOperation:operation];
}

@end
