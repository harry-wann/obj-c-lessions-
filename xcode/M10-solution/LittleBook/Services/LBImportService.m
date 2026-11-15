#import "LBImportService.h"
#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBCategory.h"
#import "LBCategory+LBPath.h"

NSString * const LBImportCSVHeader = @"timestamp,kind,amount,category,note";

static const NSTimeInterval LBImportProgressInterval = 0.1;   // 進度回報節流：100 ms

@implementation LBImportService {
    dispatch_queue_t _queue;   // 串列：同時只跑一個匯入
}

- (instancetype)initWithLedger:(LBLedger *)ledger {
    NSParameterAssert(ledger != nil);
    if ((self = [super init])) {
        _ledger = ledger;
        _queue = dispatch_queue_create("com.littlebook.import", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - 解析

/// 解析一列；格式錯回 nil。categories 是「路徑 → 節點」的快取，避免每列都走一次樹。
+ (nullable LBTransaction *)lb_transactionFromLine:(NSString *)line
                                        categories:(NSMutableDictionary *)categories {
    NSArray<NSString *> *fields = [line componentsSeparatedByString:@","];
    if (fields.count < 5) {
        return nil;
    }
    NSScanner *scanner = [NSScanner scannerWithString:fields[0]];
    double timestamp = 0;
    if (![scanner scanDouble:&timestamp] || !scanner.isAtEnd) {
        return nil;
    }
    LBTransactionKind kind;
    if ([fields[1] isEqualToString:@"expense"]) {
        kind = LBTransactionKindExpense;
    } else if ([fields[1] isEqualToString:@"income"]) {
        kind = LBTransactionKindIncome;
    } else {
        return nil;
    }
    static NSLocale *posix = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        posix = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    });
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:fields[2] locale:posix];
    NSDecimal decimal = amount.decimalValue;
    if (NSDecimalIsNotANumber(&decimal)
        || [amount compare:NSDecimalNumber.zero] != NSOrderedDescending) {
        return nil;
    }

    LBCategory *category = nil;
    NSString *path = fields[3];
    if (path.length > 0) {
        id cached = categories[path];
        if (cached == nil) {
            cached = [LBCategory lb_categoryWithPath:path] ?: (id)[NSNull null];
            categories[path] = cached;
        }
        category = (cached == [NSNull null]) ? nil : cached;
    }

    NSString *note = fields[4];
    if (fields.count > 5) {   // note 裡有逗號
        note = [[fields subarrayWithRange:NSMakeRange(4, fields.count - 4)]
                componentsJoinedByString:@","];
    }
    return [[LBTransaction alloc] initWithAmount:amount
                                            kind:kind
                                            date:[NSDate dateWithTimeIntervalSince1970:timestamp]
                                            note:note
                                        category:category];
}

#pragma mark - 匯入

- (NSProgress *)importCSVAtURL:(NSURL *)url
                     batchSize:(NSUInteger)batchSize
                      progress:(void (^)(NSUInteger, NSUInteger))progressBlock
                    completion:(void (^)(NSError *))completion {
    NSParameterAssert(url != nil);
    NSParameterAssert(completion != nil);
    NSUInteger size = MAX(batchSize, (NSUInteger)1);
    NSProgress *progress = [NSProgress discreteProgressWithTotalUnitCount:-1];   // 總數解析後才知道
    progress.cancellable = YES;
    LBLedger *ledger = self.ledger;

    dispatch_async(_queue, ^{
        NSError *error = nil;
        // 1. 讀檔：mapped 讓大檔不必整個複製進記憶體
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe
                                               error:&error];
        NSString *text = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                              : nil;
        if (text == nil) {
            NSError *result = error ?: [NSError errorWithDomain:LBErrorDomain
                                                           code:LBErrorCodeMalformedJSON
                                                       userInfo:@{NSLocalizedDescriptionKey:
                                                                      @"CSV 不是 UTF-8 文字"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(result);
            });
            return;
        }

        // 2. 切行；第一行是標題
        NSMutableArray<NSString *> *lines = [NSMutableArray array];
        [text enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            if (line.length > 0) {
                [lines addObject:line];
            }
        }];
        BOOL hasHeader = lines.count > 0 && [lines[0] isEqualToString:LBImportCSVHeader];
        NSUInteger start = hasHeader ? 1 : 0;
        NSUInteger total = lines.count - start;
        progress.totalUnitCount = (int64_t)total;

        // 3. 逐列解析、湊滿一批就丟給帳本（一次 barrier），進度最多每 100 ms 回報一次
        NSMutableDictionary<NSString *, id> *categories = [NSMutableDictionary dictionary];
        NSMutableArray<LBTransaction *> *batch = [NSMutableArray arrayWithCapacity:size];
        NSTimeInterval lastReport = 0;
        NSUInteger done = 0;
        BOOL cancelled = NO;
        for (NSUInteger i = start; i < lines.count; i++) {
            if (progress.isCancelled) {
                cancelled = YES;
                break;
            }
            @autoreleasepool {   // 迴圈裡大量暫時物件：每列就放掉，壓低記憶體峰值
                LBTransaction *tx = [LBImportService lb_transactionFromLine:lines[i]
                                                                 categories:categories];
                if (tx != nil) {
                    [batch addObject:tx];
                }
            }
            done += 1;
            if (batch.count >= size) {
                [ledger performBatchImport:[batch copy]];
                [batch removeAllObjects];
            }
            progress.completedUnitCount = (int64_t)done;
            NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
            if (progressBlock != nil && now - lastReport >= LBImportProgressInterval) {
                lastReport = now;
                NSUInteger reportedDone = done;
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressBlock(reportedDone, total);
                });
            }
        }
        if (batch.count > 0 && !cancelled) {
            [ledger performBatchImport:[batch copy]];
        }

        // 4. 等帳本把所有批次寫完，completion 時呼叫端一定讀得到
        [ledger waitForPendingWrites];
        NSError *result = nil;
        if (cancelled) {
            result = [NSError errorWithDomain:LBErrorDomain
                                         code:LBErrorCodeCancelled
                                     userInfo:@{NSLocalizedDescriptionKey: @"匯入已取消"}];
        }
        NSUInteger finalDone = done;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!cancelled && progressBlock != nil) {
                progressBlock(finalDone, total);   // 最後一次一定回報 100%
            }
            completion(result);
        });
    });
    return progress;
}

#pragma mark - 測試資料

+ (NSURL *)generateSampleCSVWithCount:(NSUInteger)count error:(NSError **)error {
    // 葉節點路徑：飲食/早餐、交通/捷運 …；收入只用「收入/薪資」
    NSMutableArray<NSString *> *expensePaths = [NSMutableArray array];
    NSString *incomePath = @"收入/薪資";
    for (LBCategory *root in [LBCategory defaultTree]) {
        for (LBCategory *node in [root flattened]) {
            if (node.children.count == 0 && ![[node lb_path] isEqualToString:incomePath]) {
                [expensePaths addObject:[node lb_path]];
            }
        }
    }
    NSArray<NSString *> *notes = @[@"便當", @"咖啡", @"捷運", @"晚餐", @"電影", @"房租", @"水電"];

    NSMutableString *csv = [NSMutableString stringWithCapacity:(count + 1) * 48];
    [csv appendString:LBImportCSVHeader];
    [csv appendString:@"\n"];
    NSTimeInterval now = floor(NSDate.date.timeIntervalSince1970);
    NSTimeInterval step = count > 0 ? (365.0 * 86400.0) / (double)count : 0;
    for (NSUInteger i = 0; i < count; i++) {
        @autoreleasepool {
            BOOL income = (i % 20 == 0);
            // 固定公式產生的「假亂數」：同樣的 count 每次產生一樣的檔，方便比較數字
            unsigned long cents = (unsigned long)((i * 7919 + 13) % 200000) + 100;
            if (income) {
                cents *= 20;
            }
            NSString *path = income ? incomePath : expensePaths[i % expensePaths.count];
            [csv appendFormat:@"%.0f,%@,%lu.%02lu,%@,%@ #%lu\n",
             now - floor((double)i * step), income ? @"income" : @"expense",
             cents / 100, cents % 100, path, notes[i % notes.count], (unsigned long)(i + 1)];
        }
    }

    NSString *name = [NSString stringWithFormat:@"LittleBook-sample-%lu-%@.csv",
                      (unsigned long)count, NSUUID.UUID.UUIDString];
    NSURL *url = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
                  URLByAppendingPathComponent:name];
    NSData *data = [csv dataUsingEncoding:NSUTF8StringEncoding];
    if (![data writeToURL:url options:NSDataWritingAtomic error:error]) {
        return nil;
    }
    return url;
}

@end
