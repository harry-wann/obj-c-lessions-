//
//  LBLegacyKitVersion.h
//  LBLegacyKit
//
//  Created by LittleBook Team on 2013/04/02.
//  Copyright (c) 2013 LittleBook. All rights reserved.
//

#import <Foundation/Foundation.h>

// 靜態庫的版本資訊；App 啟動時印出來，方便回報問題時確認用的是哪一版
@interface LBLegacyKitVersion : NSObject

+ (NSString *)versionString;

@end
