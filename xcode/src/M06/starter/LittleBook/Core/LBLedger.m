#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBMonthSection.h"

/// 類別延伸：total 對外 readonly、對內 readwrite。
/// 合成出來的 setter 會自動包上 willChangeValueForKey: / didChangeValueForKey:，
/// 所以「走 setter」就是 KVO-compliant；直接寫 _total 則不會有任何通知。
@interface LBLedger ()
@property (nonatomic, strong, readwrite) NSDecimalNumber *total;
@end

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
        _total = NSDecimalNumber.zero;   // init 裡用 ivar：物件還沒建好，不該送 KVO
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

    [self lb_refreshTotal];
    // required 方法可以直接呼叫；delegate 為 nil 時送訊息沒有任何效果。
    [self.delegate ledger:self didAddTransaction:tx];
}

- (BOOL)removeTransactionWithIdentifier:(NSUUID *)identifier {
    NSParameterAssert(identifier != nil);
    LBTransaction *tx = _index[identifier];
    if (tx == nil) {
        return NO;
    }
    [_index removeObjectForKey:identifier];
    [_items removeObject:tx];   // removeObject: 用 isEqual: 找，identifier 相同就是同一筆
    [self lb_refreshTotal];
    return YES;
}

- (void)reset {
    [_items removeAllObjects];
    [_index removeAllObjects];
    [self lb_refreshTotal];

    // optional 方法：呼叫前一定要 respondsToSelector:，否則 unrecognized selector 直接 crash。
    id<LBLedgerObserver> delegate = self.delegate;   // weak → 先轉成 strong 區域變數
    if ([delegate respondsToSelector:@selector(ledgerDidReset:)]) {
        [delegate ledgerDidReset:self];
    }
}

#pragma mark - KVO

/// 重新計算 total 並發出 KVO 通知。
- (void)lb_refreshTotal {
    // TODO: M06 — 用 totalForKind: 算出「收入 − 支出」，透過 self.total = … 走 setter
    //（合成的 setter 會自動送 willChange / didChange）。不在主執行緒時 dispatch_async 回主佇列。
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
