@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// 測試用的假網路層：NSURLProtocol 子類別，依 URL path 回預先登記的 JSON 與狀態碼，不打網路。
/// 用法：把它放進 NSURLSessionConfiguration.protocolClasses（見 +stubbedSession）。
@interface LBStubURLProtocol : NSURLProtocol

/// 登記 path（例如 @"/api/latest"）的回應；沒登記的 path 一律回 404 空 body。
+ (void)stubPath:(NSString *)path statusCode:(NSInteger)statusCode data:(NSData *)data;
+ (void)stubPath:(NSString *)path statusCode:(NSInteger)statusCode JSONObject:(id)object;
+ (void)removeAllStubs;

/// ephemeral configuration + protocolClasses = @[self] 的 session。
+ (NSURLSession *)stubbedSession;

@end

NS_ASSUME_NONNULL_END
