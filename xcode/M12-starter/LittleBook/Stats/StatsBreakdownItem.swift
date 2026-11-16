import Foundation

/// 12.2 包裝層：categoryBreakdown() 回傳的 tuple 在 ObjC 端看不到，
/// 所以另外包一個 ObjC 吃得下的殼（NSObject 子類別、欄位都是 ObjC 型別）。
/// Swift 內部照 Swift 寫；@objc 入口集中在這個檔，之後 ObjC 退場時整個刪掉就好。
@objc final class StatsBreakdownItem: NSObject {
    @objc let name: String
    @objc let total: NSDecimalNumber

    init(name: String, total: NSDecimalNumber) {
        self.name = name
        self.total = total
        super.init()
    }
}

extension StatsViewModel {
    /// ObjC 端：for (StatsBreakdownItem *item in [viewModel breakdownItems]) { … }
    @objc func breakdownItems() -> [StatsBreakdownItem] {
        categoryBreakdown().map { StatsBreakdownItem(name: $0.name, total: $0.total) }
    }
}
