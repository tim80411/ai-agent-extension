# spec-writer AC-as-Test-Cases Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Strengthen the spec-writer plugin's Acceptance Criteria format by adopting Given-When-Then as the primary format, adding scenario coverage checks, and reorganizing templates into an `assets/` directory.

**Architecture:** Pure markdown file changes across the spec-writer plugin. No code, no tests — this is a methodology/template update. Six files affected, three moved.

**Tech Stack:** Markdown, Claude Code plugin system

---

### Task 1: Move templates from `references/` to `assets/`

**Files:**
- Move: `plugins/spec-writer/skills/spec-writing/references/user-story.md` → `plugins/spec-writer/skills/spec-writing/assets/user-story.md`
- Move: `plugins/spec-writer/skills/spec-writing/references/enabler-story.md` → `plugins/spec-writer/skills/spec-writing/assets/enabler-story.md`
- Move: `plugins/spec-writer/skills/spec-writing/references/spike.md` → `plugins/spec-writer/skills/spec-writing/assets/spike.md`

**Step 1: Create assets directory and move files**

```bash
mkdir -p plugins/spec-writer/skills/spec-writing/assets
git mv plugins/spec-writer/skills/spec-writing/references/user-story.md plugins/spec-writer/skills/spec-writing/assets/user-story.md
git mv plugins/spec-writer/skills/spec-writing/references/enabler-story.md plugins/spec-writer/skills/spec-writing/assets/enabler-story.md
git mv plugins/spec-writer/skills/spec-writing/references/spike.md plugins/spec-writer/skills/spec-writing/assets/spike.md
```

**Step 2: Commit**

```bash
git add -A plugins/spec-writer/skills/spec-writing/assets/
git commit -m "refactor: move spec-writer templates from references/ to assets/"
```

---

### Task 2: Rewrite `references/03-acceptance-criteria.md`

**Files:**
- Modify: `plugins/spec-writer/skills/spec-writing/references/03-acceptance-criteria.md` (full rewrite)

**Step 1: Rewrite the file**

Replace the entire content of `03-acceptance-criteria.md` with:

```markdown
# 驗收標準撰寫原則

## 核心概念：AC 即 Test Case

每一條驗收標準都應該是 QA 可以直接轉為測試案例的規格。撰寫時問自己：「QA 看到這條 AC，能不能直接寫出測試步驟和預期結果？」如果不能，就需要更具體。

驗收標準描述 **「What — 要達成什麼」**，不描述 **「How — 怎麼達成」**。

---

## Given-When-Then 格式

這是撰寫驗收標準的 **主要格式**。每條驗收標準都應以情境（Scenario）為單位，使用 Given-When-Then 結構：

- **Given**：前提/假設條件（可以有多個，用 AND 串接）
- **When**：觸發動作（**只能有一個**）
- **Then**：預期結果（可以有多個，用 AND 串接）

### 重要規則：Given 多條件，When 單一觸發

Given 負責描述所有前提條件，When 只放一個觸發動作。這樣文件清晰不易誤解。

**好：**

```
GIVEN 使用者已登入
  AND 購物車中有 3 件商品
  AND 配送地址已填寫完成
WHEN 使用者點擊「送出訂單」按鈕
THEN 系統建立訂單
  AND 使用者看到訂單確認頁面
  AND 購物車清空
```

**壞（When 有多個觸發，容易混淆）：**

```
GIVEN 使用者已登入
WHEN 使用者填寫配送地址
  AND 使用者點擊「送出訂單」按鈕
THEN 系統建立訂單
```

上面的壞例子中，「填寫配送地址」和「點擊送出」到底哪個才是真正的觸發條件？把前提條件放在 Given，When 只放觸發動作，閱讀起來更清晰。

---

## 情境分組

每個 Story 的驗收標準應以情境分組，確保覆蓋度：

| 分組 | 說明 | 必要性 |
|------|------|--------|
| **Happy Path** | 正常流程，使用者順利完成操作 | **必要** — 每個 Story 至少一個 |
| **Error Path** | 錯誤處理，系統遇到異常時的行為 | 視需求 — 若有明顯的錯誤情境應涵蓋 |
| **Edge Case** | 邊界情境，極端或特殊條件 | 視需求 — 有助於釐清模糊地帶 |

### 範例

```
情境 1: 正常查詢年資超過 5 年的員工（Happy Path）
GIVEN 現在時間是 2019/01/01
  AND 系統中有年資超過 5 年的員工資料
WHEN 我撈取年資超過 5 年的員工資料
THEN 報表資料筆數應為 2
  AND 第一筆資料應為 Bob（年資 6 年）

情境 2: 查無符合條件的員工（Edge Case）
GIVEN 現在時間是 2019/01/01
  AND 系統中沒有年資超過 10 年的員工
WHEN 我撈取年資超過 10 年的員工資料
THEN 報表顯示「查無資料」提示

情境 3: 未登入就嘗試查詢（Error Path）
GIVEN 使用者尚未登入系統
WHEN 使用者嘗試撈取員工資料
THEN 系統顯示「請先登入」提示
  AND 不顯示任何員工資料
```

---

## Outcome-Focused 原則

即使使用 Given-When-Then 格式，仍須避免洩漏實作細節。

### 好（Outcome-Focused）

```
GIVEN 使用者已登入
WHEN 使用者存取工具首頁
THEN 頁面載入時間 < 3 秒
  AND 所有連線透過 HTTPS 加密
```

### 壞（Implementation-Focused）

```
GIVEN 使用者已登入
WHEN 使用者存取工具首頁
THEN Cloud CDN 回傳快取內容
  AND GCP managed SSL 憑證驗證通過
```

---

## 撰寫檢查清單

- [ ] 是否使用 Given-When-Then 格式？
- [ ] Given 是否只包含前提條件？When 是否只有一個觸發動作？
- [ ] 是否至少有 Happy Path 情境？
- [ ] 是否考慮了 Error Path 和 Edge Case？
- [ ] 每條情境是否可被 QA 直接轉為測試案例（pass/fail）？
- [ ] 非技術人員是否能讀懂？
- [ ] 是否描述結果而非手段（Outcome-Focused）？
- [ ] 是否可量化（有明確的數字或可觀測的行為）？

---

## 常見錯誤

| 錯誤 | 問題 | 修正 |
|------|------|------|
| 「使用 Redis 快取」 | 規定實作技術 | 「回應時間 < 200ms」 |
| 「按鈕應為藍色」 | 規定視覺設計 | 「使用者能清楚辨識主要操作」 |
| 「呼叫 /api/v2/users」 | 規定 API 設計 | 「系統能取得使用者資訊」 |
| 「程式碼覆蓋率 > 80%」 | 衡量手段而非結果 | 「核心流程有自動化測試保護」 |
| When 有多個動作 | 觸發條件不明確 | 把前提條件移到 Given，When 只留一個 |
| 只有 Happy Path | 覆蓋度不足 | 補充 Error Path 和 Edge Case 情境 |
```

**Step 2: Commit**

```bash
git add plugins/spec-writer/skills/spec-writing/references/03-acceptance-criteria.md
git commit -m "docs: rewrite AC reference to adopt Given-When-Then as primary format"
```

---

### Task 3: Update templates with Given-When-Then format

**Files:**
- Modify: `plugins/spec-writer/skills/spec-writing/assets/user-story.md`
- Modify: `plugins/spec-writer/skills/spec-writing/assets/enabler-story.md`

**Step 1: Rewrite `assets/user-story.md`**

Replace entire content with:

```markdown
h2. 描述

身為＿＿，我需要＿＿，以便＿＿。

h2. 範圍

（說明本 Story 涵蓋的具體範圍）

h2. 驗收標準

情境 1: ＿＿（Happy Path）
GIVEN ＿＿
WHEN ＿＿
THEN ＿＿

情境 2: ＿＿（Error Path）
GIVEN ＿＿
WHEN ＿＿
THEN ＿＿

情境 3: ＿＿（Edge Case）
GIVEN ＿＿
WHEN ＿＿
THEN ＿＿

（情境數量不固定，至少需要 Happy Path。Error/Edge 視需求增減。）

h2. 依賴

* PROJ-N（Story N — 名稱）說明依賴原因

h2. 優先序

P_ — 一句話說明排序理由
```

**Step 2: Rewrite `assets/enabler-story.md`**

Replace entire content with:

```markdown
h2. 描述

作為開發團隊，我們需要＿＿，使＿＿。

（若有範圍限定，在此補充說明）

h2. 價值陳述

此項變更＿＿（說明賦能了哪些 User Story 或消除了什麼風險）。

h2. 驗收標準

情境 1: ＿＿（Happy Path）
GIVEN ＿＿
WHEN ＿＿
THEN ＿＿

情境 2: ＿＿（Error Path）
GIVEN ＿＿
WHEN ＿＿
THEN ＿＿

情境 3: ＿＿（Edge Case）
GIVEN ＿＿
WHEN ＿＿
THEN ＿＿

（情境數量不固定，至少需要 Happy Path。Error/Edge 視需求增減。）

h2. 不含（Out of Scope）

* 不做的事項 1
* 不做的事項 2

h2. 依賴

* PROJ-N（Story N — 名稱）說明依賴原因

h2. 優先序

P_ — 一句話說明排序理由
```

**Step 3: Commit**

```bash
git add plugins/spec-writer/skills/spec-writing/assets/user-story.md plugins/spec-writer/skills/spec-writing/assets/enabler-story.md
git commit -m "docs: update story templates with Given-When-Then AC format"
```

---

### Task 4: Update `SKILL.md` Phase 2 and template paths

**Files:**
- Modify: `plugins/spec-writer/skills/spec-writing/SKILL.md:107-151` (Phase 2 section)
- Modify: `plugins/spec-writer/skills/spec-writing/SKILL.md:216-224` (reference index)

**Step 1: Update Phase 2 Actions in SKILL.md**

In Phase 2, after step 2c (填寫模板), add a new step 2d for AC writing guidance. The current steps 2d and 2e become 2e and 2f.

Find this block (lines 137-143):

```
   c. **填寫模板**，替換所有佔位符；不適用的段落整段移除。

   d. **套用命名規則**（來自 `references/08-workflow-conventions.md`）：
```

Replace with:

```
   c. **填寫模板**，替換所有佔位符；不適用的段落整段移除。

   d. **撰寫驗收標準**（參照 `references/03-acceptance-criteria.md`），以 Given-When-Then 情境格式撰寫：
      - 每個 Story 至少包含一個 Happy Path 情境
      - 評估是否需要 Error Path 和 Edge Case 情境
      - Given 可包含多個前提條件（用 AND 串接），When 只有一個觸發動作
      - 每條情境都應可被 QA 直接轉為測試案例

   e. **套用命名規則**（來自 `references/08-workflow-conventions.md`）：
```

Also update the remaining step letter (2e → 2f):

Find: `   e. **標記 Labels 與優先序**`
Replace with: `   f. **標記 Labels 與優先序**`

**Step 2: Update all template path references in SKILL.md**

Find all occurrences of template paths and update:

- `references/user-story.md` → `assets/user-story.md`
- `references/enabler-story.md` → `assets/enabler-story.md`
- `references/spike.md` → `assets/spike.md`

These appear in Phase 2 step 2b (lines 133-135).

**Step 3: Update the reference index at the bottom of SKILL.md**

Add a new entry for the assets directory. After the existing reference list (line 224), add:

```markdown

## 模板索引

- **`assets/user-story.md`** — User Story 模板（Given-When-Then 驗收標準格式）
- **`assets/enabler-story.md`** — Enabler Story 模板（Given-When-Then 驗收標準格式）
- **`assets/spike.md`** — Spike 模板
```

**Step 4: Commit**

```bash
git add plugins/spec-writer/skills/spec-writing/SKILL.md
git commit -m "docs: update SKILL.md with AC writing guidance and assets/ paths"
```

---

### Task 5: Update `references/08-workflow-conventions.md` template paths

**Files:**
- Modify: `plugins/spec-writer/skills/spec-writing/references/08-workflow-conventions.md:63-71`

**Step 1: Update the template mapping table**

Find this block (lines 63-71):

```markdown
## 模板對應關係

| Story 類型 | 模板檔案 |
|-----------|---------|
| User Story | `references/user-story.md` |
| Enabler Story | `references/enabler-story.md` |
| Spike | `references/spike.md` |

**使用方式**：用 `Read` 工具讀取對應模板，以模板結構為基底，將所有佔位符替換為實際內容。若某段落對當前 Story 不適用，整段移除（不保留空白佔位符）。
```

Replace with:

```markdown
## 模板對應關係

| Story 類型 | 模板檔案 |
|-----------|---------|
| User Story | `assets/user-story.md` |
| Enabler Story | `assets/enabler-story.md` |
| Spike | `assets/spike.md` |

**使用方式**：用 `Read` 工具讀取對應模板，以模板結構為基底，將所有佔位符替換為實際內容。若某段落對當前 Story 不適用，整段移除（不保留空白佔位符）。驗收標準須使用 Given-When-Then 情境格式（詳見 `references/03-acceptance-criteria.md`）。
```

**Step 2: Commit**

```bash
git add plugins/spec-writer/skills/spec-writing/references/08-workflow-conventions.md
git commit -m "docs: update workflow conventions with assets/ template paths"
```

---

### Task 6: Update `agents/spec-reviewer.md` with AC coverage checks

**Files:**
- Modify: `plugins/spec-writer/agents/spec-reviewer.md:41-105`

**Step 1: Add AC coverage check to the agent's core responsibilities**

Find this block (lines 41-46):

```markdown
**核心職責：**

1. 對每個 Story 執行 INVEST 六項檢查（Independent、Negotiable、Valuable、Estimable、Small、Testable）
2. 掃描七大反模式（洩漏實作細節、任務偽裝成 Story、模糊的受益者、Feature-First、按技術層切分、驗收標準規定 UI 設計、所有 Story 都是 P0）
3. 檢查驗收標準是否為 Outcome-Focused 而非 Implementation-Focused
4. 檢查優先序標記是否合理
```

Replace with:

```markdown
**核心職責：**

1. 對每個 Story 執行 INVEST 六項檢查（Independent、Negotiable、Valuable、Estimable、Small、Testable）
2. 掃描七大反模式（洩漏實作細節、任務偽裝成 Story、模糊的受益者、Feature-First、按技術層切分、驗收標準規定 UI 設計、所有 Story 都是 P0）
3. 檢查驗收標準是否為 Outcome-Focused 而非 Implementation-Focused
4. 檢查驗收標準的 AC 情境覆蓋度（Given-When-Then 格式、Happy/Error/Edge Path 覆蓋）
5. 檢查優先序標記是否合理
```

**Step 2: Add AC coverage check to the review flow**

Find this block (lines 50-56):

```markdown
**審查流程：**

1. 讀取 `references/05-invest-checklist.md` 與 `references/06-anti-patterns.md` 作為評判依據
2. 讀取待審查的 Stories 內容
3. 對每個 Story 逐一執行 INVEST 檢查，記錄 pass/fail
4. 對每個 Story 逐一比對反模式清單
5. 檢查驗收標準是否描述「What」而非「How」
6. 檢查是否有超過 30% 的 Stories 標記為 P0
7. 彙整審查結果
```

Replace with:

```markdown
**審查流程：**

1. 讀取 `references/05-invest-checklist.md`、`references/06-anti-patterns.md`、`references/03-acceptance-criteria.md` 作為評判依據
2. 讀取待審查的 Stories 內容
3. 對每個 Story 逐一執行 INVEST 檢查，記錄 pass/fail
4. 對每個 Story 逐一比對反模式清單
5. 檢查驗收標準是否描述「What」而非「How」
6. 檢查驗收標準的 AC 情境覆蓋度：
   - 是否使用 Given-When-Then 格式？
   - Given 是否只放前提條件？When 是否只有一個觸發動作？
   - 是否至少有 Happy Path 情境？
   - 是否有考慮 Error Path？（若明顯有錯誤情境但未涵蓋，標記為「需補充」）
   - 是否有考慮 Edge Case？（若有邊界情境但未涵蓋，標記為「建議補充」）
   - 每條情境是否具體到 QA 可直接寫測試？
7. 檢查是否有超過 30% 的 Stories 標記為 P0
8. 彙整審查結果
```

**Step 3: Add AC coverage output format**

Find this block (lines 79-103):

```markdown
**輸出格式：**

對每個 Story 輸出以下格式：

\```
## Story: [Story 標題]

### INVEST 檢查
- I (Independent): ✅/❌ [說明]
- N (Negotiable): ✅/❌ [說明]
- V (Valuable): ✅/❌ [說明]
- E (Estimable): ✅/❌ [說明]
- S (Small): ✅/❌ [說明]
- T (Testable): ✅/❌ [說明]

### 反模式掃描
- [命中的反模式及修正建議]

### 驗收標準檢查
- [Outcome-Focused 或 Implementation-Focused 判定]

### 整體評估
- 品質等級: 優/良/需修正
- 修正建議: [具體建議]
\```
```

Replace with:

```markdown
**輸出格式：**

對每個 Story 輸出以下格式：

\```
## Story: [Story 標題]

### INVEST 檢查
- I (Independent): ✅/❌ [說明]
- N (Negotiable): ✅/❌ [說明]
- V (Valuable): ✅/❌ [說明]
- E (Estimable): ✅/❌ [說明]
- S (Small): ✅/❌ [說明]
- T (Testable): ✅/❌ [說明]

### 反模式掃描
- [命中的反模式及修正建議]

### 驗收標準檢查
- [Outcome-Focused 或 Implementation-Focused 判定]

### AC 情境覆蓋度
- Happy Path: ✅/❌
- Error Path: ✅/❌/N/A [說明]
- Edge Case: ✅/❌/N/A [說明]
- Given-When-Then 格式正確性: ✅/❌ [說明]

### 整體評估
- 品質等級: 優/良/需修正
- 修正建議: [具體建議]
\```
```

**Step 4: Commit**

```bash
git add plugins/spec-writer/agents/spec-reviewer.md
git commit -m "docs: add AC scenario coverage checks to spec-reviewer agent"
```

---

### Task 7: Final verification and squash commit

**Step 1: Verify directory structure**

```bash
ls -R plugins/spec-writer/skills/spec-writing/
```

Expected output should show:
- `SKILL.md` at root
- `references/` with 01-08 files (no template files)
- `assets/` with user-story.md, enabler-story.md, spike.md

**Step 2: Verify no broken references**

Search for any remaining `references/user-story.md`, `references/enabler-story.md`, or `references/spike.md` references:

```bash
grep -r "references/user-story\|references/enabler-story\|references/spike" plugins/spec-writer/
```

Expected: no output (all references updated to `assets/`)

**Step 3: Review all changes since branching**

```bash
git log --oneline HEAD~6..HEAD
```

Verify 6 commits covering all tasks.
