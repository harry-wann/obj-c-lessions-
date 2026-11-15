#import "LBReportBuilder.h"

@implementation LBReportBuilder

- (void)build {
    NSString *report = [NSString stringWithFormat:@"小帳本報表 %@", [NSDate date]];
    // 先取到 strong 區域變數再呼叫，避免多執行緒下中途變 nil
    id<LBReportBuilderDelegate> delegate = self.delegate;
    [delegate reportBuilder:self didBuildReport:report];   // 對 nil 送訊息是安全的
}

@end
