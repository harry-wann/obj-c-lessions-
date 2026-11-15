#import "LBSyncQueue.h"

typedef void (^LBSyncTaskBlock)(dispatch_block_t done);

@implementation LBSyncQueue {
    dispatch_queue_t _queue;                      // 串列：保護 _tasks / _running
    dispatch_group_t _group;                      // 每個任務 enter 一次、done 時 leave 一次
    NSMutableArray<LBSyncTaskBlock> *_tasks;      // 等待中的任務，index 0 最早
    BOOL _running;
    NSUInteger _pending;
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
    // TODO: M07 — dispatch_group_enter、_pending += 1，再 dispatch_async 到 _queue：
    //            把 task 加進 _tasks 並呼叫 lb_startNextIfIdle
}

/// 只能在 _queue 上呼叫。
- (void)lb_startNextIfIdle {
    // TODO: M07 — 若 _running 或沒有任務就返回；否則取出第一個任務、_running = YES，
    //            做一個 done block（切回 _queue：_running = NO、_pending -= 1、
    //            dispatch_group_leave、再呼叫自己啟動下一個；done 被呼叫兩次要忽略），然後 task(done)
}

- (void)flushWithCompletion:(dispatch_block_t)completion {
    NSParameterAssert(completion != nil);
    // TODO: M07 — dispatch_group_notify(_group, dispatch_get_main_queue(), completion)
}

@end
