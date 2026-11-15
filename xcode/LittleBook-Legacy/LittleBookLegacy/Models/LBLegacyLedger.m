//
//  LBLegacyLedger.m
//  LittleBookLegacy
//
//  Created by LittleBook Team on 2012/11/20.
//  Copyright (c) 2012 LittleBook. All rights reserved.
//

#import "LBLegacyLedger.h"
#import "LBLegacyLedgerManager.h"
#import "LBLegacyTransaction.h"

NSString * const LBLegacyLedgerDidChangeNotification = @"LBLegacyLedgerDidChangeNotification";

@interface LBLegacyLedger ()
- (void)recalculateTotal;
- (void)postChange;
@end

@implementation LBLegacyLedger

@synthesize transactions = _transactions;
@synthesize total = _total;

+ (LBLegacyLedger *)sharedLedger
{
    // 2014/05：大家都懶得打兩層，加了這個捷徑
    return [[LBLegacyLedgerManager sharedManager] ledger];
}

- (id)init
{
    self = [super init];
    if (self) {
        _transactions = [[NSMutableArray alloc] init];
        _total = [[NSDecimalNumber zero] retain];
    }
    return self;
}

- (void)dealloc
{
    [_transactions release];
    [_total release];
    [super dealloc];
}

#pragma mark - Query

- (NSUInteger)count
{
    return [_transactions count];
}

- (LBLegacyTransaction *)transactionAtIndex:(NSUInteger)index
{
    return [_transactions objectAtIndex:index];
}

#pragma mark - Mutation

- (void)addTransaction:(LBLegacyTransaction *)transaction
{
    if (transaction == nil) {
        return;
    }
    LBLegacyTransaction *newest = nil;
    if ([_transactions count] > 0) {
        newest = [_transactions objectAtIndex:0];
    }
    transaction.previous = newest;      // assign：不持有
    transaction.owner = self;           // assign：不持有
    [_transactions insertObject:transaction atIndex:0];   // 陣列 retain → +1
    [self recalculateTotal];
    [self postChange];
}

- (void)removeTransactionAtIndex:(NSUInteger)index
{
    if (index >= [_transactions count]) {
        return;
    }
    LBLegacyTransaction *victim = [_transactions objectAtIndex:index];
    // 比它新的那一筆（index - 1）原本指向它；改指向它的 previous，免得留下懸空指標
    if (index > 0) {
        LBLegacyTransaction *newer = [_transactions objectAtIndex:index - 1];
        newer.previous = victim.previous;
    }
    victim.owner = nil;
    [_transactions removeObjectAtIndex:index];   // 陣列 release；之後不能再碰 victim
    [self recalculateTotal];
    [self postChange];
}

- (void)transactionDidChange:(LBLegacyTransaction *)transaction
{
    [self recalculateTotal];
    [self postChange];
}

- (void)loadSampleData
{
    // 舊的先加；addTransaction: 會插在最前面，所以畫面上最後一筆是「咖啡」
    // 備註前後故意有空白：那是從舊版 CSV 匯入時帶進來的，顯示時要 lb_trimmed
    NSArray *notes = [NSArray arrayWithObjects:
                      @"　咖啡　", @"捷運\n", @"  早餐 蛋餅  ", @"午餐便當", nil];
    NSArray *amounts = [NSArray arrayWithObjects:@"65", @"30", @"45", @"95", nil];
    for (NSUInteger i = 0; i < [notes count]; i++) {
        NSDecimalNumber *amount =
            [NSDecimalNumber decimalNumberWithString:[amounts objectAtIndex:i]];
        LBLegacyTransaction *tx =
            [[LBLegacyTransaction alloc] initWithNote:[notes objectAtIndex:i] amount:amount];
        [self addTransaction:tx];
        [tx release];   // 帳本已經 retain 了，我放手
    }
}

#pragma mark - Private

- (void)recalculateTotal
{
    NSDecimalNumber *sum = [NSDecimalNumber zero];
    for (LBLegacyTransaction *tx in _transactions) {
        if (tx.amount != nil) {
            sum = [sum decimalNumberByAdding:tx.amount];
        }
    }
    [_total release];
    _total = [sum retain];
}

- (void)postChange
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:LBLegacyLedgerDidChangeNotification object:self];
}

@end
