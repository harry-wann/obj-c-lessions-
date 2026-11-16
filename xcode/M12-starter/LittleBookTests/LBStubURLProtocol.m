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

// 以下三個只在 @synchronized ([LBStubURLProtocol class]) 裡讀寫
static NSTimeInterval LBStubDelay = 0;
static NSUInteger LBStubInFlight = 0;
static NSUInteger LBStubMaxInFlight = 0;
static NSUInteger LBStubTotal = 0;

@implementation LBStubURLProtocol {
    BOOL _stopped;   // stopLoading 之後不能再呼叫 client
}

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
        LBStubDelay = 0;
    }
    [self resetConcurrencyStats];
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

#pragma mark - 延遲與並行統計（M10）

+ (void)setResponseDelay:(NSTimeInterval)delay {
    @synchronized (self) {
        LBStubDelay = MAX(delay, 0);
    }
}

+ (NSUInteger)maxConcurrentRequests {
    @synchronized (self) {
        return LBStubMaxInFlight;
    }
}

+ (NSUInteger)totalRequests {
    @synchronized (self) {
        return LBStubTotal;
    }
}

+ (void)resetConcurrencyStats {
    @synchronized (self) {
        LBStubInFlight = 0;
        LBStubMaxInFlight = 0;
        LBStubTotal = 0;
    }
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return YES;   // 只掛在測試 session 上，所以全部接手
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSTimeInterval delay = 0;
    @synchronized ([LBStubURLProtocol class]) {
        LBStubInFlight += 1;
        LBStubTotal += 1;
        LBStubMaxInFlight = MAX(LBStubMaxInFlight, LBStubInFlight);
        delay = LBStubDelay;
    }
    if (delay <= 0) {
        [self lb_finishLoading];
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [self lb_finishLoading];
    });
}

- (void)lb_finishLoading {
    // 先把「在飛」計數減掉再回應：回應一送出，限流那邊就會放下一個請求進來，
    // 若順序相反，統計會短暫多算一個。
    @synchronized ([LBStubURLProtocol class]) {
        if (LBStubInFlight > 0) {   // reset 之後才回來的舊請求不能讓它變成負數（無號數會繞回）
            LBStubInFlight -= 1;
        }
    }
    @synchronized (self) {
        if (_stopped) {
            return;
        }
    }
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
    @synchronized (self) {
        _stopped = YES;
    }
}

@end
