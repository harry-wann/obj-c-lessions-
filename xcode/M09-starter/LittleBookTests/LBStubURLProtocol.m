#import "LBStubURLProtocol.h"

static NSString * const LBStubStatusKey = @"status";
static NSString * const LBStubDataKey = @"data";

static NSMutableDictionary<NSString *, NSDictionary *> *LBStubTable(void) {
    static NSMutableDictionary<NSString *, NSDictionary *> *table = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        table = [NSMutableDictionary dictionary];
    });
    return table;
}

@implementation LBStubURLProtocol

#pragma mark - 登記

+ (void)stubPath:(NSString *)path statusCode:(NSInteger)statusCode data:(NSData *)data {
    @synchronized (self) {
        LBStubTable()[path] = @{LBStubStatusKey: @(statusCode), LBStubDataKey: [data copy]};
    }
}

+ (void)stubPath:(NSString *)path statusCode:(NSInteger)statusCode JSONObject:(id)object {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    NSAssert(data != nil, @"stub JSON 無法序列化：%@", error);
    [self stubPath:path statusCode:statusCode data:data];
}

+ (void)removeAllStubs {
    @synchronized (self) {
        [LBStubTable() removeAllObjects];
    }
}

+ (nullable NSDictionary *)lb_stubForPath:(nullable NSString *)path {
    if (path == nil) {
        return nil;
    }
    @synchronized (self) {
        return LBStubTable()[path];
    }
}

+ (NSURLSession *)stubbedSession {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    config.protocolClasses = @[[LBStubURLProtocol class]];   // 這個 session 的所有請求都走 stub
    return [NSURLSession sessionWithConfiguration:config];
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return YES;   // 只掛在測試 session 上，所以全部接手
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSURL *url = self.request.URL;
    NSDictionary *stub = [LBStubURLProtocol lb_stubForPath:url.path];
    NSInteger status = stub ? [stub[LBStubStatusKey] integerValue] : 404;
    NSData *data = stub ? stub[LBStubDataKey] : [NSData data];

    NSHTTPURLResponse *response =
        [[NSHTTPURLResponse alloc] initWithURL:url
                                    statusCode:status
                                   HTTPVersion:@"HTTP/1.1"
                                  headerFields:@{@"Content-Type": @"application/json"}];
    id<NSURLProtocolClient> client = self.client;
    [client URLProtocol:self
     didReceiveResponse:response
     cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [client URLProtocol:self didLoadData:data];
    [client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
    // 同步回完了，沒有東西要取消
}

@end
