@import Foundation;

@class LBLedger, LBTransaction;

NS_ASSUME_NONNULL_BEGIN

/// 帳本的委派協定。方法名以來源物件開頭（ledger:didAdd…），是 Cocoa 的命名慣例。
@protocol LBLedgerObserver <NSObject>

@required
- (void)ledger:(LBLedger *)ledger didAddTransaction:(LBTransaction *)transaction;

@optional
/// 呼叫前必須先用 respondsToSelector: 檢查。
- (void)ledgerDidReset:(LBLedger *)ledger;

@end

NS_ASSUME_NONNULL_END
