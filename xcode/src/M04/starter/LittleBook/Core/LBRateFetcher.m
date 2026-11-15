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

- (void)fetchWithCompletion:(LBRateFetcherCompletion)completion {
    // TODO: M04 — block 捕獲 self，而 self 又用 _pendingCompletion 持有 block：循環參考。
    // 改成 weakSelf / strongSelf 樣板，並在用完後把 _pendingCompletion 設為 nil。
    _pendingCompletion = ^(NSDecimalNumber *rate) {
        self.lastRate = rate;
        if (completion) {
            completion(rate);
        }
    };

    // 模擬網路回應（同步 stub）
    NSDecimalNumber *stubRate = [NSDecimalNumber decimalNumberWithString:@"31.5"];
    _pendingCompletion(stubRate);
}

@end
