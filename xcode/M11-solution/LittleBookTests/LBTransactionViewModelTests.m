#import <XCTest/XCTest.h>
#import "LBTransactionViewModel.h"
#import "LBTransaction.h"

@interface LBTransactionViewModelTests : XCTestCase
@end

@implementation LBTransactionViewModelTests

- (LBTransaction *)transactionWithNote:(NSString *)note {
    return [LBTransaction expenseWithAmount:[NSDecimalNumber decimalNumberWithString:@"1280"]
                                       note:note];
}

- (void)tearDown {
    [LBTransactionViewModel resetCache];
    [super tearDown];
}

- (void)testFormatsOnceAndCaches {
    [LBTransactionViewModel resetCache];
    XCTAssertEqual([LBTransactionViewModel formattingCount], (NSUInteger)0);

    LBTransaction *lunch = [self transactionWithNote:@"午餐"];
    LBTransactionViewModel *first = [LBTransactionViewModel viewModelWithTransaction:lunch];
    LBTransactionViewModel *second = [LBTransactionViewModel viewModelWithTransaction:lunch];
    XCTAssertEqual([LBTransactionViewModel formattingCount], (NSUInteger)1,
                   @"同一筆交易只格式化一次（捲回來不重算）");
    XCTAssertEqual(first, second, @"命中快取回同一個物件");
    XCTAssertEqualObjects(first.title, @"午餐");

    // copy 出來的是同一筆（不可變物件 copy 回自己），也要命中
    (void)[LBTransactionViewModel viewModelWithTransaction:[lunch copy]];
    XCTAssertEqual([LBTransactionViewModel formattingCount], (NSUInteger)1);

    // 另一筆：多一次
    LBTransactionViewModel *dinner =
        [LBTransactionViewModel viewModelWithTransaction:[self transactionWithNote:@"晚餐"]];
    XCTAssertEqualObjects(dinner.title, @"晚餐");
    XCTAssertEqual([LBTransactionViewModel formattingCount], (NSUInteger)2);

    // 直接 init 不經過快取：一定格式化
    (void)[[LBTransactionViewModel alloc] initWithTransaction:lunch];
    XCTAssertEqual([LBTransactionViewModel formattingCount], (NSUInteger)3);

    // 超過容量：最久沒用的（lunch）被淘汰，再要一次就要重算
    NSUInteger capacity = [LBTransactionViewModel cacheCapacity];
    XCTAssertGreaterThan(capacity, (NSUInteger)0);
    for (NSUInteger i = 0; i < capacity; i++) {
        (void)[LBTransactionViewModel viewModelWithTransaction:
               [self transactionWithNote:[NSString stringWithFormat:@"#%lu", (unsigned long)i]]];
    }
    NSUInteger before = [LBTransactionViewModel formattingCount];
    (void)[LBTransactionViewModel viewModelWithTransaction:lunch];
    XCTAssertEqual([LBTransactionViewModel formattingCount], before + 1, @"LRU 淘汰後要重算");

    // resetCache：清空並歸零
    [LBTransactionViewModel resetCache];
    XCTAssertEqual([LBTransactionViewModel formattingCount], (NSUInteger)0);
    (void)[LBTransactionViewModel viewModelWithTransaction:lunch];
    XCTAssertEqual([LBTransactionViewModel formattingCount], (NSUInteger)1);
}

@end
