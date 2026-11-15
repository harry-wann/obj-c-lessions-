# 內容撰寫指南（給課文與題目作者）

> 寫完後先跑 `python3 -I scripts/fix-yaml.py <檔案…>` 自動替含「: 」的字串加引號，再跑 `node scripts/validate.mjs`、`node scripts/check-fm.mjs`、`node scripts/check-ex.mjs`、`node --experimental-strip-types scripts/check-solutions.mjs`（code 題的參考解必須通過自己的檢查）。

## 檔案位置與命名

- 課文：`src/content/lessons/m0X/X-Y-slug.mdx`，例：`m02/2-4-properties.mdx`。slug 用英文小寫與連字號。
- 題目：`src/content/exercises/m0X/X-Y-<type>-N.yaml`，一題一檔。`id` 必須等於 `m0X-X-Y-<type>-N`，例：`m02-2-4-fill-1`。
- 參考範例：`src/content/lessons/m02/2-4-properties.mdx` 與 `src/content/exercises/m02/2-4-*.yaml`。**密度、語氣、版型都以它為準。**

## 課文 frontmatter

```yaml
---
title: 屬性 @property          # 不含章節號
module: 2
chapter: "2.4"                 # 字串
order: 4                       # 模組內排序
minutes: 25
prereq: ["2.3"]
objectives: [ "...", "...", "..." ]   # 3 條以內
summary: 一句話（搜尋與列表用）
optional: false                # 選讀章節 true
terms:                         # 本章術語（台灣 / 中國大陸 / 日本）
  - { en: property, tw: 屬性, cn: 属性, jp: プロパティ }
appProgress: 這一章做完後 App 多了什麼（一句）
---
```

## 可用元件（在 frontmatter 後 import）

```mdx
import Compare from '../../../components/Compare.astro';
import Pitfall from '../../../components/Pitfall.astro';
import Crash from '../../../components/Crash.astro';
import Tip from '../../../components/Tip.astro';
import Term from '../../../components/Term.astro';
import Steps from '../../../components/Steps.astro';
```

- `<Compare>`：四語言對照分頁。用 `<Fragment slot="swift">`、`kotlin`、`java`、`ts` 放各語言程式碼區塊（fenced code），slot 之外的文字會顯示在分頁下方當說明。四個 slot 都要有（除非該語言真的沒有對應概念，那就在說明文字中講）。
- `<Pitfall title="...">`：⚠️ 實務陷阱。可選 `<Fragment slot="bad">` 與 `<Fragment slot="good">` 放錯誤 / 正確寫法。
- `<Crash message={`...`}>`：💥 崩潰現場。`message` 放真實錯誤訊息（用反引號樣板字串以支援多行），內文說明怎麼讀、原因、修法。
- `<Tip title="...">`：💡 重點。
- `<Term en="protocol" tw="協定" cn="协议" jp="プロトコル" />`：術語首次出現時用，行內顯示「協定protocol」。
- `<Steps title="...">`：💻 Xcode 操作步驟（放 ol 清單）。

MDX 注意：`{` `}` `<` 在正文中要小心，程式碼一律放 fenced code block（```objc、```swift、```kotlin、```java、```ts、```bash）。正文中出現 `<` 要寫成 `&lt;` 或放進反引號。

## 章節固定結構（依序）

1. `<Compare>` 你已經會的（先用熟悉的語言寫同一件事）
2. `## Objective-C 怎麼寫`：概念 → 語法 → 可貼進 Scratch 執行的完整範例（每個範例自成一段、含 `NSLog` 輸出與預期輸出的註解）
3. 2–4 個 `<Pitfall>`（必須是工作上真的會踩的）
4. 1 個 `<Crash>`（真實錯誤訊息）
5. `## 小結`：3–5 條
（小測驗、練習、小帳本進度、術語卡由版型自動產生，課文不用寫）

## 題目 YAML（各題型欄位）

共通：`id`、`chapter`、`type`、`title`、`prompt`（可用 \`code\` 與 **粗體**）、`minutes`、`mobile`（預設 true；要打大段程式碼的設 false）、`hints`（2–3 條，由淺入深）、`tier`（`basic` 預設 / `advanced` / `interview`，非 basic 的會收在「想多練？」）、`section: quiz`（小測驗；不寫則為練習）。

- **quiz**：`options[]`、`answer`（索引或索引陣列）、`multi`、`explain`、`feedback: { "<錯誤選項索引>": "針對性說明" }`、可選 `code`。
- **fill**：`code`（空格寫 `___1___`）、`blanks: { "1": { accept: [..], chips: [..] } }`、`feedback: { "1=strong": "..." }`、`solution_note`。
- **parsons**：`lines[]`（正確順序）、`distractors[]`（干擾行，選填）、`solution_note`。
- **predict**：`code`、`options[]`（手機友善，建議給）或無 options 讓使用者輸入、`accept[]`（多行輸出以空格分隔）、`feedback: { "<錯誤答案>": "..." }`、`solution_note`、`note`。
- **spot**：`code`、`bug_lines[]`（1 起算）、`reasons[]`、`answer_reason`（索引）、`fix`（程式碼）、`solution_note`、`feedback`。
- **crash**：`log`、`options[]`、`answer`、`fix`、`solution_note`、`feedback`。
- **code**：`starter`、`checks[]`（`must_match` 正規表達式 / `must_not_match` / `contains` / `not_contains` / `selector_equals: "addAmount:note:"` / `selector_present` / `brackets_balanced: true` / `property_attrs: { name, attrs: [] }`，每條可加 `message`）、`solution`、`solution_note`。驗證器會先移除註解並折疊空白再比對；正規表達式請寫得寬鬆（允許空白差異）。`mobile: false`。
- **xcode**：`starter`（`xcode/M0X-starter`）、`steps[]`、`tests[]`（`類別/方法名`）、`acceptance[]`、`solution_note`。`mobile: false`。
- **flash**：`front`、`back`。多用於 `tier: interview`。

每章建議：小測驗 3–5 題（quiz / fill，`section: quiz`）；練習 3–5 題（predict / spot / crash / parsons / fill 混合 + 1 題 code）；1 題 xcode（對應 docs/02 的 💻 項目，分章拆開）；1–2 題 `tier: advanced` 或 `interview`（資料結構章節的進階 / 面試等級題放這裡）。

YAML 注意：含 `: `、`@`、`#`、`{`、`[` 開頭或 `|` 的字串要加引號或用 `|` 區塊；`chapter` 一律加引號。

## 用字規範（務必遵守）

- 台灣用語：物件、類別、實體、方法、屬性、協定、委派（delegate）、分類（category）、區塊（block）、記憶體、指標、參考計數、強 / 弱參考、循環參考、執行緒、佇列、非同步、字串、陣列、字典、集合、回呼、執行期、編譯期、型別、列舉、函式、迴圈、變數、常數、預設、註解、宣告、實作、標頭檔、建置、偵錯、斷點、例外、套件、模組、巨集、快取、雜湊表、鏈結串列、堆疊（stack）、堆積（heap）、樹、走訪、遞迴、排序、搜尋。
- 不用對岸用語於正文：對象、类、数组、字符串、内存、指针、线程、队列、回调、运行时、默认、注释、实现、构建、调试、宏、缓存、哈希、链表、遍历、代码、程序、文件、项目。
- 不寫機翻腔：「進行一個 X 的動作」→「X」；少用「被」；句子短；不用「非常」「十分」堆疊。
- 術語首次出現附英文：協定（protocol）；業界慣用英文的詞之後可直接用英文：delegate、block、selector、cell、crash、runtime、Xcode。
- API、關鍵字、檔名用反引號。
- 全形標點「，。：；（）」；中英數之間留半形空格。
- 程式碼每行 ≤ 72 字；方法呼叫太長依冒號對齊斷行；範例用小帳本的類別名（`LBTransaction`、`LBLedger`、`LBCategory`…），金額用 `NSDecimalNumber`。
- 對照語言：Swift 5.x、Kotlin 2.x、Java 17、TypeScript 5.x。

## 驗證

```bash
node scripts/validate.mjs            # 檢查所有 YAML 題目與 MDX frontmatter
npm run build                        # 完整建置（較慢；多人同時寫作時由整合者統一跑）
```
