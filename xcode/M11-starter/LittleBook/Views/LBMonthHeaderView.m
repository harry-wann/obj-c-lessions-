#import "LBMonthHeaderView.h"
#import "LBMonthSection.h"
#import "NSDecimalNumber+LBFormatting.h"

@implementation LBMonthHeaderView

+ (NSString *)defaultReuseIdentifier {
    return @"LBMonthHeaderView";
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithReuseIdentifier:reuseIdentifier])) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        _titleLabel.textColor = UIColor.labelColor;

        _summaryLabel = [[UILabel alloc] init];
        _summaryLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _summaryLabel.textColor = UIColor.secondaryLabelColor;
        _summaryLabel.adjustsFontSizeToFitWidth = YES;
        _summaryLabel.minimumScaleFactor = 0.8;

        UIStackView *stack =
            [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, _summaryLabel]];
        stack.axis = UILayoutConstraintAxisVertical;
        stack.spacing = 2;
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:stack];

        UILayoutGuide *margins = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [stack.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
            [stack.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
            [stack.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
            [stack.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6],
        ]];
    }
    return self;
}

- (void)configureWithSection:(LBMonthSection *)section {
    _titleLabel.text = [NSString stringWithFormat:@"%ld 年 %ld 月",
                        (long)section.year, (long)section.month];
    _summaryLabel.text = [NSString stringWithFormat:@"支出 %@ · 收入 %@",
                          [section.expenseTotal lb_currencyString],
                          [section.incomeTotal lb_currencyString]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _titleLabel.text = nil;
    _summaryLabel.text = nil;
}

@end
