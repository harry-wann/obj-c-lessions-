# CLAUDE.md — Objective-C 速成教學網站（小帳本 LittleBook）

給 Claude Code 的專案說明。開新 session 時自動載入。接手步驟見 `docs/08-接手指南.md`，或直接輸入 `/handoff`。

## 這個 repo 是什麼

給有 Swift / Kotlin / TypeScript / Java 基礎的開發者，16 天上手 Objective-C 的教學網站。全程做完會得到一支記帳 App「小帳本」。使用者本人是唯一學習者，常用手機學習。

- `docs/` 規劃文件（01 總體規劃 … 07 決策紀錄、08 接手指南）。**改方向前先讀 07。**
- `site/` Astro 7 + MDX + Preact + Tailwind 4 網站。課文 `src/content/lessons/mXX/*.mdx`，題目 `src/content/exercises/mXX/*.yaml`。
- `xcode/` Xcode 專案（XcodeGen `project.yml`，不進版控 `.xcodeproj`）。
- Figma 設計稿：https://www.figma.com/design/4d6HGy38x11n2uOfkzOBzj（Starter 方案：3 頁上限、變數單一模式、API 呼叫次數有限）。

## 已確定的決策（不要再問使用者）

- 用語：**台灣用語為主**，術語表附中國大陸與日本 IT 界對照。規則見 `site/AUTHORING.md`「用字規範」與 `docs/06-術語對照表.md`。
- 目標工作：純 ObjC 舊專案維護 **與** ObjC + Swift 混編都要會。
- UI：程式碼 Auto Layout 與 Storyboard / XIB **都用**。
- 資料結構：每章由淺入深三級（basic / advanced / interview），後兩級收在「想多練？」不計主線進度。
- 最終 App：記帳，含多執行緒保護、高併發、不掉幀練習（驗收指標見 `docs/03` §2）。
- 練習題分兩類：🌐 網頁驗證、💻 Xcode 驗證（Xcode Playground 不支援 ObjC，草稿本用 `xcode/Scratch`）。

## 常用指令

```bash
# 網站
cd site && npm install
npm run dev                                   # http://localhost:4321/obj-c-lessions-/
npm run build                                 # 含 Pagefind 索引

# 內容檢查（新增 / 修改課文或題目後全部要跑）
python3 -I scripts/fix-yaml.py <檔案…>         # 自動替含「: 」的 YAML 字串加引號
node scripts/validate.mjs                     # 格式、id、空格數、章節對應
node scripts/check-fm.mjs                     # frontmatter 型別
node scripts/check-ex.mjs                     # 題目型別（含 code 題 checks 必須是物件）
node --experimental-strip-types scripts/check-solutions.mjs   # code 題參考解要通過驗證器
npx astro preview --port 4321 &               # 再跑下一行（需要 playwright）
node scripts/qa-mobile.mjs                    # iPhone 尺寸全站：橫向溢出、JS 錯誤

# Xcode（Mac）
cd xcode/M05-starter && xcodegen generate && open LittleBook.xcodeproj
xcodebuild test -project LittleBook.xcodeproj -scheme LittleBook \
  -destination 'platform=iOS Simulator,name=iPhone 16'
bash xcode/tools/check.sh xcode/M10-solution  # 沒有 Xcode 時：替身 SDK 的 clang 語法檢查
```

## 重要規則

- **Xcode 程式碼只改 `xcode/src/`**，然後跑 `bash xcode/scripts/assemble.sh` 重新產生 `M01-starter` … `M12-solution`。不要直接改組裝出來的資料夾，下次組裝會被覆蓋。
  - `src/common/` 共用；`src/MNN/solution/` 該里程碑完成後的檔案（累積覆蓋）；`src/MNN/starter/` 只放與 solution 不同的空殼 / 埋雷檔；`src/MNN/tests/` 測試；`src/MNN/solution/root/` 放專案根目錄檔（project.yml、Podfile）；`src/MNN/starter/remove.txt` 列 starter 要刪的檔。
  - Legacy 修好版由 `bash xcode/scripts/assemble-legacy.sh` 從 `LittleBook-Legacy/` 產生。
- **測試名稱與共用介面以 `xcode/TESTS.md` 為準**，課文的 xcode 題引用同一批名稱。改名要同時改課文、題目、TESTS.md、src。
- 課文與題目格式以 `site/AUTHORING.md` 為準；範本章節是 `lessons/m02/2-4-properties.mdx`。
- YAML 地雷：含「: 」、以 `@`、`[`、反引號開頭的字串要加引號；但 code 題 `checks:` 底下的 `- must_match: …` 等是物件，**不能**整行加引號。
- 網站 base path 是 `/obj-c-lessions-`（repo 名稱有結尾連字號）。連結一律用 `src/lib/base.ts` 的 `url()`。
- 部署：推到 `main` 由 `.github/workflows/deploy.yml` 發佈到 GitHub Pages。
- 不要在 commit、程式碼或文件裡寫模型名稱。
