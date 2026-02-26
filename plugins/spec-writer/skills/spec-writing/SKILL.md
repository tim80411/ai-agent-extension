---
name: spec-writing
description: >-
  This skill should be used when the user asks to "撰寫 spec", "寫 user story",
  "寫 story", "撰寫需求規格", "write spec", "write user story",
  "撰寫驗收標準", "寫 acceptance criteria", "拆分 story", "拆解需求",
  "檢查 story 品質", "INVEST 檢查", "反模式掃描",
  "review my user stories", "break down a feature into stories",
  or needs guidance on spec writing methodology, story types,
  scoping, acceptance criteria, prioritization, or INVEST quality checks.
---

# Spec 撰寫方法論

引導撰寫高品質的 User Story、Enabler Story 與 Spike，並以 INVEST 標準確保品質。

全程使用中文與使用者互動。

## 開始前

建立 todo list 追蹤四個階段進度：
- [ ] Phase 0: Context Gathering
- [ ] Phase 1: Requirement Clarification
- [ ] Phase 2: Story Writing
- [ ] Phase 3: Quality Review

---

## Phase 0: Context Gathering

**Goal**: 在進入需求釐清前，取得所有可用的既有脈絡，避免在後續階段重複詢問。

**Actions**:

1. 使用 `AskUserQuestion` 工具，一次提出所有背景問題（避免多輪對話消耗 context window）：

   - 你是否有現成的需求文件、Spec、或 PRD？（若有，請提供檔案路徑或直接貼上內容）
   - 你是否有 Sprint 計劃文件、Backlog、或已存在的 User Stories？（若有，請提供路徑或貼上內容）
   - 這份 Spec 是針對哪個 Sprint 或 Milestone？（提供 Sprint 編號、期間、或目標即可）
   - 你的工作目錄是否有程式碼庫可以掃描，以幫助理解領域語言？

2. **等待使用者回答後再繼續。**

3. 若使用者提供了文件路徑或貼上內容：
   - 啟動 `context-reader` agent（via Task 工具）
   - Agent 任務：「請讀取以下文件並彙整摘要：[使用者提供的路徑或內容]」
   - Agent 須回傳：
     - 專案名稱與背景
     - 已知的需求或限制
     - 現有 Story ID 的最大編號（若有）
     - Sprint 目標或 Milestone 描述

4. 若使用者確認有程式碼庫：
   - 啟動 `codebase-explorer` agent（via Task 工具）
   - Agent 任務：「請掃描當前工作目錄，找出領域術語、既有 Story 編號、以及專案文件結構」
   - Agent 須回傳：
     - 領域術語清單（模組名稱、核心實體）
     - 現有 Story 編號水位（若有）
     - 文件資料夾結構

5. 彙整所有 agent 回傳的資訊，建立 **Context Summary**，供後續階段引用。
   若使用者無文件且無 codebase，直接建立空白 Context Summary 並進入 Phase 1。

6. 更新 todo，標記 Phase 0 完成。

---

## Phase 1: Requirement Clarification

**Goal**: 在撰寫任何 Story 之前，確保對目標、受益者、範圍邊界有明確共識。

**CRITICAL**: 這個階段不可跳過。若 Phase 0 已取得充分資訊，部分問題可以省略，但三個核心確認點必須明確。

**Required References**:
- `references/01-story-types.md` — 受益者類型與 Story 分類判斷
- `references/02-scoping.md` — No-gos 與 Appetite 定義方法

**Actions**:

1. 回顧 Phase 0 的 Context Summary。

2. 識別仍需確認的項目：
   - 受益者是否明確？
   - 期望成果是否能用一句話描述？
   - 範圍邊界（No-gos）是否已定義？

3. 針對尚未明確的項目，使用 `AskUserQuestion` 工具提問：
   - 這個需求的主要受益者是誰？（例如：終端使用者、開發團隊、PM）
   - 完成這項需求後，世界有什麼不同？請用一句話描述期望成果。
   - 這次「不做什麼」？請列出明確的 No-gos，避免範圍蔓延。

   （僅提問 Phase 0 尚未取得答案的項目）

4. **等待使用者回答後再繼續。**

5. 根據回答與 `references/01-story-types.md`，初步判斷需求將拆成哪些類型的 Stories，並向使用者確認判斷是否正確。

6. 若使用者說「你覺得怎樣就怎樣」，提供你的建議並取得明確確認。

**DO NOT PROCEED TO PHASE 2 UNTIL ALL THREE CORE ITEMS ARE CONFIRMED：**
受益者、期望成果、No-gos（或使用者明確說明「無 No-gos」）。

7. 更新 todo，標記 Phase 1 完成。

---

## Phase 2: Story Writing

**Goal**: 依據釐清後的需求，撰寫符合格式規範的 Stories。

**Required References**:
- `references/01-story-types.md` — Story 格式定義
- `references/03-acceptance-criteria.md` — Outcome-Focused 驗收標準撰寫原則
- `references/04-prioritization.md` — 優先序排定方法
- `references/08-workflow-conventions.md` — 標題命名、Label 規則、Story ID 編號規則、模板對應

**Actions**:

1. 讀取 `references/08-workflow-conventions.md`，確認命名與 Label 規則。

2. 依序處理每項需求：

   a. **判斷 Story 類型**（參照 `references/01-story-types.md`）：
      ```
      終端使用者能直接感受到？
        ├── 是 → User Story
        └── 否 → 能明確指出賦能了哪些 User Story？
                 ├── 能 → Enabler Story
                 └── 不確定 → Spike
      ```

   b. **讀取對應模板**：
      - User Story → `references/user-story.md`
      - Enabler Story → `references/enabler-story.md`
      - Spike → `references/spike.md`

   c. **填寫模板**，替換所有佔位符；不適用的段落整段移除。

   d. **套用命名規則**（來自 `references/08-workflow-conventions.md`）：
      - 取得當前最大 Story ID（來自 Phase 0 Context Summary 或從使用者確認）
      - 分配下一個編號

   e. **標記 Labels 與優先序**（參照 `references/04-prioritization.md`）。

3. 完成所有 Stories 草稿後，以清晰格式呈現給使用者確認。

4. 若使用者要求修改，根據反饋調整並再次確認。

5. **DO NOT PROCEED TO PHASE 3 UNTIL THE USER EXPLICITLY APPROVES THE DRAFT.**

6. 更新 todo，標記 Phase 2 完成。

---

## Phase 3: Quality Review

**Goal**: 確保所有 Stories 達到 INVEST 標準，且無常見反模式。

**DO NOT START WITHOUT USER APPROVAL FROM PHASE 2.**

**Required References**:
- `references/05-invest-checklist.md` — INVEST 六項標準
- `references/06-anti-patterns.md` — 七大反模式清單

**Actions**:

1. 啟動 `spec-reviewer` agent（via Task 工具）。
2. Agent 任務：「請對以下 Stories 進行 INVEST 逐條檢查與反模式掃描：[Phase 2 完成的 Stories 全文]。請讀取 references/05-invest-checklist.md 與 references/06-anti-patterns.md 作為評判依據。」
3. Agent 須回傳：
   - 每個 Story 的 INVEST 結果（pass/fail 逐項）
   - 命中的反模式及修正建議
   - 驗收標準是否 Outcome-Focused
   - 整體品質等級（優 / 良 / 需修正）

4. 向使用者呈現審查結果。

5. 若有需修正的 Story：
   - 使用 `AskUserQuestion` 詢問使用者：「立即修正 / 稍後修正 / 維持現狀」
   - **等待使用者回答後再繼續。**
   - 若有多個 Story 需修正，將所有問題合併在同一個 `AskUserQuestion` 呼叫中。
   - 若選擇立即修正，回到 Phase 2 針對特定 Story 調整，完成後重新觸發 Phase 3

6. 所有 Stories 達到「良」或「優」後，輸出最終版本。

7. 更新 todo，標記 Phase 3 完成。

---

## 流程總覽

```
Phase 0: Context Gathering
  ↓ AskUserQuestion (existing docs, sprint context, codebase?)
  ↓ [context-reader agent] ← 若有文件
  ↓ [codebase-explorer agent] ← 若有 codebase
  ↓ Build Context Summary

Phase 1: Requirement Clarification
  ↓ AskUserQuestion (beneficiary, outcome, no-gos)
  ↓ Story type pre-classification → user confirm
  ↓ GATE: user confirms understanding

Phase 2: Story Writing
  ↓ Per requirement: classify → read template → fill → assign ID → label
  ↓ Present draft to user
  ↓ GATE: user satisfied with draft

Phase 3: Quality Review
  ↓ [spec-reviewer agent]
  ↓ Present INVEST + anti-pattern results
  ↓ If issues → back to Phase 2 (targeted fix)
  ↓ Final output when all stories pass
```

## 參考文件索引

- **`references/01-story-types.md`** — User Story vs. Enabler Story 的定義、格式、範例
- **`references/02-scoping.md`** — 範圍界定方法（Shape Up pitch、No-gos、Appetite）
- **`references/03-acceptance-criteria.md`** — 驗收標準撰寫原則與好壞對比範例
- **`references/04-prioritization.md`** — 優先序排定方法
- **`references/05-invest-checklist.md`** — INVEST 六項檢查標準與實際操作方式
- **`references/06-anti-patterns.md`** — 常見反模式清單與修正方式
- **`references/07-frameworks-comparison.md`** — 各方法論比較（JTBD、Shape Up、Working Backwards）
- **`references/08-workflow-conventions.md`** — 標題命名、Label 規則、Story ID 編號規則、模板對應
