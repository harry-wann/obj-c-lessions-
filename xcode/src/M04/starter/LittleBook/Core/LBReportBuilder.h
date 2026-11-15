@import Foundation;

@class LBReportBuilder;

NS_ASSUME_NONNULL_BEGIN

@protocol LBReportBuilderDelegate <NSObject>
- (void)reportBuilder:(LBReportBuilder *)builder didBuildReport:(NSString *)report;
@end

/// 產生文字報表，完成後透過 delegate 回報。
@interface LBReportBuilder : NSObject

// TODO: M04 — delegate 宣告成 strong 會和持有 builder 的物件互相持有，改成 weak。
@property (nonatomic, strong, nullable) id<LBReportBuilderDelegate> delegate;

- (void)build;

@end

NS_ASSUME_NONNULL_END
