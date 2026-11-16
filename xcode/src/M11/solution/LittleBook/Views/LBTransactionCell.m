#import "LBTransactionCell.h"
#import "LBTransactionViewModel.h"

static const CGFloat LBIconSize = 40;

/// M11：同一個 cell 有兩種來源，對外介面完全相同（configureWithViewModel: / prepareForReuse）。
///   程式碼版：registerClass: → initWithStyle:reuseIdentifier: → lb_buildSubviews 建 view
///   XIB 版：  registerNib:（LBTransactionCell.xib）→ initWithCoder: → awakeFromNib，outlet 已連好
/// 列表用哪一個由 LB_USE_NIB_CELL 決定（見 LBTransactionListViewController 的 viewDidLoad）。
@interface LBTransactionCell ()
// XIB 的 outlet 從「cell 本身」拖過來（不是 File's Owner）；程式碼版直接設 ivar
@property (nonatomic, strong, readwrite) IBOutlet UIImageView *iconView;
@property (nonatomic, strong, readwrite) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong, readwrite) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong, readwrite) IBOutlet UILabel *amountLabel;
@property (nonatomic, strong, nullable) IBOutlet UIView *iconBackground;
@end

@implementation LBTransactionCell

+ (NSString *)defaultReuseIdentifier {
    return @"LBTransactionCell";
}

+ (NSString *)nibName {
    return @"LBTransactionCell";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        [self lb_buildSubviews];   // 程式碼版走這裡
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];          // XIB 版走這裡；outlet 已有值
    // 和程式碼版一致的外觀：顏色、等寬數字、SF Symbol 大小寫在程式碼，XIB 只管版面
    self.iconBackground.backgroundColor = UIColor.tertiarySystemFillColor;
    self.iconBackground.layer.cornerRadius = LBIconSize / 2;
    self.iconView.tintColor = UIColor.systemBlueColor;
    self.iconView.preferredSymbolConfiguration =
        [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
    self.titleLabel.textColor = UIColor.labelColor;
    self.subtitleLabel.textColor = UIColor.secondaryLabelColor;
    self.amountLabel.font = [UIFont monospacedDigitSystemFontOfSize:17
                                                             weight:UIFontWeightSemibold];
    [self lb_resetContent];        // 清掉 XIB 裡的示意文字（「標題」「-1,280.00」）
}

- (void)lb_buildSubviews {
    UIView *content = self.contentView;

    // 圓形底 + SF Symbol
    UIView *iconBackground = [[UIView alloc] init];
    iconBackground.backgroundColor = UIColor.tertiarySystemFillColor;
    iconBackground.layer.cornerRadius = LBIconSize / 2;
    iconBackground.translatesAutoresizingMaskIntoConstraints = NO;
    _iconBackground = iconBackground;

    _iconView = [[UIImageView alloc] init];
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    _iconView.tintColor = UIColor.systemBlueColor;
    _iconView.preferredSymbolConfiguration =
        [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
    _iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [iconBackground addSubview:_iconView];

    // 標題 / 副標直向堆疊
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _titleLabel.textColor = UIColor.labelColor;

    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    _subtitleLabel.textColor = UIColor.secondaryLabelColor;

    UIStackView *textStack =
        [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, _subtitleLabel]];
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.spacing = 2;
    textStack.translatesAutoresizingMaskIntoConstraints = NO;

    // 金額：等寬數字、不可被壓縮（標題太長時壓標題）
    _amountLabel = [[UILabel alloc] init];
    _amountLabel.font = [UIFont monospacedDigitSystemFontOfSize:17 weight:UIFontWeightSemibold];
    _amountLabel.textAlignment = NSTextAlignmentRight;
    _amountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_amountLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                  forAxis:UILayoutConstraintAxisHorizontal];
    [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                 forAxis:UILayoutConstraintAxisHorizontal];
    [_subtitleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                    forAxis:UILayoutConstraintAxisHorizontal];

    [content addSubview:iconBackground];
    [content addSubview:textStack];
    [content addSubview:_amountLabel];

    UILayoutGuide *margins = content.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [iconBackground.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
        [iconBackground.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],
        [iconBackground.widthAnchor constraintEqualToConstant:LBIconSize],
        [iconBackground.heightAnchor constraintEqualToConstant:LBIconSize],
        [_iconView.centerXAnchor constraintEqualToAnchor:iconBackground.centerXAnchor],
        [_iconView.centerYAnchor constraintEqualToAnchor:iconBackground.centerYAnchor],

        [textStack.leadingAnchor constraintEqualToAnchor:iconBackground.trailingAnchor
                                                constant:12],
        [textStack.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],

        [_amountLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:textStack.trailingAnchor
                                                                constant:8],
        [_amountLabel.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
        [_amountLabel.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],
    ]];
}

- (void)configureWithViewModel:(LBTransactionViewModel *)viewModel {
    _titleLabel.text = viewModel.title;
    _subtitleLabel.text = viewModel.subtitle;
    _amountLabel.text = viewModel.amountText;
    _amountLabel.textColor = viewModel.isExpense ? UIColor.systemRedColor
                                                 : UIColor.systemGreenColor;
    _iconView.image = [UIImage systemImageNamed:viewModel.symbolName];
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self lb_resetContent];
}

/// 兩個版本共用：每個會變的欄位都要回到初始狀態，否則舊資料會「殘留」到別列。
- (void)lb_resetContent {
    _titleLabel.text = nil;
    _subtitleLabel.text = nil;
    _amountLabel.text = nil;
    _amountLabel.textColor = UIColor.labelColor;
    _iconView.image = nil;
}

@end
