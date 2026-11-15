#import "LBCategoryPickerViewController.h"
#import "LBCategory.h"

@implementation LBCategoryPickerViewController

- (instancetype)initWithRootCategories:(NSArray<LBCategory *> *)roots
                              selected:(LBCategory *)selected {
    NSParameterAssert(roots != nil);
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _rootCategories = [roots copy];
        _selectedCategory = selected;
        // TODO: M08 — 用一個 NSMutableSet 記「已展開節點的 identifier」；selected 的祖先全部展開
        _visibleRows = @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"選擇分類";
    // TODO: M08 — registerClass: 自訂 cell（leading 約束 constant = 16 + depth × 20 就是縮排）
}

- (void)toggleExpansionOf:(LBCategory *)category {
    // TODO: M08 — 沒有子分類就 return；切換展開狀態、重算 visibleRows（深度優先遞迴攤平），
    //            view 已載入時用 insertRowsAtIndexPaths: / deleteRowsAtIndexPaths: 局部更新
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.visibleRows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: M08 — dequeue 自訂 cell 並設定縮排、圖示、勾勾、展開箭頭
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:nil];
}

@end
