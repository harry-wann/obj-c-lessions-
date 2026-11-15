@import Foundation;
#import "LBTypes.h"

@class LBCategory;   // 前置宣告即可，.m 才 #import

NS_ASSUME_NONNULL_BEGIN

/// 一筆交易。不可變：所有屬性 readonly，建立後不能改；因此 copy 可以直接回傳自己。
@interface LBTransaction : NSObject <NSCopying>

@property (nonatomic, copy, readonly) NSUUID *identifier;
@property (nonatomic, strong, readonly) NSDecimalNumber *amount;   // 永遠為正，方向看 kind
@property (nonatomic, assign, readonly) LBTransactionKind kind;
@property (nonatomic, copy, readonly) NSDate *date;
@property (nonatomic, copy, readonly) NSString *note;
@property (nonatomic, strong, readonly, nullable) LBCategory *category;
@property (nonatomic, assign, readonly) LBTransactionFlags flags;

/// 指定初始化器（M08 加 flags）：identifier 自動產生，amount 若為負會取絕對值。
- (instancetype)initWithAmount:(NSDecimalNumber *)amount
                          kind:(LBTransactionKind)kind
                          date:(NSDate *)date
                          note:(NSString *)note
                      category:(nullable LBCategory *)category
                         flags:(LBTransactionFlags)flags NS_DESIGNATED_INITIALIZER;

/// 便利初始化器：flags 為 None（M02 起的簽名，保留給舊呼叫端與測試）。
- (instancetype)initWithAmount:(NSDecimalNumber *)amount
                          kind:(LBTransactionKind)kind
                          date:(NSDate *)date
                          note:(NSString *)note
                      category:(nullable LBCategory *)category;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 工廠方法：今天的支出，沒有分類。
+ (instancetype)expenseWithAmount:(NSDecimalNumber *)amount note:(NSString *)note;

@end

NS_ASSUME_NONNULL_END
