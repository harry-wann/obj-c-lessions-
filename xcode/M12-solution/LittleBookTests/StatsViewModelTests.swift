import XCTest
@testable import LittleBook

/// 12.1 / 12.3：用 Swift 測 Swift 寫的 StatsViewModel，資料來自 ObjC 的 LBLedger。
/// Swift 端 XCTAssertEqual 走 Equatable（NSObject 的 isEqual:），NSDecimalNumber 比的是值。
final class StatsViewModelTests: XCTestCase {

    private var ledger: LBLedger!

    override func setUp() {
        super.setUp()
        ledger = LBLedger()
    }

    override func tearDown() {
        ledger = nil
        super.tearDown()
    }

    /// 建一筆交易加進帳本。kind 用 Bool 表示，避免寫死型別名
    /// （LBTransactionKind 在 12.1 加 NS_SWIFT_NAME 之後會變成 LBTransaction.Kind）。
    @discardableResult
    private func add(_ amount: String, income: Bool = false, note: String = "",
                     category: LBCategory? = nil) -> LBTransaction {
        let tx = LBTransaction(amount: NSDecimalNumber(string: amount),
                               kind: income ? .income : .expense,
                               date: Date(),
                               note: note,
                               category: category)
        ledger.add(tx)   // -addTransaction: 在 Swift 端自動縮成 add(_:)
        return tx
    }

    func testTotalsFromLedger() {
        let food = LBCategory(name: "飲食", symbolName: "fork.knife")
        add("100", note: "午餐", category: food)
        add("250.5", note: "計程車")
        add("50000", income: true, note: "薪水")

        let viewModel = StatsViewModel(ledger: ledger)
        XCTAssertEqual(viewModel.expenseTotal, NSDecimalNumber(string: "350.5"))
        XCTAssertEqual(viewModel.incomeTotal, NSDecimalNumber(string: "50000"))
        XCTAssertEqual(viewModel.balance, NSDecimalNumber(string: "49649.5"))

        // 空帳本：全部是 0，不是 nil
        let empty = StatsViewModel(ledger: LBLedger())
        XCTAssertEqual(empty.expenseTotal, NSDecimalNumber.zero)
        XCTAssertEqual(empty.balance, NSDecimalNumber.zero)
    }

    func testCategoryBreakdownSorted() {
        let food = LBCategory(name: "飲食", symbolName: "fork.knife")
        let transport = LBCategory(name: "交通", symbolName: "tram")
        add("120", category: food)
        add("80", category: food)
        add("500", category: transport)
        add("30")                                  // 沒分類
        add("99999", income: true, category: food)  // 收入不算進支出分類

        let viewModel = StatsViewModel(ledger: ledger)
        // @testable：Swift 測試可以直接呼叫回傳 tuple 的 categoryBreakdown()，不用走 @objc 包裝層
        let breakdown = viewModel.categoryBreakdown()
        XCTAssertEqual(breakdown.map { $0.name }, ["交通", "飲食", StatsViewModel.uncategorizedName])
        XCTAssertEqual(breakdown.map { $0.total },
                       [NSDecimalNumber(string: "500"), NSDecimalNumber(string: "200"),
                        NSDecimalNumber(string: "30")])
        // ObjC 看得到的兩個入口，順序一致
        XCTAssertEqual(viewModel.categoryNames(), breakdown.map { $0.name })
        XCTAssertEqual(viewModel.breakdownItems().map { $0.name }, breakdown.map { $0.name })
    }
}
