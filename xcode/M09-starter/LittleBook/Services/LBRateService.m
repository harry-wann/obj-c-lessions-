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

- (void)fetchRatesForBase:(NSString *)base completion:(LBRatesCompletion)completion {
    NSParameterAssert(base != nil);
    NSParameterAssert(completion != nil);

    NSURL *endpoint = [self.baseURL URLByAppendingPathComponent:@"latest"];
    NSURLComponents *components = [NSURLComponents componentsWithURL:endpoint
                                             resolvingAgainstBaseURL:NO];
    components.queryItems = @[[NSURLQueryItem queryItemWithName:@"base" value:base]];
    NSURL *url = components.URL;

    NSURLSessionDataTask *task = [self.session dataTaskWithURL:url
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // 這裡在 NSURLSession 的背景執行緒：先把結果算好，再切回主佇列。
            NSDictionary<NSString *, NSDecimalNumber *> *rates = nil;
            NSError *resultError = error;
            if (resultError == nil) {
                NSInteger status = 200;
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    status = ((NSHTTPURLResponse *)response).statusCode;
                }
                if (status < 200 || status >= 300) {
                    // NSURLSession 不會把 404 / 500 當錯誤，HTTP 狀態碼要自己判
                    NSString *message = [NSString stringWithFormat:@"伺服器回應 HTTP %ld", (long)status];
                    resultError = [LBRateService lb_errorWithCode:LBErrorCodeHTTPStatus
                                                      description:message
                                                         userInfo:@{LBRateServiceHTTPStatusCodeKey: @(status)}];
                } else {
                    rates = [LBRateService ratesFromJSONData:data ?: [NSData data] error:&resultError];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(rates, resultError);
            });
        }];
    [task resume];   // 忘了 resume 什麼都不會發生，也沒有任何錯誤訊息
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
