//
//  LBLegacyLedgerManager.h
//  LittleBookLegacy
//
//  Created by LittleBook Team on 2012/11/20.
//  Copyright (c) 2012 LittleBook. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LBLegacyLedger;

// 典型的舊專案 Singleton：到處都是 [[LBLegacyLedgerManager sharedManager] ledger]
@interface LBLegacyLedgerManager : NSObject {
    LBLegacyLedger *_ledger;
}

@property (nonatomic, retain) LBLegacyLedger *ledger;

+ (LBLegacyLedgerManager *)sharedManager;

@end
