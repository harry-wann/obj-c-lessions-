#import "LBLinkedList.h"

// 類別延伸：讓串列可以改節點的連結，對外仍是 readonly。
@interface LBLinkedListNode ()
@property (nonatomic, strong, readwrite) id object;
@property (nonatomic, strong, readwrite, nullable) LBLinkedListNode *next;
@property (nonatomic, weak, readwrite, nullable) LBLinkedListNode *prev;
- (instancetype)initWithObject:(id)object;
@end

@implementation LBLinkedListNode

- (instancetype)initWithObject:(id)object {
    if ((self = [super init])) {
        _object = object;
    }
    return self;
}

@end

@implementation LBLinkedList

- (LBLinkedListNode *)appendObject:(id)object {
    // TODO: M04 — 建節點、接在 _tail 後面（空串列時 head = tail = node）、count + 1
    return nil;
}

- (void)removeNode:(LBLinkedListNode *)node {
    // TODO: M04 — 把 prev.next 接到 next、next.prev 接到 prev；處理頭尾；count - 1
}

- (void)enumerateObjectsUsingBlock:(void (^)(id object, NSUInteger idx, BOOL *stop))block {
    // TODO: M04 — 從 _head 沿 next 走，*stop 為 YES 就停
}

@end
