#import "LBPersistence.h"
#import "LBLedger.h"
#import "LBTransaction.h"

NSString * const LBPersistenceFileName = @"ledger.json";

static NSString * const LBPersistenceVersionKey = @"version";
static NSString * const LBPersistenceTransactionsKey = @"transactions";
static const NSInteger LBPersistenceCurrentVersion = 1;

@implementation LBPersistence {
    dispatch_queue_t _writeQueue;   // 串列：兩次背景存檔不會同時寫同一個檔
}

+ (NSURL *)defaultDirectoryURL {
    // 不要寫死路徑：沙盒路徑每次安裝（甚至每次啟動）都可能不同
    NSURL *support = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory
                                                          inDomains:NSUserDomainMask].firstObject;
    if (support == nil) {
        support = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    }
    return [support URLByAppendingPathComponent:@"LittleBook" isDirectory:YES];
}

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL {
    NSParameterAssert(directoryURL != nil);
    NSParameterAssert(directoryURL.isFileURL);
    if ((self = [super init])) {
        _directoryURL = [directoryURL copy];
        _fileURL = [_directoryURL URLByAppendingPathComponent:LBPersistenceFileName
                                                 isDirectory:NO];
        _writeQueue = dispatch_queue_create("com.littlebook.persistence", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - 錯誤

+ (NSError *)lb_errorWithCode:(LBErrorCode)code
                  description:(NSString *)description
              underlyingError:(nullable NSError *)underlying {
    NSMutableDictionary<NSErrorUserInfoKey, id> *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = description;
    if (underlying != nil) {
        userInfo[NSUnderlyingErrorKey] = underlying;
    }
    return [NSError errorWithDomain:LBErrorDomain code:code userInfo:userInfo];
}

#pragma mark - 寫入

/// 快照 → 字典陣列 → JSON → 原子寫入。只碰傳進來的陣列，可以在任何執行緒呼叫。
- (BOOL)lb_writeTransactions:(NSArray<LBTransaction *> *)transactions error:(NSError **)error {
    NSMutableArray<NSDictionary *> *items = [NSMutableArray arrayWithCapacity:transactions.count];
    for (LBTransaction *tx in transactions) {
        [items addObject:[tx dictionaryRepresentation]];
    }
    NSDictionary *root = @{
        LBPersistenceVersionKey: @(LBPersistenceCurrentVersion),
        LBPersistenceTransactionsKey: items,
    };
    NSData *data = [NSJSONSerialization dataWithJSONObject:root options:0 error:error];
    if (data == nil) {
        return NO;
    }
    if (![NSFileManager.defaultManager createDirectoryAtURL:_directoryURL
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:error]) {
        return NO;
    }
    // NSDataWritingAtomic：先寫到暫存檔，成功才 rename 蓋過舊檔
    return [data writeToURL:_fileURL options:NSDataWritingAtomic error:error];
}

- (BOOL)saveLedger:(LBLedger *)ledger error:(NSError **)error {
    NSParameterAssert(ledger != nil);
    return [self lb_writeTransactions:ledger.transactions error:error];
}

- (void)saveLedger:(LBLedger *)ledger completion:(void (^)(NSError *))completion {
    NSParameterAssert(ledger != nil);
    NSArray<LBTransaction *> *snapshot = ledger.transactions;   // 在呼叫端取快照
    dispatch_async(_writeQueue, ^{
        NSError *error = nil;
        BOOL ok = [self lb_writeTransactions:snapshot error:&error];
        NSError *result = ok ? nil : error;
        if (completion != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(result);
            });
        }
    });
}

#pragma mark - 讀取

- (LBLedger *)loadLedgerWithError:(NSError **)error {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    if (![fileManager fileExistsAtPath:_fileURL.path]) {
        return [[LBLedger alloc] init];   // 第一次啟動：沒有檔案不是錯誤
    }

    NSError *readError = nil;
    NSData *data = [NSData dataWithContentsOfURL:_fileURL options:0 error:&readError];
    if (data == nil) {
        if (error != NULL) {
            *error = readError;   // I/O 錯誤（權限等）：原樣往上傳
        }
        return nil;
    }

    NSError *jsonError = nil;
    id root = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    id items = [root isKindOfClass:[NSDictionary class]]
        ? ((NSDictionary *)root)[LBPersistenceTransactionsKey] : nil;
    if (![items isKindOfClass:[NSArray class]]) {
        if (error != NULL) {
            *error = [LBPersistence lb_errorWithCode:LBErrorCodeMalformedJSON
                                         description:@"帳本檔案格式不正確"
                                     underlyingError:jsonError];
        }
        return nil;
    }

    NSMutableArray<LBTransaction *> *transactions =
        [NSMutableArray arrayWithCapacity:((NSArray *)items).count];
    for (id item in (NSArray *)items) {
        if (![item isKindOfClass:[NSDictionary class]]) {
            if (error != NULL) {
                *error = [LBPersistence lb_errorWithCode:LBErrorCodeMalformedJSON
                                             description:@"帳本檔案裡有不是物件的交易"
                                         underlyingError:nil];
            }
            return nil;
        }
        NSError *itemError = nil;
        LBTransaction *tx = [[LBTransaction alloc] initWithDictionary:item error:&itemError];
        if (tx == nil) {
            if (error != NULL) {
                *error = itemError;
            }
            return nil;
        }
        [transactions addObject:tx];
    }
    // 一次建好整本帳：排序一次、算一次總額（逐筆 add 在 10 萬筆時會非常慢）
    return [[LBLedger alloc] initWithTransactions:transactions];
}

@end
