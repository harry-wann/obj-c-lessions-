//
//  LBLegacyTransaction.m
//  LittleBookLegacy
//
//  Created by LittleBook Team on 2012/11/20.
//  Copyright (c) 2012 LittleBook. All rights reserved.
//

#import "LBLegacyTransaction.h"

@implementation LBLegacyTransaction

@synthesize note = _note;
@synthesize date = _date;
@synthesize owner = _owner;
@synthesize previous = _previous;
// amount 的 setter / getter 自己寫（要順便清掉格式化快取），所以不 @synthesize

#pragma mark - Init / Factory

- (id)init
{
    return [self initWithNote:@"" amount:[NSDecimalNumber zero]];
}

- (id)initWithNote:(NSString *)note amount:(NSDecimalNumber *)amount
{
    self = [super init];
    if (self) {
        // init 裡直接寫 ivar，不走 setter
        _note = [note copy];
        _amount = [amount retain];
        _date = [[NSDate alloc] init];
    }
    return self;
}

+ (instancetype)transactionWithNote:(NSString *)note
{
    return [self transactionWithNote:note amount:[NSDecimalNumber zero]];
}

+ (instancetype)transactionWithNote:(NSString *)note amount:(NSDecimalNumber *)amount
{
    return [[[self alloc] initWithNote:note amount:amount] autorelease];
}

#pragma mark - Accessors

- (void)setAmount:(NSDecimalNumber *)amount
{
    if (_amount != amount) {
        [amount retain];
        [_amount release];   // 雷 2：舊值要放手
        _amount = amount;

        // 金額變了，格式化快取作廢
        [_formattedAmountCache release];
        _formattedAmountCache = nil;
    }
}

- (NSDecimalNumber *)amount
{
    return _amount;
}

- (NSString *)formattedAmount
{
    if (_formattedAmountCache == nil) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];   // +1
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [formatter setMaximumFractionDigits:0];
        NSString *digits = [formatter stringFromNumber:_amount];          // +0
        [formatter release];
        _formattedAmountCache = [[NSString alloc] initWithFormat:@"NT$%@", digits];   // +1，ivar 持有
    }
    return _formattedAmountCache;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p note=%@ amount=%@>",
            NSStringFromClass([self class]), self, _note, _amount];
}

#pragma mark - dealloc

- (void)dealloc
{
    // 把 ivar 都清乾淨（2014/02 code review 的要求）
    [_note release];
    [_amount release];
    [_date release];
    [_formattedAmountCache release];
    // _owner / _previous 是 assign：從沒 retain 過，不 release（雷 1）
    [super dealloc];
}

@end
