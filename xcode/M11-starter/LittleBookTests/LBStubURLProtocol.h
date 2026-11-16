@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// 測試用的假網路層：NSURLProtocol 子類別，依 URL path 回預先登記的 JSON 與狀態碼，不打網路。
/// 用法：把它放進 NSURLSessionConfiguration.protocolClasses（見 +stubbedSession）。
/// M10：可設定回應延遲，並統計「同時在飛」的請求數最高到多少（驗證 semaphore 限流）。
@interface LBStubURLProtocol : NSURLProtocol

/// 登記 path（例如 @"/api/latest"）的回應；沒登記的 path 一律回 404 空 body。
+ (void)stubPath:(NSString *)path statusCode:(NSInteger)statusCode data:(NSData *)data;
+ (void)stubPath:(NSString *)path statusCode:(NSInteger)statusCode JSONObject:(id)object;
/// 同時清掉延遲設定與並行統計。
+ (void)removeAllStubs;

/// ephemeral configuration + protocolClasses = @[self] 的 session。
+ (NSURLSession *)stubbedSession;

/// M10：每個請求等這麼久才回應（預設 0 = 立刻回）。
+ (void)setResponseDelay:(NSTimeInterval)delay;
/// M10：自上次 reset 以來，同時在處理中的請求數最大值。
+ (NSUInteger)maxConcurrentRequests;
/// M10：自上次 reset 以來，總共收到幾個請求。
+ (NSUInteger)totalRequests;
+ (void)resetConcurrencyStats;

@end

NS_ASSUME_NONNULL_END
