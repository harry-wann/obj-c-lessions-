//
//  NSString+LBUtils.h
//  LBLegacyKit
//
//  Created by LittleBook Team on 2013/04/02.
//  Copyright (c) 2013 LittleBook. All rights reserved.
//

#import <Foundation/Foundation.h>

// 字串小工具。所有 category 方法一律加 lb_ 前綴，避免跟其他庫的同名方法互相蓋掉。
@interface NSString (LBUtils)

// 去掉前後的空白與換行（全形空白 U+3000 也算）
- (NSString *)lb_trimmed;

// 空字串或只有空白就回 YES
- (BOOL)lb_isBlank;

@end
