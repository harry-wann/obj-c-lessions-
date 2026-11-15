@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef void (^LBRateFetcherCompletion)(NSDecimalNumber *rate);

/// 抓單一幣別匯率（這一版是同步 stub，之後的模組才接 NSURLSession）。
@interface LBRateFetcher : NSObject

@property (nonatomic, copy, readonly) NSString *currencyCode;
@property (nonatomic, strong, readonly, nullable) NSDecimalNumber *lastRate;

- (instancetype)initWithCurrencyCode:(NSString *)currencyCode NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)fetchWithCompletion:(LBRateFetcherCompletion)completion;

@end

NS_ASSUME_NONNULL_END
