@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// 交易種類：支出或收入。
typedef NS_ENUM(NSInteger, LBTransactionKind) {
    LBTransactionKindExpense = 0,
    LBTransactionKindIncome = 1,
};

/// 交易旗標：位元旗標，可用 | 組合、& 檢查。
typedef NS_OPTIONS(NSUInteger, LBTransactionFlags) {
    LBTransactionFlagsNone = 0,
    LBTransactionFlagsReconciled = 1 << 0,   // 已對帳
    LBTransactionFlagsRecurring = 1 << 1,    // 定期
};

/// 全域錯誤 domain（值為 @"com.littlebook.error"）。
extern NSString * const LBErrorDomain;

/// 錯誤碼。NS_ERROR_ENUM 把 enum 綁到 LBErrorDomain；匯入 Swift 後會變成 LBError.Code（M12）。
typedef NS_ERROR_ENUM(LBErrorDomain, LBErrorCode) {
    LBErrorCodeMalformedJSON = 100,     // JSON 解析失敗或結構不是預期的物件
    LBErrorCodeUnexpectedType = 101,    // 欄位型別不對（例如匯率是字串 "abc"）
    LBErrorCodeHTTPStatus = 102,        // HTTP 非 2xx；userInfo 帶 LBRateServiceHTTPStatusCodeKey
    LBErrorCodeCancelled = 103,         // 任務被取消
};

/// 把以「分」為單位的整數格式化成千分位字串。
/// 128000 → @"1,280.00"；-5 → @"-0.05"。
NSString *LBFormatCents(long long cents);

NS_ASSUME_NONNULL_END
