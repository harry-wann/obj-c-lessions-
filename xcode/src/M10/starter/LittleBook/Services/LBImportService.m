#import "LBImportService.h"
#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBCategory.h"
#import "LBCategory+LBPath.h"

NSString * const LBImportCSVHeader = @"timestamp,kind,amount,category,note";

@implementation LBImportService

- (instancetype)initWithLedger:(LBLedger *)ledger {
    NSParameterAssert(ledger != nil);
    if ((self = [super init])) {
        _ledger = ledger;
        // TODO: M10 — 建一條串列佇列給匯入用
    }
    return self;
}

- (NSProgress *)importCSVAtURL:(NSURL *)url
                     batchSize:(NSUInteger)batchSize
                      progress:(void (^)(NSUInteger, NSUInteger))progressBlock
                    completion:(void (^)(NSError *))completion {
    // TODO: M10 — 回傳 cancellable 的 NSProgress；背景佇列：讀檔 → 切行（第一行標題）→ 逐列解析
    //            （迴圈內 @autoreleasepool、每列檢查 progress.isCancelled）→ 每 batchSize 筆
    //            [ledger performBatchImport:] → 進度最多每 100 ms 丟回主佇列一次、結束再報一次 →
    //            [ledger waitForPendingWrites] → 主佇列 completion（取消時 LBErrorCodeCancelled）
    NSProgress *progress = [NSProgress discreteProgressWithTotalUnitCount:-1];
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil);
    });
    return progress;
}

+ (NSURL *)generateSampleCSVWithCount:(NSUInteger)count error:(NSError **)error {
    // TODO: M10 — 第一行 LBImportCSVHeader，之後 count 列（日期由新到舊），寫到 NSTemporaryDirectory()
    return nil;
}

@end
