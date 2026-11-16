#import "LBUndoStack.h"

/// 一個動作 = 一對 block。block 屬性要寫 copy（ARC 其實會自動 copy，但慣例要寫）。
@interface LBUndoEntry : NSObject
@property (nonatomic, copy) LBUndoAction undo;
@property (nonatomic, copy) LBUndoAction redo;
@end

@implementation LBUndoEntry
@end

@implementation LBUndoStack {
    NSMutableArray<LBUndoEntry *> *_undoStack;   // 最後一個元素是堆疊頂端
    NSMutableArray<LBUndoEntry *> *_redoStack;
}

- (instancetype)init {
    if ((self = [super init])) {
        _undoStack = [NSMutableArray array];
        _redoStack = [NSMutableArray array];
    }
    return self;
}

- (BOOL)canUndo {
    return _undoStack.count > 0;
}

- (BOOL)canRedo {
    return _redoStack.count > 0;
}

- (void)registerUndo:(LBUndoAction)undo redo:(LBUndoAction)redo {
    NSParameterAssert(undo != nil);
    NSParameterAssert(redo != nil);
    LBUndoEntry *entry = [[LBUndoEntry alloc] init];
    entry.undo = undo;
    entry.redo = redo;
    [_undoStack addObject:entry];
    [_redoStack removeAllObjects];   // 新動作之後，舊的 redo 歷史就沒有意義了
}

- (void)undo {
    LBUndoEntry *entry = _undoStack.lastObject;   // lastObject 在空陣列回 nil，不會越界
    if (entry == nil) {
        return;
    }
    [_undoStack removeLastObject];
    entry.undo();
    [_redoStack addObject:entry];
}

- (void)redo {
    LBUndoEntry *entry = _redoStack.lastObject;
    if (entry == nil) {
        return;
    }
    [_redoStack removeLastObject];
    entry.redo();
    [_undoStack addObject:entry];
}

- (void)removeAllActions {
    [_undoStack removeAllObjects];
    [_redoStack removeAllObjects];
}

@end
