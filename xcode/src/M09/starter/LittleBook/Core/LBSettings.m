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
        // TODO: M09 — registerDefaults:：currencyCode = TWD、showsCents = YES、appearance = 0
    }
    return self;
}

// TODO: M09 — 三個屬性都改成直接讀寫 _userDefaults（stringForKey: / boolForKey: / integerForKey:），
//            setter 寫完送 LBSettingsDidChangeNotification（主執行緒）。目前只存在記憶體裡。

- (NSString *)currencyCode {
    return @"";
}

- (void)setCurrencyCode:(NSString *)currencyCode {
}

- (BOOL)showsCents {
    return NO;
}

- (void)setShowsCents:(BOOL)showsCents {
}

- (NSInteger)appearance {
    return 0;
}

- (void)setAppearance:(NSInteger)appearance {
}

@end
