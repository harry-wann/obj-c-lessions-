#import <XCTest/XCTest.h>
#import "LBTransactionEditorViewController.h"
#import "LBLedger.h"
#import "LBTransaction.h"
#import "LBTypes.h"

/// 假的 delegate：記下收到的呼叫。
@interface LBEditorDelegateSpy : NSObject <LBTransactionEditorDelegate>
@property (nonatomic, strong, nullable) LBTransaction *savedTransaction;
@property (nonatomic, assign) NSUInteger saveCount;
@property (nonatomic, assign) NSUInteger cancelCount;
@end

@implementation LBEditorDelegateSpy

- (void)editor:(LBTransactionEditorViewController *)editor
    didSaveTransaction:(LBTransaction *)transaction {
    self.savedTransaction = transaction;
    self.saveCount += 1;
}

- (void)editorDidCancel:(LBTransactionEditorViewController *)editor {
    self.cancelCount += 1;
}

@end

@interface LBTransactionEditorViewControllerTests : XCTestCase
@end

@implementation LBTransactionEditorViewControllerTests

- (void)testSaveCallsDelegateWithTransaction {
    LBLedger *ledger = [[LBLedger alloc] init];
    LBTransactionEditorViewController *editor =
        [[LBTransactionEditorViewController alloc] initWithLedger:ledger transaction:nil];
    LBEditorDelegateSpy *spy = [[LBEditorDelegateSpy alloc] init];
    editor.delegate = spy;
    [editor loadViewIfNeeded];   // 表單控制項在 viewDidLoad 建立

    editor.amountField.text = @"1,280.5";   // 千分位逗號要能吃
    NSError *error = nil;
    XCTAssertTrue([editor saveWithError:&error]);
    XCTAssertNil(error);
    XCTAssertEqual(spy.saveCount, (NSUInteger)1);
    XCTAssertNotNil(spy.savedTransaction);
    XCTAssertEqualObjects(spy.savedTransaction.amount,
                          [NSDecimalNumber decimalNumberWithString:@"1280.5"]);
    XCTAssertEqual(spy.savedTransaction.kind, LBTransactionKindExpense);
    XCTAssertEqual(ledger.transactions.count, (NSUInteger)0,
                   @"編輯頁不直接改 ledger，交給 delegate 決定（列表才能登記復原）");

    // delegate 是 weak：編輯頁不能持有它
    __weak LBEditorDelegateSpy *weakSpy = nil;
    @autoreleasepool {
        LBEditorDelegateSpy *temporary = [[LBEditorDelegateSpy alloc] init];
        editor.delegate = temporary;
        weakSpy = temporary;
    }
    XCTAssertNil(weakSpy);
    XCTAssertNil(editor.delegate);
}

- (void)testInvalidAmountDoesNotSave {
    LBLedger *ledger = [[LBLedger alloc] init];
    LBTransactionEditorViewController *editor =
        [[LBTransactionEditorViewController alloc] initWithLedger:ledger transaction:nil];
    LBEditorDelegateSpy *spy = [[LBEditorDelegateSpy alloc] init];
    editor.delegate = spy;
    [editor loadViewIfNeeded];

    for (NSString *text in @[@"", @"   ", @"abc", @"0", @"-50", @"0.00"]) {
        editor.amountField.text = text;
        NSError *error = nil;
        XCTAssertFalse([editor saveWithError:&error], @"「%@」不是合法金額", text);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, LBErrorDomain);
        XCTAssertEqual(error.code, (NSInteger)LBErrorCodeInvalidAmount);
    }
    editor.amountField.text = nil;
    XCTAssertFalse([editor saveWithError:NULL], @"error 傳 NULL 也不能 crash");
    XCTAssertEqual(spy.saveCount, (NSUInteger)0, @"非法金額不能呼叫 delegate");
}

@end
