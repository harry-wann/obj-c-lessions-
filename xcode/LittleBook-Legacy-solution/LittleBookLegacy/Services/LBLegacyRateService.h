//
//  LBLegacyRateService.h
//  LittleBookLegacy
//
//  Created by LittleBook Team on 2013/08/15.
//  Copyright (c) 2013 LittleBook. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LBLegacyRateService;

extern NSString * const LBLegacyRateServiceErrorDomain;

@protocol LBLegacyRateServiceDelegate <NSObject>
// rates：幣別代碼 → NSDecimalNumber（1 單位基準幣可換多少）
- (void)rateService:(LBLegacyRateService *)service didLoadRates:(NSDictionary *)rates;
- (void)rateService:(LBLegacyRateService *)service didFailWithError:(NSError *)error;
@end

// 匯率服務（2013 年版）：NSURLConnection + delegate。
// connection 建在主執行緒的 run loop 上，所以 delegate 回呼也都在主執行緒。
@interface LBLegacyRateService : NSObject {
    id<LBLegacyRateServiceDelegate> _delegate;   // assign：不持有
    NSString *_baseURLString;
    NSURLConnection *_connection;
    NSMutableData *_buffer;
    NSInteger _statusCode;
}

@property (nonatomic, assign) id<LBLegacyRateServiceDelegate> delegate;
@property (nonatomic, copy) NSString *baseURLString;

// init 會讀 Info.plist 的 LBLegacyRateBaseURL
- (id)initWithBaseURLString:(NSString *)baseURLString;

// GET {baseURLString}/{base}；結果透過 delegate 回來
- (void)fetchRatesForBase:(NSString *)base;
- (void)cancel;
- (BOOL)isLoading;

// 純解析：{"rates":{"USD":0.0312,...}} → NSDictionary；格式不對回 nil
+ (NSDictionary *)parseRates:(NSData *)data;

@end
