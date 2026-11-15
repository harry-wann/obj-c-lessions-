#import "LBTransactionCell.h"
#import "LBTransactionViewModel.h"

@implementation LBTransactionCell

+ (NSString *)defaultReuseIdentifier {
    return @"LBTransactionCell";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // TODO: M08 — 程式碼 Auto Layout：左 40pt 圓形底 + SF Symbol、中間標題 / 副標（UIStackView）、
        //            右側等寬數字金額（抗壓縮優先度 Required）。記得 translatesAutoresizingMaskIntoConstraints = NO。
        _iconView = [[UIImageView alloc] init];
        _titleLabel = [[UILabel alloc] init];
        _subtitleLabel = [[UILabel alloc] init];
        _amountLabel = [[UILabel alloc] init];
    }
    return self;
}

- (void)configureWithViewModel:(LBTransactionViewModel *)viewModel {
    // TODO: M08 — 把 view model 的字串貼到 label；金額支出紅 / 收入綠；圖示用 systemImageNamed:
}

- (void)prepareForReuse {
    [super prepareForReuse];
    // TODO: M08 — 每個會變的欄位都要重設（文字、圖片、金額顏色），否則舊資料會殘留到別列
}

@end
