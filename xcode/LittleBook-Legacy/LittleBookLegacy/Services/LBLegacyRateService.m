//
//  LBLegacyRateService.m
//  LittleBookLegacy
//
//  Created by LittleBook Team on 2013/08/15.
//  Copyright (c) 2013 LittleBook. All rights reserved.
//

#import "LBLegacyRateService.h"

NSString * const LBLegacyRateServiceErrorDomain = @"LBLegacyRateServiceErrorDomain";

@interface LBLegacyRateService ()
- (NSURL *)urlForBase:(NSString *)base;
- (void)clearConnection;
@end

@implementation LBLegacyRateService

@synthesize delegate = _delegate;
@synthesize baseURLString = _baseURLString;

- (id)init
{
    NSString *base = [[[NSBundle mainBundle] infoDictionary] objectForKey:kLBRateBaseURLKey];
    return [self initWithBaseURLString:base];
}

- (id)initWithBaseURLString:(NSString *)baseURLString
{
    self = [super init];
    if (self) {
        _baseURLString = [baseURLString copy];
    }
    return self;
}

- (void)dealloc
{
    [_connection release];
    [_buffer release];
    [_baseURLString release];
    [super dealloc];
}

#pragma mark - Public

- (BOOL)isLoading
{
    return _connection != nil;
}

- (void)fetchRatesForBase:(NSString *)base
{
    [self cancel];   // 上一個請求還在跑就先取消

    NSURLRequest *req = [NSURLRequest requestWithURL:[self urlForBase:base]
                                         cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                     timeoutInterval:30.0];
    _statusCode = 0;
    _buffer = [[NSMutableData alloc] init];
    _connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
}

- (void)cancel
{
    [_connection cancel];
    [self clearConnection];
}

+ (NSDictionary *)parseRates:(NSData *)data
{
    if ([data length] == 0) {
        return nil;
    }
    NSError *error = nil;
    id root = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (![root isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    id ratesObject = [root objectForKey:@"rates"];
    if (![ratesObject isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSMutableDictionary *result = [NSMutableDictionary dictionary];   // autoreleased
    for (NSString *code in ratesObject) {
        id value = [ratesObject objectForKey:code];
        NSString *text = nil;
        if ([value isKindOfClass:[NSNumber class]]) {
            text = [value stringValue];     // 0.0312 → @"0.0312"，避免 double 的尾數誤差
        } else if ([value isKindOfClass:[NSString class]]) {
            text = value;
        }
        if (text == nil) {
            continue;   // NSNull 或其他型別：跳過
        }
        NSDecimalNumber *rate = [NSDecimalNumber decimalNumberWithString:text];
        if (![rate isEqualToNumber:[NSDecimalNumber notANumber]]) {
            [result setObject:rate forKey:code];
        }
    }
    return result;
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        _statusCode = [(NSHTTPURLResponse *)response statusCode];
    }
    [_buffer setLength:0];   // 轉址時可能收到多次 response，從頭累積
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_buffer appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSDictionary *rates = nil;
    NSError *error = nil;
    if (_statusCode != 0 && (_statusCode < 200 || _statusCode >= 300)) {
        NSDictionary *info = [NSDictionary dictionaryWithObject:@"匯率伺服器回應錯誤"
                                                         forKey:NSLocalizedDescriptionKey];
        error = [NSError errorWithDomain:LBLegacyRateServiceErrorDomain
                                    code:_statusCode
                                userInfo:info];
    } else {
        rates = [[self class] parseRates:_buffer];
        if (rates == nil) {
            NSDictionary *info = [NSDictionary dictionaryWithObject:@"匯率資料格式不正確"
                                                             forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:LBLegacyRateServiceErrorDomain
                                        code:-1
                                    userInfo:info];
        }
    }
    [self clearConnection];   // 先清狀態再回呼：delegate 可能在回呼裡又發一個請求

    if (rates != nil) {
        [_delegate rateService:self didLoadRates:rates];
    } else {
        [_delegate rateService:self didFailWithError:error];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self clearConnection];
    [_delegate rateService:self didFailWithError:error];
}

#pragma mark - Private

- (NSURL *)urlForBase:(NSString *)base
{
    NSString *s = [NSString stringWithFormat:@"%@/%@", _baseURLString, base];
    return [NSURL URLWithString:s];
}

- (void)clearConnection
{
    [_connection release];
    _connection = nil;
    [_buffer release];
    _buffer = nil;
}

@end
