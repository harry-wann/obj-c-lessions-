#import "LBPersistence.h"
#import "LBLedger.h"
#import "LBTransaction.h"

NSString * const LBPersistenceFileName = @"ledger.json";

@implementation LBPersistence

+ (NSURL *)defaultDirectoryURL {
    // TODO: M09 — NSFileManager URLsForDirectory:NSApplicationSupportDirectory … ＋ @"LittleBook"
    //            （不要寫死路徑）
    return [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
}

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL {
    NSParameterAssert(directoryURL != nil);
    if ((self = [super init])) {
        _directoryURL = [directoryURL copy];
        _fileURL = [_directoryURL URLByAppendingPathComponent:LBPersistenceFileName
                                                 isDirectory:NO];
        // TODO: M09 — 建一條串列 dispatch queue 給背景存檔用
    }
    return self;
}

- (BOOL)saveLedger:(LBLedger *)ledger error:(NSError **)error {
    // TODO: M09 — {"version":1,"transactions":[dictionaryRepresentation…]} → NSJSONSerialization
    //            → 建資料夾（withIntermediateDirectories:YES）→ writeToURL:options:NSDataWritingAtomic
    return NO;
}

- (LBLedger *)loadLedgerWithError:(NSError **)error {
    // TODO: M09 — 檔案不存在 → 回空帳本（不是錯誤）；JSON 壞掉 / 結構不對 → LBErrorCodeMalformedJSON；
    //            每筆用 initWithDictionary:error:；最後用 [[LBLedger alloc] initWithTransactions:]
    return nil;
}

- (void)saveLedger:(LBLedger *)ledger completion:(void (^)(NSError *))completion {
    // TODO: M09 — 先取快照 ledger.transactions，背景串列佇列寫入，主佇列呼叫 completion
}

@end
