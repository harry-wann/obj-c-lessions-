//
//  LBLegacyListViewController.h
//  LittleBookLegacy
//
//  Created by LittleBook Team on 2012/11/20.
//  Copyright (c) 2012 LittleBook. All rights reserved.
//

#import <UIKit/UIKit.h>

// 交易列表（Main.storyboard 的 root view controller）
@interface LBLegacyListViewController : UITableViewController {
    UILabel *_totalLabel;
}

// MRC 時代的 outlet 用 retain，dealloc 要 release
@property (nonatomic, retain) IBOutlet UILabel *totalLabel;   // 表頭的合計

- (IBAction)addTapped:(id)sender;

@end
