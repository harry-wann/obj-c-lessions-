@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// 教學用雜湊表（鏈結法）。行為對齊 NSMutableDictionary：
/// key 會被 copy、以 hash / isEqual: 比對；初始 8 桶，負載因子超過 0.75 時擴成兩倍。
@interface LBHashMap<__covariant KeyType, __covariant ObjectType> : NSObject

@property (nonatomic, assign, readonly) NSUInteger count;
@property (nonatomic, assign, readonly) NSUInteger bucketCount;

- (void)setObject:(ObjectType)object forKey:(KeyType<NSCopying>)key;
- (nullable ObjectType)objectForKey:(KeyType)key;

/// 有找到並移除回 YES。
- (BOOL)removeObjectForKey:(KeyType)key;

@end

NS_ASSUME_NONNULL_END
