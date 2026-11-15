@import Foundation;

@class LBTransaction;

NS_ASSUME_NONNULL_BEGIN

/// 列表的一個月份區段：該月所有交易（依日期倒序）與收支合計。
@interface LBMonthSection : NSObject

@property (nonatomic, assign, readonly) NSInteger year;
@property (nonatomic, assign, readonly) NSInteger month;
@property (nonatomic, copy, readonly) NSArray<LBTransaction *> *transactions;
@property (nonatomic, strong, readonly) NSDecimalNumber *expenseTotal;
@property (nonatomic, strong, readonly) NSDecimalNumber *incomeTotal;

- (instancetype)initWithYear:(NSInteger)year
                       month:(NSInteger)month
                transactions:(NSArray<LBTransaction *> *)transactions NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
