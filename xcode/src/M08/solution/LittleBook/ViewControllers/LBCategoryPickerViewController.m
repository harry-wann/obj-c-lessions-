#import "LBCategoryPickerViewController.h"
#import "LBCategory.h"

static NSString * const LBCategoryCellIdentifier = @"LBCategoryCell";
static const CGFloat LBCategoryIndentWidth = 20;

#pragma mark - LBCategoryCell

/// 自訂 cell：leading 約束的 constant 隨深度變化，就是「縮排」。
@interface LBCategoryCell : UITableViewCell
@property (nonatomic, copy, nullable) dispatch_block_t onToggle;
- (void)configureWithCategory:(LBCategory *)category
                     selected:(BOOL)selected
                     expanded:(BOOL)expanded;
- (void)setExpanded:(BOOL)expanded;
@end

@implementation LBCategoryCell {
    UIImageView *_symbolView;
    UILabel *_nameLabel;
    UIButton *_toggleButton;
    NSLayoutConstraint *_leadingConstraint;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        UIView *content = self.contentView;

        _symbolView = [[UIImageView alloc] init];
        _symbolView.contentMode = UIViewContentModeScaleAspectFit;
        _symbolView.tintColor = UIColor.systemBlueColor;
        _symbolView.translatesAutoresizingMaskIntoConstraints = NO;

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;

        _toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _toggleButton.tintColor = UIColor.tertiaryLabelColor;
        _toggleButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_toggleButton addTarget:self
                          action:@selector(lb_toggleTapped)
                forControlEvents:UIControlEventTouchUpInside];

        [content addSubview:_symbolView];
        [content addSubview:_nameLabel];
        [content addSubview:_toggleButton];

        _leadingConstraint =
            [_symbolView.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:16];
        [NSLayoutConstraint activateConstraints:@[
            _leadingConstraint,
            [_symbolView.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],
            [_symbolView.widthAnchor constraintEqualToConstant:28],
            [_symbolView.heightAnchor constraintEqualToConstant:28],
            [_nameLabel.leadingAnchor constraintEqualToAnchor:_symbolView.trailingAnchor
                                                     constant:12],
            [_nameLabel.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],
            [_toggleButton.leadingAnchor
                constraintGreaterThanOrEqualToAnchor:_nameLabel.trailingAnchor constant:8],
            [_toggleButton.trailingAnchor constraintEqualToAnchor:content.trailingAnchor
                                                         constant:-8],
            [_toggleButton.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],
            [_toggleButton.widthAnchor constraintEqualToConstant:44],
            [_toggleButton.heightAnchor constraintEqualToConstant:44],
            [content.heightAnchor constraintGreaterThanOrEqualToConstant:44],
        ]];
    }
    return self;
}

- (void)configureWithCategory:(LBCategory *)category
                     selected:(BOOL)selected
                     expanded:(BOOL)expanded {
    _nameLabel.text = category.name;
    _symbolView.image = [UIImage systemImageNamed:category.symbolName];
    _leadingConstraint.constant = 16 + LBCategoryIndentWidth * (CGFloat)category.depth;
    _toggleButton.hidden = category.children.count == 0;
    [self setExpanded:expanded];
    self.accessoryType = selected ? UITableViewCellAccessoryCheckmark
                                  : UITableViewCellAccessoryNone;
}

- (void)setExpanded:(BOOL)expanded {
    NSString *symbol = expanded ? @"chevron.down" : @"chevron.right";
    [_toggleButton setImage:[UIImage systemImageNamed:symbol] forState:UIControlStateNormal];
}

- (void)lb_toggleTapped {
    if (self.onToggle != nil) {
        self.onToggle();
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _nameLabel.text = nil;
    _symbolView.image = nil;
    _toggleButton.hidden = NO;
    self.onToggle = nil;
    self.accessoryType = UITableViewCellAccessoryNone;
}

@end

#pragma mark - LBCategoryPickerViewController

@implementation LBCategoryPickerViewController {
    NSMutableSet<NSString *> *_expanded;   // 已展開節點的 identifier
}

- (instancetype)initWithRootCategories:(NSArray<LBCategory *> *)roots
                              selected:(LBCategory *)selected {
    NSParameterAssert(roots != nil);
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _rootCategories = [roots copy];
        _selectedCategory = selected;
        _expanded = [NSMutableSet set];
        // 讓已選的分類一進來就看得到：把它的祖先全部展開
        LBCategory *ancestor = selected.parent;
        while (ancestor != nil) {
            [_expanded addObject:ancestor.identifier];
            ancestor = ancestor.parent;
        }
        _visibleRows = [self lb_computeVisibleRows];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"選擇分類";
    [self.tableView registerClass:[LBCategoryCell class]
           forCellReuseIdentifier:LBCategoryCellIdentifier];
    self.tableView.rowHeight = 48;
}

#pragma mark - 樹 → 列表

/// 深度優先攤平（遞迴），只進入已展開的節點。
- (void)lb_appendVisibleRowsFrom:(LBCategory *)category into:(NSMutableArray<LBCategory *> *)rows {
    [rows addObject:category];
    if ([_expanded containsObject:category.identifier]) {
        for (LBCategory *child in category.children) {
            [self lb_appendVisibleRowsFrom:child into:rows];
        }
    }
}

- (NSArray<LBCategory *> *)lb_computeVisibleRows {
    NSMutableArray<LBCategory *> *rows = [NSMutableArray array];
    for (LBCategory *root in _rootCategories) {
        [self lb_appendVisibleRowsFrom:root into:rows];
    }
    return [rows copy];
}

- (void)toggleExpansionOf:(LBCategory *)category {
    NSParameterAssert(category != nil);
    if (category.children.count == 0) {
        return;
    }
    NSArray<LBCategory *> *before = _visibleRows;
    if ([_expanded containsObject:category.identifier]) {
        [_expanded removeObject:category.identifier];
    } else {
        [_expanded addObject:category.identifier];
    }
    NSArray<LBCategory *> *after = [self lb_computeVisibleRows];
    _visibleRows = after;

    if (!self.isViewLoaded) {
        return;
    }
    NSUInteger index = [before indexOfObjectIdenticalTo:category];
    if (index == NSNotFound) {
        [self.tableView reloadData];   // 這個節點本來就看不到（理論上不會發生），整個重載
        return;
    }
    // 變動的列一定緊接在這個節點後面、而且連續：差幾列就 insert / delete 幾列
    NSInteger delta = (NSInteger)after.count - (NSInteger)before.count;
    NSMutableArray<NSIndexPath *> *paths = [NSMutableArray array];
    for (NSInteger i = 1; i <= labs(delta); i++) {
        [paths addObject:[NSIndexPath indexPathForRow:(NSInteger)index + i inSection:0]];
    }
    UITableView *tableView = self.tableView;
    [tableView performBatchUpdates:^{
        if (delta > 0) {
            [tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
        } else if (delta < 0) {
            [tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
        }
    } completion:nil];
    NSIndexPath *nodePath = [NSIndexPath indexPathForRow:(NSInteger)index inSection:0];
    LBCategoryCell *cell = [tableView cellForRowAtIndexPath:nodePath];
    [cell setExpanded:[self->_expanded containsObject:category.identifier]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)_visibleRows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LBCategoryCell *cell = [tableView dequeueReusableCellWithIdentifier:LBCategoryCellIdentifier
                                                           forIndexPath:indexPath];
    LBCategory *category = _visibleRows[(NSUInteger)indexPath.row];
    BOOL selected = _selectedCategory != nil
                 && [_selectedCategory.identifier isEqualToString:category.identifier];
    [cell configureWithCategory:category
                       selected:selected
                       expanded:[_expanded containsObject:category.identifier]];
    __weak typeof(self) weakSelf = self;
    cell.onToggle = ^{
        [weakSelf toggleExpansionOf:category];
    };
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LBCategory *category = _visibleRows[(NSUInteger)indexPath.row];
    LBCategory *previous = _selectedCategory;
    _selectedCategory = category;

    // 只刷新受影響的兩列（舊的勾勾拿掉、新的勾勾加上）
    NSMutableArray<NSIndexPath *> *paths = [NSMutableArray arrayWithObject:indexPath];
    if (previous != nil) {
        NSUInteger previousIndex = [_visibleRows indexOfObjectIdenticalTo:previous];
        if (previousIndex != NSNotFound && previousIndex != (NSUInteger)indexPath.row) {
            [paths addObject:[NSIndexPath indexPathForRow:(NSInteger)previousIndex inSection:0]];
        }
    }
    [tableView reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];

    if (self.onSelect != nil) {
        self.onSelect(category);
    }
}

@end
