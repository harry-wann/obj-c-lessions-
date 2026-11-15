#import "LBSearchController.h"
#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBCategory.h"

@implementation LBSearchController

- (instancetype)initWithLedger:(LBLedger *)ledger {
    NSParameterAssert(ledger != nil);
    if ((self = [super init])) {
        _ledger = ledger;
        _debounceInterval = 0.25;
        // TODO: M10 — NSOperationQueue（maxConcurrentOperationCount = 1）
    }
    return self;
}

- (void)search:(NSString *)query results:(LBSearchResultsBlock)results {
    // TODO: M10 — 1. _generation += 1，記下這次的世代；取消佇列裡的舊 operation
    //            2. dispatch_after(debounceInterval) 回主佇列：世代已經變了就作廢（debounce）
    //            3. NSBlockOperation 背景過濾 ledger.transactions（備註 / 分類名，不分大小寫），
    //               每幾百筆檢查 isCancelled；simulatedLatency > 0 時先等那麼久（測試用）
    //            4. 回主佇列：世代還是最新的才呼叫 results（舊結果晚到就丟掉）
}

- (void)cancel {
    // TODO: M10 — 世代 +1、cancelAllOperations
}

@end
