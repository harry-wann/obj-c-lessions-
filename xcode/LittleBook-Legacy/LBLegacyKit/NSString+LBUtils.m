//
//  NSString+LBUtils.m
//  LBLegacyKit
//
//  Created by LittleBook Team on 2013/04/02.
//  Copyright (c) 2013 LittleBook. All rights reserved.
//

#import "NSString+LBUtils.h"

@implementation NSString (LBUtils)

- (NSString *)lb_trimmed {
    // mutableCopy 回傳 +1，用完要 release
    NSMutableCharacterSet *set = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
    [set addCharactersInString:@"　"];   // 保險：全形空白
    NSString *result = [self stringByTrimmingCharactersInSet:set];   // autoreleased，+0
    [set release];
    return result;
}

- (BOOL)lb_isBlank {
    return [[self lb_trimmed] length] == 0;
}

@end
