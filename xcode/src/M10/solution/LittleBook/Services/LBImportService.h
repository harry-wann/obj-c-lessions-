@import Foundation;
#import "LBTypes.h"

@class LBLedger;

NS_ASSUME_NONNULL_BEGIN

/// CSV 欄位（第一行是標題，固定為這一行）：
///   timestamp,kind,amount,category,note
///   1762300800,expense,120.50,飲食/午餐,測試資料 #1
/// timestamp 是 timeIntervalSince1970；kind 是 expense / income；category 是分類路徑（可空白）；
/// 簡化版 CSV：不處理引號，note 裡多出來的逗號視為 note 的一部分。格式錯的列略過不算錯誤。
extern NSString * const LBImportCSVHeader;

/// 大量匯入（10.3）：背景佇列解析，每 batchSize 筆呼叫一次 -[LBLedger performBatchImport:]，
/// 進度回報節流（最多每 100 ms 一次，加上結束時一次），可用回傳的 NSProgress 取消。
@interface LBImportService : NSObject

- (instancetype)initWithLedger:(LBLedger *)ledger NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) LBLedger *ledger;

/// progress 與 completion 都在主佇列呼叫。取消後 completion 收到 LBErrorCodeCancelled，
/// 已經送進帳本的批次會保留（和「匯入到一半斷電」一樣，由呼叫端決定要不要清掉）。
/// completion 被呼叫時，已送出的批次都已寫入帳本（讀得到）。
- (NSProgress *)importCSVAtURL:(NSURL *)url
                     batchSize:(NSUInteger)batchSize
                      progress:(nullable void (^)(NSUInteger done, NSUInteger total))progress
                    completion:(void (^)(NSError * _Nullable error))completion;

/// 在 NSTemporaryDirectory() 產生 count 筆測試資料（日期由新到舊，分散在最近一年），回傳檔案位置。
+ (nullable NSURL *)generateSampleCSVWithCount:(NSUInteger)count error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
