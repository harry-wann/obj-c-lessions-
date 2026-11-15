#import "LBSettings.h"

NSString * const LBSettingsCurrencyCodeKey = @"LBSettings.currencyCode";
NSString * const LBSettingsShowsCentsKey = @"LBSettings.showsCents";
NSString * const LBSettingsAppearanceKey = @"LBSettings.appearance";
NSNotificationName const LBSettingsDidChangeNotification = @"LBSettingsDidChangeNotification";

@implementation LBSettings

+ (instancetype)shared {
    static LBSettings *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[LBSettings alloc] initWithUserDefaults:NSUserDefaults.standardUserDefaults];
    });
    return shared;
}

+ (NSArray<NSString *> *)supportedCurrencyCodes {
    return @[@"TWD", @"USD", @"JPY", @"EUR", @"CNY"];
}

- (instancetype)initWithUserDefaults:(NSUserDefaults *)defaults {
    NSParameterAssert(defaults != nil);
    if ((self = [super init])) {
        _userDefaults = defaults;
        // 預設值只存在記憶體（registration domain），每次建立都要重新登記
        [_userDefaults registerDefaults:@{
            LBSettingsCurrencyCodeKey: @"TWD",
            LBSettingsShowsCentsKey: @YES,
            LBSettingsAppearanceKey: @(LBAppearanceSystem),
        }];
    }
    return self;
}

#pragma mark - 屬性（直接讀寫 NSUserDefaults，不另外快取）

- (NSString *)currencyCode {
    NSString *code = [_userDefaults stringForKey:LBSettingsCurrencyCodeKey];
    return code.length > 0 ? code : @"TWD";   // 防禦：有人塞了空字串或非字串
}

- (void)setCurrencyCode:(NSString *)currencyCode {
    NSParameterAssert(currencyCode != nil);
    [_userDefaults setObject:[currencyCode copy] forKey:LBSettingsCurrencyCodeKey];
    [self lb_postChange];
}

- (BOOL)showsCents {
    return [_userDefaults boolForKey:LBSettingsShowsCentsKey];
}

- (void)setShowsCents:(BOOL)showsCents {
    [_userDefaults setBool:showsCents forKey:LBSettingsShowsCentsKey];
    [self lb_postChange];
}

- (NSInteger)appearance {
    NSInteger value = [_userDefaults integerForKey:LBSettingsAppearanceKey];
    return (value >= LBAppearanceSystem && value <= LBAppearanceDark) ? value : LBAppearanceSystem;
}

- (void)setAppearance:(NSInteger)appearance {
    [_userDefaults setInteger:appearance forKey:LBSettingsAppearanceKey];
    [self lb_postChange];
}

/// 不用再呼叫 synchronize：系統會自己找時機寫回磁碟。
- (void)lb_postChange {
    dispatch_block_t post = ^{
        [NSNotificationCenter.defaultCenter postNotificationName:LBSettingsDidChangeNotification
                                                          object:self];
    };
    if (NSThread.isMainThread) {
        post();
    } else {
        dispatch_async(dispatch_get_main_queue(), post);
    }
}

@end
