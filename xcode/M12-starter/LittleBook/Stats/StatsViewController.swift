import UIKit

// TODO: M12 — 12.1 / 12.2：統計頁（畫面 06）。
//   - 加 @objc(StatsViewController)：不然 runtime 名字是 LittleBook.StatsViewController，
//     NSClassFromString(@"StatsViewController") 會回 nil
//   - init 裡 title = "統計"；viewDidLoad 建三張統計卡（支出 / 收入 / 結餘）與依分類的長條
//   - 用 KVO 觀察 viewModel.ledger 的 total（observe(\.total)），變了就重畫
//   - SceneDelegate.m 透過 LittleBook-Swift.h 建立它，放進第二個 tab
// 跑 LBBridgingTests 兩個測試確認。
final class StatsViewController: UIViewController {

    let viewModel: StatsViewModel

    /// ObjC 端：[[StatsViewController alloc] initWithLedger:ledger]（init 要自己標 @objc）
    @objc init(ledger: LBLedger) {
        viewModel = StatsViewModel(ledger: ledger)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("StatsViewController 只用程式碼建立")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        // TODO: M12 — 版面與資料
    }
}
