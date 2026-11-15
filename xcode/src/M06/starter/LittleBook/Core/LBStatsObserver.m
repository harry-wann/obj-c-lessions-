#import "LBStatsObserver.h"
#import "LBLedger.h"

// TODO: M06 — 宣告一個靜態變數，用它的位址當 KVO context
// static void *LBStatsObserverTotalContext = &LBStatsObserverTotalContext;

@implementation LBStatsObserver

- (instancetype)initWithLedger:(LBLedger *)ledger {
    NSParameterAssert(ledger != nil);
    if ((self = [super init])) {
        _ledger = ledger;
        _lastTotal = ledger.total;
        // TODO: M06 — addObserver:forKeyPath:options:context:（keyPath 用
        // NSStringFromSelector(@selector(total)) 避免打錯字）
    }
    return self;
}

- (void)dealloc {
    // TODO: M06 — removeObserver:forKeyPath:context:，與 init 的註冊成對
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
    // TODO: M06 — context 不是自己的就轉給 super；是自己的就更新 _lastTotal、_changeCount、呼叫 onChange
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
