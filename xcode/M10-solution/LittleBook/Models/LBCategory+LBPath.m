#import "LBCategory+LBPath.h"

static NSString * const LBCategoryPathSeparator = @"/";

@implementation LBCategory (LBPath)

- (NSString *)lb_path {
    // 往上走到根，再反過來接起來：樹的「尋找路徑」
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (LBCategory *node = self; node != nil; node = node.parent) {
        [names insertObject:node.name atIndex:0];
    }
    return [names componentsJoinedByString:LBCategoryPathSeparator];
}

+ (LBCategory *)lb_categoryWithPath:(NSString *)path {
    NSParameterAssert(path != nil);
    NSArray<NSString *> *names = [path componentsSeparatedByString:LBCategoryPathSeparator];
    NSArray<LBCategory *> *level = [LBCategory defaultTree];
    LBCategory *found = nil;
    for (NSString *name in names) {
        found = nil;
        for (LBCategory *candidate in level) {
            if ([candidate.name isEqualToString:name]) {
                found = candidate;
                break;
            }
        }
        if (found == nil) {
            return nil;
        }
        level = found.children;
    }
    return found;
}

@end
