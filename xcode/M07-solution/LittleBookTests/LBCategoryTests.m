#import <XCTest/XCTest.h>
#import "LBCategory.h"

@interface LBCategoryTests : XCTestCase
@end

@implementation LBCategoryTests

- (LBCategory *)category:(NSString *)name {
    return [[LBCategory alloc] initWithName:name symbolName:@"tag"];
}

- (void)testDepth {
    LBCategory *root = [self category:@"生活"];
    LBCategory *food = [self category:@"飲食"];
    LBCategory *breakfast = [self category:@"早餐"];
    [root addChild:food];
    [food addChild:breakfast];

    XCTAssertEqual(root.depth, (NSUInteger)0);
    XCTAssertEqual(food.depth, (NSUInteger)1);
    XCTAssertEqual(breakfast.depth, (NSUInteger)2);
    XCTAssertTrue(breakfast.parent == food);
    XCTAssertEqual(root.children.count, (NSUInteger)1);

    // children 對外是快照，不是內部的可變陣列
    XCTAssertFalse([root.children isKindOfClass:[NSMutableArray class]]);
    [root addChild:food];   // 重複加入會被忽略
    XCTAssertEqual(root.children.count, (NSUInteger)1);
    XCTAssertNotNil(root.identifier);
    XCTAssertEqualObjects(root.name, @"生活");
    XCTAssertEqualObjects(root.symbolName, @"tag");
}

- (void)testParentIsWeak {
    LBCategory *child = [self category:@"早餐"];
    __weak LBCategory *weakParent = nil;
    @autoreleasepool {
        LBCategory *parent = [self category:@"飲食"];
        [parent addChild:child];
        weakParent = parent;
        XCTAssertNotNil(child.parent);
        XCTAssertEqual(child.depth, (NSUInteger)1);
    }
    // 沒有人持有 parent 之後它應該被釋放；若 parent 是 strong，父子互相持有就不會
    XCTAssertNil(weakParent, @"parent 應為 weak，否則父子形成循環參考");
    XCTAssertNil(child.parent, @"weak 參考會自動歸零");
    XCTAssertEqual(child.depth, (NSUInteger)0);
}

- (void)testFlattened {
    LBCategory *root = [self category:@"生活"];
    LBCategory *food = [self category:@"飲食"];
    LBCategory *breakfast = [self category:@"早餐"];
    LBCategory *dinner = [self category:@"晚餐"];
    LBCategory *transport = [self category:@"交通"];
    [root addChild:food];
    [food addChild:breakfast];
    [food addChild:dinner];
    [root addChild:transport];

    NSArray<LBCategory *> *flat = [root flattened];
    NSArray<LBCategory *> *expected = @[root, food, breakfast, dinner, transport];
    XCTAssertEqualObjects(flat, expected, @"深度優先、含自己");

    NSArray<LBCategory *> *leaf = [breakfast flattened];
    XCTAssertEqualObjects(leaf, @[breakfast]);
}

@end
