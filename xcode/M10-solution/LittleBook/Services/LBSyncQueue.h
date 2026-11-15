@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// 離線待同步的 FIFO 佇列：任務一個接一個執行（前一個呼叫 done 之後，下一個才開始），
/// 內部用串列 dispatch queue 保護狀態，dispatch_group 等待全部完成。
@interface LBSyncQueue : NSObject

/// 尚未完成（含正在執行）的任務數。
@property (nonatomic, readonly) NSUInteger pendingCount;

/// 排入一個任務。任務可以是非同步的：做完時呼叫 done（只會生效一次）。
- (void)enqueueTask:(void (^)(dispatch_block_t done))task;

/// 等目前所有任務完成後，在主佇列呼叫 completion；佇列是空的就直接回呼。
- (void)flushWithCompletion:(dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
