@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// 雙向鏈結串列的節點。next 是 strong、prev 是 weak：
/// 若兩邊都 strong，相鄰節點會互相持有，整條串列永遠釋放不掉。
@interface LBLinkedListNode : NSObject

@property (nonatomic, strong, readonly) id object;
@property (nonatomic, strong, readonly, nullable) LBLinkedListNode *next;
@property (nonatomic, weak, readonly, nullable) LBLinkedListNode *prev;

@end

/// 雙向鏈結串列：頭尾插入與移除節點都是 O(1)。
@interface LBLinkedList<__covariant ObjectType> : NSObject

@property (nonatomic, strong, readonly, nullable) LBLinkedListNode *head;
@property (nonatomic, strong, readonly, nullable) LBLinkedListNode *tail;
@property (nonatomic, assign, readonly) NSUInteger count;

/// 加到尾端，回傳新節點（之後可用它 O(1) 移除）。
- (LBLinkedListNode *)appendObject:(ObjectType)object;

/// 移除節點；node 必須屬於這個串列。移除後 node 的 prev / next 都是 nil。
- (void)removeNode:(LBLinkedListNode *)node;

/// 從頭到尾列舉；*stop = YES 可提前結束。
- (void)enumerateObjectsUsingBlock:(void (^)(ObjectType object, NSUInteger idx, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
