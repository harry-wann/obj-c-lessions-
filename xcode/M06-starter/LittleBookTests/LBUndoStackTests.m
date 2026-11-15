#import <XCTest/XCTest.h>
#import "LBUndoStack.h"
#import "LBLedger.h"
#import "LBTransaction.h"

@interface LBUndoStackTests : XCTestCase
@end

@implementation LBUndoStackTests

- (void)testUndoRedo {
    LBUndoStack *stack = [[LBUndoStack alloc] init];
    XCTAssertFalse(stack.canUndo);
    XCTAssertFalse(stack.canRedo);
    XCTAssertNoThrow([stack undo], @"沒有東西可復原時什麼都不做");
    XCTAssertNoThrow([stack redo]);

    __block NSInteger value = 0;
    value = 1;
    [stack registerUndo:^{ value = 0; } redo:^{ value = 1; }];
    XCTAssertTrue(stack.canUndo);
    XCTAssertFalse(stack.canRedo);

    [stack undo];
    XCTAssertEqual(value, (NSInteger)0);
    XCTAssertFalse(stack.canUndo);
    XCTAssertTrue(stack.canRedo);

    [stack redo];
    XCTAssertEqual(value, (NSInteger)1);
    XCTAssertTrue(stack.canUndo);
    XCTAssertFalse(stack.canRedo);

    // 多個動作：後登記的先復原
    value = 2;
    [stack registerUndo:^{ value = 1; } redo:^{ value = 2; }];
    [stack undo];
    XCTAssertEqual(value, (NSInteger)1);
    [stack undo];
    XCTAssertEqual(value, (NSInteger)0);
    [stack redo];
    [stack redo];
    XCTAssertEqual(value, (NSInteger)2);
}

- (void)testRedoClearedOnNewAction {
    LBUndoStack *stack = [[LBUndoStack alloc] init];
    NSMutableArray<NSString *> *log = [NSMutableArray array];

    [stack registerUndo:^{ [log addObject:@"undo A"]; } redo:^{ [log addObject:@"redo A"]; }];
    [stack undo];
    XCTAssertTrue(stack.canRedo);

    [stack registerUndo:^{ [log addObject:@"undo B"]; } redo:^{ [log addObject:@"redo B"]; }];
    XCTAssertFalse(stack.canRedo, @"登記新動作後，舊的 redo 歷史要清掉");
    [stack redo];   // 什麼都不做
    XCTAssertEqualObjects(log, @[@"undo A"]);

    [stack removeAllActions];
    XCTAssertFalse(stack.canUndo);
    XCTAssertFalse(stack.canRedo);
}

- (void)testUndoRemovesTransaction {
    LBLedger *ledger = [[LBLedger alloc] init];
    LBUndoStack *stack = [[LBUndoStack alloc] init];
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:@"120"];
    LBTransaction *tx = [LBTransaction expenseWithAmount:amount note:@"午餐"];

    // 「新增」這個動作：復原 = 移除，重做 = 再加回去
    [ledger addTransaction:tx];
    [stack registerUndo:^{
        [ledger removeTransactionWithIdentifier:tx.identifier];
    } redo:^{
        [ledger addTransaction:tx];
    }];
    XCTAssertEqual(ledger.transactions.count, (NSUInteger)1);

    [stack undo];
    XCTAssertEqual(ledger.transactions.count, (NSUInteger)0);
    XCTAssertNil([ledger transactionWithIdentifier:tx.identifier]);

    [stack redo];
    XCTAssertEqual(ledger.transactions.count, (NSUInteger)1);
    XCTAssertEqualObjects(ledger.transactions.firstObject, tx);
}

@end
