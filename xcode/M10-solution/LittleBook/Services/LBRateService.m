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

#pragma mark - 錯誤

+ (NSError *)lb_errorWithCode:(LBErrorCode)code
                  description:(NSString *)description
                     userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)extra {
    NSMutableDictionary<NSErrorUserInfoKey, id> *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = description;
    if (extra != nil) {
        [userInfo addEntriesFromDictionary:extra];
    }
    return [NSError errorWithDomain:LBErrorDomain code:code userInfo:userInfo];
}

#pragma mark - 解析（純函式，可單測）

/// JSON 值 → NSDecimalNumber。數字直接轉；數字字串（"32.15"）也接受；其他回 nil。
+ (nullable NSDecimalNumber *)lb_decimalNumberFromJSONValue:(id)value {
    // JSON 的 true / false 也是 NSNumber，但匯率不該是布林
    if (value == (id)kCFBooleanTrue || value == (id)kCFBooleanFalse) {
        return nil;
    }
    NSString *text = nil;
    if ([value isKindOfClass:[NSNumber class]]) {
        // 經過字串再轉 NSDecimal，避免 double → NSDecimal 的二進位誤差（32.15 → 32.1500000…）
        text = [value stringValue];
    } else if ([value isKindOfClass:[NSString class]]) {
        text = value;
    } else {
        return nil;
    }
    NSLocale *posix = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:text locale:posix];
    NSDecimal decimal = number.decimalValue;
    if (NSDecimalIsNotANumber(&decimal)) {
        return nil;   // "abc" 會解析成 NaN
    }
    return number;
}

+ (NSDictionary<NSString *, NSDecimalNumber *> *)ratesFromJSONData:(NSData *)data
                                                             error:(NSError **)error {
    NSParameterAssert(data != nil);
    NSError *jsonError = nil;
    id root = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (root == nil || ![root isKindOfClass:[NSDictionary class]]) {
        if (error != NULL) {
            NSDictionary *extra = jsonError ? @{NSUnderlyingErrorKey: jsonError} : nil;
            *error = [self lb_errorWithCode:LBErrorCodeMalformedJSON
                                description:@"匯率 JSON 格式不正確"
                                   userInfo:extra];
        }
        return nil;
    }

    id ratesObject = ((NSDictionary *)root)[@"rates"];
    if (![ratesObject isKindOfClass:[NSDictionary class]]) {
        if (error != NULL) {
            *error = [self lb_errorWithCode:LBErrorCodeMalformedJSON
                                description:@"匯率 JSON 缺少 rates 物件"
                                   userInfo:nil];
        }
        return nil;
    }

    NSDictionary *ratesJSON = ratesObject;
    NSMutableDictionary<NSString *, NSDecimalNumber *> *result = [NSMutableDictionary dictionary];
    for (id key in ratesJSON) {   // 對 NSDictionary 做 for-in 得到的是 key
        if (![key isKindOfClass:[NSString class]]) {
            continue;
        }
        id value = ratesJSON[key];
        if (value == [NSNull null]) {
            continue;   // JSON 的 null：這個幣別今天沒資料，跳過即可
        }
        NSDecimalNumber *rate = [self lb_decimalNumberFromJSONValue:value];
        if (rate == nil) {
            if (error != NULL) {
                NSString *message = [NSString stringWithFormat:@"匯率 %@ 不是數字：%@", key, value];
                *error = [self lb_errorWithCode:LBErrorCodeUnexpectedType
                                    description:message
                                       userInfo:nil];
            }
            return nil;
        }
        result[key] = rate;
    }
    return [result copy];
}

#pragma mark - 網路

/// 共用實作：completion 在 callbackQueue 上呼叫。單一抓取用主佇列；M10 的並行抓取用背景佇列，
/// 這樣「等 semaphore 的背景執行緒」和「回呼」都不需要主執行緒，不會互相卡住。
- (void)lb_fetchRatesForBase:(NSString *)base
               callbackQueue:(dispatch_queue_t)callbackQueue
                  completion:(LBRatesCompletion)completion {
    NSURL *endpoint = [self.baseURL URLByAppendingPathComponent:@"latest"];
    NSURLComponents *components = [NSURLComponents componentsWithURL:endpoint
                                             resolvingAgainstBaseURL:NO];
    components.queryItems = @[[NSURLQueryItem queryItemWithName:@"base" value:base]];
    NSURL *url = components.URL;

    NSURLSessionDataTask *task = [self.session dataTaskWithURL:url
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // 這裡在 NSURLSession 的背景執行緒：先把結果算好，再切到指定的佇列。
            NSDictionary<NSString *, NSDecimalNumber *> *rates = nil;
            NSError *resultError = error;
            if (resultError == nil) {
                NSInteger status = 200;
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    status = ((NSHTTPURLResponse *)response).statusCode;
                }
                if (status < 200 || status >= 300) {
                    // NSURLSession 不會把 404 / 500 當錯誤，HTTP 狀態碼要自己判
                    NSString *message = [NSString stringWithFormat:@"伺服器回應 HTTP %ld",
                                         (long)status];
                    NSDictionary *extra = @{LBRateServiceHTTPStatusCodeKey: @(status)};
                    resultError = [LBRateService lb_errorWithCode:LBErrorCodeHTTPStatus
                                                      description:message
                                                         userInfo:extra];
                } else {
                    rates = [LBRateService ratesFromJSONData:data ?: [NSData data]
                                                       error:&resultError];
                }
            }
            dispatch_async(callbackQueue, ^{
                completion(rates, resultError);
            });
        }];
    [task resume];   // 忘了 resume 什麼都不會發生，也沒有任何錯誤訊息
}

- (void)fetchRatesForBase:(NSString *)base completion:(LBRatesCompletion)completion {
    NSParameterAssert(base != nil);
    NSParameterAssert(completion != nil);
    [self lb_fetchRatesForBase:base callbackQueue:dispatch_get_main_queue() completion:completion];
}

#pragma mark - 並行抓取（M10）

- (void)fetchRatesForBases:(NSArray<NSString *> *)bases
             maxConcurrent:(NSUInteger)max
                completion:(void (^)(NSDictionary<NSString *, NSDictionary *> *results,
                                     NSArray<NSError *> *errors))completion {
    NSParameterAssert(bases != nil);
    NSParameterAssert(completion != nil);
    NSArray<NSString *> *list = [bases copy];
    // 限流：同時最多 max 個請求在飛（0 當 1）。50 個請求不限流 = 50 條連線 + 一堆執行緒（10.5）
    dispatch_semaphore_t slots = dispatch_semaphore_create((long)MAX(max, (NSUInteger)1));
    dispatch_group_t group = dispatch_group_create();
    // 結果容器只在這條串列佇列上改：回呼來自不同執行緒，NSMutableDictionary 不能同時寫
    dispatch_queue_t collector = dispatch_queue_create("com.littlebook.rates.collect",
                                                       DISPATCH_QUEUE_SERIAL);
    NSMutableDictionary<NSString *, NSDictionary *> *results = [NSMutableDictionary dictionary];
    NSMutableArray<NSError *> *errors = [NSMutableArray array];

    // 發請求的迴圈會在 semaphore 上等待，所以一定要在背景佇列跑，絕對不能卡主執行緒
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        for (NSString *base in list) {
            dispatch_semaphore_wait(slots, DISPATCH_TIME_FOREVER);   // 拿到名額才發
            dispatch_group_enter(group);
            [self lb_fetchRatesForBase:base
                         callbackQueue:collector
                            completion:^(NSDictionary<NSString *, NSDecimalNumber *> *rates,
                                         NSError *error) {
                // 已在 collector 上：直接改容器
                if (rates != nil) {
                    results[base] = rates;
                } else if (error != nil) {
                    [errors addObject:error];
                }
                dispatch_semaphore_signal(slots);   // 還名額
                dispatch_group_leave(group);
            }];
        }
        // 全部完成：先在 collector 上取快照（保證所有寫入都做完），再回主佇列
        dispatch_group_notify(group, collector, ^{
            NSDictionary *finalResults = [results copy];
            NSArray *finalErrors = [errors copy];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(finalResults, finalErrors);
            });
        });
    });
}

@end
