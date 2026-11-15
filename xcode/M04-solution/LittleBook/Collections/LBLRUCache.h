@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// LRU 快取：雙向鏈結串列（紀錄使用順序）＋ NSMutableDictionary（key → 節點）。
/// 最近用過的在最前面；超過容量時淘汰最後一個。
@interface LBLRUCache<__covariant KeyType, __covariant ObjectType> : NSObject

@property (nonatomic, assign, readonly) NSUInteger capacity;
@property (nonatomic, assign, readonly) NSUInteger count;

- (instancetype)initWithCapacity:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 命中時會把該項搬到最前面。
- (nullable ObjectType)objectForKey:(KeyType)key;

/// 新增或覆寫；超過容量時淘汰最久沒用的那一個。
- (void)setObject:(ObjectType)object forKey:(KeyType<NSCopying>)key;

- (void)removeObjectForKey:(KeyType)key;
- (void)removeAllObjects;

@end

NS_ASSUME_NONNULL_END
