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
    if ((self = [super init])) {
        _capacity = capacity;
        // TODO: M04 — 建立 _order 與 _nodesByKey
    }
    return self;
}

- (NSUInteger)count {
    // TODO: M04 — 就是串列的 count
    return 0;
}

- (id)objectForKey:(id)key {
    // TODO: M04 — 從字典找節點；命中就 moveNodeToFront: 再回傳 entry.object
    return nil;
}

- (void)setObject:(id)object forKey:(id<NSCopying>)key {
    // TODO: M04 — 已存在就覆寫並搬到最前；否則 prependObject: 並記進字典；
    // 超過 capacity 就把 tail 從串列與字典一起移除。
}

- (void)removeObjectForKey:(id)key {
    // TODO: M04
}

- (void)removeAllObjects {
    // TODO: M04
}

@end
