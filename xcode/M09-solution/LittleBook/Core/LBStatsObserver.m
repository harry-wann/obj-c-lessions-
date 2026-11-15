#import "LBStatsObserver.h"
#import "LBLedger.h"

/// 用這個變數自己的位址當 context：全程式唯一、不會和其他 KVO 註冊撞到。
static void *LBStatsObserverTotalContext = &LBStatsObserverTotalContext;

@implementation LBStatsObserver

- (instancetype)initWithLedger:(LBLedger *)ledger {
    NSParameterAssert(ledger != nil);
    if ((self = [super init])) {
        _ledger = ledger;
        _lastTotal = ledger.total;
        [_ledger addObserver:self
                  forKeyPath:NSStringFromSelector(@selector(total))
                     options:NSKeyValueObservingOptionNew
                     context:LBStatsObserverTotalContext];
    }
    return self;
}

- (void)dealloc {
    // 註冊與移除成對出現；少了這行就是「deallocated while key value observers were still
    // registered」或對已釋放物件送訊息的 crash。
    [_ledger removeObserver:self
                 forKeyPath:NSStringFromSelector(@selector(total))
                    context:LBStatsObserverTotalContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
    if (context != LBStatsObserverTotalContext) {
        // 不是我們註冊的觀察：交給 super，父類別可能也在觀察別的東西。
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    id newValue = change[NSKeyValueChangeNewKey];
    if ([newValue isKindOfClass:[NSDecimalNumber class]]) {
        _lastTotal = newValue;
    }
    _changeCount += 1;
    if (self.onChange != nil) {
        self.onChange(_lastTotal);
    }
}

@end
