@import Foundation;

// 草稿本：想試什麼語法就寫在這裡，⌘R 執行、看主控台輸出。

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSLog(@"Hello, 小帳本");

        // 格式指定子：%@ 物件、%ld 配 (long)、%d int、%f double、%zd NSInteger
        NSInteger count = 3;
        double price = 1280.5;
        NSLog(@"筆數 %ld，金額 %.2f，布林 %d", (long)count, price, (int)YES);

        // 字面值：陣列、字典、數字裝箱
        NSArray<NSString *> *notes = @[@"早餐", @"捷運", @"咖啡"];
        NSDictionary<NSString *, NSNumber *> *amounts = @{@"早餐": @85, @"捷運": @32};
        for (NSString *note in notes) {
            NSNumber *amount = amounts[note];   // 找不到回 nil，不會當掉
            NSLog(@"%@ → %@", note, amount ?: @"（無金額）");
        }

        // 金額一律用 NSDecimalNumber，double 會有 0.1 + 0.2 的問題
        NSDecimalNumber *a = [NSDecimalNumber decimalNumberWithString:@"0.1"];
        NSDecimalNumber *b = [NSDecimalNumber decimalNumberWithString:@"0.2"];
        NSLog(@"0.1 + 0.2 = %@（double 算是 %.17f）", [a decimalNumberByAdding:b], 0.1 + 0.2);

        // 對 nil 送訊息是安全的
        NSString *nothing = nil;
        NSLog(@"nil 的 length = %lu", (unsigned long)nothing.length);
    }
    return 0;
}
