// LittleBook-Bridging-Header.h（12.1）
// 列在這裡的 ObjC 標頭，App target 裡的 Swift 檔才看得到；沒列的類別在 Swift 端是
// `Cannot find 'LBXxx' in scope`。project.yml 的 SWIFT_OBJC_BRIDGING_HEADER 指向這個檔。
// 規則：這裡只放 #import；每個被列進來的標頭都必須包 NS_ASSUME_NONNULL_BEGIN / END，
// 否則 Swift 端全是隱式解包的 `!`（LBBridgingTests/testNullabilityAnnotationsPresent 會檢查）。
// 反方向：ObjC 要用 Swift 類別時 #import "LittleBook-Swift.h"——只能寫在 .m，不能寫在 .h。

#import "LBTypes.h"
#import "LBTransaction.h"
#import "LBCategory.h"
#import "LBLedger.h"
#import "LBSettings.h"
#import "LBRateService.h"
#import "LBPersistence.h"
#import "NSDecimalNumber+LBFormatting.h"
