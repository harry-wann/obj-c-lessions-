#pragma once
// 語法檢查用：模擬 Xcode 由 M12 的 Swift 檔自動產生的 LittleBook-Swift.h（只列 @objc 可見的部分）。
// 真的建置時這個檔由編譯器產生在 DerivedSources，內容以 Xcode 產生的為準；
// Swift 端改了 @objc 介面（StatsViewModel / StatsViewController / StatsBreakdownItem）要同步改這裡。
#import <UIKit/UIKit.h>

@class LBLedger;

_Pragma("clang assume_nonnull begin")

@interface StatsBreakdownItem : NSObject
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, strong) NSDecimalNumber *total;
- (instancetype)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
@end

@interface StatsViewModel : NSObject
@property (nonatomic, readonly, strong) LBLedger *ledger;
- (instancetype)initWithLedger:(LBLedger *)ledger __attribute__((objc_designated_initializer));
@property (nonatomic, readonly, strong) NSDecimalNumber *expenseTotal;
@property (nonatomic, readonly, strong) NSDecimalNumber *incomeTotal;
@property (nonatomic, readonly, strong) NSDecimalNumber *balance;
- (NSArray<NSString *> *)categoryNames __attribute__((warn_unused_result));
- (instancetype)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
@end

@interface StatsViewModel (LittleBook)
- (NSArray<StatsBreakdownItem *> *)breakdownItems __attribute__((warn_unused_result));
@end

@interface StatsViewController : UIViewController
@property (nonatomic, readonly, strong) StatsViewModel *viewModel;
- (instancetype)initWithLedger:(LBLedger *)ledger __attribute__((objc_designated_initializer));
- (nullable instancetype)initWithCoder:(NSCoder *)coder __attribute__((unavailable));
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil __attribute__((unavailable));
@end

_Pragma("clang assume_nonnull end")
