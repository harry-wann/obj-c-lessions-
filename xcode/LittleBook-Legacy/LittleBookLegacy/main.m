//
//  main.m
//  LittleBookLegacy
//
//  Created by LittleBook Team on 2012/11/20.
//  Copyright (c) 2012 LittleBook. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LBLegacyAppDelegate.h"

int main(int argc, char *argv[])
{
    // @autoreleasepool 出現之前的寫法（11.2）
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil,
                                   NSStringFromClass([LBLegacyAppDelegate class]));
    [pool release];
    return retVal;
}
