#!/usr/bin/env bash
# 從 xcode/LittleBook-Legacy/（埋雷版，唯一來源）產生 xcode/LittleBook-Legacy-solution/（六雷修好）。
# 做法：整個複製一份，再對固定幾個檔案做「必須剛好命中一次」的字串替換；
# 任何一處沒命中（例如原版被改過）就中止，避免產出半套解答。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/LittleBook-Legacy"
DEST="$ROOT/LittleBook-Legacy-solution"

rm -rf "$DEST"
mkdir -p "$DEST"
# 不帶 Pods/、產生出來的 .xcodeproj / .xcworkspace / Info.plist
(cd "$SRC" && tar cf - --exclude=Pods --exclude='*.xcodeproj' --exclude='*.xcworkspace' \
    --exclude=Podfile.lock --exclude=LittleBookLegacy/Info.plist .) | (cd "$DEST" && tar xf -)

python3 -I - "$DEST" <<'PY'
import sys, pathlib

dest = pathlib.Path(sys.argv[1])

def patch(rel, old, new):
    p = dest / rel
    text = p.read_text(encoding="utf-8")
    n = text.count(old)
    if n != 1:
        sys.exit(f"assemble-legacy: {rel} 預期命中 1 次，實際 {n} 次：{old[:60]!r}")
    p.write_text(text.replace(old, new), encoding="utf-8")

TX = "LittleBookLegacy/Models/LBLegacyTransaction.m"
# 雷 1：dealloc 不 release assign 屬性
patch(TX, "    [_formattedAmountCache release];\n    [_previous release];\n",
          "    [_formattedAmountCache release];\n"
          "    // _owner / _previous 是 assign：從沒 retain 過，不 release（雷 1）\n")
# 雷 2：setter 先 retain 新的、再 release 舊的、最後賦值
patch(TX, "        _amount = [amount retain];\n\n",
          "        [amount retain];\n        [_amount release];   // 雷 2：舊值要放手\n"
          "        _amount = amount;\n\n")
# 雷 3：storyboard 的 outlet 接回現在的屬性名
patch("LittleBookLegacy/Base.lproj/Main.storyboard",
      'property="summaryLabel"', 'property="totalLabel"')
# 雷 4：segue identifier 拼字
patch("LittleBookLegacy/Controllers/LBLegacyListViewController.m",
      '@"showDetial"', '@"showDetail"')
# 雷 5：App target 自己加 -ObjC；Podfile 拿掉剝除 -ObjC 的歷史 post_install
patch("project.yml", '        OTHER_LDFLAGS:\n          - "$(inherited)"\n',
      '        OTHER_LDFLAGS:\n          - "$(inherited)"\n'
      '          - "-ObjC"   # 雷 5：靜態庫裡只有 category 的 .o 也要拉進來\n')
pod = dest / "Podfile"
text = pod.read_text(encoding="utf-8")
cut = text.index("# 2015/06 某 SDK")
pod.write_text(text[:cut].rstrip() + "\n", encoding="utf-8")
# 雷 6：擁有者 dealloc 時取消請求、清掉 assign delegate；service 自己 dealloc 也 cancel
patch("LittleBookLegacy/Controllers/LBLegacyDetailViewController.m",
      "- (void)dealloc\n{\n    [_rateService release];\n",
      "- (void)dealloc\n{\n"
      "    // 雷 6：NSURLConnection 會 retain service，service 會比我活得久；\n"
      "    // 先把指向我的 assign delegate 清掉，再取消請求\n"
      "    _rateService.delegate = nil;\n    [_rateService cancel];\n"
      "    [_rateService release];\n")
patch("LittleBookLegacy/Services/LBLegacyRateService.m",
      "- (void)dealloc\n{\n    [_connection release];\n",
      "- (void)dealloc\n{\n    [_connection cancel];   // 雷 6：保險，不再回呼到死掉的 self\n"
      "    [_connection release];\n")
# 勾選表全打勾
audit = dest / "LegacyAudit.plist"
audit.write_text(audit.read_text(encoding="utf-8").replace("\t<false/>", "\t<true/>"),
                 encoding="utf-8")
# README 開頭加說明
readme = dest / "README.md"
readme.write_text(readme.read_text(encoding="utf-8").replace(
    "# LittleBook-Legacy — 小帳本「老派版」\n",
    "# LittleBook-Legacy-solution — 小帳本「老派版」（六雷已修好）\n\n"
    "> 由 `xcode/scripts/assemble-legacy.sh` 從 `../LittleBook-Legacy/` 產生，請勿直接修改。\n"
    "> 每一處修正都有 `雷 N` 註解；說明見 `SOLUTIONS.md`。以下為原版 README。\n", 1),
    encoding="utf-8")
PY
echo "assembled $DEST"
