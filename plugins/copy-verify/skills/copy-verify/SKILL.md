---
name: copy-verify
description: Verify and align an app's user-facing copy against a per-project terminology SSOT — a guard-first loop that catches banned/inconsistent terms, engineering-jargon leaks, and raw backend errors reaching users. Covers BOTH modes — incremental (a glossary already exists) and bootstrap (stand one up for a project that has none). Use when the user mentions 改文案 / 驗文案 / 文案對齊 / 文案一致 / glossary / 禁用詞 / 術語統一 / UI copy review / microcopy audit / copy consistency / "align copy" / "terminology guard", even if they don't say the word "skill".
---

# 文案驗證與對齊（copy-verify）

當一個畫面 / 設計匯入 / 單一文案變動進來，這是**怎麼拿它去對既有標準驗證並修正**的方法論。
與專案無關、與語系無關；適用任何有 user-facing 文案的 app。兩條哲學：

1. **增量** —— 只驗**改動的** user-facing 字串，不每次全站重審。
2. **guard 優先** —— 機械性違規交給自動測試（便宜、可回歸）；自動抓不到的判斷才用人 / agent 補。

## 兩種模式（先判斷你在哪一種）

- **增量模式**：專案**已有**受版控的詞彙定本（glossary）＋防回歸 guard。→ 直接進「工作流」。
- **bootstrap 模式**：專案**沒有** glossary。→ 先做「bootstrap：建立 SSOT」，再進工作流。
  這是把本方法論帶進新專案的常見情況。

## 對照的單一真相（SSOT）

文案標準必須落在**受版控**的檔案，不能只存在人讀文件（那些常被 gitignore、易過期、不可靠）。
建議三件套（範本見 `references/`）：

| 角色 | 是什麼 | 怎麼用 |
|---|---|---|
| 詞彙定本 | `TERMS`（canonical 詞彙，**非強制**引用）＋ `BANNED_TERMS`（禁用詞清單） | 詞彙定本；新定本詞 / 新禁用詞回寫這裡 |
| 防回歸 guard | 一支測試：剝註解後掃原始碼找 `BANNED_TERMS` | 自動第一道；allowlist 只放定本檔本身與測試 |
| 錯誤訊息對映器 | 把後端 / 例外訊息映成使用者可讀訊息 | 任何錯誤態都走它，禁直接把原始錯誤吐上畫面 |

> **`BANNED_TERMS` 只收「在 UI 永遠是錯」的字**，且必須是**任何程式碼語境都不會合法出現**的 token：
> 在地化錯字 / 他地用語（如 zh-TW 產品裡的中國用語）、或帶連字號的文案專用詞（`single-demo`）。
> **裸英文技術詞不收**（`entity` / `channel` / `provider` / `port`…）——它們在變數名 / 型別 / class 名合法出現，
> 子字串比對會誤報，AST 範圍判斷成本高。這層外洩只能靠人 review（見三主線 B）。

## Bootstrap：在沒有 glossary 的專案建立 SSOT

1. **定位文案落點**：找出 user-facing 字串散在哪（元件 JSX、選單、通知、錯誤翻譯、主行程拋錯…）。
2. **決定語言 / house-style 政策**：例如「全 <locale>，保留專有名詞與規格保留的技術縮寫」。把政策寫進定本檔註解。
3. **挑定本詞**：同概念跨頁多名的，收斂成一個 canonical（見三主線 A）。
4. **挑禁用詞（務必零碰撞）**：先 `grep` 候選詞，確認它們**只**出現在文案、不在識別字 / class 名 / 協定碼；
   有碰撞的（例：某狀態欄位子字串）就**不能**收。寧可少收，不可誤報。
5. **寫 guard**：用專案既有的 test runner；掃原始碼、剝註解、比對 `BANNED_TERMS`；先跑成 **RED** 當工作清單。
6. 之後照「工作流」修到 guard **GREEN**。

## 工作流（guard 優先的增量迴圈）

**0. 定位改動的字串**：找出這次新增 / 改到的 **user-facing** 文案（JSX text、label、toast、
   空 / 載入 / 錯誤 / gate 各狀態字串）。只驗這些。

**1. 自動 guard（第一道，便宜，先跑）**：跑防回歸測試，抓機械性違規（他地用語 / 已決議翻譯的行話 /
   違反定價框架的字…）。失敗訊息直接給 `檔案: 「禁用詞」→ 改用「建議」`。

**2. 人判補（第二道，自動抓不到的）**——對改動字串逐項過：
   - **產品硬規則**（最高優先）：例如通知 / 摘要 payload 不得含敏感內容；先確認沒違反。
   - **5 維 rubric**（見下）。
   - **三條系統性主線**（見下）——尤其 B（英文技術詞外洩）guard 抓不到。
   - **W 類「文案＝接線 bug」**（見下）——光改字無效的，別只改字。

**3. 修正 + 回寫標準**：改字串；**若冒出新定本詞或新禁用詞**，回寫定本檔，讓 guard 之後守得到
   （防回歸的關鍵——guard 只跟清單一樣強）。

**4. 收尾驗證（都要綠才算完）**：
   - guard 再跑。
   - **真關卡是 build / 完整測試套件**，不是 typecheck（見 G2）。

## 5 維 rubric（人判第二道的判準）

| 維度 | 看什麼 | 常見 fail |
|---|---|---|
| **C 術語準確** | 產品領域術語正確、符合該領域官方 / 慣用說法 | 用了非官方或錯誤的領域術語 |
| **L 在地化** | 目標語系道地、無他地用語 | 他地用語；guard 外的口語不順 |
| **U UX 微文案** | 空 / 載入 / 錯誤 / gate 各狀態都有合宜文案、動作清楚 | 錯誤態白畫面、空狀態無引導、按鈕語焉不詳 |
| **B 語氣品牌** | 人稱統一、無工程黑話、無裝飾性 emoji、定價 framing 正確 | 技術詞外洩、表情符號當裝飾、paywall 框架 |
| **A AI 感** | 不像 AI 生成（無套話、無過度對仗、無「讓我們」、無 em-dash 堆疊） | 罐頭句、母湯的對仗 |

## 三條系統性主線（最高槓桿，跨頁問題）

- **A 同概念跨頁多名**：同一件事在不同頁用不同詞。**對到 `TERMS` 的定本**，全站收斂成一個。
- **B 工程術語外洩**：內部術語 / 未翻英文黑話漏進使用者文案。**guard 不收裸英文技術詞，這條全靠人看**。
- **C 錯誤訊息直吐後端**：`載入失敗：{error}`、ErrorBoundary 吐 `error.message`、把原始 stderr / 例外
  訊息插進字串。**改走錯誤對映器**（見 G4）：原始細節記 log、不上畫面。

## W 類「文案＝接線 bug」（光改字無效，通常 P0）

看到文案怪，先問「是字錯，還是行為錯」：

| 樣板 | 徵狀 | 真因 |
|---|---|---|
| W1 死導覽 | 渲染了點了沒反應的類別 / 連結 | UI 渲染了資料層其實不支援的選項 |
| W2 時序矛盾 | 提示秒數 vs 實際窗口對不上，動作失效 | 兩個 timeout 不一致 |
| W3 文案依賴 UI 字符 | 文案寫「按下 ▶」；圖示一改文案就壞 | 文字與圖示不同源、耦合 |
| W4 錯誤態白畫面 | 非預期錯誤 `return null` | 缺錯誤態 render |

## Gotchas（地雷，違反會靜默壞掉）

- **G1 — load-bearing label 不可在文案 loop 改。** 有些字串是**功能性**的，不只是顯示：
  (a) 被餵進 LLM prompt（改字＝改行為）；(b) 是 renderer / 前後端**解析的協定碼**（`UPPER_SNAKE_CASE`
  這類，翻了就 match 不到、功能壞）。先確認一個 label 只是顯示、不是被程式吃的，再改。
- **G2 — 真關卡是 build / 完整測試，不是 typecheck。** 很多打包器（esbuild 等）不做完整型別檢查，
  build 綠不代表 typecheck 綠、反之亦然；分別跑。**且：pre-commit hook 可能跑整套測試——
  把文案寫死的測試會因你改文案而 fail，那是「該更新測試」不是「繞過 hook」；更新成新定本。**
  單檔跑 `tsc` 會因缺專案 tsconfig 產生假型別錯誤，別被騙——用專案的 typecheck 指令。
- **G3 — 產品硬規則不只是文字。** 若有 payload / 內容規則（不得含敏感摘要等），驗文案時順手確認沒違反。
- **G4 — 錯誤訊息禁插值原始 error。** 走錯誤對映器給乾淨訊息；技術細節記 log、不上畫面。
  二次包裝第三方 CLI / 服務的產品最常犯這條（把工具的英文 stderr 原封吐給使用者）。
- **G5 — 人讀字典不可靠，以受版控的 glossary 為準。** 設計稿 / 需求 spec 常被 gitignore 或過期；
  定本以進版控的詞彙檔為唯一真相，決策也回寫這裡（不要只寫在會消失的文件）。

## 不做（YAGNI）

- 不每次全站逐頁重審（那是另一種情境，本 skill 專做增量 / 單畫面）。
- 不強制每個字串改走 `TERMS` 常數——字串可直接寫定本字，由 `BANNED_TERMS` guard 守不回歸即可。
- 不碰被程式解析 / 餵 LLM 的 load-bearing label（G1 邊界外）。

## 相關

- 範本：`references/glossary-template.ts`（TERMS + BANNED_TERMS 骨架）、
  `references/guard-test-template.ts`（掃描 guard 骨架，vitest 風格，可改寫成任何 runner）。
