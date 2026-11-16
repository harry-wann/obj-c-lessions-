@import Foundation;

// TODO: M12 — 12.1：這個標頭還沒標 nullability，Swift 端看到的全是 `!`（隱式解包）。
// 用 NS_ASSUME_NONNULL_BEGIN / END 包起來，再把真的會 nil 的成員（parent）標 nullable。

/// 分類樹的節點。parent 是 weak（子不持有父，避免循環參考），children 對外是不可變快照。
@interface LBCategory : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *symbolName;
@property (nonatomic, weak, readonly) LBCategory *parent;
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

/// 預設分類樹（M08）：飲食 / 交通 / 居住 / 娛樂 / 收入，各含子分類。
/// 回傳的是全程式共用的同一棵樹（dispatch_once），所以可以用 == 或 identifier 比對。
+ (NSArray<LBCategory *> *)defaultTree;

@end

