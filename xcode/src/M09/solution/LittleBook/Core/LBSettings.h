@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// 外觀設定值。
typedef NS_ENUM(NSInteger, LBAppearance) {
    LBAppearanceSystem = 0,   // 跟隨系統
    LBAppearanceLight = 1,
    LBAppearanceDark = 2,
};

/// NSUserDefaults 的 key（與 M08 編輯頁讀主幣別用的字串相同）。
extern NSString * const LBSettingsCurrencyCodeKey;    // @"LBSettings.currencyCode"
extern NSString * const LBSettingsShowsCentsKey;      // @"LBSettings.showsCents"
extern NSString * const LBSettingsAppearanceKey;      // @"LBSettings.appearance"

/// 任何設定被改時在主執行緒送出；object 是 LBSettings 本身。
extern NSNotificationName const LBSettingsDidChangeNotification;

/// 使用者設定（9.2）：只放小東西、只放 plist 型別。預設值用 registerDefaults:，
/// 不寫進磁碟、每次啟動重新登記，所以「沒改過」與「改成和預設一樣」看起來相同。
@interface LBSettings : NSObject

/// App 用的單例，背後是 standardUserDefaults。
+ (instancetype)shared;

/// 測試用：傳 [[NSUserDefaults alloc] initWithSuiteName:…]，不污染真正的設定。
- (instancetype)initWithUserDefaults:(NSUserDefaults *)defaults NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) NSUserDefaults *userDefaults;

/// 主幣別，預設 TWD。
@property (nonatomic, copy) NSString *currencyCode;
/// 是否顯示到「分」（小數兩位），預設 YES。
@property (nonatomic, assign) BOOL showsCents;
/// 0 跟隨系統 / 1 淺 / 2 深（LBAppearance），預設 0；超出範圍的值當 0。
@property (nonatomic, assign) NSInteger appearance;

/// 設定頁可選的幣別。
+ (NSArray<NSString *> *)supportedCurrencyCodes;

@end

NS_ASSUME_NONNULL_END
