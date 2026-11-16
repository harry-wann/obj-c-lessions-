# xcode/ — 課程用 Xcode 專案

課文裡每個模組的 💻 Xcode 任務都對應這裡的一個資料夾。專案不放 `.xcodeproj`，而是用
[XcodeGen](https://github.com/yonaskolb/XcodeGen) 的 `project.yml` 描述，在 Mac 上自己產生。

## 怎麼用

```bash
brew install xcodegen            # 只需一次

cd xcode/M01-starter             # 進到想做的里程碑
xcodegen generate                # 產生 LittleBook.xcodeproj（已被 .gitignore 忽略）
open LittleBook.xcodeproj        # 選一台 iOS 17 模擬器
# ⌘U 跑測試：starter 會有紅燈，把 TODO 做完就會全綠；⌘R 可在模擬器啟動 App
```

M11 起資料夾裡多了 `Podfile`（Masonry）。想用 CocoaPods 時順序固定：
`xcodegen generate` → `pod install` → `open LittleBook.xcworkspace`（之後只開 workspace；每次重跑
`xcodegen generate` 都要再 `pod install` 一次）。不裝 pod 也能建置：編輯頁用
`#if __has_include(<Masonry/Masonry.h>)` 判斷，沒有 Masonry 就退回原生 `NSLayoutAnchor`。

`Scratch/` 一樣：`cd xcode/Scratch && xcodegen generate && open Scratch.xcodeproj`，⌘R 看主控台輸出。

若 Xcode 抱怨 signing：模擬器通常不需要；真的需要就在 `project.yml` 的 `settings.base`
填 `DEVELOPMENT_TEAM`，或在 Xcode 的 Signing & Capabilities 選自己的 Personal Team，再重跑
`xcodegen generate` 前記得把改動搬回 `project.yml`（產生出來的 `.xcodeproj` 會被覆蓋）。

## 資料夾

| 資料夾 | 內容 |
|---|---|
| `TESTS.md` | 每個里程碑的測試名稱與共用型別 / 類別介面（名稱固定，課文與專案共用） |
| `Scratch/` | macOS Command Line Tool（Objective-C）草稿本。Playground 不支援 ObjC，用它試語法 |
| `M01-starter/` … `M12-starter/` | 起始專案：含前面里程碑的完成程式碼 ＋ 本里程碑的空殼（`// TODO: MNN`）＋ 已寫好、目前會失敗的測試 |
| `M01-solution/` … `M12-solution/` | 解答專案：全部實作完成，所有測試應通過 |
| `LittleBook-Legacy/` | M11 老派版：MRC + Storyboard + NSURLConnection + CocoaPods，埋雷 6 處（見其 README） |
| `LittleBook-Legacy-solution/` | 六雷修好的版本，由 `scripts/assemble-legacy.sh` 產生 |
| `src/`、`scripts/assemble.sh` | 上面 24 個 `MNN-*` 資料夾的來源與組裝腳本（見下） |
| `tools/check.sh`、`tools/stub-sdk/`、`tools/stub-pods/` | 沒有 Mac 時的語法檢查：替身 SDK ＋ clang `-fsyntax-only`（只檢查 `.m`，見下） |

M00 沒有專案：0.2 用 `Scratch` 與 `M01-starter` 的空 App 即可。

### 每個 MNN 資料夾的結構

```
project.yml                  XcodeGen 描述：LittleBook（iOS app）＋ LittleBookTests（unit test bundle）
Podfile                      M11：Masonry（不用 use_frameworks!）
.clang-format                M12 solution：12.5 的排版設定（starter 由學生自己放）
LittleBook/
  main.m  AppDelegate.h/.m  SceneDelegate.h/.m     程式碼啟動（M08 起 SceneDelegate 建 tab bar；M11 設定頁
                                                   從 Settings.storyboard 載入；M12 統計頁是 Swift）
  LittleBook-Bridging-Header.h                     M12：Swift 看得到的 ObjC 標頭
  Support/LBTypes.h/.m                            M1：enum / options / 常數 / LBFormatCents（M7、M8 加錯誤碼）
  Models/LBTransaction  LBCategory  LBMonthSection  M2、M3（M8 加 flags 初始化器與 defaultTree、M9 加 NSSecureCoding）
  Models/LBTransactionViewModel  LBCategory+LBPath  M8、M9（M10 加 LRU 快取）
  Core/LBLedger  LBLedgerObserver.h  LBUndoStack   M3、M5（M6 KVO、M7 讀寫鎖、M9 批次建立、M10 批次匯入）
  Core/LBPollingService  LBReportBuilder  LBRateFetcher   M4：埋了循環參考的三個類別
  Core/LBRouter  LBStatsObserver  LBSettings       M6、M9
  Collections/LBHashMap  LBLinkedList  LBLRUCache  LBRingBuffer   M3、M4、M10
  Categories/NSDecimalNumber+LBFormatting  NSArray+LBFunctional   M5
  Services/LBRateService  LBSyncQueue              M7（M10 加 semaphore 限流的並行抓取）
  Services/LBPersistence  LBImportService  LBSearchController   M9、M10
  Perf/LBFPSMonitor  LBLockBenchmark               M10
  ViewControllers/LBTransactionList / LBTransactionEditor / LBCategoryPicker   M8（M10 列表加搜尋）
  ViewControllers/LBSettingsViewController  LBPerformanceViewController   M9（程式碼版設定頁）、M10、
                                                   M11（改 Storyboard、屬性注入、segue showPerformance）
  ViewControllers/LBTransactionEditorViewController  M8（M11 用 Masonry 改寫約束，__has_include 保護）
  Views/LBTransactionCell(.xib)  LBMonthHeaderView  LBFrameHistoryView   M8、M10（M11 加 XIB 版 cell）
  Resources/Settings.storyboard                    M11：static cells ＋ Navigation Controller ＋ 效能面板
  Stats/StatsViewModel  StatsBreakdownItem  StatsViewController（.swift）   M12：畫面 06
LittleBookTests/             每個類別一個 XCTestCase，檔名與 TESTS.md 一致
                             （LBStubURLProtocol 是 M7 起的假網路層，M10 版加了延遲與並行統計）
                             M11：LegacyAudit.plist（測試 bundle 資源）；M12：Swift 測試 ＋ 測試用橋接標頭
```

### 各里程碑

| 里程碑 | 要做的事 | 測試 |
|---|---|---|
| M01 | `LBTypes.m`：`LBErrorDomain` 給值、`LBFormatCents` 千分位格式化 | `LBTypesTests` |
| M02 | `LBTransaction`（不可變、NSCopying、isEqual:/hash/description）、`LBCategory`（樹、parent weak） | `LBTransactionTests`、`LBCategoryTests` |
| M03 | `LBLedger`（倒序插入、identifier 索引、月份分組、加總）、`LBMonthSection`、`LBHashMap`（鏈結法） | `LBLedgerTests`、`LBHashMapTests` |
| M04 | 修掉 `LBPollingService` / `LBReportBuilder` / `LBRateFetcher` 的三個循環參考；`LBLinkedList`、`LBLRUCache` | `LBLeakTests`、`LBLinkedListTests`、`LBLRUCacheTests` |
| M05 | `LBLedgerObserver` 協定 ＋ `LBLedger.delegate` / `reset`；兩個分類；`LBUndoStack` | `LBLedgerObserverTests`、`LBFormattingTests`、`LBFunctionalTests`、`LBUndoStackTests` |
| M06 | `LBLedger.total` KVO（主執行緒通知）、`LBStatsObserver`（context、dealloc 移除）、`LBRouter`（`NSClassFromString` ＋ 型別防禦） | `LBLedgerKVOTests`、`LBRouterTests` |
| M07 | `LBRateService`（`NSURLSession`、解析防禦、主佇列回呼）、`LBSyncQueue`（FIFO ＋ `dispatch_group`）、`LBLedger` 改並行佇列 ＋ barrier | `LBRateServiceTests`、`LBSyncQueueTests`、`LBLedgerConcurrencyTests` |
| M08 | **可以用了**：交易列表（月份 section、自訂 cell、滑動刪除 ＋ 確認、復原、空狀態）、新增 / 編輯頁（表單、鍵盤遮擋、delegate 回傳）、樹狀分類選擇（縮排、局部展開）、`LBCategory defaultTree`、tab bar | `LBTransactionListViewControllerTests`、`LBCategoryPickerViewControllerTests`、`LBTransactionEditorViewControllerTests` ＋ 手動驗收 12 項 |
| M09 | `LBTransaction` 的 `NSSecureCoding` 與字典表示法（防禦 `NSNull` / 型別）、`LBPersistence`（JSON、原子寫入、背景寫）、`LBSettings`（`registerDefaults:`）、程式碼版設定頁、啟動載入 / 進背景存檔 | `LBPersistenceTests`、`LBSettingsTests`、`LBTransactionCodingTests` |
| M10 | `LBRingBuffer`、`LBFPSMonitor`（`CADisplayLink`）、`LBImportService`（背景解析、批次 barrier、節流、可取消）、`LBSearchController`（debounce ＋ 可取消 ＋ 世代計數）、`LBLockBenchmark`、並行抓匯率（semaphore 限流）、view model 快取、效能面板、列表搜尋 | `LBRingBufferTests`、`LBFPSMonitorTests`、`LBImportServiceTests`、`LBSearchControllerTests`、`LBLedgerConcurrencyTests`、`LBLockBenchmarkTests`、`LBRateServiceTests`、`LBTransactionViewModelTests` |
| M11 | **讀得懂老專案**：`Settings.storyboard`（`LBSettingsViewController` static cells、IBOutlet `currencyLabel` / `centsSwitch` / `appearanceLabel`、IBAction `centsSwitchChanged:`、segue `showPerformance` → `LBPerformanceViewController`、Storyboard ID `Settings`、外層 Navigation Controller 是 initial VC）；設定頁改 `initWithCoder:` ＋ 屬性注入；`LBTransactionCell.xib` 與 `#if LB_USE_NIB_CELL` 二選一註冊；`Podfile` ＋ 編輯頁 Masonry 改寫；`LittleBook-Legacy/` 六顆雷 ＋ `LegacyAudit.plist` 勾選（starter 全 NO、solution 全 YES） | `LBSettingsStoryboardTests`、`LBTransactionCellNibTests`、`LBLegacyAuditTests` ＋ Legacy 手動驗收 6 項 |
| M12 | **Swift 混編**：橋接標頭、`StatsViewModel.swift`（`@objc`、`categoryBreakdown()` 回 tuple、`categoryNames()` / `breakdownItems()` 給 ObjC）、`StatsViewController.swift`（`@objc(StatsViewController)`、`@objc init(ledger:)`、三張統計卡 ＋ 分類長條、KVO `ledger.total`）由 SceneDelegate 透過 `LittleBook-Swift.h` 放進第二個 tab；全部標頭 `NS_ASSUME_NONNULL`、`NS_SWIFT_NAME` 三處（`LBTransaction.Kind`、`init(amount:note:)`、`total(for:)`）；Swift 測試用 `async` 呼叫 completion handler；`.clang-format` | `StatsViewModelTests`（Swift）、`LBSwiftAsyncTests`（Swift）、`LBBridgingTests`、`LBLedgerTests/testAddingExpenseLowersTotal` ＋ 全套全綠 |

## 維護：src/ 與組裝腳本

24 個資料夾有大量重複檔案，所以真正的來源放在 `src/`，由 `scripts/assemble.sh` 組裝：

```
src/common/                       所有里程碑共用：project.yml、AppDelegate、SceneDelegate、main.m
src/MNN/solution/LittleBook/      該里程碑完成後的程式碼（後面的里程碑可覆蓋前面同名檔，例如 M05 的 LBLedger）
src/MNN/solution/root/            專案根目錄的檔案（M11 起：project.yml、Podfile；M12：.clang-format），一樣累積
src/MNN/starter/LittleBook/       只放與 solution 不同的檔案（空殼 / 埋雷版）
src/MNN/starter/LittleBookTests/  starter 專用的測試資源（M11：全部 NO 的 LegacyAudit.plist）
src/MNN/starter/root/             starter 專用的根目錄檔案（目前沒用到）
src/MNN/starter/remove.txt        starter(N) 要刪掉的檔案（例如 M11 的 Settings.storyboard 要學生自己建）
src/MNN/tests/LittleBookTests/    該里程碑的測試
```

- `starter(N)` ＝ common ＋ solution(1…N) 疊上 starter(N) ＋ tests(1…N)，再刪掉 `remove.txt` 列的檔
- `solution(N)` ＝ common ＋ solution(1…N) ＋ tests(1…N)

改程式請改 `src/`，然後執行 `scripts/assemble.sh` 重新產生所有 `MNN-*` 資料夾（會先整個刪掉再複製）。
里程碑上限預設 12，可用 `MAX=8 scripts/assemble.sh` 只組前 8 個；資料夾名一律兩位數（`M01` … `M12`）。
`remove.txt` 列的檔案若不存在會直接中止（避免來源改名後 starter 默默多出解答）。
同名的測試檔後面的里程碑會整個覆蓋（例如 M10 的 `LBRateServiceTests.m` 含 M07 的 4 個測試 ＋ M10 新增的 1 個）。

### 沒有 Mac 時的檢查

```bash
bash tools/check.sh M12-solution             # 每個 .m 跑 clang -fsyntax-only（替身 SDK）
WITH_PODS=1 bash tools/check.sh M11-solution # 多掛 Masonry 替身，檢查 __has_include 的 Masonry 那一支
xmllint --noout M11-solution/LittleBook/Resources/Settings.storyboard   # Storyboard / XIB 只能驗 XML
```

替身 SDK（`tools/stub-sdk/`）只宣告專案用到的 API，`LittleBook-Swift.h` 替身照 M12 的 `@objc` 介面手寫；
`.swift`、Storyboard / XIB 的連線、資源打包都只有真的 Xcode 才驗得到，最後仍以 Mac 上 ⌘U 為準。
