#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBMonthSection.h"

@implementation LBLedger {
    NSMutableArray<LBTransaction *> *_items;                   // 依日期倒序
    NSMutableDictionary<NSUUID *, LBTransaction *> *_index;    // identifier → 交易
    NSCalendar *_calendar;
}

- (instancetype)init {
    if ((self = [super init])) {
        _items = [NSMutableArray array];
        _index = [NSMutableDictionary dictionary];
        _calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    }
    return self;
}

#pragma mark - 讀取

- (NSArray<LBTransaction *> *)transactions {
    return [_items copy];   // 不可變快照
}

- (LBTransaction *)transactionWithIdentifier:(NSUUID *)identifier {
    NSParameterAssert(identifier != nil);
    return _index[identifier];
}

#pragma mark - 寫入

- (void)addTransaction:(LBTransaction *)tx {
    NSParameterAssert(tx != nil);
    if (_index[tx.identifier] != nil) {
        return;
    }
    // 找到第一筆日期比它早的位置插入，維持倒序；同日期的新交易排在舊的後面。
    NSUInteger insertIndex = _items.count;
    for (NSUInteger i = 0; i < _items.count; i++) {
        if ([_items[i].date compare:tx.date] == NSOrderedAscending) {
            insertIndex = i;
            break;
        }
    }
    [_items insertObject:tx atIndex:insertIndex];
    _index[tx.identifier] = tx;

    // TODO: M05 — 通知 delegate（required 方法可直接呼叫，對 nil 送訊息是安全的）
}

- (BOOL)removeTransactionWithIdentifier:(NSUUID *)identifier {
    NSParameterAssert(identifier != nil);
    LBTransaction *tx = _index[identifier];
    if (tx == nil) {
        return NO;
    }
    [_index removeObjectForKey:identifier];
    [_items removeObject:tx];   // removeObject: 用 isEqual: 找，identifier 相同就是同一筆
    return YES;
}

- (void)reset {
    // TODO: M05 — 清空 _items 與 _index；delegate 有實作 ledgerDidReset:（optional）才呼叫
}

#pragma mark - 統計

- (NSArray<LBMonthSection *> *)transactionsGroupedByMonth {
    NSMutableArray<LBMonthSection *> *sections = [NSMutableArray array];
    NSMutableArray<LBTransaction *> *bucket = [NSMutableArray array];
    NSInteger currentYear = 0;
    NSInteger currentMonth = 0;
    NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth;

    // _items 已依日期倒序，所以同月份一定相鄰：掃一遍、換月就收一個區段。
    for (LBTransaction *tx in _items) {
        NSDateComponents *components = [_calendar components:units fromDate:tx.date];
        BOOL monthChanged = components.year != currentYear || components.month != currentMonth;
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
    return [sections copy];
}

- (NSDecimalNumber *)totalForKind:(LBTransactionKind)kind {
    NSDecimalNumber *total = NSDecimalNumber.zero;
    for (LBTransaction *tx in _items) {
        if (tx.kind == kind) {
            total = [total decimalNumberByAdding:tx.amount];
        }
    }
    return total;
}

@end
