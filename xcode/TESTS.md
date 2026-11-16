# 里程碑測試清單（課文的 Xcode 任務與起始專案共用，名稱不可改）

專案以 XcodeGen `project.yml` 描述；在 Mac 上 `brew install xcodegen` 後於專案資料夾執行 `xcodegen generate`，再開 `.xcodeproj`，⌘U 跑測試。
App target：`LittleBook`（iOS 17+，Objective-C）。測試 target：`LittleBookTests`。
`xcode/Scratch`：macOS Command Line Tool（Objective-C），`main.m` 當草稿本。

| 里程碑 | 測試（類別/方法） | 對應章節 |
|---|---|---|
| M0 | （無測試）Scratch 可執行；LittleBook 可在模擬器啟動 | 0.2、0.3 |
| M1 | `LBTypesTests/testTransactionKindValues`、`LBTypesTests/testFlagsCombine`、`LBTypesTests/testErrorDomainConstant`、`LBTypesTests/testFormatCents` | 1.3、1.4、1.5 |
| M2 | `LBTransactionTests/testDesignatedInitializerSetsProperties`、`LBTransactionTests/testNoteIsCopied`、`LBTransactionTests/testPropertiesAreReadonlyFromOutside`、`LBTransactionTests/testEqualityAndHash`、`LBTransactionTests/testCopyReturnsEqualObject`、`LBTransactionTests/testDescriptionContainsAmount`、`LBCategoryTests/testDepth`、`LBCategoryTests/testParentIsWeak`、`LBCategoryTests/testFlattened` | 2.1–2.8 |
| M3 | `LBLedgerTests/testAddAndRemove`、`LBLedgerTests/testTransactionsSortedByDateDescending`、`LBLedgerTests/testGroupedByMonth`、`LBLedgerTests/testTotalForKind`、`LBLedgerTests/testTransactionsReturnsImmutableSnapshot`、`LBHashMapTests/testSetAndGet`、`LBHashMapTests/testOverwrite`、`LBHashMapTests/testRemove`、`LBHashMapTests/testGrowsBeyondInitialBuckets`、`LBHashMapTests/testCustomKeyUsesHashAndIsEqual` | 3.1–3.7 |
| M4 | `LBLeakTests/testTimerTargetReleased`、`LBLeakTests/testDelegateDoesNotRetain`、`LBLeakTests/testBlockDoesNotRetainSelf`、`LBLinkedListTests/testAppendAndCount`、`LBLinkedListTests/testRemoveNode`、`LBLinkedListTests/testPrevIsWeak`、`LBLinkedListTests/testIteration`、`LBLRUCacheTests/testEvictsLeastRecentlyUsed`、`LBLRUCacheTests/testGetMovesToFront`、`LBLRUCacheTests/testCapacity` | 4.1–4.5 |
| M5 | `LBLedgerObserverTests/testDelegateCalledOnAdd`、`LBLedgerObserverTests/testOptionalMethodNotRequired`、`LBFormattingTests/testCurrencyString`、`LBFunctionalTests/testMap`、`LBFunctionalTests/testFilter`、`LBFunctionalTests/testReduce`、`LBUndoStackTests/testUndoRedo`、`LBUndoStackTests/testRedoClearedOnNewAction`、`LBUndoStackTests/testUndoRemovesTransaction` | 5.1–5.7 |

## 共用型別與類別（名稱固定）

```objc
// LBTypes.h（M1）
typedef NS_ENUM(NSInteger, LBTransactionKind) { LBTransactionKindExpense = 0, LBTransactionKindIncome = 1 };
typedef NS_OPTIONS(NSUInteger, LBTransactionFlags) { LBTransactionFlagsNone = 0, LBTransactionFlagsReconciled = 1 << 0, LBTransactionFlagsRecurring = 1 << 1 };
extern NSString * const LBErrorDomain;          // @"com.littlebook.error"
NSString *LBFormatCents(long long cents);       // 128000 → @"1,280.00"

// LBTransaction（M2，不可變，NSCopying）
@property (nonatomic, copy, readonly) NSUUID *identifier;
@property (nonatomic, strong, readonly) NSDecimalNumber *amount;   // 永遠為正
@property (nonatomic, assign, readonly) LBTransactionKind kind;
@property (nonatomic, copy, readonly) NSDate *date;
@property (nonatomic, copy, readonly) NSString *note;
@property (nonatomic, strong, readonly, nullable) LBCategory *category;
@property (nonatomic, assign, readonly) LBTransactionFlags flags;
- (instancetype)initWithAmount:(NSDecimalNumber *)amount kind:(LBTransactionKind)kind date:(NSDate *)date note:(NSString *)note category:(nullable LBCategory *)category NS_DESIGNATED_INITIALIZER;
+ (instancetype)expenseWithAmount:(NSDecimalNumber *)amount note:(NSString *)note;

// LBCategory（M2，樹節點）
@property (nonatomic, copy, readonly) NSString *identifier, *name, *symbolName;
@property (nonatomic, weak, readonly, nullable) LBCategory *parent;
@property (nonatomic, copy, readonly) NSArray<LBCategory *> *children;
- (instancetype)initWithName:(NSString *)name symbolName:(NSString *)symbolName;
- (void)addChild:(LBCategory *)child;
- (NSUInteger)depth;
- (NSArray<LBCategory *> *)flattened;            // 深度優先，含自己

// LBLedger（M3；M5 加 delegate）
@property (nonatomic, copy, readonly) NSArray<LBTransaction *> *transactions;   // 依日期倒序的快照
@property (nonatomic, weak, nullable) id<LBLedgerObserver> delegate;          // M5
- (void)addTransaction:(LBTransaction *)tx;
- (BOOL)removeTransactionWithIdentifier:(NSUUID *)identifier;
- (nullable LBTransaction *)transactionWithIdentifier:(NSUUID *)identifier;
- (NSArray<LBMonthSection *> *)transactionsGroupedByMonth;
- (NSDecimalNumber *)totalForKind:(LBTransactionKind)kind;

// LBMonthSection（M3）
@property (nonatomic, assign, readonly) NSInteger year, month;
@property (nonatomic, copy, readonly) NSArray<LBTransaction *> *transactions;
@property (nonatomic, strong, readonly) NSDecimalNumber *expenseTotal, *incomeTotal;

// LBHashMap（M3，鏈結法）  - setObject:forKey: / objectForKey: / removeObjectForKey: / count / bucketCount
// LBLinkedList / LBLinkedListNode（M4，雙向，prev weak）  - appendObject: / removeNode: / head / tail / count / enumerateObjectsUsingBlock:
// LBLRUCache（M4）  - initWithCapacity: / objectForKey: / setObject:forKey: / count
// LBLedgerObserver 協定（M5）  - required: ledger:didAddTransaction: ; optional: ledgerDidReset:
// NSDecimalNumber+LBFormatting（M5）  - lb_currencyString（@"1,280" / @"−1,280.50" 依設定）
// NSArray+LBFunctional（M5）  - lb_map: / lb_filter: / lb_reduce:initial:
// LBUndoStack（M5）  - registerUndo:(void(^)(void))undo redo:(void(^)(void))redo / undo / redo / canUndo / canRedo
```

---

# Phase 2：里程碑 M06–M12

| 里程碑 | 測試（類別/方法） | 對應章節 |
|---|---|---|
| M06 | `LBLedgerKVOTests/testTotalChangesNotifyObserver`、`LBLedgerKVOTests/testObserverRemovedOnDealloc`、`LBRouterTests/testRouteCreatesViewControllerByName`、`LBRouterTests/testUnknownRouteReturnsNil`、`LBRouterTests/testRouteRejectsNonViewControllerClass` | 6.1–6.4 |
| M07 | `LBRateServiceTests/testParsesRatesFromStubJSON`、`LBRateServiceTests/testReportsErrorOnMalformedJSON`、`LBRateServiceTests/testReportsErrorWhenRateIsNotNumber`、`LBRateServiceTests/testCompletionCalledOnMainQueue`、`LBSyncQueueTests/testFIFOOrder`、`LBSyncQueueTests/testFlushWaitsForAll`、`LBLedgerConcurrencyTests/testConcurrentReadsAndWritesDoNotCrash` | 7.1–7.7 |
| M08 | `LBTransactionListViewControllerTests/testSectionsMatchMonths`、`LBTransactionListViewControllerTests/testCellResetsAllFields`、`LBTransactionListViewControllerTests/testDeletingLastRowRemovesSection`、`LBCategoryPickerViewControllerTests/testRowsRespectExpansion`、`LBTransactionEditorViewControllerTests/testSaveCallsDelegateWithTransaction`、`LBTransactionEditorViewControllerTests/testInvalidAmountDoesNotSave` ＋ 手動驗收 12 項 | 8.1–8.8 |
| M09 | `LBPersistenceTests/testRoundTripJSON`、`LBPersistenceTests/testWritesAtomicallyToDirectory`、`LBPersistenceTests/testCorruptFileReturnsError`、`LBPersistenceTests/testMissingFileReturnsEmptyLedger`、`LBSettingsTests/testDefaultsRegistered`、`LBSettingsTests/testCurrencyCodePersists`、`LBTransactionCodingTests/testDictionaryRoundTrip`、`LBTransactionCodingTests/testSecureCodingRoundTrip` | 9.1–9.4 |
| M10 | `LBRingBufferTests/testOverwritesOldest`、`LBRingBufferTests/testAverageAndMax`、`LBFPSMonitorTests/testClassifiesDroppedFrames`、`LBImportServiceTests/testImportsInBatchesAndReportsProgress`、`LBImportServiceTests/testCancelStopsImport`、`LBSearchControllerTests/testStaleResultsAreDropped`、`LBSearchControllerTests/testDebounceCoalescesInput`、`LBLedgerConcurrencyTests/testBarrierWritesAreSerialized`、`LBLockBenchmarkTests/testAllLocksProduceSameCount`、`LBRateServiceTests/testConcurrentFetchLimitedBySemaphore`、`LBTransactionViewModelTests/testFormatsOnceAndCaches` | 10.1–10.7 |
| M11 | `LBSettingsStoryboardTests/testStoryboardInstantiatesSettingsViewController`、`LBSettingsStoryboardTests/testOutletsConnectedAfterLoadView`、`LBTransactionCellNibTests/testNibLoadsCellWithOutlets`、`LBLegacyAuditTests/testLegacyChecklistComplete`（讀 `LegacyAudit.plist` 的 6 個勾選）＋ `LittleBook-Legacy/` 手動驗收 6 項；補充：`LBSettingsStoryboardTests/testPrepareForSegueInjectsLedgerAndMonitor` | 11.1–11.7 |
| M12 | `StatsViewModelTests/testTotalsFromLedger`（Swift）、`StatsViewModelTests/testCategoryBreakdownSorted`（Swift）、`LBBridgingTests/testObjCCanInstantiateSwiftStatsViewController`、`LBBridgingTests/testNullabilityAnnotationsPresent`（掃專案所有 `.h` 都有 `NS_ASSUME_NONNULL_BEGIN / END`、`NS_SWIFT_NAME` ≥ 2 處）＋ 全套測試全綠、Analyze 零警告、`-Werror` 可建置；補充：`LBSwiftAsyncTests/testFetchRatesCanBeAwaitedFromSwift`、`LBSwiftAsyncTests/testFetchRatesErrorBecomesThrow`（Swift，`async` 呼叫 completion handler）、`LBLedgerTests/testAddingExpenseLowersTotal`（12.3 課文範例） | 12.1–12.6 |

## Phase 2 共用介面（名稱固定）

```objc
// M06 ----------------------------------------------------------------
// LBLedger：total 變成 KVO-compliant（add / remove / reset 後在主執行緒通知）
@property (nonatomic, strong, readonly) NSDecimalNumber *total;     // 收入 − 支出
// LBRouter：以字串建立 ViewController（舊專案 URL scheme 常見寫法）
@interface LBRouter : NSObject
+ (nullable UIViewController *)viewControllerForName:(NSString *)name;  // NSClassFromString + isSubclassOfClass:[UIViewController class]
+ (void)registerAlias:(NSString *)alias forClassName:(NSString *)className;
@end
// LBStatsObserver（6.4 範例）：用 KVO 觀察 ledger.total，dealloc 移除

// M07 ----------------------------------------------------------------
typedef void (^LBRatesCompletion)(NSDictionary<NSString *, NSDecimalNumber *> * _Nullable rates, NSError * _Nullable error);
@interface LBRateService : NSObject
- (instancetype)initWithSession:(NSURLSession *)session baseURL:(NSURL *)baseURL NS_DESIGNATED_INITIALIZER;
+ (nullable NSDictionary<NSString *, NSDecimalNumber *> *)ratesFromJSONData:(NSData *)data error:(NSError **)error;  // 純解析，可單測
- (void)fetchRatesForBase:(NSString *)base completion:(LBRatesCompletion)completion;   // 回呼切回主佇列
- (void)fetchRatesForBases:(NSArray<NSString *> *)bases maxConcurrent:(NSUInteger)max completion:(void (^)(NSDictionary<NSString *, NSDictionary *> *results, NSArray<NSError *> *errors))completion;  // M10：semaphore 限流 + dispatch_group
@end
// 錯誤碼
typedef NS_ERROR_ENUM(LBErrorDomain, LBErrorCode) { LBErrorCodeMalformedJSON = 100, LBErrorCodeUnexpectedType = 101, LBErrorCodeHTTPStatus = 102, LBErrorCodeCancelled = 103 };
// 測試用 stub：LBStubURLProtocol（NSURLProtocol 子類別）依 URL 回固定 JSON；或注入 NSURLSessionConfiguration.protocolClasses
@interface LBSyncQueue : NSObject            // 離線待同步 FIFO，內部串列 dispatch queue
- (void)enqueueTask:(void (^)(dispatch_block_t done))task;   // 任務完成時呼叫 done
- (void)flushWithCompletion:(dispatch_block_t)completion;     // dispatch_group 等全部完成，主佇列回呼
@property (nonatomic, readonly) NSUInteger pendingCount;
@end
// LBLedger：內部改用 DISPATCH_QUEUE_CONCURRENT + barrier（讀並行、寫 barrier）

// M08 ----------------------------------------------------------------
@interface LBTransactionViewModel : NSObject     // cell 顯示用，字串預先算好（M10 加快取）
@property (nonatomic, copy, readonly) NSString *title, *subtitle, *amountText, *symbolName; @property (nonatomic, readonly) BOOL isExpense;
+ (instancetype)viewModelWithTransaction:(LBTransaction *)tx;
@end
@interface LBTransactionCell : UITableViewCell       // 程式碼 Auto Layout；reuseIdentifier = @"LBTransactionCell"
- (void)configureWithViewModel:(LBTransactionViewModel *)vm;
@end
@interface LBMonthHeaderView : UITableViewHeaderFooterView
- (void)configureWithSection:(LBMonthSection *)section;
@end
@interface LBTransactionListViewController : UITableViewController
- (instancetype)initWithLedger:(LBLedger *)ledger undoStack:(LBUndoStack *)undoStack;
@property (nonatomic, copy, readonly) NSArray<LBMonthSection *> *sections;     // 測試用
@end
@protocol LBTransactionEditorDelegate <NSObject>
- (void)editor:(LBTransactionEditorViewController *)editor didSaveTransaction:(LBTransaction *)transaction;
- (void)editorDidCancel:(LBTransactionEditorViewController *)editor;
@end
@interface LBTransactionEditorViewController : UIViewController
- (instancetype)initWithLedger:(LBLedger *)ledger transaction:(nullable LBTransaction *)transaction;   // nil = 新增
@property (nonatomic, weak) id<LBTransactionEditorDelegate> delegate;
- (BOOL)saveWithError:(NSError **)error;          // 測試用：金額非法回 NO
@property (nonatomic, strong) UITextField *amountField;      // 測試用
@end
@interface LBCategoryPickerViewController : UITableViewController
- (instancetype)initWithRootCategories:(NSArray<LBCategory *> *)roots selected:(nullable LBCategory *)selected;
@property (nonatomic, copy, nullable) void (^onSelect)(LBCategory *category);
@property (nonatomic, copy, readonly) NSArray<LBCategory *> *visibleRows;   // 依展開狀態攤平
- (void)toggleExpansionOf:(LBCategory *)category;
@end
// LBCategory 預設分類樹：+[LBCategory defaultTree] 回 NSArray<LBCategory *>（飲食 / 交通 / 居住 / 娛樂 / 收入 各含子分類）
// AppDelegate / SceneDelegate：UITabBarController（帳本 / 統計 / 設定），各包 UINavigationController
// 手動驗收 12 項見課文 8.4 / 8.6 的 xcode 題

// M09 ----------------------------------------------------------------
// LBTransaction：<NSSecureCoding>、- dictionaryRepresentation、- initWithDictionary:error:（防禦 NSNull / 型別）
@interface LBPersistence : NSObject
- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL;   // 測試傳 NSTemporaryDirectory()
- (BOOL)saveLedger:(LBLedger *)ledger error:(NSError **)error;     // JSON、NSDataWritingAtomic
- (nullable LBLedger *)loadLedgerWithError:(NSError **)error;      // 檔案不存在 → 空帳本（非 nil、無 error）
- (void)saveLedger:(LBLedger *)ledger completion:(void (^)(NSError * _Nullable))completion;   // 背景佇列寫、主佇列回呼
@property (nonatomic, copy, readonly) NSURL *fileURL;
@end
@interface LBSettings : NSObject
+ (instancetype)shared;
- (instancetype)initWithUserDefaults:(NSUserDefaults *)defaults;   // 測試用 suiteName
@property (nonatomic, copy) NSString *currencyCode;      // 預設 TWD（registerDefaults）
@property (nonatomic, assign) BOOL showsCents;           // 預設 YES
@property (nonatomic, assign) NSInteger appearance;       // 0 跟隨系統 / 1 淺 / 2 深
@end
// LBSettingsViewController（M09 先用程式碼，M11 改 Storyboard）

// M10 ----------------------------------------------------------------
@interface LBRingBuffer : NSObject          // 固定容量 double 緩衝
- (instancetype)initWithCapacity:(NSUInteger)capacity;
- (void)append:(double)value; - (double)average; - (double)max; - (NSUInteger)count; - (NSArray<NSNumber *> *)values;
@end
@interface LBFPSMonitor : NSObject          // CADisplayLink；DEBUG 用
+ (instancetype)shared; - (void)start; - (void)stop;
@property (nonatomic, readonly) double fps, lastFrameMilliseconds; @property (nonatomic, readonly) LBRingBuffer *history;
+ (NSInteger)classifyFrameDuration:(double)milliseconds;   // 0 正常 <16.7、1 警告 <33、2 掉幀；可單測
@end
@interface LBImportService : NSObject
- (instancetype)initWithLedger:(LBLedger *)ledger;
- (NSProgress *)importCSVAtURL:(NSURL *)url batchSize:(NSUInteger)batchSize progress:(void (^)(NSUInteger done, NSUInteger total))progress completion:(void (^)(NSError * _Nullable))completion;  // 背景解析、每批 performBatchImport:、進度節流 100 ms、支援 cancel
+ (NSURL *)generateSampleCSVWithCount:(NSUInteger)count error:(NSError **)error;   // 產生測試資料
@end
@interface LBSearchController : NSObject
- (instancetype)initWithLedger:(LBLedger *)ledger;
@property (nonatomic, assign) NSTimeInterval debounceInterval;   // 預設 0.25
- (void)search:(NSString *)query results:(void (^)(NSArray<LBTransaction *> *results, NSString *query))results;   // 世代計數：舊結果不回呼
- (void)cancel;
@end
@interface LBLockBenchmark : NSObject
+ (NSDictionary<NSString *, NSNumber *> *)runWithIterations:(NSUInteger)n threads:(NSUInteger)t;   // keys: synchronized / NSLock / unfair_lock / serialQueue → 秒數；每種鎖的計數器都必須等於 n*t
@end
// LBPerformanceViewController：畫面 10；LBTransactionViewModel 加 LBLRUCache 快取

// M11 ----------------------------------------------------------------
// Settings.storyboard：LBSettingsViewController（static cells；IBOutlet currencyLabel / centsSwitch / appearanceLabel；segue identifier "showPerformance" → LBPerformanceViewController）
//   Storyboard ID "Settings"（instantiateViewControllerWithIdentifier:）；initial VC 是包著它的 UINavigationController
//   （SceneDelegate 用 instantiateInitialViewController）；IBAction centsSwitchChanged:；unwind 目的地 unwindFromPerformance:
// LBTransactionCell.xib：同一個 cell 的 XIB 版；registerNib:；File's Owner 不用
//   列表用 #if LB_USE_NIB_CELL 二選一註冊（課文 11.4 的巨集名；project.yml 的 Debug 定義成 1）
// Podfile：Masonry（編輯頁改寫一次）；use_frameworks! 不用（靜態）
// LittleBook-Legacy/：獨立專案（MRC、全 Storyboard、NSURLConnection、UIAlertView、CocoaPods），埋雷 6 處：
//   1 LBLegacyTransaction over-release（dealloc 多 release）2 setter 漏 release 洩漏 3 LBLegacyListViewController 一條 IBOutlet 斷線
//   4 segue identifier 打錯 5 category 在靜態庫未加 -ObjC 6 NSURLConnection delegate 未在 dealloc 取消（類別名以課文為準：LBLegacyRateService、NSString+LBUtils、LBLegacyLedgerManager；詳見 LittleBook-Legacy/SOLUTIONS.md）
// LegacyAudit.plist：6 個 BOOL 勾選；LBLegacyAuditTests 讀它（學生修完後手動勾）
//   key 與 LittleBook-Legacy/LegacyAudit.plist 相同：fixedOverRelease / fixedSetterLeak / fixedBrokenOutlet /
//   fixedSegueIdentifier / addedObjCLinkerFlag / cancelsConnectionInDealloc
//   （練習題 11.1 / 11.6 寫的 overReleaseFixed … connectionCancelledInDealloc 測試也認，當別名）

// M12 ----------------------------------------------------------------
// StatsViewController.swift / StatsViewModel.swift（@objc，繼承 NSObject）：
//   final class StatsViewModel: NSObject { init(ledger: LBLedger); var expenseTotal / incomeTotal / balance: NSDecimalNumber; func categoryBreakdown() -> [(name: String, total: NSDecimalNumber)]  (排序由大到小；ObjC 看不到 tuple → 另提供 @objc func categoryNames() -> [String]) }
//   @objc final class StatsViewController: UIViewController { @objc init(ledger: LBLedger) }   // ObjC 透過 LittleBook-Swift.h 建立並放進 tab
// LittleBook-Bridging-Header.h：import LBLedger.h 等；project.yml 加 SWIFT_OBJC_BRIDGING_HEADER、SWIFT_VERSION 5
// 全部 ObjC 標頭補 NS_ASSUME_NONNULL；NS_SWIFT_NAME 示範至少 2 處；completion handler 方法 Swift 端可 async 呼叫
```

## Phase 2 補充介面（M08–M12 實作時為測試 / 頁面新增；名稱同樣固定）

```objc
// M08 ----------------------------------------------------------------
// LBTypes.h：LBErrorCodeInvalidAmount = 104（編輯頁金額非正數）
// LBTransaction：新增指定初始化器（舊的 5 參數版本變成便利初始化器，flags = None）
- (instancetype)initWithAmount:(NSDecimalNumber *)amount kind:(LBTransactionKind)kind date:(NSDate *)date note:(NSString *)note category:(nullable LBCategory *)category flags:(LBTransactionFlags)flags NS_DESIGNATED_INITIALIZER;
// LBTransactionCell：+ (NSString *)defaultReuseIdentifier（@"LBTransactionCell"）；readonly iconView / titleLabel / subtitleLabel / amountLabel（測試檢查 prepareForReuse）
// LBMonthHeaderView：+ (NSString *)defaultReuseIdentifier；readonly titleLabel / summaryLabel
// LBTransactionListViewController：
- (void)deleteTransactionAtIndexPath:(NSIndexPath *)indexPath;   // 不經確認直接刪：ledger 移除 + 登記復原 + performBatchUpdates（該月最後一筆連 section 刪）
- (void)reloadFromLedger;
// LBTransactionEditorDelegate @optional - editor:didDeleteTransaction:；編輯頁 readonly kindControl / datePicker / noteField / reconciledSwitch / recurringSwitch
// LBCategoryPickerViewController：readonly rootCategories / selectedCategory
// 編輯頁的幣別直接讀 NSUserDefaults key @"LBSettings.currencyCode"（與 M09 的 LBSettings 相同，未設定時顯示 TWD）

// M09 ----------------------------------------------------------------
// LBTransaction 字典 key：LBTransactionKeyIdentifier @"id" / Amount @"amount"（字串）/ Kind @"kind" / Date @"date"（timeIntervalSince1970）/ Note @"note" / Category @"category"（分類路徑，可省略）/ Flags @"flags"
// LBCategory (LBPath)：- (NSString *)lb_path（@"飲食/午餐"）；+ (nullable LBCategory *)lb_categoryWithPath:（在 defaultTree 找）
//   存檔不存分類 identifier：defaultTree 每次啟動重建，UUID 會變
// LBLedger：- (instancetype)initWithTransactions:(NSArray<LBTransaction *> *)transactions;   // 載入用：排序一次、算一次 total、不送通知
// LBSettings：typedef NS_ENUM(NSInteger, LBAppearance) { LBAppearanceSystem, LBAppearanceLight, LBAppearanceDark };
//   key：LBSettingsCurrencyCodeKey / LBSettingsShowsCentsKey / LBSettingsAppearanceKey；LBSettingsDidChangeNotification（主執行緒）
//   readonly userDefaults；+ (NSArray<NSString *> *)supportedCurrencyCodes
// LBPersistence：LBPersistenceFileName（@"ledger.json"）；+ (NSURL *)defaultDirectoryURL（Application Support/LittleBook）；readonly directoryURL
// LBSettingsViewController：- initWithSettings:ledger:undoStack:persistence:（M11 改 Storyboard 時改用屬性注入）

// M10 ----------------------------------------------------------------
// LBLedger：
- (void)performBatchImport:(NSArray<LBTransaction *> *)batch;   // 一次 dispatch_barrier_async，合併後送 LBLedgerDidImportBatchNotification
- (void)waitForPendingWrites;                                     // 空的 dispatch_barrier_sync
extern NSNotificationName const LBLedgerDidImportBatchNotification;   // userInfo[LBLedgerImportedCountKey] = 實際加入筆數
// LBRingBuffer：readonly capacity；- removeAllValues
// LBFPSMonitor：typedef NS_ENUM(NSInteger, LBFrameClass) { LBFrameClassNormal, LBFrameClassWarning, LBFrameClassDropped };
//   readonly running（isRunning）/ droppedFrameCount；LBFPSMonitorDidUpdateNotification（約每 0.5 秒）
// LBImportService：LBImportCSVHeader = @"timestamp,kind,amount,category,note"
// LBSearchController：
@property (nonatomic, assign) NSTimeInterval simulatedLatency;   // 測試用：背景過濾額外等這麼久（模擬慢查詢）
@property (nonatomic, assign, readonly) NSUInteger generation;   // 世代計數
@property (nonatomic, assign, readonly) NSTimeInterval lastDuration;
// LBLockBenchmark：key 常數 LBLockBenchmarkSynchronized / NSLock / UnfairLock / SerialQueue；+ (NSArray<NSString *> *)allKeys
+ (NSDictionary<NSString *, NSNumber *> *)runWithIterations:(NSUInteger)n threads:(NSUInteger)t counts:(NSDictionary<NSString *, NSNumber *> * _Nullable * _Nullable)counts;   // 測試用：回傳每種鎖的最終計數
// LBTransactionViewModel（快取）：
+ (NSUInteger)formattingCount;   // 真正格式化的次數（測試驗證「只格式化一次」）
+ (void)resetCache;              // 清空快取並歸零；設定改變時也呼叫
+ (NSUInteger)cacheCapacity;     // 1000
// LBPerformanceViewController：- initWithLedger:；importCount（預設 100,000）
// LBFrameHistoryView（Views/）：values（毫秒）/ maximumMilliseconds / slotCount
// 測試用 LBStubURLProtocol（M10 版）：+ setResponseDelay: / + maxConcurrentRequests / + totalRequests / + resetConcurrencyStats

// M11 ----------------------------------------------------------------
// LBSettingsViewController（Storyboard 版；initWithCoder: 是唯一的指定初始化器，其餘 init 全 NS_UNAVAILABLE）：
extern NSString * const LBSettingsStoryboardName;          // @"Settings"
extern NSString * const LBSettingsStoryboardIdentifier;    // @"Settings"（Storyboard ID）
extern NSString * const LBSettingsShowPerformanceSegue;    // @"showPerformance"
+ (instancetype)instantiateFromStoryboard;                 // bundleForClass: 載入，測試與 App 共用
@property (nonatomic, strong, null_resettable) LBSettings *settings;   // 沒注入 = [LBSettings shared]
@property (nonatomic, strong, nullable) LBLedger *ledger;               // 以下三個沒注入時資料功能停用
@property (nonatomic, strong, nullable) LBUndoStack *undoStack;
@property (nonatomic, strong, nullable) LBPersistence *persistence;
@property (nonatomic, weak, readonly, nullable) IBOutlet UILabel *currencyLabel;   // centsSwitch / appearanceLabel 同
- (IBAction)centsSwitchChanged:(UISwitch *)sender;
- (IBAction)unwindFromPerformance:(UIStoryboardSegue *)segue;
//   Storyboard 區段：0「一般」主幣別 / 顯示小數位 / 外觀；1「資料」效能面板（segue）/ 匯出 JSON / 匯入測試資料 / 清除全部資料
// LBPerformanceViewController：initWithCoder: 改為指定初始化器（ledger 先給空帳本）；ledger 改 readwrite；
@property (nonatomic, strong, null_resettable) LBFPSMonitor *monitor;   // prepareForSegue: 注入，沒注入 = shared
// LBTransactionCell：+ (NSString *)nibName（@"LBTransactionCell"）；XIB 版另有私有 outlet iconBackground
// LBTransactionEditorViewController：#if __has_include(<Masonry/Masonry.h>) 用 Masonry，否則原生 anchor（約束相同）
// 檔案位置：LittleBook/Resources/Settings.storyboard、LittleBook/Views/LBTransactionCell.xib、
//           LittleBookTests/LegacyAudit.plist（測試 bundle 資源）、專案根目錄 Podfile

// M12 ----------------------------------------------------------------
// project.yml：SWIFT_VERSION 5.0；App：SWIFT_OBJC_BRIDGING_HEADER = LittleBook/LittleBook-Bridging-Header.h、
//   DEFINES_MODULE YES；測試：SWIFT_OBJC_BRIDGING_HEADER = LittleBookTests/LittleBookTests-Bridging-Header.h、
//   HEADER_SEARCH_PATHS 加 $(CONFIGURATION_TEMP_DIR)/LittleBook.build/DerivedSources（ObjC 測試 import LittleBook-Swift.h）
// NS_SWIFT_NAME（三處）：LBTransactionKind → LBTransaction.Kind；+expenseWithAmount:note: → init(amount:note:)；
//   -[LBLedger totalForKind:] → total(for:)
@objc(StatsViewController) final class StatsViewController: UIViewController { @objc let viewModel: StatsViewModel; @objc init(ledger: LBLedger) }   // title = "統計"
@objc final class StatsViewModel: NSObject { @objc let ledger: LBLedger; static let uncategorizedName = "未分類"; @objc func categoryNames() -> [String] }
@objc final class StatsBreakdownItem: NSObject { @objc let name: String; @objc let total: NSDecimalNumber }   // + extension StatsViewModel { @objc func breakdownItems() -> [StatsBreakdownItem] }
// categoryBreakdown()：只算支出、依分類名分桶（沒分類 →「未分類」）、金額由大到小，同額依名稱
// 專案根目錄 .clang-format：課文 12.5 那一份（solution 才有）
```
