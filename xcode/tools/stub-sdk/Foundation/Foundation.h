#pragma once
// 語法檢查用的極簡 Foundation 替身（只宣告專案用到的部分）
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

typedef long NSInteger;
typedef unsigned long NSUInteger;
typedef bool BOOL;
#define YES ((BOOL)1)
#define NO ((BOOL)0)
#define nil ((void *)0)
#define Nil ((void *)0)
#ifndef NULL
#define NULL ((void *)0)
#endif
typedef double NSTimeInterval;
typedef double CGFloat;
typedef struct { CGFloat x, y; } CGPoint;
typedef struct { CGFloat width, height; } CGSize;
typedef struct { CGPoint origin; CGSize size; } CGRect;
CGRect CGRectMake(CGFloat x, CGFloat y, CGFloat w, CGFloat h);
CGPoint CGPointMake(CGFloat x, CGFloat y);
CGSize CGSizeMake(CGFloat w, CGFloat h);
CGFloat CGRectGetMaxY(CGRect r);
CGFloat CGRectGetMinY(CGRect r);
extern const CGRect CGRectZero;
typedef struct { NSUInteger location, length; } NSRange;
NSRange NSMakeRange(NSUInteger loc, NSUInteger len);
enum { NSNotFound = 0x7fffffffffffffffL };
typedef struct { unsigned long state; id __unsafe_unretained *itemsPtr; unsigned long *mutationsPtr;
    unsigned long extra[5]; } NSFastEnumerationState;

double floor(double); double fabs(double); int isfinite_impl(double);
#define isfinite(x) isfinite_impl(x)
#define INFINITY (__builtin_inf())
void *calloc(size_t, size_t); void *malloc(size_t); void free(void *);
long labs(long);
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))

#define NS_ASSUME_NONNULL_BEGIN _Pragma("clang assume_nonnull begin")
#define NS_ASSUME_NONNULL_END _Pragma("clang assume_nonnull end")
#define NS_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
#define NS_UNAVAILABLE __attribute__((unavailable))
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NS_OPTIONS(_type, _name) enum _name : _type _name; enum _name : _type
#define NS_ERROR_ENUM(_domain, _name) enum _name : NSInteger _name; enum _name : NSInteger
#define NS_SWIFT_NAME(x)
#define NS_NOESCAPE __attribute__((noescape))
#define NSParameterAssert(c) do { (void)(c); } while (0)
#define NSAssert(c, desc, ...) do { (void)(c); (void)(desc); } while (0)
#define NSLog(fmt, ...) NSLogImpl(fmt, ##__VA_ARGS__)

typedef enum NSComparisonResult : NSInteger { NSOrderedAscending = -1, NSOrderedSame, NSOrderedDescending } NSComparisonResult;
typedef NSComparisonResult (^NSComparator)(id obj1, id obj2);
typedef void (^dispatch_block_t)(void);

_Pragma("clang assume_nonnull begin")

@class NSString, NSError, NSURL, NSData, NSDate, NSLocale, NSCoder,
    NSRunLoop, NSNumber, NSCharacterSet, NSNotification;
@class NSArray<ObjectType>, NSDictionary<KeyType, ObjectType>, NSSet<ObjectType>;
typedef struct _NSZone NSZone;

void NSLogImpl(NSString *format, ...);
NSString *NSStringFromClass(Class c);
NSString *NSStringFromSelector(SEL s);
Class _Nullable NSClassFromString(NSString *s);

@protocol NSObject
- (BOOL)isEqual:(nullable id)object;
@property (readonly) NSUInteger hash;
- (BOOL)isKindOfClass:(Class)c;
- (BOOL)respondsToSelector:(SEL)s;
@property (readonly, copy) NSString *description;
@end
@protocol NSCopying
- (id)copyWithZone:(nullable NSZone *)zone;
@end
@protocol NSMutableCopying
- (id)mutableCopyWithZone:(nullable NSZone *)zone;
@end
@protocol NSCoding
- (void)encodeWithCoder:(NSCoder *)coder;
- (nullable instancetype)initWithCoder:(NSCoder *)coder;
@end
@protocol NSSecureCoding <NSCoding>
@property (class, readonly) BOOL supportsSecureCoding;
@end
@protocol NSFastEnumeration
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer
                                    count:(NSUInteger)len;
@end

__attribute__((objc_root_class))
@interface NSObject <NSObject>
+ (instancetype)alloc;
+ (instancetype)new;
- (instancetype)init;
- (id)copy;
- (id)mutableCopy;
+ (Class)class;
- (Class)class;
+ (BOOL)isSubclassOfClass:(Class)c;
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object
                        change:(nullable NSDictionary *)change context:(nullable void *)context;
- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSUInteger)options
            context:(nullable void *)context;
- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
               context:(nullable void *)context;
- (void)performSelector:(SEL)s withObject:(nullable id)o afterDelay:(NSTimeInterval)d;
@end
typedef NSString *NSKeyValueChangeKey;
extern NSKeyValueChangeKey const NSKeyValueChangeNewKey;
enum { NSKeyValueObservingOptionNew = 1 };

@interface NSProxy <NSObject>
@end

@interface NSString : NSObject <NSCopying, NSMutableCopying, NSSecureCoding>
@property (readonly) NSUInteger length;
+ (instancetype)stringWithFormat:(NSString *)format, ...;
- (instancetype)initWithFormat:(NSString *)format, ...;
+ (nullable instancetype)stringWithContentsOfURL:(NSURL *)url encoding:(NSUInteger)enc
                                           error:(NSError **)error;
- (nullable instancetype)initWithData:(NSData *)data encoding:(NSUInteger)encoding;
- (BOOL)isEqualToString:(NSString *)s;
- (BOOL)hasPrefix:(NSString *)s;
- (BOOL)hasSuffix:(NSString *)s;
- (BOOL)containsString:(NSString *)s;
- (NSString *)substringToIndex:(NSUInteger)i;
- (NSString *)substringWithRange:(NSRange)r;
- (NSString *)stringByAppendingString:(NSString *)s;
- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)a withString:(NSString *)b;
- (NSString *)stringByTrimmingCharactersInSet:(NSCharacterSet *)set;
- (NSArray<NSString *> *)componentsSeparatedByString:(NSString *)s;
- (NSRange)rangeOfString:(NSString *)s options:(NSUInteger)options;
- (nullable NSData *)dataUsingEncoding:(NSUInteger)encoding;
- (void)enumerateLinesUsingBlock:(void (^)(NSString *line, BOOL *stop))block;
+ (nullable instancetype)stringWithContentsOfFile:(NSString *)path encoding:(NSUInteger)enc
                                            error:(NSError **)error;
@property (readonly, copy) NSString *pathExtension;
@property (readonly, copy) NSString *lastPathComponent;
@property (readonly, copy) NSString *stringByDeletingLastPathComponent;
- (NSString *)stringByAppendingPathComponent:(NSString *)s;
@property (readonly) double doubleValue;
@property (readonly) NSInteger integerValue;
@end
enum { NSUTF8StringEncoding = 4 };
enum { NSCaseInsensitiveSearch = 1, NSDiacriticInsensitiveSearch = 128, NSWidthInsensitiveSearch = 256 };
typedef NSUInteger NSStringCompareOptions;

@interface NSMutableString : NSString
+ (instancetype)string;
+ (instancetype)stringWithCapacity:(NSUInteger)c;
+ (instancetype)stringWithString:(NSString *)s;
- (void)appendString:(NSString *)s;
- (void)appendFormat:(NSString *)format, ...;
@end

@interface NSCharacterSet : NSObject
@property (class, readonly, copy) NSCharacterSet *whitespaceCharacterSet;
@property (class, readonly, copy) NSCharacterSet *whitespaceAndNewlineCharacterSet;
@end

@interface NSValue : NSObject <NSCopying>
@property (readonly) CGRect CGRectValue;
@end

@interface NSNumber : NSValue
+ (NSNumber *)numberWithInt:(int)v;
+ (NSNumber *)numberWithUnsignedInt:(unsigned int)v;
+ (NSNumber *)numberWithLong:(long)v;
+ (NSNumber *)numberWithUnsignedLong:(unsigned long)v;
+ (NSNumber *)numberWithLongLong:(long long)v;
+ (NSNumber *)numberWithUnsignedLongLong:(unsigned long long)v;
+ (NSNumber *)numberWithInteger:(NSInteger)v;
+ (NSNumber *)numberWithUnsignedInteger:(NSUInteger)v;
+ (NSNumber *)numberWithDouble:(double)v;
+ (NSNumber *)numberWithFloat:(float)v;
+ (NSNumber *)numberWithBool:(BOOL)v;
+ (NSNumber *)numberWithChar:(char)v;
@property (readonly) double doubleValue;
@property (readonly) NSInteger integerValue;
@property (readonly) NSUInteger unsignedIntegerValue;
@property (readonly) long long longLongValue;
@property (readonly) unsigned long long unsignedLongLongValue;
@property (readonly) BOOL boolValue;
@property (readonly, copy) NSString *stringValue;
- (NSComparisonResult)compare:(NSNumber *)other;
@end

typedef struct { int _exponent; unsigned int _length; unsigned short _mantissa[8]; } NSDecimal;
BOOL NSDecimalIsNotANumber(const NSDecimal *d);
typedef enum NSRoundingMode : NSUInteger { NSRoundPlain, NSRoundDown, NSRoundUp, NSRoundBankers } NSRoundingMode;
@protocol NSDecimalNumberBehaviors
@end
@interface NSDecimalNumberHandler : NSObject <NSDecimalNumberBehaviors>
+ (instancetype)decimalNumberHandlerWithRoundingMode:(NSRoundingMode)m scale:(short)s
    raiseOnExactness:(BOOL)a raiseOnOverflow:(BOOL)b raiseOnUnderflow:(BOOL)c
    raiseOnDivideByZero:(BOOL)d;
@end
@interface NSDecimalNumber : NSNumber
+ (NSDecimalNumber *)decimalNumberWithString:(nullable NSString *)s;
+ (NSDecimalNumber *)decimalNumberWithString:(nullable NSString *)s locale:(nullable id)locale;
+ (NSDecimalNumber *)decimalNumberWithMantissa:(unsigned long long)m exponent:(short)e
                                    isNegative:(BOOL)n;
@property (class, readonly, copy) NSDecimalNumber *zero;
@property (class, readonly, copy) NSDecimalNumber *one;
@property (readonly) NSDecimal decimalValue;
- (NSDecimalNumber *)decimalNumberByAdding:(NSDecimalNumber *)n;
- (NSDecimalNumber *)decimalNumberBySubtracting:(NSDecimalNumber *)n;
- (NSDecimalNumber *)decimalNumberByMultiplyingBy:(NSDecimalNumber *)n;
- (NSDecimalNumber *)decimalNumberByMultiplyingByPowerOf10:(short)p;
- (NSDecimalNumber *)decimalNumberByRoundingAccordingToBehavior:(nullable id<NSDecimalNumberBehaviors>)b;
@end

@interface NSArray<__covariant ObjectType> : NSObject <NSCopying, NSMutableCopying, NSFastEnumeration, NSSecureCoding>
+ (instancetype)array;
+ (instancetype)arrayWithObject:(ObjectType)o;
+ (instancetype)arrayWithObjects:(const ObjectType _Nonnull [_Nullable])objects count:(NSUInteger)cnt;
@property (readonly) NSUInteger count;
@property (nullable, readonly) ObjectType firstObject;
@property (nullable, readonly) ObjectType lastObject;
- (ObjectType)objectAtIndex:(NSUInteger)i;
- (ObjectType)objectAtIndexedSubscript:(NSUInteger)i;
- (BOOL)containsObject:(ObjectType)o;
- (NSUInteger)indexOfObject:(ObjectType)o;
- (NSUInteger)indexOfObjectIdenticalTo:(ObjectType)o;
- (NSUInteger)indexOfObject:(ObjectType)o inSortedRange:(NSRange)r options:(NSUInteger)opts
            usingComparator:(NSComparator)cmp;
- (NSArray<ObjectType> *)subarrayWithRange:(NSRange)r;
- (NSString *)componentsJoinedByString:(NSString *)s;
- (NSArray<ObjectType> *)sortedArrayWithOptions:(NSUInteger)opts usingComparator:(NSComparator)cmp;
- (NSArray<ObjectType> *)arrayByAddingObject:(ObjectType)o;
@end
enum { NSSortStable = 16, NSBinarySearchingFirstEqual = 256, NSBinarySearchingLastEqual = 512,
       NSBinarySearchingInsertionIndex = 1024 };

@interface NSMutableArray<ObjectType> : NSArray<ObjectType>
+ (instancetype)arrayWithCapacity:(NSUInteger)c;
- (void)addObject:(ObjectType)o;
- (void)addObjectsFromArray:(NSArray<ObjectType> *)a;
- (void)insertObject:(ObjectType)o atIndex:(NSUInteger)i;
- (void)removeObject:(ObjectType)o;
- (void)removeObjectIdenticalTo:(ObjectType)o;
- (void)removeObjectAtIndex:(NSUInteger)i;
- (void)removeLastObject;
- (void)removeAllObjects;
- (void)setObject:(ObjectType)o atIndexedSubscript:(NSUInteger)i;
@end

@interface NSDictionary<__covariant KeyType, __covariant ObjectType> : NSObject <NSCopying, NSMutableCopying, NSFastEnumeration, NSSecureCoding>
+ (instancetype)dictionary;
+ (instancetype)dictionaryWithObjects:(const ObjectType _Nonnull [_Nullable])objects
                              forKeys:(const KeyType <NSCopying> _Nonnull [_Nullable])keys
                                count:(NSUInteger)cnt;
@property (readonly) NSUInteger count;
@property (readonly, copy) NSArray<KeyType> *allKeys;
- (nullable ObjectType)objectForKey:(KeyType)k;
- (nullable ObjectType)objectForKeyedSubscript:(KeyType)k;
+ (nullable NSDictionary<KeyType, ObjectType> *)dictionaryWithContentsOfURL:(NSURL *)url;
@end
@interface NSMutableDictionary<KeyType, ObjectType> : NSDictionary<KeyType, ObjectType>
+ (instancetype)dictionaryWithCapacity:(NSUInteger)c;
- (void)setObject:(ObjectType)o forKey:(KeyType <NSCopying>)k;
- (void)setObject:(nullable ObjectType)o forKeyedSubscript:(KeyType <NSCopying>)k;
- (void)removeObjectForKey:(KeyType)k;
- (void)removeAllObjects;
- (void)addEntriesFromDictionary:(NSDictionary<KeyType, ObjectType> *)d;
@end

@interface NSSet<__covariant ObjectType> : NSObject <NSCopying, NSFastEnumeration>
+ (instancetype)set;
+ (instancetype)setWithArray:(NSArray<ObjectType> *)a;
+ (instancetype)setWithObjects:(ObjectType)first, ... __attribute__((sentinel));
- (BOOL)containsObject:(ObjectType)o;
@property (readonly) NSUInteger count;
@end
@interface NSMutableSet<ObjectType> : NSSet<ObjectType>
- (void)addObject:(ObjectType)o;
- (void)removeObject:(ObjectType)o;
@end

@interface NSNull : NSObject <NSCopying>
+ (NSNull *)null;
@end

@interface NSData : NSObject <NSCopying>
+ (instancetype)data;
+ (nullable instancetype)dataWithContentsOfURL:(NSURL *)url;
+ (nullable instancetype)dataWithContentsOfURL:(NSURL *)url options:(NSUInteger)o error:(NSError **)e;
- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)a;
- (BOOL)writeToURL:(NSURL *)url options:(NSUInteger)o error:(NSError **)e;
@property (readonly) NSUInteger length;
@end
enum { NSDataWritingAtomic = 1, NSDataReadingMappedIfSafe = 1 };

@interface NSDate : NSObject <NSCopying, NSSecureCoding>
+ (instancetype)date;
+ (instancetype)dateWithTimeIntervalSince1970:(NSTimeInterval)t;
@property (readonly) NSTimeInterval timeIntervalSince1970;
- (NSComparisonResult)compare:(NSDate *)other;
- (BOOL)isEqualToDate:(NSDate *)other;
@end

@interface NSUUID : NSObject <NSCopying, NSSecureCoding>
+ (instancetype)UUID;
- (nullable instancetype)initWithUUIDString:(NSString *)s;
@property (readonly, copy) NSString *UUIDString;
@end

typedef NSString *NSErrorDomain;
typedef NSString *NSErrorUserInfoKey;
extern NSErrorUserInfoKey const NSLocalizedDescriptionKey;
extern NSErrorUserInfoKey const NSUnderlyingErrorKey;
@interface NSError : NSObject <NSCopying>
+ (instancetype)errorWithDomain:(NSErrorDomain)d code:(NSInteger)c
                       userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)u;
@property (readonly, copy) NSErrorDomain domain;
@property (readonly) NSInteger code;
@property (readonly, copy) NSDictionary<NSErrorUserInfoKey, id> *userInfo;
@property (readonly, copy) NSString *localizedDescription;
@end

@interface NSURL : NSObject <NSCopying, NSSecureCoding>
+ (nullable instancetype)URLWithString:(NSString *)s;
+ (NSURL *)fileURLWithPath:(NSString *)p isDirectory:(BOOL)d;
- (NSURL *)URLByAppendingPathComponent:(NSString *)c;
- (NSURL *)URLByAppendingPathComponent:(NSString *)c isDirectory:(BOOL)d;
@property (nullable, readonly, copy) NSURL *URLByDeletingLastPathComponent;
@property (nullable, readonly, copy) NSString *path;
@property (nullable, readonly, copy) NSString *lastPathComponent;
@property (readonly, getter=isFileURL) BOOL fileURL;
@end
NSString *NSTemporaryDirectory(void);

@interface NSURLQueryItem : NSObject
+ (instancetype)queryItemWithName:(NSString *)n value:(nullable NSString *)v;
@end
@interface NSURLComponents : NSObject
+ (nullable instancetype)componentsWithURL:(NSURL *)u resolvingAgainstBaseURL:(BOOL)r;
@property (nullable, copy) NSArray<NSURLQueryItem *> *queryItems;
@property (nullable, readonly, copy) NSURL *URL;
@end

enum { NSApplicationSupportDirectory = 14, NSUserDomainMask = 1 };
@interface NSEnumerator<ObjectType> : NSObject <NSFastEnumeration>
- (nullable ObjectType)nextObject;
@end
@interface NSDirectoryEnumerator<ObjectType> : NSEnumerator<ObjectType>
@end
@interface NSFileManager : NSObject
@property (class, readonly, strong) NSFileManager *defaultManager;
- (NSArray<NSURL *> *)URLsForDirectory:(NSUInteger)d inDomains:(NSUInteger)m;
- (BOOL)fileExistsAtPath:(NSString *)p;
- (BOOL)createDirectoryAtURL:(NSURL *)u withIntermediateDirectories:(BOOL)c
                  attributes:(nullable NSDictionary *)a error:(NSError **)e;
- (BOOL)removeItemAtURL:(NSURL *)u error:(NSError **)e;
- (BOOL)moveItemAtURL:(NSURL *)a toURL:(NSURL *)b error:(NSError **)e;
- (nullable NSArray<NSString *> *)contentsOfDirectoryAtPath:(NSString *)p error:(NSError **)e;
- (BOOL)fileExistsAtPath:(NSString *)p isDirectory:(nullable BOOL *)d;
- (nullable NSDirectoryEnumerator<NSString *> *)enumeratorAtPath:(NSString *)p;
@end

@interface NSJSONSerialization : NSObject
+ (nullable id)JSONObjectWithData:(NSData *)d options:(NSUInteger)o error:(NSError **)e;
+ (nullable NSData *)dataWithJSONObject:(id)o options:(NSUInteger)opt error:(NSError **)e;
+ (BOOL)isValidJSONObject:(id)o;
@end

typedef NSString *NSNotificationName;
@interface NSNotification : NSObject
@property (readonly, copy) NSNotificationName name;
@property (nullable, readonly, retain) id object;
@property (nullable, readonly, copy) NSDictionary *userInfo;
@end
@class NSOperationQueue;
@interface NSNotificationCenter : NSObject
@property (class, readonly, strong) NSNotificationCenter *defaultCenter;
- (void)addObserver:(id)o selector:(SEL)s name:(nullable NSNotificationName)n object:(nullable id)obj;
- (id<NSObject>)addObserverForName:(nullable NSNotificationName)n object:(nullable id)obj
                             queue:(nullable NSOperationQueue *)q
                        usingBlock:(void (^)(NSNotification *note))block;
- (void)postNotificationName:(NSNotificationName)n object:(nullable id)o;
- (void)postNotificationName:(NSNotificationName)n object:(nullable id)o
                    userInfo:(nullable NSDictionary *)u;
- (void)removeObserver:(id)o;
- (void)removeObserver:(id)o name:(nullable NSNotificationName)n object:(nullable id)obj;
@end

@interface NSUserDefaults : NSObject
@property (class, readonly, strong) NSUserDefaults *standardUserDefaults;
- (nullable instancetype)initWithSuiteName:(nullable NSString *)s;
- (void)registerDefaults:(NSDictionary<NSString *, id> *)d;
- (nullable NSString *)stringForKey:(NSString *)k;
- (BOOL)boolForKey:(NSString *)k;
- (NSInteger)integerForKey:(NSString *)k;
- (void)setObject:(nullable id)o forKey:(NSString *)k;
- (void)setBool:(BOOL)b forKey:(NSString *)k;
- (void)setInteger:(NSInteger)i forKey:(NSString *)k;
- (void)removePersistentDomainForName:(NSString *)n;
- (nullable NSDictionary<NSString *, id> *)persistentDomainForName:(NSString *)n;
@end

@interface NSProgress : NSObject
+ (NSProgress *)discreteProgressWithTotalUnitCount:(int64_t)c;
+ (NSProgress *)progressWithTotalUnitCount:(int64_t)c;
@property int64_t totalUnitCount;
@property int64_t completedUnitCount;
@property (getter=isCancellable) BOOL cancellable;
@property (readonly, getter=isCancelled) BOOL cancelled;
- (void)cancel;
@end

@interface NSOperation : NSObject
@property (readonly, getter=isCancelled) BOOL cancelled;
- (void)cancel;
@end
@interface NSBlockOperation : NSOperation
- (void)addExecutionBlock:(void (^)(void))block;
@end
typedef enum NSQualityOfService : NSInteger { NSQualityOfServiceUserInteractive = 0x21,
    NSQualityOfServiceUserInitiated = 0x19, NSQualityOfServiceUtility = 0x11 } NSQualityOfService;
@interface NSOperationQueue : NSObject
@property (nullable, copy) NSString *name;
@property NSInteger maxConcurrentOperationCount;
@property NSQualityOfService qualityOfService;
- (void)addOperation:(NSOperation *)op;
- (void)cancelAllOperations;
@end

@interface NSThread : NSObject
@property (class, readonly) BOOL isMainThread;
+ (void)sleepForTimeInterval:(NSTimeInterval)t;
@end
@interface NSProcessInfo : NSObject
@property (class, readonly, strong) NSProcessInfo *processInfo;
@property (readonly) NSTimeInterval systemUptime;
@end
@protocol NSLocking
- (void)lock;
- (void)unlock;
@end
@interface NSLock : NSObject <NSLocking>
@end
@interface NSScanner : NSObject
+ (instancetype)scannerWithString:(NSString *)s;
- (BOOL)scanDouble:(nullable double *)r;
@property (readonly, getter=isAtEnd) BOOL atEnd;
@end
@interface NSLocale : NSObject
+ (instancetype)localeWithLocaleIdentifier:(NSString *)i;
@property (class, readonly, copy) NSLocale *currentLocale;
@end
typedef NSString *NSCalendarIdentifier;
extern NSCalendarIdentifier const NSCalendarIdentifierGregorian;
enum { NSCalendarUnitYear = 4, NSCalendarUnitMonth = 8, NSCalendarUnitDay = 16 };
typedef NSUInteger NSCalendarUnit;
@interface NSDateComponents : NSObject
@property NSInteger year, month, day, hour;
@end
@interface NSCalendar : NSObject
+ (nullable NSCalendar *)calendarWithIdentifier:(NSCalendarIdentifier)i;
- (NSDateComponents *)components:(NSCalendarUnit)u fromDate:(NSDate *)d;
- (nullable NSDate *)dateFromComponents:(NSDateComponents *)c;
@end
@interface NSFormatter : NSObject
@end
@interface NSDateFormatter : NSFormatter
@property (null_resettable, copy) NSLocale *locale;
- (void)setLocalizedDateFormatFromTemplate:(NSString *)t;
- (NSString *)stringFromDate:(NSDate *)d;
@end
enum { NSNumberFormatterDecimalStyle = 1 };
@interface NSNumberFormatter : NSFormatter
@property NSUInteger numberStyle;
- (nullable NSString *)stringFromNumber:(NSNumber *)n;
@end

@interface NSIndexPath : NSObject <NSCopying>
@end
@interface NSIndexSet : NSObject <NSCopying>
+ (instancetype)indexSetWithIndex:(NSUInteger)i;
@end

@interface NSCoder : NSObject
- (void)encodeObject:(nullable id)o forKey:(NSString *)k;
- (void)encodeInteger:(NSInteger)i forKey:(NSString *)k;
- (nullable id)decodeObjectOfClass:(Class)c forKey:(NSString *)k;
- (NSInteger)decodeIntegerForKey:(NSString *)k;
- (void)failWithError:(NSError *)e;
@end
@interface NSKeyedArchiver : NSCoder
+ (nullable NSData *)archivedDataWithRootObject:(id)o requiringSecureCoding:(BOOL)r
                                          error:(NSError **)e;
@end
@interface NSKeyedUnarchiver : NSCoder
+ (nullable id)unarchivedObjectOfClass:(Class)c fromData:(NSData *)d error:(NSError **)e;
+ (nullable id)unarchivedObjectOfClasses:(NSSet<Class> *)c fromData:(NSData *)d error:(NSError **)e;
@end

@interface NSBundle : NSObject
@property (class, readonly, strong) NSBundle *mainBundle;
+ (NSBundle *)bundleForClass:(Class)c;
- (nullable NSURL *)URLForResource:(nullable NSString *)name withExtension:(nullable NSString *)ext;
@end

typedef NSString *NSRunLoopMode;
extern NSRunLoopMode const NSRunLoopCommonModes;
extern NSRunLoopMode const NSDefaultRunLoopMode;
@interface NSRunLoop : NSObject
@property (class, readonly, strong) NSRunLoop *mainRunLoop;
@end
@interface NSTimer : NSObject
+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)i repeats:(BOOL)r
                                      block:(void (^)(NSTimer *timer))block;
- (void)invalidate;
@end

// URL loading
@interface NSURLResponse : NSObject
@end
@interface NSHTTPURLResponse : NSURLResponse
- (nullable instancetype)initWithURL:(NSURL *)u statusCode:(NSInteger)s
                         HTTPVersion:(nullable NSString *)v
                        headerFields:(nullable NSDictionary<NSString *, NSString *> *)h;
@property (readonly) NSInteger statusCode;
@end
@interface NSURLRequest : NSObject
@property (nullable, readonly, copy) NSURL *URL;
@end
@interface NSURLSessionTask : NSObject
- (void)resume;
- (void)cancel;
@end
@interface NSURLSessionDataTask : NSURLSessionTask
@end
@interface NSURLSessionConfiguration : NSObject
@property (class, readonly, strong) NSURLSessionConfiguration *ephemeralSessionConfiguration;
@property (nullable, copy) NSArray<Class> *protocolClasses;
@end
@interface NSURLSession : NSObject
@property (class, readonly, strong) NSURLSession *sharedSession;
+ (NSURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)c;
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)u
    completionHandler:(void (^)(NSData *_Nullable d, NSURLResponse *_Nullable r,
                                NSError *_Nullable e))h;
@end
typedef enum NSURLCacheStoragePolicy : NSUInteger { NSURLCacheStorageAllowed,
    NSURLCacheStorageAllowedInMemoryOnly, NSURLCacheStorageNotAllowed } NSURLCacheStoragePolicy;
@class NSURLProtocol;
@protocol NSURLProtocolClient <NSObject>
- (void)URLProtocol:(NSURLProtocol *)p didReceiveResponse:(NSURLResponse *)r
 cacheStoragePolicy:(NSURLCacheStoragePolicy)policy;
- (void)URLProtocol:(NSURLProtocol *)p didLoadData:(NSData *)d;
- (void)URLProtocolDidFinishLoading:(NSURLProtocol *)p;
@end
@interface NSURLProtocol : NSObject
@property (readonly, copy) NSURLRequest *request;
@property (nullable, readonly, retain) id<NSURLProtocolClient> client;
+ (BOOL)canInitWithRequest:(NSURLRequest *)r;
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)r;
- (void)startLoading;
- (void)stopLoading;
@end

// CoreFoundation 布林
typedef const struct __CFBoolean *CFBooleanRef;
extern const CFBooleanRef kCFBooleanTrue;
extern const CFBooleanRef kCFBooleanFalse;
typedef double CFAbsoluteTime;

// libdispatch
typedef NSObject *dispatch_queue_t;
typedef NSObject *dispatch_group_t;
typedef NSObject *dispatch_semaphore_t;
typedef NSObject *dispatch_queue_attr_t;
typedef uint64_t dispatch_time_t;
typedef long dispatch_once_t;
#define DISPATCH_TIME_NOW (0ull)
#define DISPATCH_TIME_FOREVER (~0ull)
#define DISPATCH_QUEUE_SERIAL ((dispatch_queue_attr_t _Nullable)0)
extern dispatch_queue_attr_t _dispatch_queue_attr_concurrent;
#define DISPATCH_QUEUE_CONCURRENT _dispatch_queue_attr_concurrent
#define NSEC_PER_SEC 1000000000ull
#define NSEC_PER_MSEC 1000000ull
enum { QOS_CLASS_USER_INTERACTIVE = 0x21, QOS_CLASS_USER_INITIATED = 0x19, QOS_CLASS_DEFAULT = 0x15,
       QOS_CLASS_UTILITY = 0x11, QOS_CLASS_BACKGROUND = 0x09 };
dispatch_queue_t dispatch_queue_create(const char *_Nullable label, dispatch_queue_attr_t _Nullable attr);
dispatch_queue_t dispatch_get_main_queue(void);
dispatch_queue_t dispatch_get_global_queue(long identifier, unsigned long flags);
void dispatch_async(dispatch_queue_t q, dispatch_block_t b);
void dispatch_sync(dispatch_queue_t q, NS_NOESCAPE dispatch_block_t b);
void dispatch_barrier_async(dispatch_queue_t q, dispatch_block_t b);
void dispatch_barrier_sync(dispatch_queue_t q, NS_NOESCAPE dispatch_block_t b);
void dispatch_after(dispatch_time_t when, dispatch_queue_t q, dispatch_block_t b);
void dispatch_apply(size_t iterations, dispatch_queue_t _Nullable q, NS_NOESCAPE void (^block)(size_t));
dispatch_time_t dispatch_time(dispatch_time_t when, int64_t delta);
void dispatch_once(dispatch_once_t *predicate, NS_NOESCAPE dispatch_block_t block);
dispatch_group_t dispatch_group_create(void);
void dispatch_group_enter(dispatch_group_t g);
void dispatch_group_leave(dispatch_group_t g);
void dispatch_group_notify(dispatch_group_t g, dispatch_queue_t q, dispatch_block_t b);
dispatch_semaphore_t dispatch_semaphore_create(intptr_t value);
intptr_t dispatch_semaphore_wait(dispatch_semaphore_t s, dispatch_time_t t);
intptr_t dispatch_semaphore_signal(dispatch_semaphore_t s);

_Pragma("clang assume_nonnull end")
