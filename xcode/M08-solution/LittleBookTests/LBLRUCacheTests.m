#import <XCTest/XCTest.h>
#import "LBLRUCache.h"

@interface LBLRUCacheTests : XCTestCase
@end

@implementation LBLRUCacheTests

- (void)testEvictsLeastRecentlyUsed {
    LBLRUCache<NSString *, NSString *> *cache = [[LBLRUCache alloc] initWithCapacity:2];
    [cache setObject:@"1" forKey:@"a"];
    [cache setObject:@"2" forKey:@"b"];
    [cache setObject:@"3" forKey:@"c"];   // 超過容量，最久沒用的 a 被淘汰

    XCTAssertNil([cache objectForKey:@"a"]);
    XCTAssertEqualObjects([cache objectForKey:@"b"], @"2");
    XCTAssertEqualObjects([cache objectForKey:@"c"], @"3");
    XCTAssertEqual(cache.count, (NSUInteger)2);
}

- (void)testGetMovesToFront {
    LBLRUCache<NSString *, NSString *> *cache = [[LBLRUCache alloc] initWithCapacity:2];
    [cache setObject:@"1" forKey:@"a"];
    [cache setObject:@"2" forKey:@"b"];
    XCTAssertEqualObjects([cache objectForKey:@"a"], @"1");   // 讀 a → a 變最近用過
    [cache setObject:@"3" forKey:@"c"];                       // 這次淘汰的是 b

    XCTAssertEqualObjects([cache objectForKey:@"a"], @"1");
    XCTAssertNil([cache objectForKey:@"b"]);
    XCTAssertEqualObjects([cache objectForKey:@"c"], @"3");

    // 覆寫既有 key 也算「用過」
    [cache setObject:@"1x" forKey:@"a"];
    [cache setObject:@"4" forKey:@"d"];                       // 淘汰 c
    XCTAssertEqualObjects([cache objectForKey:@"a"], @"1x");
    XCTAssertNil([cache objectForKey:@"c"]);
}

- (void)testCapacity {
    LBLRUCache<NSString *, NSNumber *> *cache = [[LBLRUCache alloc] initWithCapacity:3];
    XCTAssertEqual(cache.capacity, (NSUInteger)3);
    XCTAssertEqual(cache.count, (NSUInteger)0);

    for (NSInteger i = 0; i < 10; i++) {
        [cache setObject:@(i) forKey:[NSString stringWithFormat:@"k%ld", (long)i]];
        XCTAssertLessThanOrEqual(cache.count, (NSUInteger)3);
    }
    XCTAssertEqual(cache.count, (NSUInteger)3);
    XCTAssertNil([cache objectForKey:@"k0"]);
    XCTAssertEqualObjects([cache objectForKey:@"k9"], @9);

    [cache setObject:@99 forKey:@"k9"];   // 覆寫不增加 count
    XCTAssertEqual(cache.count, (NSUInteger)3);

    [cache removeObjectForKey:@"k9"];
    XCTAssertEqual(cache.count, (NSUInteger)2);
    [cache removeAllObjects];
    XCTAssertEqual(cache.count, (NSUInteger)0);
}

@end
