#import "LBFrameHistoryView.h"
#import "LBFPSMonitor.h"

static const double LBFrameBudgetMilliseconds = 16.7;

@implementation LBFrameHistoryView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _values = @[];
        _maximumMilliseconds = 50;
        _slotCount = 60;
        // 不透明背景：少一層圖層混合（10.2 Color Blended Layers）
        self.opaque = YES;
        self.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)setValues:(NSArray<NSNumber *> *)values {
    _values = [values copy];
    [self setNeedsDisplay];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, 96);
}

+ (UIColor *)lb_colorForMilliseconds:(double)milliseconds {
    switch ([LBFPSMonitor classifyFrameDuration:milliseconds]) {
        case LBFrameClassNormal:
            return UIColor.systemGreenColor;
        case LBFrameClassWarning:
            return UIColor.systemOrangeColor;
        default:
            return UIColor.systemRedColor;
    }
}

- (void)drawRect:(CGRect)rect {
    CGRect bounds = self.bounds;
    if (bounds.size.width <= 0 || bounds.size.height <= 0 || _maximumMilliseconds <= 0) {
        return;
    }
    NSUInteger slots = MAX(_slotCount, (NSUInteger)1);
    CGFloat slotWidth = bounds.size.width / (CGFloat)slots;
    CGFloat barWidth = MAX(slotWidth - 1, 1);
    CGFloat height = bounds.size.height;

    // 最新的貼右邊：不足 slotCount 根時左邊留白
    NSUInteger count = MIN(_values.count, slots);
    NSUInteger offset = slots - count;
    NSUInteger first = _values.count - count;
    for (NSUInteger i = 0; i < count; i++) {
        double ms = _values[first + i].doubleValue;
        CGFloat ratio = (CGFloat)MIN(MAX(ms / _maximumMilliseconds, 0.0), 1.0);
        CGFloat barHeight = MAX(ratio * height, 1);
        CGRect bar = CGRectMake((CGFloat)(offset + i) * slotWidth, height - barHeight,
                                barWidth, barHeight);
        [[LBFrameHistoryView lb_colorForMilliseconds:ms] setFill];
        UIRectFill(bar);
    }

    // 16.7 ms 預算線
    CGFloat budgetY = height - (CGFloat)(LBFrameBudgetMilliseconds / _maximumMilliseconds) * height;
    UIBezierPath *line = [UIBezierPath bezierPath];
    [line moveToPoint:CGPointMake(0, budgetY)];
    [line addLineToPoint:CGPointMake(bounds.size.width, budgetY)];
    CGFloat dashes[] = {4, 4};
    [line setLineDash:dashes count:2 phase:0];
    line.lineWidth = 1;
    [UIColor.secondaryLabelColor setStroke];
    [line stroke];
}

@end
