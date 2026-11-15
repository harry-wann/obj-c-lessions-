//
//  LBLegacyListViewController.m
//  LittleBookLegacy
//
//  Created by LittleBook Team on 2012/11/20.
//  Copyright (c) 2012 LittleBook. All rights reserved.
//

#import "LBLegacyListViewController.h"
#import "LBLegacyDetailViewController.h"
#import "LBLegacyLedger.h"
#import "LBLegacyTransaction.h"

static NSString * const kLBTransactionCellIdentifier = @"LBLegacyTransactionCell";

@interface LBLegacyListViewController ()
- (void)updateTotal;
- (void)ledgerDidChange:(NSNotification *)notification;
@end

@implementation LBLegacyListViewController

@synthesize totalLabel = _totalLabel;

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ledgerDidChange:)
                                                 name:LBLegacyLedgerDidChangeNotification
                                               object:nil];
    [self updateTotal];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self updateTotal];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_totalLabel release];
    [super dealloc];
}

#pragma mark - Actions

- (IBAction)addTapped:(id)sender
{
    NSArray *notes = [NSArray arrayWithObjects:@"  飲料  ", @"文具\n", @"　晚餐　", nil];
    NSString *note = [notes objectAtIndex:arc4random_uniform((u_int32_t)[notes count])];
    unsigned long long dollars = 10 + arc4random_uniform(200);
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithMantissa:dollars
                                                                exponent:0
                                                              isNegative:NO];
    LBLegacyTransaction *tx = [[LBLegacyTransaction alloc] initWithNote:note amount:amount];
    [[LBLegacyLedger sharedLedger] addTransaction:tx];   // 帳本 retain
    [tx release];                                         // 我放手
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[LBLegacyLedger sharedLedger] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // prototype cell 由 storyboard 註冊，dequeue 一定拿得到（+0，不用 release）
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:kLBTransactionCellIdentifier
                                        forIndexPath:indexPath];
    LBLegacyTransaction *tx = [[LBLegacyLedger sharedLedger] transactionAtIndex:indexPath.row];
    cell.textLabel.text = [tx.note lb_trimmed];
    cell.detailTextLabel.text = [tx formattedAmount];
    return cell;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // 帳本會發通知，ledgerDidChange: 裡 reloadData
        [[LBLegacyLedger sharedLedger] removeTransactionAtIndex:indexPath.row];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"showDetail" sender:indexPath];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        LBLegacyDetailViewController *detail =
            (LBLegacyDetailViewController *)[segue destinationViewController];
        detail.transaction = [[LBLegacyLedger sharedLedger] transactionAtIndex:indexPath.row];
    }
}

#pragma mark - Private

- (void)updateTotal
{
    LBLegacyLedger *ledger = [LBLegacyLedger sharedLedger];
    self.totalLabel.text = [NSString stringWithFormat:@"合計 NT$%@（%lu 筆）",
                            [ledger.total stringValue], (unsigned long)[ledger count]];
}

- (void)ledgerDidChange:(NSNotification *)notification
{
    [self.tableView reloadData];
    [self updateTotal];
}

@end
