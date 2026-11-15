@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// 復原動作：沒有參數、沒有回傳值的 block。
typedef void (^LBUndoAction)(void);

/// 雙堆疊的復原 / 重做：每個動作用一對 block（怎麼復原、怎麼重做）封裝。
@interface LBUndoStack : NSObject

@property (nonatomic, assign, readonly) BOOL canUndo;
@property (nonatomic, assign, readonly) BOOL canRedo;

/// 登記一個已經做完的動作。登記新動作會清空 redo 堆疊。
- (void)registerUndo:(LBUndoAction)undo redo:(LBUndoAction)redo;

/// 沒有可復原的動作時什麼都不做。
- (void)undo;
- (void)redo;

- (void)removeAllActions;

@end

NS_ASSUME_NONNULL_END
