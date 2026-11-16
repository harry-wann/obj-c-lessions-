import Foundation

// TODO: M12 — 12.1：用 Swift 讀 ObjC 的 LBLedger 算統計（StatsViewModelTests 兩個測試）。
//   - expenseTotal / incomeTotal：ledger.transactions 依 kind（.expense / .income）加總 amount
//   - balance = incomeTotal − expenseTotal
//   - categoryBreakdown()：只算支出，依 tx.category?.name 分桶（沒分類 → 「未分類」），
//     金額由大到小排序（同額依名稱）
// 12.2：類別與要給 ObjC 看的成員加 @objc（categoryBreakdown() 回 tuple，不能加）。
// 寫完回頭檢查 LBTransaction.h / LBCategory.h 的 nullability：Generated Interface 裡不該有 `!`。
final class StatsViewModel: NSObject {

    static let uncategorizedName = "未分類"

    let ledger: LBLedger

    init(ledger: LBLedger) {
        self.ledger = ledger
        super.init()
    }

    var expenseTotal: NSDecimalNumber {
        NSDecimalNumber.zero   // TODO: M12
    }

    var incomeTotal: NSDecimalNumber {
        NSDecimalNumber.zero   // TODO: M12
    }

    var balance: NSDecimalNumber {
        NSDecimalNumber.zero   // TODO: M12
    }

    func categoryBreakdown() -> [(name: String, total: NSDecimalNumber)] {
        []                     // TODO: M12
    }

    @objc func categoryNames() -> [String] {
        categoryBreakdown().map { $0.name }
    }
}
