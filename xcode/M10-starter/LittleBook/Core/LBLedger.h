@import Foundation;
#import "LBTypes.h"
#import "LBLedgerObserver.h"

@class LBTransaction, LBMonthSection;

NS_ASSUME_NONNULL_BEGIN

/// M10：performBatchImport: 的一批寫入完成後，在主執行緒送出；object 是帳本。
/// userInfo[LBLedgerImportedCountKey] 是這一批實際加入的筆數（NSNumber）。
extern NSNotificationName const LBLedgerDidImportBatchNotification;
extern NSString * const LBLedgerImportedCountKey;

/// 帳本：所有交易的容器與查詢邏輯。對外只回不可變型別。
@interface LBLedger : NSObject

/// 依日期倒序（最新在前）的快照；每次呼叫都是新的不可變陣列。
@property (nonatomic, copy, readonly) NSArray<LBTransaction *> *transactions;

/// 收入 − 支出。KVO-compliant：add / remove / reset 之後透過 setter 更新，
/// 通知一律在主執行緒送出（觀察者通常是 UI）。
@property (nonatomic, strong, readonly) NSDecimalNumber *total;

/// 一次放入大量交易（M09：從存檔載入用）。只排序一次、只算一次 total，不送 delegate 通知；
/// identifier 重複的只留第一筆。逐筆 addTransaction: 每次都線性找位置 + 重算總額，
/// 10 萬筆會慢到不能用。
- (instancetype)initWithTransactions:(NSArray<LBTransaction *> *)transactions;

/// 委派一律 weak：帳本不擁有觀察者，否則容易形成循環參考。
@property (nonatomic, weak, nullable) id<LBLedgerObserver> delegate;

/// 加入一筆交易；相同 identifier 已存在時忽略。成功加入會通知 delegate。
- (void)addTransaction:(LBTransaction *)tx;

/// 依 identifier 移除；找到並移除回 YES。
- (BOOL)removeTransactionWithIdentifier:(NSUUID *)identifier;

- (nullable LBTransaction *)transactionWithIdentifier:(NSUUID *)identifier;

/// 清空所有交易；delegate 有實作 ledgerDidReset: 才會被通知。
- (void)reset;

/// M10：一批交易用「一次」dispatch_barrier_async 寫入（射後不理，立刻返回）。
/// 批次內先排序再和現有資料合併（O(n + m)），重複的 identifier 會略過；
/// 寫完在主執行緒更新 total 並送 LBLedgerDidImportBatchNotification（不逐筆呼叫 delegate）。
/// 之後任何讀取（dispatch_sync）都會排在這個 barrier 後面，所以一定看得到這批資料。
- (void)performBatchImport:(NSArray<LBTransaction *> *)batch;

/// 等之前排進去的寫入（含 performBatchImport:）全部完成才返回。不可在帳本內部佇列上呼叫。
- (void)waitForPendingWrites;

/// 依年月分組，月份倒序；每個區段內的交易也依日期倒序。
- (NSArray<LBMonthSection *> *)transactionsGroupedByMonth;

/// 某一種類的金額加總。
- (NSDecimalNumber *)totalForKind:(LBTransactionKind)kind;

@end

NS_ASSUME_NONNULL_END
