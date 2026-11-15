#pragma once
#import <Foundation/Foundation.h>
_Pragma("clang assume_nonnull begin")
@interface XCTestExpectation : NSObject
- (void)fulfill;
@property (getter=isInverted) BOOL inverted;
@end
@interface XCTKVOExpectation : XCTestExpectation
- (instancetype)initWithKeyPath:(NSString *)k object:(id)o expectedValue:(nullable id)v;
@end
@interface XCTestCase : NSObject
- (void)setUp;
- (void)tearDown;
- (XCTestExpectation *)expectationWithDescription:(NSString *)d;
- (XCTestExpectation *)expectationForNotification:(NSNotificationName)n object:(nullable id)o
                                          handler:(nullable BOOL (^)(NSNotification *n))h;
- (void)waitForExpectations:(NSArray<XCTestExpectation *> *)e timeout:(NSTimeInterval)t;
- (void)waitForExpectationsWithTimeout:(NSTimeInterval)t handler:(nullable id)h;
@end
_Pragma("clang assume_nonnull end")
// 斷言：型別檢查用（實作只是把參數算一次）
void _XCTFail(const char *f, ...);
#define _XCT_MSG(...) _XCTFail("", ##__VA_ARGS__)
#define XCTAssertTrue(e, ...) do { BOOL _v = !!(e); (void)_v; _XCT_MSG(__VA_ARGS__); } while (0)
#define XCTAssertFalse(e, ...) XCTAssertTrue(!(e), ##__VA_ARGS__)
#define XCTAssertNil(e, ...) do { id _v = (e); (void)_v; _XCT_MSG(__VA_ARGS__); } while (0)
#define XCTAssertNotNil(e, ...) XCTAssertNil(e, ##__VA_ARGS__)
#define XCTAssertEqualObjects(a, b, ...) do { id _a = (a); id _b = (b); (void)_a; (void)_b; \
    _XCT_MSG(__VA_ARGS__); } while (0)
#define XCTAssertNotEqualObjects(a, b, ...) XCTAssertEqualObjects(a, b, ##__VA_ARGS__)
#define XCTAssertEqual(a, b, ...) do { __typeof__(a) _a = (a); __typeof__(b) _b = (b); \
    (void)(_a == _b); _XCT_MSG(__VA_ARGS__); } while (0)
#define XCTAssertNotEqual(a, b, ...) XCTAssertEqual(a, b, ##__VA_ARGS__)
#define XCTAssertGreaterThan(a, b, ...) do { __typeof__(a) _a = (a); __typeof__(b) _b = (b); \
    (void)(_a > _b); _XCT_MSG(__VA_ARGS__); } while (0)
#define XCTAssertGreaterThanOrEqual XCTAssertGreaterThan
#define XCTAssertLessThan XCTAssertGreaterThan
#define XCTAssertLessThanOrEqual XCTAssertGreaterThan
#define XCTAssertEqualWithAccuracy(a, b, acc, ...) do { double _a = (a); double _b = (b); \
    double _c = (acc); (void)(_a - _b < _c); _XCT_MSG(__VA_ARGS__); } while (0)
#define XCTAssertNoThrow(e, ...) do { (e); _XCT_MSG(__VA_ARGS__); } while (0)
#define XCTFail(...) _XCT_MSG(__VA_ARGS__)
