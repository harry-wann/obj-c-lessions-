#import "LBHashMap.h"

static const NSUInteger LBHashMapInitialBucketCount = 8;
static const double LBHashMapMaxLoadFactor = 0.75;

/// 桶裡的一個節點：同一桶的節點用 next 串成鏈。
@interface LBHashMapEntry : NSObject
@property (nonatomic, strong) id key;
@property (nonatomic, strong) id object;
@property (nonatomic, strong, nullable) LBHashMapEntry *next;
@end

@implementation LBHashMapEntry
@end

@implementation LBHashMap {
    NSMutableArray<id> *_buckets;   // 每格是 LBHashMapEntry（鏈頭）或 NSNull（空桶）
    NSUInteger _count;
}

- (instancetype)init {
    if ((self = [super init])) {
        // TODO: M03 — 建立 LBHashMapInitialBucketCount 個空桶（用 NSNull 佔位）
        _buckets = [NSMutableArray array];
    }
    return self;
}

- (NSUInteger)count {
    return _count;
}

- (NSUInteger)bucketCount {
    return _buckets.count;
}

- (void)setObject:(id)object forKey:(id<NSCopying>)key {
    // TODO: M03 — [key hash] % bucketCount 找桶；已存在就覆寫，否則插在鏈頭並 copy key；
    // 負載因子 count / bucketCount 超過 LBHashMapMaxLoadFactor 就擴成兩倍並 rehash。
    (void)LBHashMapMaxLoadFactor;
    (void)LBHashMapInitialBucketCount;
}

- (id)objectForKey:(id)key {
    // TODO: M03 — 找桶、沿鏈用 isEqual: 比對
    return nil;
}

- (BOOL)removeObjectForKey:(id)key {
    // TODO: M03 — 沿鏈找到後把前一個節點的 next 接到下一個
    return NO;
}

@end
