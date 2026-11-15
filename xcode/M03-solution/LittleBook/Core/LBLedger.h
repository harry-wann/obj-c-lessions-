@import Foundation;
#import "LBTypes.h"

@class LBTransaction, LBMonthSection;

NS_ASSUME_NONNULL_BEGIN

/// 帳本：所有交易的容器與查詢邏輯。對外只回不可變型別。
@interface LBLedger : NSObject

/// 依日期倒序（最新在前）的快照；每次呼叫都是新的不可變陣列。
@property (nonatomic, copy, readonly) NSArray<LBTransaction *> *transactions;

/// 加入一筆交易；相同 identifier 已存在時忽略。
- (void)addTransaction:(LBTransaction *)tx;

/// 依 identifier 移除；找到並移除回 YES。
- (BOOL)removeTransactionWithIdentifier:(NSUUID *)identifier;

- (nullable LBTransaction *)transactionWithIdentifier:(NSUUID *)identifier;

/// 依年月分組，月份倒序；每個區段內的交易也依日期倒序。
- (NSArray<LBMonthSection *> *)transactionsGroupedByMonth;

/// 某一種類的金額加總。
- (NSDecimalNumber *)totalForKind:(LBTransactionKind)kind;

@end

NS_ASSUME_NONNULL_END
