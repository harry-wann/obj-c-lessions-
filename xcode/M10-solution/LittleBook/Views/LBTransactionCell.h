@import UIKit;

@class LBTransactionViewModel;

NS_ASSUME_NONNULL_BEGIN

/// 交易列（程式碼 Auto Layout）：左 40pt 圓形圖示、中間標題 / 副標、右側金額。列高 64。
@interface LBTransactionCell : UITableViewCell

/// registerClass: / dequeue 共用的識別字 @"LBTransactionCell"。
+ (NSString *)defaultReuseIdentifier;

@property (nonatomic, strong, readonly) UIImageView *iconView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@property (nonatomic, strong, readonly) UILabel *amountLabel;

- (void)configureWithViewModel:(LBTransactionViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
