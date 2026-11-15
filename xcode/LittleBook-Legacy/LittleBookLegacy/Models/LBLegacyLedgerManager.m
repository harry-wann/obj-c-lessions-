//
//  LBLegacyLedgerManager.m
//  LittleBookLegacy
//
//  Created by LittleBook Team on 2012/11/20.
//  Copyright (c) 2012 LittleBook. All rights reserved.
//

#import "LBLegacyLedgerManager.h"
#import "LBLegacyLedger.h"

static LBLegacyLedgerManager *sSharedManager = nil;

@implementation LBLegacyLedgerManager

@synthesize ledger = _ledger;

+ (LBLegacyLedgerManager *)sharedManager
{
    // dispatch_once 普及之前的寫法：每次都要拿鎖，但保證只建一次
    @synchronized(self) {
        if (sSharedManager == nil) {
            sSharedManager = [[self alloc] init];   // 永不 release：活到 App 結束
        }
    }
    return sSharedManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        _ledger = [[LBLegacyLedger alloc] init];   // 直接寫 ivar：+1，dealloc 配一個 release
        [_ledger loadSampleData];
    }
    return self;
}

- (void)dealloc
{
    [_ledger release];
    [super dealloc];
}

@end
