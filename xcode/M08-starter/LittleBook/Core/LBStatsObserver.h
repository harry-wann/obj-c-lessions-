@import Foundation;

@class LBLedger;

NS_ASSUME_NONNULL_BEGIN

/// 6.4 範例：用 KVO 觀察 ledger.total。示範三件事：
/// 1. context 用「靜態變數的位址」而不是字串，才能和父類別 / 子類別的觀察區分開；
/// 2. 不是自己的 context 一定要轉給 super；
/// 3. dealloc 要 removeObserver:，否則帳本下次通知就是對殭屍物件送訊息。
@interface LBStatsObserver : NSObject

@property (nonatomic, strong, readonly) LBLedger *ledger;
@property (nonatomic, strong, readonly) NSDecimalNumber *lastTotal;
@property (nonatomic, assign, readonly) NSUInteger changeCount;

/// 每次 total 改變時呼叫（在主執行緒）。
@property (nonatomic, copy, nullable) void (^onChange)(NSDecimalNumber *total);

- (instancetype)initWithLedger:(LBLedger *)ledger NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
