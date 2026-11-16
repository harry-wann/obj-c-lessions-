---
description: 接手本專案：讀現況、建置網站、在 Mac 上逐一驗證 Xcode 里程碑並修正
---

你接手一個已完成大部分工作的專案：Objective-C 速成教學網站與配套的 Xcode 專案「小帳本」。我現在在自己的 Mac 上，有 Xcode 與 Homebrew。

1. 先讀 `CLAUDE.md`、`docs/08-接手指南.md`、`docs/07-決策紀錄與補充建議.md`，掌握現況、規則與已確定的決策。不要重新討論已確定的決策。
2. 確認目前分支與 git 狀態。
3. 網站：`cd site && npm install && npm run build`，並跑 validate / check-fm / check-ex / check-solutions（指令見 CLAUDE.md）。回報結果。
4. Xcode 實機驗證（主要工作）：
   - 確認 xcodegen 已安裝（沒有就 `brew install xcodegen`）。
   - 依序對 `xcode/M01-solution` … `M12-solution`：`xcodegen generate`，然後 `xcodebuild test -project LittleBook.xcodeproj -scheme LittleBook -destination 'platform=iOS Simulator,name=<可用的 iPhone 模擬器>'`。用 `xcrun simctl list devices available` 找模擬器名稱。
   - 每個 starter 至少要能建置（`xcodebuild build-for-testing`）。
   - 失敗時：只改 `xcode/src/` 底下的來源，再跑 `bash xcode/scripts/assemble.sh` 重新組裝；若改了測試名稱或介面，同步更新 `xcode/TESTS.md` 與 `site/` 裡對應的課文、題目。
   - 對時間敏感、不穩定的測試，改成不依賴時間的寫法，不要只把等待時間拉長。
   - 優先處理 `docs/08` §3 列出的風險項目。
5. LittleBook-Legacy：`xcodegen generate` 後確認 6 個雷的症狀照 README 出現；`LittleBook-Legacy-solution` 能正常跑。
6. 用 `xcode/Scratch` 核對 `docs/08` §3「仍未驗證 / 留意」的項目與新寫的課文，與實際輸出不符的就修正課文或題目，並跑內容檢查。
7. 每完成一個里程碑或一批修正就 commit 並 push 到目前分支；commit 訊息用繁體中文。
8. 全部完成後：更新 `docs/08` §1、§3（刪掉已驗證的風險、記下新發現），並問我是否要合併到 main 與啟用 GitHub Pages。

工作原則：遇到需要我決定的事（例如內容方向、要不要做 Phase 3）再問；其餘照 CLAUDE.md 與 `site/AUTHORING.md` 的規範直接做，不用每步確認。

$ARGUMENTS
