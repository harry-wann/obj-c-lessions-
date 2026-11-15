//
//  LBLegacyDetailViewController.h
//  LittleBookLegacy
//
//  Created by LittleBook Team on 2012/11/20.
//  Copyright (c) 2012 LittleBook. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LBLegacyRateService.h"

@class LBLegacyTransaction;

// 交易明細：顯示備註、改金額、顯示約合多少美元（匯率由 LBLegacyRateService 抓）
@interface LBLegacyDetailViewController : UIViewController <LBLegacyRateServiceDelegate> {
    LBLegacyTransaction *_transaction;
    LBLegacyRateService *_rateService;
    NSDecimalNumber *_usdRate;
    UILabel *_noteLabel;
    UITextField *_amountField;
    UILabel *_rateLabel;
}

@property (nonatomic, retain) LBLegacyTransaction *transaction;   // 由 prepareForSegue: 塞進來

@property (nonatomic, retain) IBOutlet UILabel *noteLabel;
@property (nonatomic, retain) IBOutlet UITextField *amountField;
@property (nonatomic, retain) IBOutlet UILabel *rateLabel;

- (IBAction)saveTapped:(id)sender;

@end
