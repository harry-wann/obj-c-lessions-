# Objective-C 速成教學網站（小帳本 / LittleBook）

給有 Swift / Kotlin / TypeScript / Java 基礎的開發者，1–2 週內上手 Objective-C 並進入工作。全程做完會得到一支完整的 iOS 記帳 App「小帳本」。

目前狀態：**課程內容全部完成** — 13 個模組（0–12）、83 章、797 題（含 20 張面試速記卡與各章資料結構加練區）；Xcode 起始專案 M01–M12（starter / solution 各 12 份）與 `LittleBook-Legacy` 埋雷版 / 修好版。

## 怎麼跑

```bash
cd site && npm install && npm run dev        # 本機預覽 http://localhost:4321/obj-c-lessions-/
npm run build                                 # 正式建置（含 Pagefind 搜尋索引）
node scripts/validate.mjs                     # 檢查課文與題目格式
node scripts/check-fm.mjs && node scripts/check-ex.mjs   # frontmatter 與題目型別
node --experimental-strip-types scripts/check-solutions.mjs   # code 題參考解能通過驗證器
node scripts/qa-mobile.mjs                    # 手機尺寸全站檢查（需先 build + preview）
```

部署：GitHub Pages。把本分支合併到 `main`，在 repo Settings → Pages 選「GitHub Actions」，`.github/workflows/deploy.yml` 會自動建置並發佈到 `https://harry-wann.github.io/obj-c-lessions-/`。

Xcode 專案：`xcode/README.md`（需要 Mac，`brew install xcodegen`）。在 Linux 上可用 `bash xcode/tools/check.sh xcode/M10-solution` 以替身 SDK 做語法檢查。

- UI 設計稿（Figma）：https://www.figma.com/design/4d6HGy38x11n2uOfkzOBzj
- 規劃文件在 [`docs/`](docs/)：

| 文件 | 內容 |
|---|---|
| [01 總體規劃](docs/01-總體規劃.md) | 定位、設計原則、資訊架構、技術選型、手機版設計、分期交付 |
| [02 課程大綱](docs/02-課程大綱.md) | 12 模組 × 70 章：目標、四語言對照、實務陷阱、崩潰現場、練習、專案進度、資料結構三級制、Figma 畫面對照 |
| [03 實作專案：小帳本](docs/03-實作專案-小帳本.md) | App 規格（10 張畫面）、效能與多執行緒驗收指標、架構、資料模型、里程碑、測試策略 |
| [04 練習題系統設計](docs/04-練習題系統設計.md) | 9 種題型、手機友善原則、題目 YAML 格式、網頁端驗證器、Xcode 任務驗證 |
| [05 學習計畫](docs/05-兩週學習計畫.md) | 16 天完整版、12 天速成版、每日流程、上工前檢查表 |
| [06 術語對照表](docs/06-術語對照表.md) | 英文 / 台灣 / 中國大陸 / 日本 術語對照約 150 條，與寫作規範 |
| [07 決策紀錄與補充建議](docs/07-決策紀錄與補充建議.md) | 已確認的決定、現實限制、補充建議、完成狀態 |
| [08 接手指南](docs/08-接手指南.md) | 本機接手步驟、已知風險清單、給新 session 的 prompt（或在 Claude Code 輸入 `/handoff`） |
