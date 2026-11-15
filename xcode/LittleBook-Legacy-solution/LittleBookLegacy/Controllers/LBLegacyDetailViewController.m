//
//  LBLegacyDetailViewController.m
//  LittleBookLegacy
//
//  Created by LittleBook Team on 2012/11/20.
//  Copyright (c) 2012 LittleBook. All rights reserved.
//

#import "LBLegacyDetailViewController.h"
#import "LBLegacyLedger.h"
#import "LBLegacyTransaction.h"

@interface LBLegacyDetailViewController ()
- (void)refreshLabels;
- (void)refreshRateLabel;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
@end

@implementation LBLegacyDetailViewController

@synthesize transaction = _transaction;
@synthesize noteLabel = _noteLabel;
@synthesize amountField = _amountField;
@synthesize rateLabel = _rateLabel;

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"明細";
    [self refreshLabels];

    _rateService = [[LBLegacyRateService alloc] init];   // +1，dealloc 配一個 release
    _rateService.delegate = self;                        // assign
    self.rateLabel.text = @"匯率載入中…";
    [_rateService fetchRatesForBase:@"TWD"];
}

- (void)dealloc
{
    // 雷 6：NSURLConnection 會 retain service，service 會比我活得久；
    // 先把指向我的 assign delegate 清掉，再取消請求
    _rateService.delegate = nil;
    [_rateService cancel];
    [_rateService release];
    [_transaction release];
    [_usdRate release];
    [_noteLabel release];
    [_amountField release];
    [_rateLabel release];
    [super dealloc];
}

#pragma mark - Actions

- (IBAction)saveTapped:(id)sender
{
    NSString *text = [self.amountField.text lb_trimmed];
    if ([text length] == 0) {
        [self showAlertWithTitle:@"請輸入金額" message:nil];
        return;
    }
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:text];
    if ([amount isEqualToNumber:[NSDecimalNumber notANumber]]) {
        [self showAlertWithTitle:@"金額格式不正確" message:text];
        return;
    }
    self.transaction.amount = amount;
    [[LBLegacyLedger sharedLedger] transactionDidChange:self.transaction];
    [self.amountField resignFirstResponder];
    [self refreshRateLabel];
}

#pragma mark - LBLegacyRateServiceDelegate

- (void)rateService:(LBLegacyRateService *)service didLoadRates:(NSDictionary *)rates
{
    NSDecimalNumber *usd = [rates objectForKey:@"USD"];
    [usd retain];
    [_usdRate release];
    _usdRate = usd;
    [self refreshRateLabel];
}

- (void)rateService:(LBLegacyRateService *)service didFailWithError:(NSError *)error
{
    self.rateLabel.text = @"匯率暫時無法取得";
    [self showAlertWithTitle:@"匯率載入失敗" message:[error localizedDescription]];
}

#pragma mark - Private

- (void)refreshLabels
{
    self.noteLabel.text = [_transaction.note lb_trimmed];
    self.amountField.text = [_transaction.amount stringValue];
}

- (void)refreshRateLabel
{
    if (_usdRate == nil) {
        self.rateLabel.text = @"沒有美元匯率";
        return;
    }
    NSDecimalNumberHandler *rounding =
        [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                               scale:2
                                                    raiseOnExactness:NO
                                                     raiseOnOverflow:NO
                                                    raiseOnUnderflow:NO
                                                 raiseOnDivideByZero:NO];
    NSDecimalNumber *usd = [_transaction.amount decimalNumberByMultiplyingBy:_usdRate
                                                                withBehavior:rounding];
    self.rateLabel.text = [NSString stringWithFormat:@"約 US$%@", [usd stringValue]];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    // iOS 8 之前沒有 UIAlertController；UIAlertView 自己會在顯示期間被系統持有
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"好"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

@end
