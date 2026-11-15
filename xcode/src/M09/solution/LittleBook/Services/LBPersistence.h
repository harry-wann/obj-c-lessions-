@import Foundation;
#import "LBTypes.h"

@class LBLedger;

NS_ASSUME_NONNULL_BEGIN

/// 存檔的檔名（在 directoryURL 底下）。
extern NSString * const LBPersistenceFileName;   // @"ledger.json"

/// 整本帳存成一個 JSON 檔（9.4）：
///   {"version": 1, "transactions": [ {...LBTransaction dictionaryRepresentation...}, ... ]}
/// 寫入用 NSDataWritingAtomic（先寫暫存檔再 rename，當機不會留下半個檔）；
/// 讀回來的每個欄位都要防禦（7.7 的同一套）。
@interface LBPersistence : NSObject

/// App 預設：Application Support/LittleBook/（不會被使用者看到，會被備份）。
+ (NSURL *)defaultDirectoryURL;

/// 測試傳 NSTemporaryDirectory() 底下的子資料夾。資料夾不存在時，第一次存檔會自動建立。
- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, copy, readonly) NSURL *directoryURL;
@property (nonatomic, copy, readonly) NSURL *fileURL;

/// 同步寫入（呼叫端自己決定在哪條執行緒）。失敗回 NO 並填 error。
- (BOOL)saveLedger:(LBLedger *)ledger error:(NSError **)error;

/// 檔案不存在 → 空帳本（非 nil、error 不填）；壞檔 → nil + LBErrorCodeMalformedJSON；
/// 某筆交易欄位錯 → nil + LBErrorCodeUnexpectedType。
- (nullable LBLedger *)loadLedgerWithError:(NSError **)error;

/// 在背景串列佇列寫入，完成後在主佇列呼叫 completion（成功時 error 為 nil）。
/// 先在呼叫端取快照（ledger.transactions），之後帳本再變動也不影響這次寫入的內容。
- (void)saveLedger:(LBLedger *)ledger
        completion:(nullable void (^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
