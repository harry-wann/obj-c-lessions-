# LittleBook-Legacy — 六顆雷的位置與修法

> 先照 README 的症狀自己找。這份是卡住時看的；完整修好的專案在 `../LittleBook-Legacy-solution/`。

## 雷 1 · over-release（`fixedOverRelease`）

**位置**：`LittleBookLegacy/Models/LBLegacyTransaction.m` 的 `-dealloc`。

```objc
[_previous release];   // ← 多的這一行
```

**原因**：`previous` 是 `assign` 屬性（MRC 版的 weak back-pointer），從來沒有 retain 過它，
dealloc 卻 release 了它。刪除一筆交易時，它的 dealloc 把「比它舊的那一筆」的計數從 1 減到 0，
那一筆又在自己的 dealloc 裡 release 再舊的一筆……一路連鎖，帳本陣列裡剩下的全是死物件。
刪最舊那一筆不會出事，是因為它的 `previous` 是 nil。

**修法**：刪掉那一行。`dealloc` 該 release 的清單 = `retain` / `copy` 屬性 + 自己 alloc 的 ivar，
`assign` 一個都不碰（11.1 Pitfall「dealloc 裡 release 了 assign 屬性」）。
**不要**用在別處補一個 `retain` 來「平衡」，那只是把 crash 換成洩漏。

Zombie 訊息的 selector 是誰先碰到死物件就是誰：通常是 `recalculateTotal` 裡的 `amount`，
也可能是 cell 的 `note`，或陣列之後送出的 `release`。

## 雷 2 · setter 沒有 release 舊值（`fixedSetterLeak`）

**位置**：`LBLegacyTransaction.m` 手寫的 `-setAmount:`。

```objc
// 埋雷版：舊的 _amount 沒有 release，直接被蓋掉 → 每呼叫一次洩漏一個
if (_amount != amount) {
    _amount = [amount retain];
    ...
}

// 修好：先 retain 新的、再 release 舊的、最後賦值
if (_amount != amount) {
    [amount retain];
    [_amount release];
    _amount = amount;
    ...
}
```

`init` 走的是 ivar 直接賦值，所以只有明細頁「儲存」（`self.transaction.amount = amount;`）
才會走到這個 setter。用 Instruments → Leaks 或 Debug Memory Graph 看得到洩漏的 `NSDecimalNumber`。

## 雷 3 · IBOutlet 斷線（`fixedBrokenOutlet`）

**位置**：`LittleBookLegacy/Base.lproj/Main.storyboard`，列表場景的 `<connections>`：

```xml
<outlet property="summaryLabel" destination="tTl-Lg-002" id="oSm-Lg-002"/>
```

**原因**：屬性早就改名為 `totalLabel`（`LBLegacyListViewController.h`），但是手動改名，
storyboard 還記得舊名字。載入 storyboard 時 UIKit 用 KVC 對 VC 做
`setValue:forKey:@"summaryLabel"`，找不到 → `NSUnknownKeyException`。

**修法**（擇一）：在 IB 的 Connections inspector 刪掉黃色三角形那條，從表頭 label 重新拉到
`totalLabel`；或直接把 XML 的 `property="summaryLabel"` 改成 `property="totalLabel"`。
以後改 outlet 名用 Refactor → Rename，它會連 storyboard 一起改（11.3）。

## 雷 4 · segue identifier 打錯（`fixedSegueIdentifier`）

**位置**：`LittleBookLegacy/Controllers/LBLegacyListViewController.m` 的
`-tableView:didSelectRowAtIndexPath:`。

```objc
[self performSegueWithIdentifier:@"showDetial" sender:indexPath];   // Detial
```

storyboard 與 `prepareForSegue:` 都是 `showDetail`。修法：改成 `@"showDetail"`。
更好的寫法是放成常數只打一次：
`static NSString * const LBSegueShowDetail = @"showDetail";`（11.3 Tip）。

## 雷 5 · 靜態庫的 category 沒被連結（`addedObjCLinkerFlag`）

**位置**：`project.yml`，app target `LittleBookLegacy` 的 `OTHER_LDFLAGS`。

```yaml
OTHER_LDFLAGS:
  - "$(inherited)"
  - "-ObjC"          # ← 補這行，然後 xcodegen generate（有用 Pods 再 pod install）
```

**原因**：`NSString+LBUtils.m` 住在靜態庫 `libLBLegacyKit.a` 裡，而且只有 category、沒有類別。
連結器預設只拉進「有符號被參考到」的 object file；`[str lb_trimmed]` 是送訊息、不是參考符號，
所以整個 `NSString+LBUtils.o` 被丟掉。同一個庫裡的 `LBLegacyKitVersion.o` 有被 AppDelegate
參考（`_OBJC_CLASS_$_LBLegacyKitVersion`），所以「庫有連進來」——這正是它難查的地方。
`-ObjC` 叫連結器把所有含 ObjC 類別或 category 的 object file 都拉進來（11.6）。
若仍無效，可改用 `-force_load $(BUILT_PRODUCTS_DIR)/libLBLegacyKit.a`。

**跟 CocoaPods 的關係**：CocoaPods 產生的 xcconfig 本來會帶 `-ObjC`，透過 `$(inherited)`
就會「意外」修好這顆雷。這個 Podfile 的 `post_install` 是歷史遺留，會把 Pods xcconfig 裡的
`-ObjC` 拿掉，所以有沒有 `pod install` 雷都在。正確的修法是在 **App 自己的** Build Settings
加 `-ObjC`，不要依賴 Pods；solution 也順手把那段 `post_install` 刪了。

## 雷 6 · 離開畫面時沒有取消 NSURLConnection（`cancelsConnectionInDealloc`）

**位置**：`LittleBookLegacy/Services/LBLegacyRateService.m` 的 `-dealloc`，以及持有它的
`LittleBookLegacy/Controllers/LBLegacyDetailViewController.m` 的 `-dealloc`。

```objc
// LBLegacyDetailViewController.m
- (void)dealloc
{
    _rateService.delegate = nil;   // 它的 delegate 是 assign，先把指向自己的指標拿掉
    [_rateService cancel];         // 內部 [_connection cancel]
    [_rateService release];
    ...
    [super dealloc];
}

// LBLegacyRateService.m
- (void)dealloc
{
    [_connection cancel];          // 11.2 課文那一行
    [_connection release];
    ...
}
```

**原因**：明細頁 pop 之後就 dealloc 了，但 service 的 `delegate` 是 `assign`，還指著它。
請求完成時 service 呼叫 `[_delegate rateService:didLoadRates:]` → 送訊息給死掉的 VC。

**為什麼兩邊都要改**：`NSURLConnection` 會 **retain 它的 delegate**（也就是 service），直到完成、
失敗或被 cancel 為止。所以請求還在跑的時候，service 根本不會 dealloc——只在 service 的 dealloc
寫 `[_connection cancel]`（11.2 課文的寫法）是正確的好習慣，但單靠它擋不住這個 crash。
真正擋住的是 **擁有者在自己的 dealloc 裡 cancel 並清掉 delegate**。
`NSURLSession` 一樣：session 會強持有 delegate，用完要 `invalidateAndCancel`（11.2、7.x）。

## 勾選

六顆都修好、症狀都不再出現後，把 `LegacyAudit.plist` 六個 key 都改成 `<true/>`。
