#import "LBRateService.h"

NSString * const LBRateServiceHTTPStatusCodeKey = @"LBRateServiceHTTPStatusCode";

@implementation LBRateService

- (instancetype)initWithSession:(NSURLSession *)session baseURL:(NSURL *)baseURL {
    NSParameterAssert(session != nil);
    NSParameterAssert(baseURL != nil);
    if ((self = [super init])) {
        _session = session;
        _baseURL = [baseURL copy];
    }
    return self;
}

+ (NSDictionary<NSString *, NSDecimalNumber *> *)ratesFromJSONData:(NSData *)data
                                                             error:(NSError **)error {
    NSParameterAssert(data != nil);
    // TODO: M07 — NSJSONSerialization 解析；root 不是 NSDictionary 或缺 rates → LBErrorCodeMalformedJSON；
    //            逐一檢查值：NSNull 跳過、NSNumber（或數字字串）轉 NSDecimalNumber、
    //            其他型別 → LBErrorCodeUnexpectedType。記得 error 可能是 NULL，寫入前要判。
    if (error != NULL) {
        *error = [NSError errorWithDomain:LBErrorDomain
                                     code:LBErrorCodeMalformedJSON
                                 userInfo:@{NSLocalizedDescriptionKey: @"尚未實作"}];
    }
    return nil;
}

- (void)fetchRatesForBase:(NSString *)base completion:(LBRatesCompletion)completion {
    NSParameterAssert(base != nil);
    NSParameterAssert(completion != nil);
    // TODO: M07 — 組 URL（baseURL/latest?base=…）、dataTaskWithURL:completionHandler:、resume；
    //            回呼裡判 HTTP 狀態碼（非 2xx → LBErrorCodeHTTPStatus）、呼叫 ratesFromJSONData:error:，
    //            最後 dispatch_async(dispatch_get_main_queue()) 呼叫 completion。
}

- (void)fetchRatesForBases:(NSArray<NSString *> *)bases
             maxConcurrent:(NSUInteger)max
                completion:(void (^)(NSDictionary<NSString *, NSDictionary *> *results,
                                     NSArray<NSError *> *errors))completion {
    NSParameterAssert(completion != nil);
    // TODO: M10 — dispatch_semaphore 限流 + dispatch_group 等全部完成。目前先回空結果。
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(@{}, @[]);
    });
}

@end
