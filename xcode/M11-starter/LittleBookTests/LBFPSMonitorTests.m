#import <XCTest/XCTest.h>
#import "LBFPSMonitor.h"
#import "LBRingBuffer.h"

@interface LBFPSMonitorTests : XCTestCase
@end

@implementation LBFPSMonitorTests

- (void)testClassifiesDroppedFrames {
    // 60 Hz 一幀 16.67 ms：之內算正常
    XCTAssertEqual([LBFPSMonitor classifyFrameDuration:0], (NSInteger)LBFrameClassNormal);
    XCTAssertEqual([LBFPSMonitor classifyFrameDuration:8.3], (NSInteger)LBFrameClassNormal);
    XCTAssertEqual([LBFPSMonitor classifyFrameDuration:16.67], (NSInteger)LBFrameClassNormal);
    XCTAssertEqual([LBFPSMonitor classifyFrameDuration:-1], (NSInteger)LBFrameClassNormal);
    // 超過一幀、不到兩幀：警告
    XCTAssertEqual([LBFPSMonitor classifyFrameDuration:16.7], (NSInteger)LBFrameClassWarning);
    XCTAssertEqual([LBFPSMonitor classifyFrameDuration:25], (NSInteger)LBFrameClassWarning);
    XCTAssertEqual([LBFPSMonitor classifyFrameDuration:32.9], (NSInteger)LBFrameClassWarning);
    // 兩幀以上：掉幀
    XCTAssertEqual([LBFPSMonitor classifyFrameDuration:33], (NSInteger)LBFrameClassDropped);
    XCTAssertEqual([LBFPSMonitor classifyFrameDuration:33.4], (NSInteger)LBFrameClassDropped);
    XCTAssertEqual([LBFPSMonitor classifyFrameDuration:250], (NSInteger)LBFrameClassDropped);

    // 監視器本身：單例、歷史容量 60、start / stop 成對
    LBFPSMonitor *monitor = [LBFPSMonitor shared];
    XCTAssertEqual(monitor, [LBFPSMonitor shared]);
    XCTAssertEqual(monitor.history.capacity, (NSUInteger)60);
    BOOL wasRunning = monitor.isRunning;
    [monitor start];
    XCTAssertTrue(monitor.isRunning);
    [monitor stop];
    XCTAssertFalse(monitor.isRunning);
    if (wasRunning) {
        [monitor start];   // 還原 App（DEBUG）原本的狀態
    }
}

@end
