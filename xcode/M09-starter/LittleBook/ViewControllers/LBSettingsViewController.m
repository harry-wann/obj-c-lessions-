#import "LBSettingsViewController.h"
#import "LBSettings.h"
#import "LBLedger.h"
#import "LBUndoStack.h"
#import "LBPersistence.h"

@implementation LBSettingsViewController

- (instancetype)initWithSettings:(LBSettings *)settings
                          ledger:(LBLedger *)ledger
                       undoStack:(LBUndoStack *)undoStack
                     persistence:(LBPersistence *)persistence {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _settings = settings;
        _ledger = ledger;
        _undoStack = undoStack;
        _persistence = persistence;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"設定";
    // TODO: M09 — grouped table（畫面 08）：
    //   一般：主幣別（action sheet 選 supportedCurrencyCodes）、顯示小數位（UISwitch）、外觀
    //   資料：匯出 JSON（先存檔再 UIActivityViewController 分享 fileURL）
    //   清除全部資料：連問兩次，ledger reset + undoStack removeAllActions + 存檔
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 0;   // TODO: M09
}

@end
