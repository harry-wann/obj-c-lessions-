#pragma once
// 語法檢查用的極簡 Masonry 1.1 替身：只宣告 LittleBook 編輯頁用到的鏈式 DSL。
// 真的建置請 `pod install`；替身只用來確認 #if __has_include(<Masonry/Masonry.h>) 那一支寫得對。
#import <UIKit/UIKit.h>
_Pragma("clang assume_nonnull begin")

@interface MASViewAttribute : NSObject
@end

@interface MASConstraint : NSObject
- (MASConstraint * (^)(id attr))equalTo;
- (MASConstraint * (^)(id attr))greaterThanOrEqualTo;
- (MASConstraint * (^)(id attr))lessThanOrEqualTo;
- (MASConstraint * (^)(UIEdgeInsets insets))insets;
- (MASConstraint * (^)(CGFloat offset))offset;
@property (nonatomic, strong, readonly) MASConstraint *left, *right, *top, *bottom, *leading,
    *trailing, *width, *height, *centerX, *centerY;
@end

// mas_ 巨集：把 C 數值包成物件再交給 equalTo
#define MASBoxValue(value) @(value)
#define mas_equalTo(...) equalTo(MASBoxValue((__VA_ARGS__)))
#define mas_greaterThanOrEqualTo(...) greaterThanOrEqualTo(MASBoxValue((__VA_ARGS__)))
#define mas_lessThanOrEqualTo(...) lessThanOrEqualTo(MASBoxValue((__VA_ARGS__)))

@interface MASConstraintMaker : NSObject
@property (nonatomic, strong, readonly) MASConstraint *left, *right, *top, *bottom, *leading,
    *trailing, *width, *height, *centerX, *centerY, *edges, *size, *center;
@end

@interface UIView (MASAdditions)
@property (nonatomic, strong, readonly) MASViewAttribute *mas_left, *mas_right, *mas_top,
    *mas_bottom, *mas_leading, *mas_trailing, *mas_width, *mas_height;
@property (nonatomic, strong, readonly) MASViewAttribute *mas_safeAreaLayoutGuide,
    *mas_safeAreaLayoutGuideTop, *mas_safeAreaLayoutGuideBottom,
    *mas_safeAreaLayoutGuideLeading, *mas_safeAreaLayoutGuideTrailing;
- (NSArray *)mas_makeConstraints:(void (NS_NOESCAPE ^)(MASConstraintMaker *make))block;
- (NSArray *)mas_updateConstraints:(void (NS_NOESCAPE ^)(MASConstraintMaker *make))block;
- (NSArray *)mas_remakeConstraints:(void (NS_NOESCAPE ^)(MASConstraintMaker *make))block;
@end

_Pragma("clang assume_nonnull end")
