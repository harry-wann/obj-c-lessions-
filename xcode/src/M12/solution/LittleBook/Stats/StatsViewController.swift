import UIKit

/// 統計頁（畫面 06）：三張統計卡（支出 / 收入 / 結餘）＋ 依分類的支出長條。
/// 用 Swift 寫，由 ObjC 的 SceneDelegate 透過 LittleBook-Swift.h 建立並放進第二個 tab（12.2）。
/// `@objc(StatsViewController)` 固定 ObjC runtime 的類別名：不加的話 runtime 名字是
/// `LittleBook.StatsViewController`，NSClassFromString(@"StatsViewController") 會回 nil。
@objc(StatsViewController)
final class StatsViewController: UIViewController {

    /// 資料來源（ObjC 端也看得到，LBBridgingTests 會用）。
    @objc let viewModel: StatsViewModel

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let expenseCard = StatsCardView(title: "支出", tint: .systemRed)
    private let incomeCard = StatsCardView(title: "收入", tint: .systemGreen)
    private let balanceCard = StatsCardView(title: "結餘", tint: .systemBlue)
    private let breakdownStack = UIStackView()
    private let emptyLabel = UILabel()

    /// KVO：ledger.total 一變就重畫（M06 保證通知在主執行緒）。持有它 = 持續觀察，釋放即停止。
    private var totalObservation: NSKeyValueObservation?
    private var notificationTokens: [NSObjectProtocol] = []

    /// ObjC 端：[[StatsViewController alloc] initWithLedger:ledger]
    @objc init(ledger: LBLedger) {
        viewModel = StatsViewModel(ledger: ledger)
        super.init(nibName: nil, bundle: nil)
        title = "統計"
    }

    @available(*, unavailable, message: "StatsViewController 只用程式碼建立")
    required init?(coder: NSCoder) {
        fatalError("StatsViewController 只用程式碼建立")
    }

    deinit {
        notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - 生命週期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        buildLayout()
        startObserving()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()   // 保險：別的分頁改過資料（例如設定頁清除全部）
    }

    // MARK: - 觀察

    private func startObserving() {
        // Swift 的 KVO：key path 版 observe，回傳的 token 要留著
        totalObservation = viewModel.ledger.observe(\.total, options: [.new]) { [weak self] _, _ in
            if Thread.isMainThread {
                self?.reload()
            } else {
                DispatchQueue.main.async { self?.reload() }
            }
        }
        // 批次匯入（M10）每批送一次通知；設定改了（顯示小數位、幣別）要重新格式化
        let center = NotificationCenter.default
        notificationTokens.append(center.addObserver(forName: .LBLedgerDidImportBatch,
                                                     object: viewModel.ledger,
                                                     queue: .main) { [weak self] _ in
            self?.reload()
        })
        notificationTokens.append(center.addObserver(forName: .LBSettingsDidChange,
                                                     object: nil,
                                                     queue: .main) { [weak self] _ in
            self?.reload()
        })
    }

    // MARK: - 版面

    private func buildLayout() {
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16,
                                                                        bottom: 32, trailing: 16)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        let content = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: content.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            // 直向捲動：內容寬度 = scrollView 寬度
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        // 第一排：支出、收入並排；第二排：結餘
        let topRow = UIStackView(arrangedSubviews: [expenseCard, incomeCard])
        topRow.axis = .horizontal
        topRow.spacing = 12
        topRow.distribution = .fillEqually
        contentStack.addArrangedSubview(topRow)
        contentStack.addArrangedSubview(balanceCard)

        let header = UILabel()
        header.text = "支出分類"
        header.font = .preferredFont(forTextStyle: .headline)
        header.adjustsFontForContentSizeCategory = true
        contentStack.setCustomSpacing(24, after: balanceCard)
        contentStack.addArrangedSubview(header)

        breakdownStack.axis = .vertical
        breakdownStack.spacing = 14
        emptyLabel.text = "還沒有支出"
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = .preferredFont(forTextStyle: .body)
        emptyLabel.textAlignment = .center
        contentStack.addArrangedSubview(StatsCardView.wrapping(breakdownStack))
    }

    // MARK: - 資料

    /// 重算三個總額與分類長條。資料量是「分類數」，每次全部重建就好。
    private func reload() {
        guard isViewLoaded else {
            return
        }
        expenseCard.value = format(viewModel.expenseTotal)
        incomeCard.value = format(viewModel.incomeTotal)
        balanceCard.value = format(viewModel.balance)

        breakdownStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let breakdown = viewModel.categoryBreakdown()
        guard let largest = breakdown.first?.total.doubleValue, largest > 0 else {
            breakdownStack.addArrangedSubview(emptyLabel)
            return
        }
        for item in breakdown {
            let fraction = CGFloat(item.total.doubleValue / largest)
            breakdownStack.addArrangedSubview(StatsBarRow(name: item.name,
                                                          amountText: format(item.total),
                                                          fraction: fraction))
        }
    }

    /// 依設定頁的「主幣別」與「顯示小數位」格式化。
    private func format(_ amount: NSDecimalNumber) -> String {
        let settings = LBSettings.shared()
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = settings.showsCents ? 2 : 0
        formatter.maximumFractionDigits = settings.showsCents ? 2 : 0
        let number = formatter.string(from: amount) ?? amount.stringValue
        return "\(settings.currencyCode) \(number)"
    }
}

// MARK: - 子 view（只在 Swift 內部用，不標 @objc）

/// 圓角統計卡：上面小標題、下面大數字。
private final class StatsCardView: UIView {

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    var value: String? {
        get { valueLabel.text }
        set { valueLabel.text = newValue }
    }

    init(title: String, tint: UIColor) {
        super.init(frame: .zero)
        StatsCardView.applyCardStyle(to: self)

        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.textColor = .secondaryLabel
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 22, weight: .semibold)
        valueLabel.textColor = tint
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.5

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 4
        StatsCardView.pin(stack, into: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 任意內容包成同樣外觀的卡片（分類長條那一張用）。
    static func wrapping(_ content: UIView) -> UIView {
        let card = UIView()
        applyCardStyle(to: card)
        pin(content, into: card)
        return card
    }

    private static func applyCardStyle(to view: UIView) {
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
    }

    private static func pin(_ content: UIView, into card: UIView) {
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
        ])
    }
}

/// 一列分類長條：上面「名稱 …… 金額」，下面依比例填滿的橫條（最大的那一類 = 滿格）。
private final class StatsBarRow: UIView {

    init(name: String, amountText: String, fraction: CGFloat) {
        super.init(frame: .zero)

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .preferredFont(forTextStyle: .body)
        let amountLabel = UILabel()
        amountLabel.text = amountText
        amountLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        amountLabel.textColor = .secondaryLabel
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let textRow = UIStackView(arrangedSubviews: [nameLabel, amountLabel])
        textRow.spacing = 8

        let track = UIView()
        track.backgroundColor = .tertiarySystemFill
        track.layer.cornerRadius = 4
        let fill = UIView()
        fill.backgroundColor = .systemRed
        fill.layer.cornerRadius = 4
        fill.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(fill)

        let stack = UIStackView(arrangedSubviews: [textRow, track])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        // multiplier 不能是 0：最小留一點點，讓很小的分類也看得到
        let ratio = min(max(fraction, 0.02), 1)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            track.heightAnchor.constraint(equalToConstant: 8),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: ratio),
        ])
        isAccessibilityElement = true
        accessibilityLabel = "\(name) \(amountText)"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
