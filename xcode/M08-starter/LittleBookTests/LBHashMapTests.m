#import <XCTest/XCTest.h>
#import "LBHashMap.h"

/// 測試用自訂 key：覆寫 isEqual: / hash，讓內容相同的不同實體被視為同一個 key。
@interface LBTestPointKey : NSObject <NSCopying>
@property (nonatomic, assign, readonly) NSInteger x;
@property (nonatomic, assign, readonly) NSInteger y;
- (instancetype)initWithX:(NSInteger)x y:(NSInteger)y;
@end

@implementation LBTestPointKey

- (instancetype)initWithX:(NSInteger)x y:(NSInteger)y {
    if ((self = [super init])) {
        _x = x;
        _y = y;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[LBTestPointKey class]]) {
        return NO;
    }
    LBTestPointKey *other = object;
    return _x == other.x && _y == other.y;
}

- (NSUInteger)hash {
    return (NSUInteger)_x * 31 + (NSUInteger)_y;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;   // 不可變
}

@end

@interface LBHashMapTests : XCTestCase
@end

@implementation LBHashMapTests

- (void)testSetAndGet {
    LBHashMap<NSString *, NSNumber *> *map = [[LBHashMap alloc] init];
    XCTAssertEqual(map.count, (NSUInteger)0);
    XCTAssertNil([map objectForKey:@"missing"]);

    [map setObject:@85 forKey:@"早餐"];
    [map setObject:@32 forKey:@"捷運"];
    XCTAssertEqual(map.count, (NSUInteger)2);
    XCTAssertEqualObjects([map objectForKey:@"早餐"], @85);
    XCTAssertEqualObjects([map objectForKey:@"捷運"], @32);

    // key 會被 copy：之後改掉原本的可變字串，仍可用原內容查到
    NSMutableString *mutableKey = [NSMutableString stringWithString:@"咖啡"];
    [map setObject:@60 forKey:mutableKey];
    [mutableKey appendString:@"（改掉）"];
    XCTAssertEqualObjects([map objectForKey:@"咖啡"], @60);
    XCTAssertNil([map objectForKey:mutableKey]);
}

- (void)testOverwrite {
    LBHashMap<NSString *, NSNumber *> *map = [[LBHashMap alloc] init];
    [map setObject:@1 forKey:@"k"];
    [map setObject:@2 forKey:@"k"];
    XCTAssertEqual(map.count, (NSUInteger)1, @"覆寫不會增加 count");
    XCTAssertEqualObjects([map objectForKey:@"k"], @2);
}

- (void)testRemove {
    LBHashMap<NSString *, NSNumber *> *map = [[LBHashMap alloc] init];
    for (NSInteger i = 0; i < 5; i++) {
        [map setObject:@(i) forKey:[NSString stringWithFormat:@"k%ld", (long)i]];
    }
    XCTAssertTrue([map removeObjectForKey:@"k2"]);
    XCTAssertFalse([map removeObjectForKey:@"k2"]);
    XCTAssertFalse([map removeObjectForKey:@"nope"]);
    XCTAssertEqual(map.count, (NSUInteger)4);
    XCTAssertNil([map objectForKey:@"k2"]);
    XCTAssertEqualObjects([map objectForKey:@"k3"], @3);

    // 把剩下的也刪光
    for (NSString *key in @[@"k0", @"k1", @"k3", @"k4"]) {
        XCTAssertTrue([map removeObjectForKey:key]);
    }
    XCTAssertEqual(map.count, (NSUInteger)0);
}

- (void)testGrowsBeyondInitialBuckets {
    LBHashMap<NSString *, NSNumber *> *map = [[LBHashMap alloc] init];
    XCTAssertEqual(map.bucketCount, (NSUInteger)8);

    for (NSInteger i = 0; i < 6; i++) {
        [map setObject:@(i) forKey:[NSString stringWithFormat:@"k%ld", (long)i]];
    }
    XCTAssertEqual(map.bucketCount, (NSUInteger)8, @"6 / 8 = 0.75 還不用擴容");

    [map setObject:@6 forKey:@"k6"];
    XCTAssertEqual(map.bucketCount, (NSUInteger)16, @"7 / 8 > 0.75 擴成兩倍");

    for (NSInteger i = 7; i < 100; i++) {
        [map setObject:@(i) forKey:[NSString stringWithFormat:@"k%ld", (long)i]];
    }
    XCTAssertEqual(map.count, (NSUInteger)100);
    XCTAssertGreaterThanOrEqual(map.bucketCount, (NSUInteger)128);
    for (NSInteger i = 0; i < 100; i++) {
        NSString *key = [NSString stringWithFormat:@"k%ld", (long)i];
        XCTAssertEqualObjects([map objectForKey:key], @(i), @"擴容後所有值仍要找得到");
    }
}

- (void)testCustomKeyUsesHashAndIsEqual {
    LBHashMap<LBTestPointKey *, NSString *> *map = [[LBHashMap alloc] init];
    LBTestPointKey *first = [[LBTestPointKey alloc] initWithX:1 y:2];
    LBTestPointKey *same = [[LBTestPointKey alloc] initWithX:1 y:2];
    LBTestPointKey *other = [[LBTestPointKey alloc] initWithX:2 y:1];

    [map setObject:@"A" forKey:first];
    XCTAssertEqualObjects([map objectForKey:same], @"A", @"不同實體、內容相同，要用 isEqual: 找到");
    XCTAssertNil([map objectForKey:other]);

    [map setObject:@"B" forKey:same];
    XCTAssertEqual(map.count, (NSUInteger)1, @"相等的 key 視為同一個，覆寫而非新增");
    XCTAssertEqualObjects([map objectForKey:first], @"B");
    XCTAssertTrue([map removeObjectForKey:same]);
    XCTAssertNil([map objectForKey:first]);
}

@end
