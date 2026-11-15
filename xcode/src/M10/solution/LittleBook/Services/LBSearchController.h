@import Foundation;

@class LBLedger, LBTransaction;

NS_ASSUME_NONNULL_BEGIN

typedef void (^LBSearchResultsBlock)(NSArray<LBTransaction *> *results, NSString *query);

/// 搜尋（10.6，畫面 03）：輸入 → debounce → NSOperationQueue 背景過濾（可取消）→ 主執行緒回呼。
/// 世代計數（generation counter）：每次 search: 世代 +1；結果回到主執行緒時世代不是最新就丟掉，
/// 所以「舊查詢比較慢、晚到」也不會蓋掉新結果。只在主執行緒呼叫。
@interface LBSearchController : NSObject

- (instancetype)initWithLedger:(LBLedger *)ledger NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) LBLedger *ledger;

/// 預設 0.25 秒。
@property (nonatomic, assign) NSTimeInterval debounceInterval;

/// 測試用：讓背景過濾額外等這麼久再回傳（模擬大量資料時的慢查詢）。預設 0。
/// 在 search: 被呼叫的當下讀取。
@property (nonatomic, assign) NSTimeInterval simulatedLatency;

/// 目前的世代（每次 search: / cancel 都 +1）。
@property (nonatomic, assign, readonly) NSUInteger generation;

/// 最近一次「有回呼」的搜尋，從開始過濾到結果回到主執行緒花的秒數。
@property (nonatomic, assign, readonly) NSTimeInterval lastDuration;

/// 比對備註與分類名稱（不分大小寫、不分全半形重音）；空白查詢回傳全部交易。
/// results 在主執行緒呼叫，而且只有最新一次 search: 的結果會回呼。
- (void)search:(NSString *)query results:(LBSearchResultsBlock)results;

/// 取消等待中的 debounce 與正在跑的過濾；之前的 search: 都不會再回呼。
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
