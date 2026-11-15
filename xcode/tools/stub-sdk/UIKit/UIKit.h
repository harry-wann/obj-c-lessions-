#pragma once
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
_Pragma("clang assume_nonnull begin")

typedef struct { CGFloat top, left, bottom, right; } UIEdgeInsets;
typedef struct { CGFloat top, leading, bottom, trailing; } NSDirectionalEdgeInsets;
NSDirectionalEdgeInsets NSDirectionalEdgeInsetsMake(CGFloat t, CGFloat l, CGFloat b, CGFloat r);
extern const CGFloat UIViewNoIntrinsicMetric;
extern const CGFloat UITableViewAutomaticDimension;
typedef float UILayoutPriority;
static const UILayoutPriority UILayoutPriorityRequired = 1000;
static const UILayoutPriority UILayoutPriorityDefaultLow = 250;
void UIRectFill(CGRect r);
int UIApplicationMain(int argc, char *_Nullable argv[_Nonnull], NSString *_Nullable p,
                      NSString *_Nullable d);

@class NSLayoutXAxisAnchor, NSLayoutYAxisAnchor, NSLayoutDimension, UITextField;
@class UIView, UIWindow, UIViewController, UIScene, UIWindowScene, UINavigationController,
    UITabBarController, UIImage, UINavigationItem, UITabBarItem, UIBarButtonItem, UITableView,
    UIGestureRecognizer, UISearchController, UISearchBar, UIPopoverPresentationController;

@interface UIColor : NSObject
@property (class, readonly) UIColor *systemBackgroundColor, *systemGroupedBackgroundColor,
    *secondarySystemGroupedBackgroundColor, *labelColor, *secondaryLabelColor,
    *tertiaryLabelColor, *systemRedColor, *systemGreenColor, *systemBlueColor,
    *systemOrangeColor, *systemGrayColor, *tertiarySystemFillColor;
- (void)setFill;
- (void)setStroke;
@end

typedef NSString *UIFontTextStyle;
extern UIFontTextStyle const UIFontTextStyleBody, UIFontTextStyleHeadline,
    UIFontTextStyleSubheadline, UIFontTextStyleCaption1, UIFontTextStyleFootnote,
    UIFontTextStyleTitle3, UIFontTextStyleLargeTitle;
typedef CGFloat UIFontWeight;
extern const UIFontWeight UIFontWeightRegular, UIFontWeightSemibold, UIFontWeightBold,
    UIFontWeightMedium;
@interface UIFont : NSObject
+ (UIFont *)preferredFontForTextStyle:(UIFontTextStyle)s;
+ (UIFont *)monospacedDigitSystemFontOfSize:(CGFloat)s weight:(UIFontWeight)w;
@end

typedef enum UIImageSymbolWeight : NSInteger { UIImageSymbolWeightLight = 3,
    UIImageSymbolWeightMedium = 5 } UIImageSymbolWeight;
@interface UIImageSymbolConfiguration : NSObject
+ (instancetype)configurationWithPointSize:(CGFloat)p weight:(UIImageSymbolWeight)w;
@end
@interface UIImage : NSObject
+ (nullable UIImage *)systemImageNamed:(NSString *)n;
@end

@interface NSLayoutConstraint : NSObject
@property (getter=isActive) BOOL active;
@property CGFloat constant;
+ (void)activateConstraints:(NSArray<NSLayoutConstraint *> *)c;
@end
@interface NSLayoutAnchor<AnchorType> : NSObject
- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutAnchor<AnchorType> *)a;
- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutAnchor<AnchorType> *)a constant:(CGFloat)c;
- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:(NSLayoutAnchor<AnchorType> *)a
                                                    constant:(CGFloat)c;
- (NSLayoutConstraint *)constraintLessThanOrEqualToAnchor:(NSLayoutAnchor<AnchorType> *)a
                                                 constant:(CGFloat)c;
@end
@interface NSLayoutXAxisAnchor : NSLayoutAnchor<NSLayoutXAxisAnchor *>
@end
@interface NSLayoutYAxisAnchor : NSLayoutAnchor<NSLayoutYAxisAnchor *>
@end
@interface NSLayoutDimension : NSLayoutAnchor<NSLayoutDimension *>
- (NSLayoutConstraint *)constraintEqualToConstant:(CGFloat)c;
- (NSLayoutConstraint *)constraintGreaterThanOrEqualToConstant:(CGFloat)c;
- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutDimension *)a;
@end
@interface UILayoutGuide : NSObject
@property (readonly, strong) NSLayoutXAxisAnchor *leadingAnchor, *trailingAnchor, *centerXAnchor;
@property (readonly, strong) NSLayoutYAxisAnchor *topAnchor, *bottomAnchor, *centerYAnchor;
@property (readonly, strong) NSLayoutDimension *widthAnchor, *heightAnchor;
@end

typedef enum UILayoutConstraintAxis : NSInteger { UILayoutConstraintAxisHorizontal,
    UILayoutConstraintAxisVertical } UILayoutConstraintAxis;
typedef enum UIViewContentMode : NSInteger { UIViewContentModeScaleAspectFit = 1,
    UIViewContentModeRedraw = 3 } UIViewContentMode;
typedef enum UIUserInterfaceStyle : NSInteger { UIUserInterfaceStyleUnspecified,
    UIUserInterfaceStyleLight, UIUserInterfaceStyleDark } UIUserInterfaceStyle;

@interface UIResponder : NSObject
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
@property (readonly) BOOL isFirstResponder;
@end

@interface UIView : UIResponder
- (instancetype)initWithFrame:(CGRect)f NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)c NS_DESIGNATED_INITIALIZER;
@property (nullable, copy) UIColor *backgroundColor;
@property (null_resettable, copy) UIColor *tintColor;
@property (readonly, strong) CALayer *layer;
@property CGRect frame;
@property CGRect bounds;
@property (getter=isHidden) BOOL hidden;
@property (getter=isOpaque) BOOL opaque;
@property UIViewContentMode contentMode;
@property BOOL translatesAutoresizingMaskIntoConstraints;
@property (readonly) UIEdgeInsets safeAreaInsets;
@property (readonly, strong) UILayoutGuide *safeAreaLayoutGuide;
@property (readonly, strong) UILayoutGuide *layoutMarginsGuide;
@property (nullable, readonly) UIWindow *window;
@property UIUserInterfaceStyle overrideUserInterfaceStyle;
@property (readonly) CGSize intrinsicContentSize;
@property (readonly, strong) NSLayoutXAxisAnchor *leadingAnchor, *trailingAnchor, *centerXAnchor;
@property (readonly, strong) NSLayoutYAxisAnchor *topAnchor, *bottomAnchor, *centerYAnchor,
    *firstBaselineAnchor;
@property (readonly, strong) NSLayoutDimension *widthAnchor, *heightAnchor;
- (void)addSubview:(UIView *)v;
- (void)setNeedsDisplay;
- (void)layoutIfNeeded;
- (void)drawRect:(CGRect)r;
- (BOOL)endEditing:(BOOL)f;
- (CGRect)convertRect:(CGRect)r fromView:(nullable UIView *)v;
- (void)addGestureRecognizer:(UIGestureRecognizer *)g;
- (void)setContentHuggingPriority:(UILayoutPriority)p forAxis:(UILayoutConstraintAxis)a;
- (void)setContentCompressionResistancePriority:(UILayoutPriority)p
                                        forAxis:(UILayoutConstraintAxis)a;
@end

@interface UIBezierPath : NSObject
+ (instancetype)bezierPath;
- (void)moveToPoint:(CGPoint)p;
- (void)addLineToPoint:(CGPoint)p;
- (void)setLineDash:(nullable const CGFloat *)pattern count:(NSInteger)count phase:(CGFloat)phase;
@property CGFloat lineWidth;
- (void)stroke;
@end

@interface UIGestureRecognizer : NSObject
- (instancetype)initWithTarget:(nullable id)t action:(nullable SEL)a;
@property BOOL cancelsTouchesInView;
@end
@interface UITapGestureRecognizer : UIGestureRecognizer
@end

typedef enum UIControlState : NSUInteger { UIControlStateNormal = 0 } UIControlState;
typedef enum UIControlEvents : NSUInteger { UIControlEventTouchUpInside = 1 << 6,
    UIControlEventValueChanged = 1 << 12 } UIControlEvents;
typedef enum UIControlContentHorizontalAlignment : NSInteger {
    UIControlContentHorizontalAlignmentLeading = 4 } UIControlContentHorizontalAlignment;
@interface UIControl : UIView
- (void)addTarget:(nullable id)t action:(SEL)a forControlEvents:(UIControlEvents)e;
@property (getter=isEnabled) BOOL enabled;
@property UIControlContentHorizontalAlignment contentHorizontalAlignment;
@end
@interface UILabel : UIView
@property (nullable, copy) NSString *text;
@property (null_resettable, strong) UIFont *font;
@property (null_resettable, strong) UIColor *textColor;
@property NSInteger textAlignment;
@property NSInteger numberOfLines;
@property BOOL adjustsFontSizeToFitWidth;
@property CGFloat minimumScaleFactor;
@end
enum { NSTextAlignmentLeft = 0, NSTextAlignmentCenter = 1, NSTextAlignmentRight = 2 };
typedef enum UIButtonType : NSInteger { UIButtonTypeSystem = 1 } UIButtonType;
@interface UIButton : UIControl
+ (instancetype)buttonWithType:(UIButtonType)t;
- (void)setTitle:(nullable NSString *)t forState:(UIControlState)s;
- (void)setImage:(nullable UIImage *)i forState:(UIControlState)s;
@property (nullable, readonly, strong) UILabel *titleLabel;
@end
@interface UIImageView : UIView
- (instancetype)initWithImage:(nullable UIImage *)i;
@property (nullable, strong) UIImage *image;
@property (nullable, copy) UIImageSymbolConfiguration *preferredSymbolConfiguration;
@end
@interface UISwitch : UIControl
@property (getter=isOn) BOOL on;
@end
@interface UISegmentedControl : UIControl
- (instancetype)initWithItems:(nullable NSArray *)items;
@property NSInteger selectedSegmentIndex;
@end
typedef enum UIDatePickerMode : NSInteger { UIDatePickerModeDate = 1 } UIDatePickerMode;
typedef enum UIDatePickerStyle : NSInteger { UIDatePickerStyleCompact = 2 } UIDatePickerStyle;
@interface UIDatePicker : UIControl
@property UIDatePickerMode datePickerMode;
@property UIDatePickerStyle preferredDatePickerStyle;
@property (strong) NSDate *date;
@end
typedef enum UIProgressViewStyle : NSInteger { UIProgressViewStyleDefault } UIProgressViewStyle;
@interface UIProgressView : UIView
- (instancetype)initWithProgressViewStyle:(UIProgressViewStyle)s;
@property float progress;
@end
@protocol UITextFieldDelegate <NSObject>
@optional
- (BOOL)textFieldShouldReturn:(UITextField *)t;
@end
typedef enum UIKeyboardType : NSInteger { UIKeyboardTypeDecimalPad = 8 } UIKeyboardType;
typedef enum UIReturnKeyType : NSInteger { UIReturnKeyDone = 9 } UIReturnKeyType;
typedef enum UITextFieldViewMode : NSInteger { UITextFieldViewModeWhileEditing = 1 }
    UITextFieldViewMode;
@interface UITextField : UIControl
@property (nullable, copy) NSString *text;
@property (nullable, copy) NSString *placeholder;
@property (nullable, strong) UIFont *font;
@property (nullable, strong) UIColor *textColor;
@property NSInteger textAlignment;
@property BOOL adjustsFontSizeToFitWidth;
@property CGFloat minimumFontSize;
@property UIKeyboardType keyboardType;
@property UIReturnKeyType returnKeyType;
@property UITextFieldViewMode clearButtonMode;
@property (nullable, weak) id<UITextFieldDelegate> delegate;
@end
typedef enum UIStackViewAlignment : NSInteger { UIStackViewAlignmentFill,
    UIStackViewAlignmentLeading, UIStackViewAlignmentFirstBaseline,
    UIStackViewAlignmentCenter } UIStackViewAlignment;
@interface UIStackView : UIView
- (instancetype)initWithArrangedSubviews:(NSArray<__kindof UIView *> *)views;
- (void)addArrangedSubview:(UIView *)v;
@property UILayoutConstraintAxis axis;
@property CGFloat spacing;
@property UIStackViewAlignment alignment;
@property (getter=isLayoutMarginsRelativeArrangement) BOOL layoutMarginsRelativeArrangement;
@property NSDirectionalEdgeInsets directionalLayoutMargins;
@end
typedef enum UIScrollViewKeyboardDismissMode : NSInteger {
    UIScrollViewKeyboardDismissModeInteractive = 2 } UIScrollViewKeyboardDismissMode;
@interface UIScrollView : UIView
@property BOOL alwaysBounceVertical;
@property UIScrollViewKeyboardDismissMode keyboardDismissMode;
@property UIEdgeInsets contentInset;
@property UIEdgeInsets verticalScrollIndicatorInsets;
@property CGPoint contentOffset;
@property CGSize contentSize;
- (void)setContentOffset:(CGPoint)o animated:(BOOL)a;
@property (readonly, strong) UILayoutGuide *contentLayoutGuide;
@property (readonly, strong) UILayoutGuide *frameLayoutGuide;
@end

// Table
typedef enum UITableViewStyle : NSInteger { UITableViewStylePlain, UITableViewStyleGrouped,
    UITableViewStyleInsetGrouped } UITableViewStyle;
typedef enum UITableViewCellStyle : NSInteger { UITableViewCellStyleDefault,
    UITableViewCellStyleValue1 } UITableViewCellStyle;
typedef enum UITableViewCellAccessoryType : NSInteger { UITableViewCellAccessoryNone,
    UITableViewCellAccessoryDisclosureIndicator, UITableViewCellAccessoryDetailDisclosureButton,
    UITableViewCellAccessoryCheckmark } UITableViewCellAccessoryType;
typedef enum UITableViewCellSelectionStyle : NSInteger { UITableViewCellSelectionStyleNone }
    UITableViewCellSelectionStyle;
typedef enum UITableViewCellEditingStyle : NSInteger { UITableViewCellEditingStyleNone,
    UITableViewCellEditingStyleDelete } UITableViewCellEditingStyle;
typedef enum UITableViewRowAnimation : NSInteger { UITableViewRowAnimationFade,
    UITableViewRowAnimationNone = 5, UITableViewRowAnimationAutomatic = 100 }
    UITableViewRowAnimation;

@interface NSIndexPath (UIKit)
+ (instancetype)indexPathForRow:(NSInteger)r inSection:(NSInteger)s;
@property (readonly) NSInteger row;
@property (readonly) NSInteger section;
@end

@interface UITableViewCell : UIView
- (instancetype)initWithStyle:(UITableViewCellStyle)s
              reuseIdentifier:(nullable NSString *)r NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)c NS_DESIGNATED_INITIALIZER;
@property (readonly, strong) UIView *contentView;
@property (nullable, readonly, strong) UILabel *textLabel;
@property (nullable, readonly, strong) UILabel *detailTextLabel;
@property (nullable, readonly, copy) NSString *reuseIdentifier;
@property UITableViewCellAccessoryType accessoryType;
@property (nullable, strong) UIView *accessoryView;
@property UITableViewCellSelectionStyle selectionStyle;
- (void)prepareForReuse;
@end
@interface UITableViewHeaderFooterView : UIView
- (instancetype)initWithReuseIdentifier:(nullable NSString *)r NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)c NS_DESIGNATED_INITIALIZER;
@property (readonly, strong) UIView *contentView;
- (void)prepareForReuse;
@end
@protocol UITableViewDataSource <NSObject>
@required
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s;
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)i;
@optional
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t;
- (nullable NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s;
- (nullable NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s;
- (BOOL)tableView:(UITableView *)t canEditRowAtIndexPath:(NSIndexPath *)i;
- (void)tableView:(UITableView *)t commitEditingStyle:(UITableViewCellEditingStyle)e
    forRowAtIndexPath:(NSIndexPath *)i;
@end
@protocol UITableViewDelegate <NSObject>
@optional
- (nullable UIView *)tableView:(UITableView *)t viewForHeaderInSection:(NSInteger)s;
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)i;
@end
@interface UITableView : UIScrollView
@property CGFloat rowHeight;
@property CGFloat sectionHeaderHeight;
@property CGFloat estimatedSectionHeaderHeight;
@property (nullable, strong) UIView *backgroundView;
@property (readonly) NSInteger numberOfSections;
- (NSInteger)numberOfRowsInSection:(NSInteger)s;
- (void)registerClass:(nullable Class)c forCellReuseIdentifier:(NSString *)i;
- (void)registerClass:(nullable Class)c forHeaderFooterViewReuseIdentifier:(NSString *)i;
- (nullable __kindof UITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)i;
- (__kindof UITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)i
                                                    forIndexPath:(NSIndexPath *)p;
- (nullable __kindof UITableViewHeaderFooterView *)dequeueReusableHeaderFooterViewWithIdentifier:
    (NSString *)i;
- (nullable __kindof UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)p;
- (nullable UITableViewHeaderFooterView *)headerViewForSection:(NSInteger)s;
- (void)reloadData;
- (void)performBatchUpdates:(void (NS_NOESCAPE ^ _Nullable)(void))u
                 completion:(void (^ _Nullable)(BOOL finished))c;
- (void)insertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)p withRowAnimation:(UITableViewRowAnimation)a;
- (void)deleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)p withRowAnimation:(UITableViewRowAnimation)a;
- (void)reloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)p withRowAnimation:(UITableViewRowAnimation)a;
- (void)deleteSections:(NSIndexSet *)s withRowAnimation:(UITableViewRowAnimation)a;
- (void)deselectRowAtIndexPath:(NSIndexPath *)p animated:(BOOL)a;
@end

// View controllers
typedef enum UINavigationItemLargeTitleDisplayMode : NSInteger {
    UINavigationItemLargeTitleDisplayModeAutomatic, UINavigationItemLargeTitleDisplayModeAlways,
    UINavigationItemLargeTitleDisplayModeNever } UINavigationItemLargeTitleDisplayMode;
typedef enum UIBarButtonSystemItem : NSInteger { UIBarButtonSystemItemCancel = 1,
    UIBarButtonSystemItemSave = 3, UIBarButtonSystemItemAdd = 4 } UIBarButtonSystemItem;
typedef enum UIBarButtonItemStyle : NSInteger { UIBarButtonItemStylePlain } UIBarButtonItemStyle;
@interface UIBarButtonItem : NSObject
- (instancetype)initWithBarButtonSystemItem:(UIBarButtonSystemItem)i target:(nullable id)t
                                     action:(nullable SEL)a;
- (instancetype)initWithTitle:(nullable NSString *)t style:(UIBarButtonItemStyle)s
                       target:(nullable id)tg action:(nullable SEL)a;
@property (getter=isEnabled) BOOL enabled;
@end
@interface UINavigationItem : NSObject
@property (nullable, strong) UIBarButtonItem *leftBarButtonItem;
@property (nullable, strong) UIBarButtonItem *rightBarButtonItem;
@property (nullable, strong) UISearchController *searchController;
@property UINavigationItemLargeTitleDisplayMode largeTitleDisplayMode;
@end
@interface UITabBarItem : NSObject
- (instancetype)initWithTitle:(nullable NSString *)t image:(nullable UIImage *)i tag:(NSInteger)g;
@end
@interface UIViewController : UIResponder
- (instancetype)initWithNibName:(nullable NSString *)n
                         bundle:(nullable NSBundle *)b NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)c NS_DESIGNATED_INITIALIZER;
@property (null_resettable, strong) UIView *view;
@property (nullable, copy) NSString *title;
@property (readonly, getter=isViewLoaded) BOOL viewLoaded;
@property (readonly, strong) UINavigationItem *navigationItem;
@property (nullable, readonly, strong) UINavigationController *navigationController;
@property (nullable, readonly, strong) UITabBarController *tabBarController;
@property (nullable, readonly) UIViewController *presentedViewController;
@property (nullable, readonly, strong) UIPopoverPresentationController *popoverPresentationController;
@property (nullable, strong) UITabBarItem *tabBarItem;
@property BOOL definesPresentationContext;
- (void)loadViewIfNeeded;
- (void)viewDidLoad;
- (void)viewWillAppear:(BOOL)a;
- (void)viewDidAppear:(BOOL)a;
- (void)viewWillDisappear:(BOOL)a;
- (void)presentViewController:(UIViewController *)v animated:(BOOL)a
                   completion:(void (^ _Nullable)(void))c;
- (void)dismissViewControllerAnimated:(BOOL)a completion:(void (^ _Nullable)(void))c;
@end
@interface UIPopoverPresentationController : NSObject
@property (nullable, strong) UIView *sourceView;
@property CGRect sourceRect;
@end
@interface UITableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
- (instancetype)initWithStyle:(UITableViewStyle)s NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)n
                         bundle:(nullable NSBundle *)b NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)c NS_DESIGNATED_INITIALIZER;
@property (null_resettable, strong) UITableView *tableView;
@end
@interface UINavigationBar : UIView
@property BOOL prefersLargeTitles;
@end
@interface UINavigationController : UIViewController
- (instancetype)initWithRootViewController:(UIViewController *)r;
@property (copy) NSArray<__kindof UIViewController *> *viewControllers;
@property (readonly) UINavigationBar *navigationBar;
- (void)pushViewController:(UIViewController *)v animated:(BOOL)a;
- (nullable UIViewController *)popViewControllerAnimated:(BOOL)a;
- (nullable NSArray *)popToViewController:(UIViewController *)v animated:(BOOL)a;
@end
@interface UITabBarController : UIViewController
@property (nullable, copy) NSArray<__kindof UIViewController *> *viewControllers;
@property NSUInteger selectedIndex;
@end
typedef enum UIAlertControllerStyle : NSInteger { UIAlertControllerStyleActionSheet,
    UIAlertControllerStyleAlert } UIAlertControllerStyle;
typedef enum UIAlertActionStyle : NSInteger { UIAlertActionStyleDefault, UIAlertActionStyleCancel,
    UIAlertActionStyleDestructive } UIAlertActionStyle;
@interface UIAlertAction : NSObject
+ (instancetype)actionWithTitle:(nullable NSString *)t style:(UIAlertActionStyle)s
                        handler:(void (^ _Nullable)(UIAlertAction *action))h;
@end
@interface UIAlertController : UIViewController
+ (instancetype)alertControllerWithTitle:(nullable NSString *)t message:(nullable NSString *)m
                          preferredStyle:(UIAlertControllerStyle)s;
- (void)addAction:(UIAlertAction *)a;
@end
@interface UIActivityViewController : UIViewController
- (instancetype)initWithActivityItems:(NSArray *)i applicationActivities:(nullable NSArray *)a;
@end
@interface UISearchBar : UIView
@property (nullable, copy) NSString *text;
@property (nullable, copy) NSString *placeholder;
@end
@protocol UISearchResultsUpdating <NSObject>
@required
- (void)updateSearchResultsForSearchController:(UISearchController *)s;
@end
@interface UISearchController : UIViewController
- (instancetype)initWithSearchResultsController:(nullable UIViewController *)c;
@property (nullable, weak) id<UISearchResultsUpdating> searchResultsUpdater;
@property BOOL obscuresBackgroundDuringPresentation;
@property (readonly, strong) UISearchBar *searchBar;
@property (getter=isActive) BOOL active;
@end

// App / Scene
extern NSNotificationName const UIKeyboardWillShowNotification;
extern NSNotificationName const UIKeyboardWillHideNotification;
extern NSString *const UIKeyboardFrameEndUserInfoKey;
typedef NSUInteger UIBackgroundTaskIdentifier;
extern const UIBackgroundTaskIdentifier UIBackgroundTaskInvalid;
@interface UIApplication : UIResponder
@property (class, readonly) UIApplication *sharedApplication;
@property (readonly) NSSet<UIScene *> *connectedScenes;
- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithName:(nullable NSString *)n
                                        expirationHandler:(void (^ _Nullable)(void))h;
- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)i;
@end
@interface UISceneSession : NSObject
@property (readonly) NSString *role;
@end
@interface UISceneConnectionOptions : NSObject
@end
@interface UISceneConfiguration : NSObject
- (instancetype)initWithName:(nullable NSString *)n sessionRole:(NSString *)r;
@end
@interface UIScene : UIResponder
@end
@interface UIWindowScene : UIScene
@end
@protocol UISceneDelegate <NSObject>
@optional
- (void)scene:(UIScene *)s willConnectToSession:(UISceneSession *)ss
      options:(UISceneConnectionOptions *)o;
- (void)sceneDidDisconnect:(UIScene *)s;
- (void)sceneDidEnterBackground:(UIScene *)s;
@end
@protocol UIWindowSceneDelegate <UISceneDelegate>
@property (nullable, nonatomic, strong) UIWindow *window;
@end
@protocol UIApplicationDelegate <NSObject>
@end
@interface UIWindow : UIView
- (instancetype)initWithWindowScene:(UIWindowScene *)s;
- (instancetype)initWithFrame:(CGRect)f;
@property (nullable, strong) UIViewController *rootViewController;
- (void)makeKeyAndVisible;
@end

_Pragma("clang assume_nonnull end")
