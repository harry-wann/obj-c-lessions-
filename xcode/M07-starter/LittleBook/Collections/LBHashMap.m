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
        _buckets = [self.class emptyBucketsWithCount:LBHashMapInitialBucketCount];
    }
    return self;
}

+ (NSMutableArray<id> *)emptyBucketsWithCount:(NSUInteger)count {
    NSMutableArray<id> *buckets = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        [buckets addObject:[NSNull null]];   // NSArray 不能放 nil，用 NSNull 代表空桶
    }
    return buckets;
}

- (NSUInteger)count {
    return _count;
}

- (NSUInteger)bucketCount {
    return _buckets.count;
}

#pragma mark - 內部工具

- (NSUInteger)indexForKey:(id)key bucketCount:(NSUInteger)bucketCount {
    return [key hash] % bucketCount;
}

- (nullable LBHashMapEntry *)headOfBucket:(NSUInteger)index {
    id slot = _buckets[index];
    return slot == [NSNull null] ? nil : slot;
}

- (void)setHead:(nullable LBHashMapEntry *)head ofBucket:(NSUInteger)index {
    _buckets[index] = (head != nil) ? (id)head : (id)[NSNull null];
}

#pragma mark - 存取

- (void)setObject:(id)object forKey:(id<NSCopying>)key {
    NSParameterAssert(object != nil);
    NSParameterAssert(key != nil);
    id plainKey = key;
    NSUInteger index = [self indexForKey:plainKey bucketCount:_buckets.count];

    // 已存在就覆寫
    for (LBHashMapEntry *entry = [self headOfBucket:index]; entry != nil; entry = entry.next) {
        if ([entry.key isEqual:plainKey]) {
            entry.object = object;
            return;
        }
    }

    // 不存在：新節點插在鏈頭（O(1)）
    LBHashMapEntry *entry = [[LBHashMapEntry alloc] init];
    entry.key = [key copyWithZone:nil];   // key 要 copy，呼叫端之後改可變字串也不影響
    entry.object = object;
    entry.next = [self headOfBucket:index];
    [self setHead:entry ofBucket:index];
    _count += 1;

    if ((double)_count / (double)_buckets.count > LBHashMapMaxLoadFactor) {
        [self resizeToBucketCount:_buckets.count * 2];
    }
}

- (id)objectForKey:(id)key {
    NSParameterAssert(key != nil);
    NSUInteger index = [self indexForKey:key bucketCount:_buckets.count];
    for (LBHashMapEntry *entry = [self headOfBucket:index]; entry != nil; entry = entry.next) {
        if ([entry.key isEqual:key]) {
            return entry.object;
        }
    }
    return nil;
}

- (BOOL)removeObjectForKey:(id)key {
    NSParameterAssert(key != nil);
    NSUInteger index = [self indexForKey:key bucketCount:_buckets.count];
    LBHashMapEntry *previous = nil;
    for (LBHashMapEntry *entry = [self headOfBucket:index]; entry != nil; entry = entry.next) {
        if ([entry.key isEqual:key]) {
            if (previous == nil) {
                [self setHead:entry.next ofBucket:index];
            } else {
                previous.next = entry.next;
            }
            _count -= 1;
            return YES;
        }
        previous = entry;
    }
    return NO;
}

#pragma mark - 擴容

- (void)resizeToBucketCount:(NSUInteger)newBucketCount {
    NSMutableArray<id> *newBuckets = [self.class emptyBucketsWithCount:newBucketCount];
    // 所有節點重新計算桶位（rehash），搬到新陣列。
    for (id slot in _buckets) {
        LBHashMapEntry *entry = (slot == [NSNull null]) ? nil : slot;
        while (entry != nil) {
            LBHashMapEntry *next = entry.next;
            NSUInteger index = [self indexForKey:entry.key bucketCount:newBucketCount];
            id head = newBuckets[index];
            entry.next = (head == [NSNull null]) ? nil : head;
            newBuckets[index] = entry;
            entry = next;
        }
    }
    _buckets = newBuckets;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p count=%lu buckets=%lu>",
            NSStringFromClass(self.class), self,
            (unsigned long)_count, (unsigned long)_buckets.count];
}

@end
