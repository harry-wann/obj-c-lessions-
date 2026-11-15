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

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p object=%@>",
            NSStringFromClass(self.class), self, _object];
}

@end

@implementation LBLinkedList

#pragma mark - 新增

- (LBLinkedListNode *)appendObject:(id)object {
    NSParameterAssert(object != nil);
    LBLinkedListNode *node = [[LBLinkedListNode alloc] initWithObject:object];
    if (_tail == nil) {
        _head = node;           // 空串列：頭尾都是它
        _tail = node;
    } else {
        node.prev = _tail;      // weak：不會多一個強參考
        _tail.next = node;      // strong：串列真正「持有」節點的路徑
        _tail = node;
    }
    _count += 1;
    return node;
}

#pragma mark - 移除

- (void)removeNode:(LBLinkedListNode *)node {
    NSParameterAssert(node != nil);
    LBLinkedListNode *previous = node.prev;
    LBLinkedListNode *next = node.next;

    if (previous != nil) {
        previous.next = next;
    } else {
        _head = next;        // 移除的是頭
    }
    if (next != nil) {
        next.prev = previous;
    } else {
        _tail = previous;    // 移除的是尾
    }
    node.prev = nil;
    node.next = nil;
    _count -= 1;
}

#pragma mark - 列舉

- (void)enumerateObjectsUsingBlock:(void (^)(id object, NSUInteger idx, BOOL *stop))block {
    NSParameterAssert(block != nil);
    BOOL stop = NO;
    NSUInteger idx = 0;
    for (LBLinkedListNode *node = _head; node != nil && !stop; node = node.next) {
        block(node.object, idx, &stop);
        idx += 1;
    }
}

- (NSString *)description {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (LBLinkedListNode *node = _head; node != nil; node = node.next) {
        [parts addObject:[node.object description]];
    }
    return [NSString stringWithFormat:@"<%@: %p [%@]>", NSStringFromClass(self.class), self,
            [parts componentsJoinedByString:@" ⇄ "]];
}

@end
