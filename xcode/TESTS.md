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
