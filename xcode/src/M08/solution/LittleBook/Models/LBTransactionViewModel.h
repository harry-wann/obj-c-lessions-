@import Foundation;

@class LBTransaction;

NS_ASSUME_NONNULL_BEGIN

/// cell 顯示用的資料：字串在建立時就算好，cellForRowAtIndexPath: 只做賦值（M10 再加快取）。
@interface LBTransactionViewModel : NSObject

@property (nonatomic, copy, readonly) NSString *title;        // 備註；空的話用分類名
@property (nonatomic, copy, readonly) NSString *subtitle;     // 「分類 · 日期」
@property (nonatomic, copy, readonly) NSString *amountText;   // 「-1,280.00」/「+50,000.00」
@property (nonatomic, copy, readonly) NSString *symbolName;   // SF Symbol 名稱
@property (nonatomic, assign, readonly) BOOL isExpense;

+ (instancetype)viewModelWithTransaction:(LBTransaction *)tx;
- (instancetype)initWithTransaction:(LBTransaction *)tx NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
