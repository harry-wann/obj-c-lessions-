#import "LBRateFetcher.h"

@interface LBRateFetcher ()
@property (nonatomic, strong, readwrite, nullable) NSDecimalNumber *lastRate;
@end

@implementation LBRateFetcher {
    LBRateFetcherCompletion _pendingCompletion;   // self 持有 block
}

- (instancetype)initWithCurrencyCode:(NSString *)currencyCode {
    NSParameterAssert(currencyCode != nil);
    if ((self = [super init])) {
        _currencyCode = [currencyCode copy];
    }
    return self;
}

- (void)fetchWithCompletion:(nullable LBRateFetcherCompletion)completion {
    // 修正：block 裡不要直接用 self。self → _pendingCompletion → self 會形成循環參考。
    __weak LBRateFetcher *weakSelf = self;
    _pendingCompletion = ^(NSDecimalNumber *rate) {
        LBRateFetcher *strongSelf = weakSelf;   // 先轉 strong，確保 block 執行期間不會變 nil
        if (strongSelf == nil) {
            return;
        }
        strongSelf.lastRate = rate;
        if (completion) {
            completion(rate);
        }
    };

    // 模擬網路回應（同步 stub）
    NSDecimalNumber *stubRate = [NSDecimalNumber decimalNumberWithString:@"31.5"];
    LBRateFetcherCompletion pending = _pendingCompletion;
    _pendingCompletion = nil;   // 用完就放掉，不要一直持有
    if (pending) {
        pending(stubRate);
    }
}

@end
