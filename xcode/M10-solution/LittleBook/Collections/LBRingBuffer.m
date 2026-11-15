#import "LBRingBuffer.h"

@implementation LBRingBuffer {
    double *_storage;   // malloc 的 C 陣列：ARC 不管，dealloc 要自己 free
    NSUInteger _head;   // 下一個要寫入的位置
    NSUInteger _count;
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
    NSParameterAssert(capacity > 0);
    if ((self = [super init])) {
        _capacity = MAX(capacity, (NSUInteger)1);
        _storage = calloc(_capacity, sizeof(double));
        if (_storage == NULL) {
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    free(_storage);
}

- (void)append:(double)value {
    _storage[_head] = value;
    _head = (_head + 1) % _capacity;   // 繞回開頭：滿了就覆蓋最舊的
    if (_count < _capacity) {
        _count += 1;
    }
}

/// 第 i 個（0 = 最舊）元素在 _storage 裡的位置。
- (NSUInteger)lb_storageIndexForElement:(NSUInteger)i {
    NSUInteger oldest = (_head + _capacity - _count) % _capacity;
    return (oldest + i) % _capacity;
}

- (double)average {
    if (_count == 0) {
        return 0;
    }
    double sum = 0;
    for (NSUInteger i = 0; i < _count; i++) {
        sum += _storage[[self lb_storageIndexForElement:i]];
    }
    return sum / (double)_count;
}

- (double)max {
    if (_count == 0) {
        return 0;
    }
    double result = -INFINITY;
    for (NSUInteger i = 0; i < _count; i++) {
        result = MAX(result, _storage[[self lb_storageIndexForElement:i]]);
    }
    return result;
}

- (NSUInteger)count {
    return _count;
}

- (NSArray<NSNumber *> *)values {
    NSMutableArray<NSNumber *> *values = [NSMutableArray arrayWithCapacity:_count];
    for (NSUInteger i = 0; i < _count; i++) {
        [values addObject:@(_storage[[self lb_storageIndexForElement:i]])];
    }
    return [values copy];
}

- (void)removeAllValues {
    _head = 0;
    _count = 0;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p %lu/%lu avg=%.2f max=%.2f>",
            NSStringFromClass(self.class), self, (unsigned long)_count,
            (unsigned long)_capacity, self.average, self.max];
}

@end
