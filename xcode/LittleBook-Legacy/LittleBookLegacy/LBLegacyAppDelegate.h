//
//  LBLegacyAppDelegate.h
//  LittleBookLegacy
//
//  Created by LittleBook Team on 2012/11/20.
//  Copyright (c) 2012 LittleBook. All rights reserved.
//

#import <UIKit/UIKit.h>

// 老派啟動：Info.plist 的 UIMainStoryboardFile 指定 Main.storyboard，
// UIKit 建好 window 後透過 setWindow: 交給我們；沒有 SceneDelegate。
@interface LBLegacyAppDelegate : UIResponder <UIApplicationDelegate> {
    UIWindow *_window;
}

@property (nonatomic, retain) UIWindow *window;

@end
