#import "LBTransactionCell.h"
#import "LBTransactionViewModel.h"

static const CGFloat LBIconSize = 40;

@implementation LBTransactionCell {
    UIView *_iconBackground;
}

+ (NSString *)defaultReuseIdentifier {
    return @"LBTransactionCell";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        [self lb_buildSubviews];
    }
    return self;
}

- (void)lb_buildSubviews {
    UIView *content = self.contentView;

    // 圓形底 + SF Symbol
    _iconBackground = [[UIView alloc] init];
    _iconBackground.backgroundColor = UIColor.tertiarySystemFillColor;
    _iconBackground.layer.cornerRadius = LBIconSize / 2;
    _iconBackground.translatesAutoresizingMaskIntoConstraints = NO;

    _iconView = [[UIImageView alloc] init];
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    _iconView.tintColor = UIColor.systemBlueColor;
    _iconView.preferredSymbolConfiguration =
        [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
    _iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [_iconBackground addSubview:_iconView];

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

    [content addSubview:_iconBackground];
    [content addSubview:textStack];
    [content addSubview:_amountLabel];

    UILayoutGuide *margins = content.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [_iconBackground.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
        [_iconBackground.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],
        [_iconBackground.widthAnchor constraintEqualToConstant:LBIconSize],
        [_iconBackground.heightAnchor constraintEqualToConstant:LBIconSize],
        [_iconView.centerXAnchor constraintEqualToAnchor:_iconBackground.centerXAnchor],
        [_iconView.centerYAnchor constraintEqualToAnchor:_iconBackground.centerYAnchor],

        [textStack.leadingAnchor constraintEqualToAnchor:_iconBackground.trailingAnchor
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

// TODO: M11 — 11.4：做 LBTransactionCell.xib（Class 與 Identifier 設在 cell 上，File's Owner 不碰），
// 在類別延伸把四個屬性改成 readwrite 的 IBOutlet，並加 awakeFromNib（XIB 版走這裡，
// outlet 已連好；字型、顏色和程式碼版一致）。prepareForReuse 兩版共用。
+ (NSString *)nibName {
    return @"LBTransactionCell";
}

- (void)prepareForReuse {
    [super prepareForReuse];
    // cell 會被重用：每個會變的欄位都要回到初始狀態，否則舊資料會「殘留」到別列
    _titleLabel.text = nil;
    _subtitleLabel.text = nil;
    _amountLabel.text = nil;
    _amountLabel.textColor = UIColor.labelColor;
    _iconView.image = nil;
}

@end
