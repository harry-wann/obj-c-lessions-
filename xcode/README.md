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

`Scratch/` 一樣：`cd xcode/Scratch && xcodegen generate && open Scratch.xcodeproj`，⌘R 看主控台輸出。

若 Xcode 抱怨 signing：模擬器通常不需要；真的需要就在 `project.yml` 的 `settings.base`
填 `DEVELOPMENT_TEAM`，或在 Xcode 的 Signing & Capabilities 選自己的 Personal Team，再重跑
`xcodegen generate` 前記得把改動搬回 `project.yml`（產生出來的 `.xcodeproj` 會被覆蓋）。

## 資料夾

| 資料夾 | 內容 |
|---|---|
| `TESTS.md` | 每個里程碑的測試名稱與共用型別 / 類別介面（名稱固定，課文與專案共用） |
| `Scratch/` | macOS Command Line Tool（Objective-C）草稿本。Playground 不支援 ObjC，用它試語法 |
| `M01-starter/` … `M05-starter/` | 起始專案：含前面里程碑的完成程式碼 ＋ 本里程碑的空殼（`// TODO: M0X`）＋ 已寫好、目前會失敗的測試 |
| `M01-solution/` … `M05-solution/` | 解答專案：全部實作完成，所有測試應通過 |
| `LittleBook-Legacy/` | M11 老派版：MRC + Storyboard + NSURLConnection + CocoaPods，埋雷 6 處（見其 README） |
| `LittleBook-Legacy-solution/` | 六雷修好的版本，由 `scripts/assemble-legacy.sh` 產生 |
| `src/`、`scripts/assemble.sh` | 上面 10 個資料夾的來源與組裝腳本（見下） |

M00 沒有專案：0.2 用 `Scratch` 與 `M01-starter` 的空 App 即可。

### 每個 M0X 資料夾的結構

```
project.yml                  XcodeGen 描述：LittleBook（iOS app）＋ LittleBookTests（unit test bundle）
LittleBook/
  main.m  AppDelegate.h/.m  SceneDelegate.h/.m     程式碼啟動，不用 Storyboard
  Support/LBTypes.h/.m                            M1：enum / options / 常數 / LBFormatCents
  Models/LBTransaction  LBCategory  LBMonthSection  M2、M3
  Core/LBLedger  LBLedgerObserver.h  LBUndoStack   M3、M5
  Core/LBPollingService  LBReportBuilder  LBRateFetcher   M4：埋了循環參考的三個類別
  Collections/LBHashMap  LBLinkedList  LBLRUCache  M3、M4
  Categories/NSDecimalNumber+LBFormatting  NSArray+LBFunctional   M5
LittleBookTests/             每個類別一個 XCTestCase，檔名與 TESTS.md 一致
```

### 各里程碑

| 里程碑 | 要做的事 | 測試 |
|---|---|---|
| M01 | `LBTypes.m`：`LBErrorDomain` 給值、`LBFormatCents` 千分位格式化 | `LBTypesTests` |
| M02 | `LBTransaction`（不可變、NSCopying、isEqual:/hash/description）、`LBCategory`（樹、parent weak） | `LBTransactionTests`、`LBCategoryTests` |
| M03 | `LBLedger`（倒序插入、identifier 索引、月份分組、加總）、`LBMonthSection`、`LBHashMap`（鏈結法） | `LBLedgerTests`、`LBHashMapTests` |
| M04 | 修掉 `LBPollingService` / `LBReportBuilder` / `LBRateFetcher` 的三個循環參考；`LBLinkedList`、`LBLRUCache` | `LBLeakTests`、`LBLinkedListTests`、`LBLRUCacheTests` |
| M05 | `LBLedgerObserver` 協定 ＋ `LBLedger.delegate` / `reset`；兩個分類；`LBUndoStack` | `LBLedgerObserverTests`、`LBFormattingTests`、`LBFunctionalTests`、`LBUndoStackTests` |

## 維護：src/ 與組裝腳本

10 個資料夾有大量重複檔案，所以真正的來源放在 `src/`，由 `scripts/assemble.sh` 組裝：

```
src/common/                     所有里程碑共用：project.yml、AppDelegate、SceneDelegate、main.m
src/M0X/solution/LittleBook/    該里程碑完成後的程式碼（後面的里程碑可覆蓋前面同名檔，例如 M05 的 LBLedger）
src/M0X/starter/LittleBook/     只放與 solution 不同的檔案（空殼 / 埋雷版）
src/M0X/tests/LittleBookTests/  該里程碑的測試
```

- `starter(N)` ＝ common ＋ solution(1…N) 疊上 starter(N) ＋ tests(1…N)
- `solution(N)` ＝ common ＋ solution(1…N) ＋ tests(1…N)

改程式請改 `src/`，然後執行 `scripts/assemble.sh` 重新產生所有 `M0X-*` 資料夾（會先整個刪掉再複製）。
