#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBMonthSection.h"

NSNotificationName const LBLedgerDidImportBatchNotification = @"LBLedgerDidImportBatchNotification";
NSString * const LBLedgerImportedCountKey = @"LBLedgerImportedCount";

/// 類別延伸：total 對外 readonly、對內 readwrite；合成的 setter 自動送 KVO 通知。
@interface LBLedger ()
@property (nonatomic, strong, readwrite) NSDecimalNumber *total;
@end

/// 執行緒安全版帳本（讀寫鎖，M07 起）：
/// - _items / _index / 兩個累計值只在 _queue 上碰。
/// - 讀：dispatch_sync，多個讀可以並行。
/// - 寫：dispatch_barrier_sync（單筆，呼叫端期待回傳時已寫好）或 dispatch_barrier_async（M10 批次匯入）。
/// - delegate 與 KVO 通知一律在主執行緒。
/// M10 的效能調整：
/// - 收入 / 支出累計值隨寫入增減，total 變成 O(1)，不再每次掃 10 萬筆；
/// - 月份分組只在「跨月」時才問 NSCalendar，其餘每筆只比一次日期。
@implementation LBLedger {
    NSMutableArray<LBTransaction *> *_items;                   // 依日期倒序
    NSMutableDictionary<NSUUID *, LBTransaction *> *_index;    // identifier → 交易
    NSDecimalNumber *_incomeSum;                               // 只在 _queue 上讀寫
    NSDecimalNumber *_expenseSum;
    NSCalendar *_calendar;
    dispatch_queue_t _queue;                                   // DISPATCH_QUEUE_CONCURRENT
}

- (instancetype)init {
    if ((self = [super init])) {
        _items = [NSMutableArray array];
        _index = [NSMutableDictionary dictionary];
        _incomeSum = NSDecimalNumber.zero;
        _expenseSum = NSDecimalNumber.zero;
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
        NSArray<LBTransaction *> *sorted = [LBLedger lb_sortedDescending:transactions];
        for (LBTransaction *tx in sorted) {
            if (_index[tx.identifier] != nil) {
                continue;   // 重複的 identifier 只留第一筆
            }
            [_items addObject:tx];
            _index[tx.identifier] = tx;
            [self lb_accumulateLocked:tx sign:1];
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

+ (NSArray<LBTransaction *> *)lb_sortedDescending:(NSArray<LBTransaction *> *)transactions {
    return [transactions sortedArrayWithOptions:NSSortStable
                                usingComparator:^NSComparisonResult(LBTransaction *a,
                                                                    LBTransaction *b) {
        return [b.date compare:a.date];
    }];
}

/// 只能在 _queue 的區塊內呼叫（不加鎖）：sign = 1 加入、-1 移除。
- (void)lb_accumulateLocked:(LBTransaction *)tx sign:(NSInteger)sign {
    if (tx.kind == LBTransactionKindIncome) {
        _incomeSum = sign > 0 ? [_incomeSum decimalNumberByAdding:tx.amount]
                              : [_incomeSum decimalNumberBySubtracting:tx.amount];
    } else {
        _expenseSum = sign > 0 ? [_expenseSum decimalNumberByAdding:tx.amount]
                               : [_expenseSum decimalNumberBySubtracting:tx.amount];
    }
}

- (NSDecimalNumber *)lb_totalLocked {
    return [_incomeSum decimalNumberBySubtracting:_expenseSum];
}

/// 寫入完成後在主執行緒更新 total（走 setter 才有 KVO 通知）。
/// 刻意在主執行緒「重新讀」目前的總額：多條執行緒同時寫時，丟回主佇列的順序不保證和寫入順序一致。
- (void)lb_publishTotal {
    [self lb_performOnMain:^{
        __block NSDecimalNumber *current = nil;
        dispatch_sync(self->_queue, ^{
            current = [self lb_totalLocked];   // O(1)：累計值相減
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

#pragma mark - 寫入

/// 只能在 barrier 區塊內呼叫：二元搜尋找插入位置（第一筆日期比它早的位置），維持倒序；
/// 同日期的新交易排在舊的後面。indexOfObject:inSortedRange:… 就是現成的二元搜尋。
- (NSUInteger)lb_insertionIndexLockedFor:(LBTransaction *)tx {
    return [_items indexOfObject:tx
                   inSortedRange:NSMakeRange(0, _items.count)
                         options:NSBinarySearchingInsertionIndex | NSBinarySearchingLastEqual
                 usingComparator:^NSComparisonResult(LBTransaction *a, LBTransaction *b) {
        return [b.date compare:a.date];   // 倒序：日期大的排前面
    }];
}

- (void)addTransaction:(LBTransaction *)tx {
    NSParameterAssert(tx != nil);
    __block BOOL inserted = NO;
    dispatch_barrier_sync(_queue, ^{
        if (self->_index[tx.identifier] != nil) {
            return;   // 只離開這個 block
        }
        [self->_items insertObject:tx atIndex:[self lb_insertionIndexLockedFor:tx]];
        self->_index[tx.identifier] = tx;
        [self lb_accumulateLocked:tx sign:1];
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
        [self->_items removeObjectIdenticalTo:tx];
        [self lb_accumulateLocked:tx sign:-1];
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
        self->_incomeSum = NSDecimalNumber.zero;
        self->_expenseSum = NSDecimalNumber.zero;
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
    NSParameterAssert(batch != nil);
    if (batch.count == 0) {
        return;
    }
    // 排序在呼叫端的執行緒做（通常是匯入的背景佇列），barrier 內只做合併，獨佔時間越短越好
    NSArray<LBTransaction *> *sorted = [LBLedger lb_sortedDescending:batch];
    dispatch_barrier_async(_queue, ^{
        NSUInteger added = [self lb_mergeSortedLocked:sorted];
        if (added == 0) {
            return;
        }
        [self lb_publishTotal];   // 不在主執行緒 → 丟回主佇列，不會在這裡 dispatch_sync 自己
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter
                postNotificationName:LBLedgerDidImportBatchNotification
                              object:self
                            userInfo:@{LBLedgerImportedCountKey: @(added)}];
        });
    });
}

/// 只能在 barrier 區塊內呼叫。sorted 已依日期倒序；回傳實際加入的筆數。
- (NSUInteger)lb_mergeSortedLocked:(NSArray<LBTransaction *> *)sorted {
    NSMutableArray<LBTransaction *> *fresh = [NSMutableArray arrayWithCapacity:sorted.count];
    for (LBTransaction *tx in sorted) {
        if (_index[tx.identifier] != nil) {
            continue;   // 已存在（或同一批重複）就略過
        }
        _index[tx.identifier] = tx;
        [self lb_accumulateLocked:tx sign:1];
        [fresh addObject:tx];
    }
    if (fresh.count == 0) {
        return 0;
    }
    // 常見情況：匯入的資料都比現有的舊（CSV 依日期倒序產生）→ 直接接在後面
    LBTransaction *oldestExisting = _items.lastObject;
    if (oldestExisting == nil
        || [fresh.firstObject.date compare:oldestExisting.date] != NSOrderedDescending) {
        [_items addObjectsFromArray:fresh];
        return fresh.count;
    }
    // 一般情況：兩個倒序陣列合併，O(n + m)；同日期時舊資料在前（和 addTransaction: 一致）
    NSMutableArray<LBTransaction *> *merged =
        [NSMutableArray arrayWithCapacity:_items.count + fresh.count];
    NSUInteger i = 0;
    NSUInteger j = 0;
    while (i < _items.count && j < fresh.count) {
        if ([fresh[j].date compare:_items[i].date] == NSOrderedDescending) {
            [merged addObject:fresh[j++]];
        } else {
            [merged addObject:_items[i++]];
        }
    }
    while (i < _items.count) {
        [merged addObject:_items[i++]];
    }
    while (j < fresh.count) {
        [merged addObject:fresh[j++]];
    }
    _items = merged;
    return fresh.count;
}

- (void)waitForPendingWrites {
    // 空的 barrier：它開始執行時，前面排進去的所有區塊（含 async barrier）都已經結束
    dispatch_barrier_sync(_queue, ^{});
}

#pragma mark - 統計（讀）

- (NSArray<LBMonthSection *> *)transactionsGroupedByMonth {
    __block NSArray<LBMonthSection *> *result = nil;
    dispatch_sync(_queue, ^{
        NSMutableArray<LBMonthSection *> *sections = [NSMutableArray array];
        NSMutableArray<LBTransaction *> *bucket = [NSMutableArray array];
        NSInteger currentYear = 0;
        NSInteger currentMonth = 0;
        NSDate *monthStart = nil;   // 目前這個月的第一刻；日期 ≥ 它就還在同一個月
        NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth;

        // _items 已依日期倒序：日期只會越來越早，所以只要和「本月第一刻」比一次就知道換月了沒
        for (LBTransaction *tx in self->_items) {
            if (monthStart != nil && [tx.date compare:monthStart] != NSOrderedAscending) {
                [bucket addObject:tx];
                continue;
            }
            if (bucket.count > 0) {
                [sections addObject:[[LBMonthSection alloc] initWithYear:currentYear
                                                                   month:currentMonth
                                                            transactions:bucket]];
                [bucket removeAllObjects];
            }
            NSDateComponents *components = [self->_calendar components:units fromDate:tx.date];
            currentYear = components.year;
            currentMonth = components.month;
            components.day = 1;
            monthStart = [self->_calendar dateFromComponents:components];
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
        total = (kind == LBTransactionKindIncome) ? self->_incomeSum : self->_expenseSum;
    });
    return total;
}

@end
