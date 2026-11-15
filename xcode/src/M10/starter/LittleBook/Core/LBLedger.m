#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBMonthSection.h"

NSNotificationName const LBLedgerDidImportBatchNotification = @"LBLedgerDidImportBatchNotification";
NSString * const LBLedgerImportedCountKey = @"LBLedgerImportedCount";

/// 類別延伸：total 對外 readonly、對內 readwrite；合成的 setter 自動送 KVO 通知。
@interface LBLedger ()
@property (nonatomic, strong, readwrite) NSDecimalNumber *total;
@end

/// 執行緒安全版帳本（讀寫鎖）：
/// - _items / _index 只在 _queue 上碰。
/// - 讀：dispatch_sync，多個讀可以並行。
/// - 寫：dispatch_barrier_sync，barrier 區塊執行時佇列上沒有其他區塊，等同獨佔寫鎖。
///   用 sync 而不是 async 的理由：呼叫端（以及 M03 / M05 的測試）期待方法回傳時資料已經寫好、
///   delegate 已通知；barrier_async 是「射後不理」版本，留給 M10 的大量匯入。
/// - delegate 與 KVO 通知一律在主執行緒：呼叫端在主執行緒就同步送，否則 dispatch_async 回主佇列。
/// - total 只在主執行緒更新（setter 在主執行緒跑），UI 讀它也在主執行緒。
@implementation LBLedger {
    NSMutableArray<LBTransaction *> *_items;                   // 依日期倒序
    NSMutableDictionary<NSUUID *, LBTransaction *> *_index;    // identifier → 交易
    NSCalendar *_calendar;
    dispatch_queue_t _queue;                                   // DISPATCH_QUEUE_CONCURRENT
}

- (instancetype)init {
    if ((self = [super init])) {
        _items = [NSMutableArray array];
        _index = [NSMutableDictionary dictionary];
        _calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        _queue = dispatch_queue_create("com.littlebook.ledger", DISPATCH_QUEUE_CONCURRENT);
        _total = NSDecimalNumber.zero;
    }
    return self;
}

- (instancetype)initWithTransactions:(NSArray<LBTransaction *> *)transactions {
    NSParameterAssert(transactions != nil);
    if ((self = [self init])) {
        // 穩定排序（日期倒序）：同日期保留原本的先後，和逐筆 addTransaction: 的結果一致
        NSArray<LBTransaction *> *sorted =
            [transactions sortedArrayWithOptions:NSSortStable
                                 usingComparator:^NSComparisonResult(LBTransaction *a,
                                                                     LBTransaction *b) {
                return [b.date compare:a.date];
            }];
        for (LBTransaction *tx in sorted) {
            if (_index[tx.identifier] != nil) {
                continue;   // 重複的 identifier 只留第一筆
            }
            [_items addObject:tx];
            _index[tx.identifier] = tx;
        }
        _total = [self lb_totalLocked];   // init 裡：還沒有觀察者，也還沒有其他執行緒碰得到
    }
    return self;
}

#pragma mark - 執行緒工具

/// 在主執行緒執行 block：已在主執行緒就直接跑（保持同步語意），否則丟回主佇列。
- (void)lb_performOnMain:(dispatch_block_t)block {
    if (NSThread.isMainThread) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

/// 只能在 _queue 的區塊內呼叫（不加鎖）。
- (NSDecimalNumber *)lb_sumForKindLocked:(LBTransactionKind)kind {
    NSDecimalNumber *total = NSDecimalNumber.zero;
    for (LBTransaction *tx in _items) {
        if (tx.kind == kind) {
            total = [total decimalNumberByAdding:tx.amount];
        }
    }
    return total;
}

- (NSDecimalNumber *)lb_totalLocked {
    return [[self lb_sumForKindLocked:LBTransactionKindIncome]
            decimalNumberBySubtracting:[self lb_sumForKindLocked:LBTransactionKindExpense]];
}

/// 寫入完成後在主執行緒更新 total（走 setter 才有 KVO 通知）。
/// 刻意在主執行緒「重新讀」目前的總額，而不是把寫入當下算好的值帶過來：
/// 多條執行緒同時寫時，丟回主佇列的順序不保證和寫入順序一致，帶舊值會讓 total 停在過期的數字。
- (void)lb_publishTotal {
    [self lb_performOnMain:^{
        __block NSDecimalNumber *current = nil;
        dispatch_sync(self->_queue, ^{
            current = [self lb_totalLocked];
        });
        if (![current isEqual:self->_total]) {
            self.total = current;
        }
    }];
}

#pragma mark - 讀取（dispatch_sync，可並行）

- (NSArray<LBTransaction *> *)transactions {
    __block NSArray<LBTransaction *> *snapshot = nil;
    dispatch_sync(_queue, ^{
        snapshot = [self->_items copy];   // 不可變快照
    });
    return snapshot;
}

- (LBTransaction *)transactionWithIdentifier:(NSUUID *)identifier {
    NSParameterAssert(identifier != nil);
    __block LBTransaction *found = nil;
    dispatch_sync(_queue, ^{
        found = self->_index[identifier];
    });
    return found;
}

#pragma mark - 寫入（dispatch_barrier_sync，獨佔）

- (void)addTransaction:(LBTransaction *)tx {
    NSParameterAssert(tx != nil);
    __block BOOL inserted = NO;
    dispatch_barrier_sync(_queue, ^{
        if (self->_index[tx.identifier] != nil) {
            return;   // 只離開這個 block
        }
        // 找到第一筆日期比它早的位置插入，維持倒序；同日期的新交易排在舊的後面。
        NSUInteger insertIndex = self->_items.count;
        for (NSUInteger i = 0; i < self->_items.count; i++) {
            if ([self->_items[i].date compare:tx.date] == NSOrderedAscending) {
                insertIndex = i;
                break;
            }
        }
        [self->_items insertObject:tx atIndex:insertIndex];
        self->_index[tx.identifier] = tx;
        inserted = YES;
    });
    if (!inserted) {
        return;
    }
    [self lb_publishTotal];
    [self lb_performOnMain:^{
        [self.delegate ledger:self didAddTransaction:tx];
    }];
}

- (BOOL)removeTransactionWithIdentifier:(NSUUID *)identifier {
    NSParameterAssert(identifier != nil);
    __block BOOL removed = NO;
    dispatch_barrier_sync(_queue, ^{
        LBTransaction *tx = self->_index[identifier];
        if (tx == nil) {
            return;
        }
        [self->_index removeObjectForKey:identifier];
        [self->_items removeObject:tx];
        removed = YES;
    });
    if (removed) {
        [self lb_publishTotal];
    }
    return removed;
}

- (void)reset {
    dispatch_barrier_sync(_queue, ^{
        [self->_items removeAllObjects];
        [self->_index removeAllObjects];
    });
    [self lb_publishTotal];
    [self lb_performOnMain:^{
        id<LBLedgerObserver> delegate = self.delegate;   // weak → 先轉成 strong 區域變數
        if ([delegate respondsToSelector:@selector(ledgerDidReset:)]) {
            [delegate ledgerDidReset:self];
        }
    }];
}

#pragma mark - 批次匯入（M10）

- (void)performBatchImport:(NSArray<LBTransaction *> *)batch {
    // TODO: M10 — 先在呼叫端執行緒排序（日期倒序、NSSortStable），再用「一次」dispatch_barrier_async：
    //            略過已存在的 identifier、和 _items 合併（兩個倒序陣列 merge，O(n + m)）；
    //            寫完 lb_publishTotal，並在主佇列送 LBLedgerDidImportBatchNotification
    //            （userInfo[LBLedgerImportedCountKey] = 實際加入筆數）。
    //            進階：total 每次都掃全部交易，10 萬筆時太慢 → 改成隨寫入增減的累計值。
}

- (void)waitForPendingWrites {
    // TODO: M10 — 一個空的 dispatch_barrier_sync 就能等到前面所有寫入完成
}

#pragma mark - 統計（讀）

- (NSArray<LBMonthSection *> *)transactionsGroupedByMonth {
    __block NSArray<LBMonthSection *> *result = nil;
    dispatch_sync(_queue, ^{
        NSMutableArray<LBMonthSection *> *sections = [NSMutableArray array];
        NSMutableArray<LBTransaction *> *bucket = [NSMutableArray array];
        NSInteger currentYear = 0;
        NSInteger currentMonth = 0;
        NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth;

        // _items 已依日期倒序，所以同月份一定相鄰：掃一遍、換月就收一個區段。
        for (LBTransaction *tx in self->_items) {
            NSDateComponents *components = [self->_calendar components:units fromDate:tx.date];
            BOOL monthChanged = components.year != currentYear
                             || components.month != currentMonth;
            if (bucket.count > 0 && monthChanged) {
                [sections addObject:[[LBMonthSection alloc] initWithYear:currentYear
                                                                   month:currentMonth
                                                            transactions:bucket]];
                [bucket removeAllObjects];
            }
            currentYear = components.year;
            currentMonth = components.month;
            [bucket addObject:tx];
        }
        if (bucket.count > 0) {
            [sections addObject:[[LBMonthSection alloc] initWithYear:currentYear
                                                               month:currentMonth
                                                        transactions:bucket]];
        }
        result = [sections copy];
    });
    return result;
}

- (NSDecimalNumber *)totalForKind:(LBTransactionKind)kind {
    __block NSDecimalNumber *total = nil;
    dispatch_sync(_queue, ^{
        total = [self lb_sumForKindLocked:kind];
    });
    return total;
}

@end
