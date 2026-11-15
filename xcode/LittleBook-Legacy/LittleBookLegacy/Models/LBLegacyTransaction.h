//
//  LBLegacyTransaction.h
//  LittleBookLegacy
//
//  Created by LittleBook Team on 2012/11/20.
//  Copyright (c) 2012 LittleBook. All rights reserved.
//

#import <Foundation/Foundation.h>

// 一筆交易。
// 擁有權：note 是 copy、amount / date 是 retain；owner / previous 是 assign（不持有）。
@interface LBLegacyTransaction : NSObject {
    NSString *_note;
    NSDecimalNumber *_amount;
    NSDate *_date;
    id _owner;                          // assign：通常是 LBLegacyLedger
    LBLegacyTransaction *_previous;     // assign：帳本裡比我舊的那一筆（MRC 版的 weak prev）
    NSString *_formattedAmountCache;    // formattedAmount 的快取，金額變了就作廢
}

@property (nonatomic, copy) NSString *note;
@property (nonatomic, retain) NSDecimalNumber *amount;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, assign) id owner;
@property (nonatomic, assign) LBLegacyTransaction *previous;

// autorelease 工廠：回傳 +0，呼叫端要長期留著就自己 retain
+ (instancetype)transactionWithNote:(NSString *)note;
+ (instancetype)transactionWithNote:(NSString *)note amount:(NSDecimalNumber *)amount;

// designated initializer：alloc + init 回傳 +1，呼叫端負責 release
- (id)initWithNote:(NSString *)note amount:(NSDecimalNumber *)amount;

// 例：NT$1,234
- (NSString *)formattedAmount;

@end
