import Foundation

/// 統計頁（畫面 06）的資料來源。
/// 12.1：Swift 直接讀 ObjC 的 LBLedger（透過 LittleBook-Bridging-Header.h）；
/// 12.2：繼承 NSObject + @objc，讓 ObjC 端也能透過 LittleBook-Swift.h 使用。
@objc final class StatsViewModel: NSObject {

    /// 沒有分類的交易歸到這一桶。
    static let uncategorizedName = "未分類"

    /// 統計的對象。StatsViewController 用它做 KVO（ledger.total）。
    @objc let ledger: LBLedger

    @objc init(ledger: LBLedger) {
        self.ledger = ledger
        super.init()
    }

    /// 支出總額（正數）。-[LBLedger totalForKind:] 在標頭用 NS_SWIFT_NAME 固定成 total(for:)；
    /// 參數是 NS_ENUM，在 Swift 端是 enum LBTransaction.Kind，寫 .expense / .income 即可。
    @objc var expenseTotal: NSDecimalNumber {
        ledger.total(for: .expense)
    }

    /// 收入總額。
    @objc var incomeTotal: NSDecimalNumber {
        ledger.total(for: .income)
    }

    /// 結餘 = 收入 − 支出（可能是負數）。
    @objc var balance: NSDecimalNumber {
        incomeTotal.subtracting(expenseTotal)
    }

    /// 支出依分類加總，金額由大到小；同額時依名稱排，結果穩定。
    /// 回傳 tuple 陣列：Swift 內部最自然的寫法。ObjC 沒有 tuple，所以這個方法**不能**標 @objc
    /// （會編譯錯誤）；ObjC 用 categoryNames() 或 breakdownItems()（StatsBreakdownItem.swift）。
    func categoryBreakdown() -> [(name: String, total: NSDecimalNumber)] {
        var buckets: [String: NSDecimalNumber] = [:]
        for tx in ledger.transactions where tx.kind == .expense {
            // category 在 LBTransaction.h 標了 nullable → Swift 端是 Optional，編譯器逼你處理 nil
            let name = tx.category?.name ?? StatsViewModel.uncategorizedName
            buckets[name] = (buckets[name] ?? NSDecimalNumber.zero).adding(tx.amount)
        }
        return buckets
            .map { (name: $0.key, total: $0.value) }
            .sorted { lhs, rhs in
                let order = lhs.total.compare(rhs.total)
                if order == .orderedSame {
                    return lhs.name < rhs.name
                }
                return order == .orderedDescending
            }
    }

    /// 給 ObjC 看的版本：只有分類名，順序同 categoryBreakdown()。
    @objc func categoryNames() -> [String] {
        categoryBreakdown().map { $0.name }
    }
}
