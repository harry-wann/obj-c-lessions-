#import "LBLRUCache.h"
#import "LBLinkedList.h"

/// 串列節點裡存的東西：同時記 key，淘汰時才知道要從字典刪哪個。
@interface LBLRUCacheEntry : NSObject
@property (nonatomic, strong) id key;
@property (nonatomic, strong) id object;
@end

@implementation LBLRUCacheEntry
@end

@implementation LBLRUCache {
    LBLinkedList<LBLRUCacheEntry *> *_order;                     // 頭 = 最近用過
    NSMutableDictionary<id, LBLinkedListNode *> *_nodesByKey;    // key → 節點
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
    NSParameterAssert(capacity > 0);
    if ((self = [super init])) {
        _capacity = capacity;
        _order = [[LBLinkedList alloc] init];
        _nodesByKey = [NSMutableDictionary dictionaryWithCapacity:capacity];
    }
    return self;
}

- (NSUInteger)count {
    return _order.count;
}

- (id)objectForKey:(id)key {
    NSParameterAssert(key != nil);
    LBLinkedListNode *node = _nodesByKey[key];
    if (node == nil) {
        return nil;
    }
    [_order moveNodeToFront:node];   // 剛用過 → 搬到最前面
    LBLRUCacheEntry *entry = node.object;
    return entry.object;
}

- (void)setObject:(id)object forKey:(id<NSCopying>)key {
    NSParameterAssert(object != nil);
    NSParameterAssert(key != nil);
    LBLinkedListNode *existing = _nodesByKey[key];
    if (existing != nil) {
        LBLRUCacheEntry *entry = existing.object;
        entry.object = object;
        [_order moveNodeToFront:existing];
        return;
    }

    LBLRUCacheEntry *entry = [[LBLRUCacheEntry alloc] init];
    entry.key = [key copyWithZone:nil];
    entry.object = object;
    LBLinkedListNode *node = [_order prependObject:entry];
    _nodesByKey[entry.key] = node;

    if (_order.count > _capacity) {
        [self evictLeastRecentlyUsed];
    }
}

- (void)evictLeastRecentlyUsed {
    LBLinkedListNode *tail = _order.tail;
    if (tail == nil) {
        return;
    }
    LBLRUCacheEntry *victim = tail.object;
    [_nodesByKey removeObjectForKey:victim.key];
    [_order removeNode:tail];
}

- (void)removeObjectForKey:(id)key {
    NSParameterAssert(key != nil);
    LBLinkedListNode *node = _nodesByKey[key];
    if (node == nil) {
        return;
    }
    [_nodesByKey removeObjectForKey:key];
    [_order removeNode:node];
}

- (void)removeAllObjects {
    [_nodesByKey removeAllObjects];
    _order = [[LBLinkedList alloc] init];
}

@end
