#import "LBTransactionEditorViewController.h"
#import "LBCategoryPickerViewController.h"
#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBCategory.h"
#import "LBTypes.h"
#import "NSDecimalNumber+LBFormatting.h"

// TODO: M11 — 11.5：建 Podfile（pod 'Masonry', '~> 1.1'）、pod install、開 .xcworkspace，
// 把下面 lb_buildForm / lb_cardWrapping: 的 activateConstraints: 改寫成 mas_makeConstraints:。
// 建議用 #if __has_include(<Masonry/Masonry.h>) 包起來，沒裝 pod 的人一樣能建置。

@interface LBTransactionEditorViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *formStack;
@property (nonatomic, strong) UILabel *categoryValueLabel;
@property (nonatomic, strong, nullable) LBCategory *selectedCategory;
@end

@implementation LBTransactionEditorViewController

- (instancetype)initWithLedger:(LBLedger *)ledger transaction:(LBTransaction *)transaction {
    NSParameterAssert(ledger != nil);
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _ledger = ledger;
        _transaction = transaction;
        _selectedCategory = transaction.category;
    }
    return self;
}

#pragma mark - 生命週期

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.title = self.transaction ? @"編輯交易" : @"新增交易";
    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self
                                                      action:@selector(lb_cancelTapped)];
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                      target:self
                                                      action:@selector(lb_saveTapped)];

    [self lb_buildForm];
    [self lb_populateFromTransaction];

    // 點空白處收鍵盤；cancelsTouchesInView = NO 才不會吃掉表單控制項的點擊
    UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(lb_dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 觀察者在 viewWillAppear 註冊、viewWillDisappear 移除，成對出現
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self
               selector:@selector(lb_keyboardWillChangeFrame:)
                   name:UIKeyboardWillShowNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(lb_keyboardWillChangeFrame:)
                   name:UIKeyboardWillHideNotification
                 object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.transaction == nil && !self.amountField.isFirstResponder) {
        [self.amountField becomeFirstResponder];   // 新增時直接可以打金額
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - 建立表單

- (void)lb_buildForm {
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_scrollView];

    _formStack = [[UIStackView alloc] init];
    _formStack.axis = UILayoutConstraintAxisVertical;
    _formStack.spacing = 16;
    _formStack.layoutMarginsRelativeArrangement = YES;
    _formStack.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(16, 16, 32, 16);
    _formStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_scrollView addSubview:_formStack];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    UILayoutGuide *contentGuide = _scrollView.contentLayoutGuide;
    UILayoutGuide *frameGuide = _scrollView.frameLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [_scrollView.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_scrollView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [_scrollView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],

        [_formStack.topAnchor constraintEqualToAnchor:contentGuide.topAnchor],
        [_formStack.bottomAnchor constraintEqualToAnchor:contentGuide.bottomAnchor],
        [_formStack.leadingAnchor constraintEqualToAnchor:contentGuide.leadingAnchor],
        [_formStack.trailingAnchor constraintEqualToAnchor:contentGuide.trailingAnchor],
        // 直向捲動：內容寬度鎖成和 scrollView 一樣寬
        [_formStack.widthAnchor constraintEqualToAnchor:frameGuide.widthAnchor],
    ]];

    // --- 金額卡：大字輸入 + 支出 / 收入分段控制器 ---
    _amountField = [[UITextField alloc] init];
    _amountField.font = [UIFont monospacedDigitSystemFontOfSize:40 weight:UIFontWeightBold];
    _amountField.keyboardType = UIKeyboardTypeDecimalPad;
    _amountField.placeholder = @"0";
    _amountField.textAlignment = NSTextAlignmentRight;
    _amountField.adjustsFontSizeToFitWidth = YES;
    _amountField.minimumFontSize = 20;
    _amountField.textColor = UIColor.systemRedColor;
    _amountField.delegate = self;

    _kindControl = [[UISegmentedControl alloc] initWithItems:@[@"支出", @"收入"]];
    _kindControl.selectedSegmentIndex = 0;
    [_kindControl addTarget:self
                     action:@selector(lb_kindChanged)
           forControlEvents:UIControlEventValueChanged];

    UIStackView *amountStack =
        [[UIStackView alloc] initWithArrangedSubviews:@[_amountField, _kindControl]];
    amountStack.axis = UILayoutConstraintAxisVertical;
    amountStack.spacing = 12;
    [_formStack addArrangedSubview:[self lb_cardWrapping:amountStack]];

    // --- 明細卡：日期 / 分類 / 幣別 / 備註 ---
    _datePicker = [[UIDatePicker alloc] init];
    _datePicker.datePickerMode = UIDatePickerModeDate;
    _datePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;

    _categoryValueLabel = [[UILabel alloc] init];
    _categoryValueLabel.textColor = UIColor.secondaryLabelColor;
    _categoryValueLabel.textAlignment = NSTextAlignmentRight;
    UIImageView *chevron =
        [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
    chevron.tintColor = UIColor.tertiaryLabelColor;
    UIStackView *categoryValue =
        [[UIStackView alloc] initWithArrangedSubviews:@[_categoryValueLabel, chevron]];
    categoryValue.spacing = 6;
    categoryValue.alignment = UIStackViewAlignmentCenter;

    UILabel *currencyLabel = [[UILabel alloc] init];
    // 主幣別：直接讀 NSUserDefaults（key 與 M09 的 LBSettings 相同），還沒設定過就是 TWD
    NSString *currency =
        [NSUserDefaults.standardUserDefaults stringForKey:@"LBSettings.currencyCode"];
    currencyLabel.text = currency.length > 0 ? currency : @"TWD";
    currencyLabel.textColor = UIColor.secondaryLabelColor;

    _noteField = [[UITextField alloc] init];
    _noteField.placeholder = @"備註";
    _noteField.textAlignment = NSTextAlignmentRight;
    _noteField.returnKeyType = UIReturnKeyDone;
    _noteField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _noteField.delegate = self;

    UIStackView *categoryRow = [self lb_rowWithTitle:@"分類" trailingView:categoryValue];
    UITapGestureRecognizer *categoryTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(lb_pickCategory)];
    [categoryRow addGestureRecognizer:categoryTap];

    UIStackView *detailStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self lb_rowWithTitle:@"日期" trailingView:_datePicker],
        categoryRow,
        [self lb_rowWithTitle:@"幣別" trailingView:currencyLabel],
        [self lb_rowWithTitle:@"備註" trailingView:_noteField],
    ]];
    detailStack.axis = UILayoutConstraintAxisVertical;
    detailStack.spacing = 8;
    [_formStack addArrangedSubview:[self lb_cardWrapping:detailStack]];

    // --- 旗標卡：已對帳 / 定期 ---
    _reconciledSwitch = [[UISwitch alloc] init];
    _recurringSwitch = [[UISwitch alloc] init];
    UIStackView *flagStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self lb_rowWithTitle:@"已對帳" trailingView:_reconciledSwitch],
        [self lb_rowWithTitle:@"定期" trailingView:_recurringSwitch],
    ]];
    flagStack.axis = UILayoutConstraintAxisVertical;
    flagStack.spacing = 8;
    [_formStack addArrangedSubview:[self lb_cardWrapping:flagStack]];

    // --- 編輯模式才有刪除 ---
    if (self.transaction != nil) {
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [deleteButton setTitle:@"刪除這筆交易" forState:UIControlStateNormal];
        deleteButton.tintColor = UIColor.systemRedColor;
        deleteButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        [deleteButton addTarget:self
                         action:@selector(lb_deleteTapped)
               forControlEvents:UIControlEventTouchUpInside];
        [deleteButton.heightAnchor constraintEqualToConstant:44].active = YES;
        [_formStack addArrangedSubview:[self lb_cardWrapping:deleteButton]];
    }
}

/// 圓角卡片：inset grouped 表單的外觀。
- (UIView *)lb_cardWrapping:(UIView *)content {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    card.layer.cornerRadius = 12;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
        [content.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
        [content.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-12],
        [content.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [content.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
    ]];
    return card;
}

/// 一列表單：左標題、右控制項。
- (UIStackView *)lb_rowWithTitle:(NSString *)title trailingView:(UIView *)trailing {
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [label setContentHuggingPriority:UILayoutPriorityRequired
                             forAxis:UILayoutConstraintAxisHorizontal];
    [label setContentCompressionResistancePriority:UILayoutPriorityRequired
                                           forAxis:UILayoutConstraintAxisHorizontal];

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[label, trailing]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 12;
    [row.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;
    return row;
}

- (void)lb_populateFromTransaction {
    LBTransaction *tx = self.transaction;
    _categoryValueLabel.text = _selectedCategory.name ?: @"未分類";
    if (tx == nil) {
        _datePicker.date = [NSDate date];
        return;
    }
    _amountField.text = [tx.amount lb_currencyString];
    _kindControl.selectedSegmentIndex = (tx.kind == LBTransactionKindIncome) ? 1 : 0;
    [self lb_kindChanged];
    _datePicker.date = tx.date;
    _noteField.text = tx.note;
    _reconciledSwitch.on = (tx.flags & LBTransactionFlagsReconciled) != 0;
    _recurringSwitch.on = (tx.flags & LBTransactionFlagsRecurring) != 0;
}

#pragma mark - 動作

- (void)lb_kindChanged {
    BOOL income = _kindControl.selectedSegmentIndex == 1;
    _amountField.textColor = income ? UIColor.systemGreenColor : UIColor.systemRedColor;
}

- (void)lb_cancelTapped {
    [self lb_dismissKeyboard];
    [self.delegate editorDidCancel:self];
}

- (void)lb_saveTapped {
    [self lb_dismissKeyboard];
    NSError *error = nil;
    if (![self saveWithError:&error]) {   // 先判回傳值，再看 error
        UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:@"無法儲存"
                                                message:error.localizedDescription
                                         preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)lb_deleteTapped {
    LBTransaction *tx = self.transaction;
    if (tx == nil) {
        return;
    }
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"刪除這筆交易？"
                                            message:@"刪除後可以從列表的「復原」找回。"
                                     preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"刪除"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        [weakSelf lb_performDelete];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)lb_performDelete {
    LBTransaction *tx = self.transaction;
    id<LBTransactionEditorDelegate> delegate = self.delegate;
    // optional 方法：先問 respondsToSelector:
    if ([delegate respondsToSelector:@selector(editor:didDeleteTransaction:)]) {
        [delegate editor:self didDeleteTransaction:tx];
    } else {
        [self.ledger removeTransactionWithIdentifier:tx.identifier];
        [delegate editorDidCancel:self];
    }
}

- (void)lb_pickCategory {
    [self lb_dismissKeyboard];
    LBCategoryPickerViewController *picker =
        [[LBCategoryPickerViewController alloc] initWithRootCategories:[LBCategory defaultTree]
                                                              selected:self.selectedCategory];
    __weak typeof(self) weakSelf = self;
    picker.onSelect = ^(LBCategory *category) {   // 往回傳值：block 版
        typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        strongSelf.selectedCategory = category;
        strongSelf.categoryValueLabel.text = category.name;
        [strongSelf.navigationController popViewControllerAnimated:YES];
    };
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)lb_dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - 儲存

/// 把輸入字串轉成金額：去掉千分位逗號與空白；解析不出來或 NaN 回 nil。
- (nullable NSDecimalNumber *)lb_amountFromText:(nullable NSString *)text {
    NSString *cleaned = [text stringByReplacingOccurrencesOfString:@"," withString:@""];
    cleaned = [cleaned stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (cleaned.length == 0) {
        return nil;
    }
    NSLocale *posix = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    NSDecimalNumber *value = [NSDecimalNumber decimalNumberWithString:cleaned locale:posix];
    NSDecimal decimal = value.decimalValue;
    if (NSDecimalIsNotANumber(&decimal)) {
        return nil;
    }
    return value;
}

- (BOOL)saveWithError:(NSError **)error {
    NSDecimalNumber *amount = [self lb_amountFromText:self.amountField.text];
    if (amount == nil || [amount compare:NSDecimalNumber.zero] != NSOrderedDescending) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:LBErrorDomain
                                         code:LBErrorCodeInvalidAmount
                                     userInfo:@{NSLocalizedDescriptionKey: @"金額必須大於 0"}];
        }
        return NO;
    }

    LBTransactionKind kind = (self.kindControl.selectedSegmentIndex == 1)
        ? LBTransactionKindIncome : LBTransactionKindExpense;
    LBTransactionFlags flags = LBTransactionFlagsNone;
    if (self.reconciledSwitch.isOn) {
        flags |= LBTransactionFlagsReconciled;
    }
    if (self.recurringSwitch.isOn) {
        flags |= LBTransactionFlagsRecurring;
    }
    LBTransaction *tx = [[LBTransaction alloc] initWithAmount:amount
                                                         kind:kind
                                                         date:self.datePicker.date
                                                         note:self.noteField.text ?: @""
                                                     category:self.selectedCategory
                                                        flags:flags];
    [self.delegate editor:self didSaveTransaction:tx];
    return YES;
}

#pragma mark - 鍵盤遮擋

- (void)lb_keyboardWillChangeFrame:(NSNotification *)notification {
    NSValue *frameValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    BOOL hiding = [notification.name isEqualToString:UIKeyboardWillHideNotification];
    CGFloat bottomInset = 0;
    if (!hiding && frameValue != nil) {
        // 鍵盤 frame 是螢幕座標，先轉成自己的座標再算重疊高度
        CGRect keyboardFrame = [self.view convertRect:frameValue.CGRectValue fromView:nil];
        CGFloat overlap = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(keyboardFrame);
        bottomInset = MAX(0, overlap - self.view.safeAreaInsets.bottom);
    }
    UIEdgeInsets insets = self.scrollView.contentInset;
    insets.bottom = bottomInset;
    self.scrollView.contentInset = insets;
    self.scrollView.verticalScrollIndicatorInsets = insets;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
