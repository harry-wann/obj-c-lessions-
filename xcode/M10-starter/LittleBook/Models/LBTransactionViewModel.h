@import Foundation;

@class LBTransaction;

NS_ASSUME_NONNULL_BEGIN

/// cell 顯示用的資料：字串在建立時就算好，cellForRowAtIndexPath: 只做賦值。
/// M10：viewModelWithTransaction: 經過 LBLRUCache（key = identifier）快取，
/// 同一筆交易只格式化一次（LBTransaction 不可變，identifier 相同內容就相同）。
@interface LBTransactionViewModel : NSObject

@property (nonatomic, copy, readonly) NSString *title;        // 備註；空的話用分類名
@property (nonatomic, copy, readonly) NSString *subtitle;     // 「分類 · 日期」
@property (nonatomic, copy, readonly) NSString *amountText;   // 「-1,280.00」/「+50,000.00」
@property (nonatomic, copy, readonly) NSString *symbolName;   // SF Symbol 名稱
@property (nonatomic, assign, readonly) BOOL isExpense;

/// 先查快取，沒有才建立並放進快取。
+ (instancetype)viewModelWithTransaction:(LBTransaction *)tx;
/// 直接建立（一定會格式化一次，不經過快取）。
- (instancetype)initWithTransaction:(LBTransaction *)tx NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// M10 測試用：到目前為止真正做了幾次格式化（initWithTransaction: 的次數）。
+ (NSUInteger)formattingCount;

/// 清空快取並把 formattingCount 歸零。設定（顯示小數位）改變時也要呼叫。
+ (void)resetCache;

/// 快取容量（筆）。
+ (NSUInteger)cacheCapacity;

@end

NS_ASSUME_NONNULL_END
