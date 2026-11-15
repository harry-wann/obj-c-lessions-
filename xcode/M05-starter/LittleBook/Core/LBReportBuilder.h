@import Foundation;

@class LBReportBuilder;

NS_ASSUME_NONNULL_BEGIN

@protocol LBReportBuilderDelegate <NSObject>
- (void)reportBuilder:(LBReportBuilder *)builder didBuildReport:(NSString *)report;
@end

/// 產生文字報表，完成後透過 delegate 回報。
@interface LBReportBuilder : NSObject

/// 修正：delegate 一律 weak，否則持有 builder 的物件（通常就是 delegate）會和它互相持有。
@property (nonatomic, weak, nullable) id<LBReportBuilderDelegate> delegate;

- (void)build;

@end

NS_ASSUME_NONNULL_END
