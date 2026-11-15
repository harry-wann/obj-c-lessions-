#import "LBRingBuffer.h"

@implementation LBRingBuffer {
    // TODO: M10 — double *_storage（calloc，dealloc 時 free）、_head（下一個寫入位置）、_count
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
    NSParameterAssert(capacity > 0);
    if ((self = [super init])) {
        _capacity = capacity;
    }
    return self;
}

- (void)append:(double)value {
    // TODO: M10 — 寫到 _head，_head = (_head + 1) % capacity；_count 最多到 capacity
}

- (double)average {
    return 0;   // TODO: M10 — 空的回 0
}

- (double)max {
    return 0;   // TODO: M10 — 空的回 0
}

- (NSUInteger)count {
    return 0;   // TODO: M10
}

- (NSArray<NSNumber *> *)values {
    return @[];   // TODO: M10 — 由舊到新
}

- (void)removeAllValues {
    // TODO: M10
}

@end
