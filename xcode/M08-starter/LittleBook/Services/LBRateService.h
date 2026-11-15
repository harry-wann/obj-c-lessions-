@import Foundation;
#import "LBTypes.h"

NS_ASSUME_NONNULL_BEGIN

/// 匯率回呼：成功時 rates 非 nil、error 為 nil；失敗相反。永遠在主佇列呼叫。
typedef void (^LBRatesCompletion)(NSDictionary<NSString *, NSDecimalNumber *> * _Nullable rates,
                                  NSError * _Nullable error);

/// HTTP 錯誤的 userInfo key，值是 NSNumber（狀態碼）。
extern NSString * const LBRateServiceHTTPStatusCodeKey;

/// 用 NSURLSession 抓匯率 JSON：{"base":"USD","rates":{"TWD":32.15,"JPY":149.5}}。
/// session 與 baseURL 由外部注入：測試時可以塞進掛了 LBStubURLProtocol 的 session，不打網路。
@interface LBRateService : NSObject

@property (nonatomic, strong, readonly) NSURLSession *session;
@property (nonatomic, copy, readonly) NSURL *baseURL;

- (instancetype)initWithSession:(NSURLSession *)session
                        baseURL:(NSURL *)baseURL NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 純解析，不碰網路，可直接單測。
/// 非數字的匯率回 LBErrorCodeUnexpectedType、壞 JSON 回 LBErrorCodeMalformedJSON、NSNull 跳過。
+ (nullable NSDictionary<NSString *, NSDecimalNumber *> *)ratesFromJSONData:(NSData *)data
                                                                        error:(NSError **)error;

/// GET {baseURL}/latest?base={base}；HTTP 非 2xx 回 LBErrorCodeHTTPStatus；回呼切回主佇列。
- (void)fetchRatesForBase:(NSString *)base completion:(LBRatesCompletion)completion;

/// 多個基準幣別並行抓取，semaphore 限流 + dispatch_group 等全部完成（M10 才實作）。
- (void)fetchRatesForBases:(NSArray<NSString *> *)bases
             maxConcurrent:(NSUInteger)max
                completion:(void (^)(NSDictionary<NSString *, NSDictionary *> *results,
                                     NSArray<NSError *> *errors))completion;

@end

NS_ASSUME_NONNULL_END
