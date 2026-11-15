# LittleBook-Legacy — 小帳本「老派版」

模組 11 的配套專案。它假裝是 2012–2016 年間寫成、經手過好幾個人的小帳本：

- **整個專案 MRC**（`CLANG_ENABLE_OBJC_ARC = NO`）：`@property (retain)`、`@synthesize x = _x;`、
  ivar 寫在 `@interface {}`、`[super dealloc]`、`autorelease` 工廠、`NSAutoreleasePool`。
- **Storyboard 啟動**：`Info.plist` 的 `UIMainStoryboardFile = Main`，`LBLegacyAppDelegate` 有
  `window` 屬性，沒有 SceneDelegate。
- **淘汰 API**：`NSURLConnection` + delegate 抓匯率、`UIAlertView` 顯示錯誤。
- **`.pch` 預編譯標頭**、巨集常數、`DLog`。
- **靜態庫 target `LBLegacyKit`**：`NSString+LBUtils`（`lb_trimmed`）與 `LBLegacyKitVersion`。
- **CocoaPods**：`Podfile` 裡有 AFNetworking、Masonry、SDWebImage（11.5 練習用，程式碼還沒用到）。

目的不是「寫新功能」，而是練習 **讀得懂、改得動、不弄壞**：專案裡埋了 6 顆雷，請照 11.6 的
「第一天讀專案 SOP」把它們一一找出來修掉。

## 建置

```bash
brew install xcodegen               # 只需一次
gem install cocoapods               # 只需一次（或 brew install cocoapods）

cd xcode/LittleBook-Legacy
xcodegen generate                   # 產生 LittleBookLegacy.xcodeproj
pod install                         # 產生 Pods/ 與 LittleBookLegacy.xcworkspace
open LittleBookLegacy.xcworkspace   # 從此開 .xcworkspace，不要開 .xcodeproj
```

- 選一台 iOS 模擬器，⌘R。部署目標是 iOS 12.0；`NSURLConnection` / `UIAlertView` 的
  deprecated 警告是正常的（這就是老專案）。
- 沒裝 CocoaPods 也行：跳過 `pod install`，直接 `open LittleBookLegacy.xcodeproj`。
  目前程式碼沒有 import 任何 pod，有沒有跑 `pod install`，六顆雷都重現得出來。
- **每次重跑 `xcodegen generate` 之後都要再 `pod install`**：XcodeGen 會重寫 `.xcodeproj`，
  把 CocoaPods 加進去的 build phase 與 xcconfig 設定洗掉。
- 改 Build Settings 請改 `project.yml`（`.xcodeproj` 每次 generate 都會被覆蓋），改完重新
  generate（＋ `pod install`）。
- `Pods/` 與 `.xcworkspace` 不進版控；真實專案裡 `Podfile.lock` 要進版控（11.5）。

建議先到 Edit Scheme → Run → Diagnostics 勾 **Zombie Objects**，並在 Breakpoint navigator 加一個
**Exception Breakpoint**。找洩漏用 Product → Profile → Leaks，或執行中按 Debug Memory Graph。

## 六顆雷：症狀

只寫你會**看到**什麼，不寫答案。卡住再看 [`SOLUTIONS.md`](SOLUTIONS.md)。
大致會照這個順序遇到（前一顆沒修，後一顆可能根本走不到）：

**雷 3 · 一啟動**
還沒看到列表就 crash：`NSUnknownKeyException`，訊息裡有
`not key value coding-compliant for the key ...`。在程式碼裡搜那個 key，一個也找不到。

**雷 5 · 列表第一次顯示**
crash：`-[__NSCFString lb_trimmed]: unrecognized selector sent to instance ...`。
可是 `lb_trimmed` 明明有宣告、也有實作，編譯、連結都沒有錯誤。

**雷 4 · 點任一筆交易**
crash：`Receiver (<LBLegacyListViewController: 0x...>) has no segue with identifier '...'`。
打開 storyboard，那條 segue 明明就在。

**雷 6 · 進明細頁後立刻按返回**
幾秒後偶發 `EXC_BAD_ACCESS`；開 Zombie 會看到某個**已經離開畫面的** view controller
收到匯率回呼。網路越慢越容易重現（Network Link Conditioner 選 3G 或 Very Bad Network）。

**雷 2 · 在明細頁改金額、按「儲存」**
畫面完全正常。但每存一次，Leaks / Memory Graph 就多一個沒人指著的 `NSDecimalNumber`。

**雷 1 · 列表左上「編輯」或左滑刪除**
刪**最舊**的一筆（最下面）沒事；刪其他任何一筆，有時立刻 crash、有時合計變成怪數字、
有時下一次捲動才 crash。開 Zombie 後會看到
`-[LBLegacyTransaction ...]: message sent to deallocated instance`。

提示：1、2、6 是擁有權問題（11.1、11.2）；3、4 是 Storyboard（11.3）；5 是 Build Settings（11.6）。

## 修完之後：勾 LegacyAudit.plist

每修好一顆，就把 [`LegacyAudit.plist`](LegacyAudit.plist) 對應的 `<false/>` 改成 `<true/>`：

| key | 雷 |
|---|---|
| `fixedOverRelease` | 1 |
| `fixedSetterLeak` | 2 |
| `fixedBrokenOutlet` | 3 |
| `fixedSegueIdentifier` | 4 |
| `addedObjCLinkerFlag` | 5 |
| `cancelsConnectionInDealloc` | 6 |

主線專案的 `LBLegacyAuditTests/testLegacyChecklistComplete` 會讀這個檔，六個都是 YES 才綠。
這是**誠實制**：測試只看勾選；真正的驗收是 App 能跑、上面六個症狀都不再出現。

## 修完還可以做（11.1 / 11.2 / 11.7）

- 用 Edit → Convert → To Objective-C ARC 只轉 `LBLegacyTransaction.m` 一個檔案，其他檔維持 MRC，
  比較 diff；一檔一 commit。
- 把 `LBLegacyRateService` 改成 `NSURLSession`，對外行為不變；`UIAlertView` 換成 `UIAlertController`。
- 用 Masonry 重寫明細頁的版面（目前是 storyboard 裡的 frame + autoresizing）。

## 檔案

```
project.yml                     XcodeGen：app LittleBookLegacy ＋ 靜態庫 LBLegacyKit
Podfile                         AFNetworking / Masonry / SDWebImage
LegacyAudit.plist               六個 BOOL 勾選
LBLegacyKit/                    NSString+LBUtils、LBLegacyKitVersion（編成 libLBLegacyKit.a）
LittleBookLegacy/
  main.m  LBLegacyAppDelegate   NSAutoreleasePool、window 屬性
  LittleBookLegacy-Prefix.pch   全專案隱含 import
  Base.lproj/Main.storyboard    Navigation → 列表（prototype cell）→ segue showDetail → 明細
  Models/                       LBLegacyTransaction、LBLegacyLedger、LBLegacyLedgerManager（singleton）
  Services/                     LBLegacyRateService（NSURLConnection）
  Controllers/                  LBLegacyListViewController、LBLegacyDetailViewController
```

修好的版本在 `../LittleBook-Legacy-solution/`（先自己修，再對答案）。
