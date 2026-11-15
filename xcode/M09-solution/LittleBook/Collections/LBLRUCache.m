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
    LBLinkedList<LBLRUCacheEntry *> *_order;                     // head = 最久沒用，tail = 最近用過
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
    LBLRUCacheEntry *entry = node.object;
    [self touchEntry:entry node:node];   // 剛用過 → 搬到 tail
    return entry.object;
}

- (void)setObject:(id)object forKey:(id<NSCopying>)key {
    NSParameterAssert(object != nil);
    NSParameterAssert(key != nil);
    LBLinkedListNode *existing = _nodesByKey[key];
    if (existing != nil) {
        LBLRUCacheEntry *entry = existing.object;
        entry.object = object;
        [self touchEntry:entry node:existing];
        return;
    }

    LBLRUCacheEntry *entry = [[LBLRUCacheEntry alloc] init];
    entry.key = [key copyWithZone:nil];
    entry.object = object;
    _nodesByKey[entry.key] = [_order appendObject:entry];

    if (_order.count > _capacity) {
        [self evictLeastRecentlyUsed];
    }
}

/// 把節點移到 tail：先 removeNode: 再 appendObject:，字典改指向新節點。都是 O(1)。
- (void)touchEntry:(LBLRUCacheEntry *)entry node:(LBLinkedListNode *)node {
    if (node == _order.tail) {
        return;
    }
    [_order removeNode:node];
    _nodesByKey[entry.key] = [_order appendObject:entry];
}

- (void)evictLeastRecentlyUsed {
    LBLinkedListNode *head = _order.head;   // head 是最久沒用的
    if (head == nil) {
        return;
    }
    LBLRUCacheEntry *victim = head.object;
    [_nodesByKey removeObjectForKey:victim.key];
    [_order removeNode:head];
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
