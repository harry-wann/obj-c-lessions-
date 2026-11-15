#import "LBMonthHeaderView.h"
#import "LBMonthSection.h"
#import "NSDecimalNumber+LBFormatting.h"

@implementation LBMonthHeaderView

+ (NSString *)defaultReuseIdentifier {
    return @"LBMonthHeaderView";
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithReuseIdentifier:reuseIdentifier])) {
        // TODO: M08 — 標題（Headline）＋ 合計（Subheadline）直向 UIStackView，貼齊 layoutMarginsGuide
        _titleLabel = [[UILabel alloc] init];
        _summaryLabel = [[UILabel alloc] init];
    }
    return self;
}

- (void)configureWithSection:(LBMonthSection *)section {
    // TODO: M08 — 「2025 年 11 月」與「支出 1,280.00 · 收入 50,000.00」
}

@end
