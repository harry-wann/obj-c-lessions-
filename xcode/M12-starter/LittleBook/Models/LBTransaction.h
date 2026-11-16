@import Foundation;
#import "LBTypes.h"

@class LBCategory;   // 前置宣告即可，.m 才 #import

NS_ASSUME_NONNULL_BEGIN

/// 字典表示法（M09）用的 key。JSON 檔與 dictionaryRepresentation 共用，改名要考慮舊檔遷移。
extern NSString * const LBTransactionKeyIdentifier;   // NSString（UUID）
extern NSString * const LBTransactionKeyAmount;       // NSString（"1280.5"，避免 double 誤差）
extern NSString * const LBTransactionKeyKind;         // NSNumber（0 支出 / 1 收入）
extern NSString * const LBTransactionKeyDate;         // NSNumber（timeIntervalSince1970，UTC 不受時區影響）
extern NSString * const LBTransactionKeyNote;         // NSString
extern NSString * const LBTransactionKeyCategory;     // NSString（分類路徑「飲食/午餐」，可省略）
extern NSString * const LBTransactionKeyFlags;        // NSNumber（可省略，預設 0）

/// 一筆交易。不可變：所有屬性 readonly，建立後不能改；因此 copy 可以直接回傳自己。
/// M09：<NSSecureCoding>（NSKeyedArchiver）與字典表示法（JSON 存檔）。
@interface LBTransaction : NSObject <NSCopying, NSSecureCoding>

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
/// TODO: M12 — 12.1：加 NS_SWIFT_NAME(init(amount:note:))，Swift 端寫 LBTransaction(amount:note:)。
+ (instancetype)expenseWithAmount:(NSDecimalNumber *)amount note:(NSString *)note;

#pragma mark - M09：字典表示法

/// 只含 plist / JSON 型別（NSString / NSNumber），可直接丟給 NSJSONSerialization。
- (NSDictionary<NSString *, id> *)dictionaryRepresentation;

/// 從字典還原（含 identifier）。防禦：缺欄位、型別錯、NSNull、金額非正數都回 nil 並填 error
/// （LBErrorDomain / LBErrorCodeUnexpectedType）。分類路徑在 +[LBCategory defaultTree] 找不到就當未分類。
- (nullable instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dictionary
                                      error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
