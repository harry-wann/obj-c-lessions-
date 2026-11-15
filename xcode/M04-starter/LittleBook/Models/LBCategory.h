@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// 分類樹的節點。parent 是 weak（子不持有父，避免循環參考），children 對外是不可變快照。
@interface LBCategory : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *symbolName;
@property (nonatomic, weak, readonly, nullable) LBCategory *parent;
@property (nonatomic, copy, readonly) NSArray<LBCategory *> *children;

- (instancetype)initWithName:(NSString *)name
                  symbolName:(NSString *)symbolName NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 加入子分類並把 child.parent 設為自己；重複加入同一個 child 會被忽略。
- (void)addChild:(LBCategory *)child;

/// 根節點為 0，往下每層 +1。
- (NSUInteger)depth;

/// 深度優先攤平，包含自己（自己是第一個元素）。
- (NSArray<LBCategory *> *)flattened;

@end

NS_ASSUME_NONNULL_END
