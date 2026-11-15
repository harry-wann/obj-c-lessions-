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
    // TODO: M05
    return NO;
}

- (BOOL)canRedo {
    // TODO: M05
    return NO;
}

- (void)registerUndo:(LBUndoAction)undo redo:(LBUndoAction)redo {
    // TODO: M05 — 包成 LBUndoEntry 推入 _undoStack，並清空 _redoStack
}

- (void)undo {
    // TODO: M05 — 從 _undoStack 頂端取出、執行 undo block、推入 _redoStack
}

- (void)redo {
    // TODO: M05 — 從 _redoStack 頂端取出、執行 redo block、推回 _undoStack
}

- (void)removeAllActions {
    [_undoStack removeAllObjects];
    [_redoStack removeAllObjects];
}

@end
