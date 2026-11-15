//
//  LBLegacyLedger.h
//  LittleBookLegacy
//
//  Created by LittleBook Team on 2012/11/20.
//  Copyright (c) 2012 LittleBook. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LBLegacyTransaction;

// 帳本有任何變動就發這個通知（object 是帳本本身）
extern NSString * const LBLegacyLedgerDidChangeNotification;

// 帳本：一串交易，index 0 是最新的一筆。
@interface LBLegacyLedger : NSObject {
    NSMutableArray *_transactions;
    NSDecimalNumber *_total;
}

@property (nonatomic, retain) NSMutableArray *transactions;
@property (nonatomic, retain, readonly) NSDecimalNumber *total;

// 全域共用的那一本帳。捷徑：等於 [[LBLegacyLedgerManager sharedManager] ledger]
+ (LBLegacyLedger *)sharedLedger;

- (NSUInteger)count;
- (LBLegacyTransaction *)transactionAtIndex:(NSUInteger)index;

// 新增到最前面；帳本（陣列）會 retain 它，呼叫端照自己的擁有權 release 即可
- (void)addTransaction:(LBLegacyTransaction *)transaction;
- (void)removeTransactionAtIndex:(NSUInteger)index;

// 某筆交易的內容（例如金額）在外面被改了，請帳本重算合計並發通知
- (void)transactionDidChange:(LBLegacyTransaction *)transaction;

- (void)loadSampleData;

@end
