@import UIKit;

@class LBCategory;

NS_ASSUME_NONNULL_BEGIN

/// 分類選擇（畫面 05）：樹攤平成列表、縮排 depth × 20、展開 / 收合用 insert / delete rows 局部更新。
@interface LBCategoryPickerViewController : UITableViewController

/// selected 的祖先會自動展開，讓它一進來就看得到。
- (instancetype)initWithRootCategories:(NSArray<LBCategory *> *)roots
                              selected:(nullable LBCategory *)selected;

/// 使用者點選某個分類時呼叫（往回傳值的 block 版）。pop 由呼叫端決定。
@property (nonatomic, copy, nullable) void (^onSelect)(LBCategory *category);

@property (nonatomic, copy, readonly) NSArray<LBCategory *> *rootCategories;
@property (nonatomic, strong, readonly, nullable) LBCategory *selectedCategory;

/// 目前顯示的列：深度優先，只有「已展開」節點的子分類才會出現。
@property (nonatomic, copy, readonly) NSArray<LBCategory *> *visibleRows;

/// 展開 ⇄ 收合；沒有子分類的節點什麼都不做。view 已載入時用 insert / delete rows 更新。
- (void)toggleExpansionOf:(LBCategory *)category;

@end

NS_ASSUME_NONNULL_END
