@import Foundation;
#import "LBCategory.h"

NS_ASSUME_NONNULL_BEGIN

/// 分類路徑（M09）：存檔時不能存 identifier（defaultTree 每次啟動重建，UUID 都會變），
/// 改存「飲食/午餐」這種由根到自己的名稱路徑，讀檔時再到 defaultTree 找回同一個節點。
@interface LBCategory (LBPath)

/// 由根到自己的名稱，以 "/" 連接；根節點就是自己的名稱。
- (NSString *)lb_path;

/// 在 +[LBCategory defaultTree] 依路徑找節點；找不到回 nil。
+ (nullable LBCategory *)lb_categoryWithPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
