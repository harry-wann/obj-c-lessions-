@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// 定時輪詢服務（模擬「每隔一段時間抓一次匯率」）。
@interface LBPollingService : NSObject

@property (nonatomic, assign, readonly) NSUInteger tickCount;
@property (nonatomic, assign, readonly, getter=isRunning) BOOL running;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
