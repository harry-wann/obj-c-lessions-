@import UIKit;

@class LBMonthSection;

NS_ASSUME_NONNULL_BEGIN

/// 月份區段的 header：「2025 年 11 月」＋ 該月支出 / 收入合計。
@interface LBMonthHeaderView : UITableViewHeaderFooterView

+ (NSString *)defaultReuseIdentifier;

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *summaryLabel;

- (void)configureWithSection:(LBMonthSection *)section;

@end

NS_ASSUME_NONNULL_END
