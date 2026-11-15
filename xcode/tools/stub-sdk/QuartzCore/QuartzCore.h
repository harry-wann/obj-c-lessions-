#pragma once
#import <Foundation/Foundation.h>
_Pragma("clang assume_nonnull begin")
typedef double CFTimeInterval;
CFTimeInterval CACurrentMediaTime(void);
typedef NSString *CALayerCornerCurve;
extern CALayerCornerCurve const kCACornerCurveContinuous;
@interface CALayer : NSObject
@property CGFloat cornerRadius;
@property (copy) CALayerCornerCurve cornerCurve;
@property BOOL masksToBounds;
@end
@interface CADisplayLink : NSObject
+ (CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)sel;
- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode;
- (void)invalidate;
@property (readonly) CFTimeInterval timestamp;
@property (readonly) CFTimeInterval duration;
@end
_Pragma("clang assume_nonnull end")
