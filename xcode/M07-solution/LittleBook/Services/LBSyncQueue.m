#import "LBSyncQueue.h"

typedef void (^LBSyncTaskBlock)(dispatch_block_t done);

@implementation LBSyncQueue {
    dispatch_queue_t _queue;                      // 串列：保護 _tasks / _running，任務也在上面啟動
    dispatch_group_t _group;                      // 每個任務 enter 一次、done 時 leave 一次
    NSMutableArray<LBSyncTaskBlock> *_tasks;      // 等待中的任務，index 0 最早
    BOOL _running;                                // 是否有任務正在執行（只在 _queue 上讀寫）
    NSUInteger _pending;                          // 用 @synchronized 保護，讓 getter 不必進佇列
}

- (instancetype)init {
    if ((self = [super init])) {
        _queue = dispatch_queue_create("com.littlebook.syncqueue", DISPATCH_QUEUE_SERIAL);
        _group = dispatch_group_create();
        _tasks = [NSMutableArray array];
    }
    return self;
}

- (NSUInteger)pendingCount {
    @synchronized (self) {
        return _pending;
    }
}

- (void)enqueueTask:(void (^)(dispatch_block_t))task {
    NSParameterAssert(task != nil);
    dispatch_group_enter(_group);
    @synchronized (self) {
        _pending += 1;
    }
    dispatch_async(_queue, ^{
        [self->_tasks addObject:task];
        [self lb_startNextIfIdle];
    });
}

/// 只能在 _queue 上呼叫：若沒有任務在跑，就取出最早的一個開始執行。
- (void)lb_startNextIfIdle {
    if (_running || _tasks.count == 0) {
        return;
    }
    LBSyncTaskBlock task = _tasks.firstObject;
    [_tasks removeObjectAtIndex:0];
    _running = YES;

    // done 刻意強持有 self：任務還沒結束前佇列不該消失，否則 group 的 enter / leave 會失衡。
    __block BOOL finished = NO;
    dispatch_block_t done = ^{
        dispatch_async(self->_queue, ^{
            if (finished) {
                return;   // 任務不小心呼叫兩次 done：忽略第二次
            }
            finished = YES;
            self->_running = NO;
            @synchronized (self) {
                self->_pending -= 1;
            }
            dispatch_group_leave(self->_group);
            [self lb_startNextIfIdle];
        });
    };
    task(done);
}

- (void)flushWithCompletion:(dispatch_block_t)completion {
    NSParameterAssert(completion != nil);
    // group 清空時在主佇列回呼；若現在就是空的，notify 會立刻排進主佇列。
    dispatch_group_notify(_group, dispatch_get_main_queue(), completion);
}

@end
