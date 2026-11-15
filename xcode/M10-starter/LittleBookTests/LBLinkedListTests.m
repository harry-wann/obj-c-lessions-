#import <XCTest/XCTest.h>
#import "LBLinkedList.h"

@interface LBLinkedListTests : XCTestCase
@end

@implementation LBLinkedListTests

- (void)testAppendAndCount {
    LBLinkedList<NSString *> *list = [[LBLinkedList alloc] init];
    XCTAssertEqual(list.count, (NSUInteger)0);
    XCTAssertNil(list.head);
    XCTAssertNil(list.tail);

    LBLinkedListNode *a = [list appendObject:@"a"];
    XCTAssertEqual(list.count, (NSUInteger)1);
    XCTAssertTrue(list.head == a && list.tail == a, @"只有一個節點時頭尾相同");

    LBLinkedListNode *b = [list appendObject:@"b"];
    LBLinkedListNode *c = [list appendObject:@"c"];
    XCTAssertEqual(list.count, (NSUInteger)3);
    XCTAssertTrue(list.head == a);
    XCTAssertTrue(list.tail == c);
    XCTAssertTrue(a.next == b && b.next == c);
    XCTAssertTrue(c.prev == b && b.prev == a);
    XCTAssertNil(a.prev);
    XCTAssertNil(c.next);
    XCTAssertEqualObjects(a.object, @"a");
    XCTAssertEqualObjects(c.object, @"c");
}

- (void)testRemoveNode {
    LBLinkedList<NSString *> *list = [[LBLinkedList alloc] init];
    LBLinkedListNode *a = [list appendObject:@"a"];
    LBLinkedListNode *b = [list appendObject:@"b"];
    LBLinkedListNode *c = [list appendObject:@"c"];

    [list removeNode:b];   // 移除中間
    XCTAssertEqual(list.count, (NSUInteger)2);
    XCTAssertTrue(a.next == c && c.prev == a);
    XCTAssertNil(b.next);
    XCTAssertNil(b.prev);

    [list removeNode:a];   // 移除頭
    XCTAssertTrue(list.head == c && list.tail == c);
    XCTAssertNil(c.prev);

    [list removeNode:c];   // 移除最後一個
    XCTAssertEqual(list.count, (NSUInteger)0);
    XCTAssertNil(list.head);
    XCTAssertNil(list.tail);

    // 清空後可以繼續用：移除 + 重新加到尾端（LRU 會用這招把節點搬到 tail）
    LBLinkedListNode *x = [list appendObject:@"x"];
    LBLinkedListNode *y = [list appendObject:@"y"];
    [list removeNode:x];
    LBLinkedListNode *x2 = [list appendObject:x.object];
    XCTAssertTrue(list.head == y && list.tail == x2);
    XCTAssertEqual(list.count, (NSUInteger)2);
}

- (void)testPrevIsWeak {
    __weak LBLinkedListNode *weakMiddle = nil;
    @autoreleasepool {
        LBLinkedList<NSString *> *list = [[LBLinkedList alloc] init];
        LBLinkedListNode *first = [list appendObject:@"a"];
        LBLinkedListNode *middle = [list appendObject:@"b"];
        [list appendObject:@"c"];
        XCTAssertTrue(middle.prev == first);
        weakMiddle = middle;
    }
    // 串列釋放後節點應一起釋放。若 prev 是 strong，相鄰節點互相持有就永遠釋放不掉。
    XCTAssertNil(weakMiddle, @"prev 應為 weak，否則節點之間形成循環參考");
}

- (void)testIteration {
    LBLinkedList<NSNumber *> *list = [[LBLinkedList alloc] init];
    for (NSInteger i = 1; i <= 5; i++) {
        [list appendObject:@(i)];
    }

    NSMutableArray<NSNumber *> *seen = [NSMutableArray array];
    NSMutableArray<NSNumber *> *indexes = [NSMutableArray array];
    [list enumerateObjectsUsingBlock:^(NSNumber *object, NSUInteger idx, BOOL *stop) {
        [seen addObject:object];
        [indexes addObject:@(idx)];
    }];
    NSArray<NSNumber *> *expected = @[@1, @2, @3, @4, @5];
    XCTAssertEqualObjects(seen, expected);
    XCTAssertEqualObjects(indexes, (@[@0, @1, @2, @3, @4]));   // 字面量有逗號：要再包一層括號

    // *stop 提前結束
    NSMutableArray<NSNumber *> *partial = [NSMutableArray array];
    [list enumerateObjectsUsingBlock:^(NSNumber *object, NSUInteger idx, BOOL *stop) {
        [partial addObject:object];
        if (idx == 1) {
            *stop = YES;
        }
    }];
    XCTAssertEqualObjects(partial, (@[@1, @2]));
}

@end
