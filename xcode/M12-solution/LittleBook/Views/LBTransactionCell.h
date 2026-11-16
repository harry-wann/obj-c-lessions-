@import UIKit;

@class LBTransactionViewModel;

NS_ASSUME_NONNULL_BEGIN

/// 交易列：左 40pt 圓形圖示、中間標題 / 副標、右側金額。列高 64。
/// M08 是程式碼 Auto Layout；M11 多一個 XIB 版（LBTransactionCell.xib），兩版並存、介面相同。
@interface LBTransactionCell : UITableViewCell

/// registerClass: / registerNib: / dequeue 共用的識別字 @"LBTransactionCell"
/// （XIB 裡 cell 的 Identifier 欄要一字不差）。
+ (NSString *)defaultReuseIdentifier;

/// M11：XIB 檔名（不含副檔名）@"LBTransactionCell"。
+ (NSString *)nibName;

@property (nonatomic, strong, readonly) UIImageView *iconView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@property (nonatomic, strong, readonly) UILabel *amountLabel;

- (void)configureWithViewModel:(LBTransactionViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
