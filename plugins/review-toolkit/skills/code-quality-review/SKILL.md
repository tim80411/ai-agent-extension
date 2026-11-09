---
name: code-quality-review
version: 1.1.0
description: >-
  This skill should be used when the user asks to "審查程式碼品質", "code quality review",
  "程式碼品質檢查", "六維度審查", "review code quality", "全面品質審查",
  "可讀性審查", "可測試性審查", "模組化審查", "避免意外審查",
  "難以誤用審查", "可重用性審查",
  "run code quality review", "品質掃描", "code review 六個面向",
  "code review", "review my code", "分級審查", "risk-tiered review",
  or needs a comprehensive, multi-perspective code quality analysis
  covering readability, testability, surprises, misuse prevention,
  modularity, and reusability.
---

# 六維度程式碼品質審查

依變更規模與敏感路徑分級，對目標程式碼執行最多六個獨立視角的平行審查，產出結構化的品質報告。預設只報「嚴重」與「重要」發現。

全程使用繁體中文與使用者互動。

## 審查視角總覽

| 代碼 | 視角 | 核心問題 | Agent |
|------|------|---------|-------|
| RD | 可讀性 | 其他開發者能快速理解嗎？ | `readability-reviewer` |
| TB | 可測試性 | 能輕易寫出單元測試嗎？ | `testability-reviewer` |
| AS | 避免意外 | 有沒有出乎意料的行為？ | `surprises-reviewer` |
| HM | 難以誤用 | API 是否容易被誤用？ | `misuse-reviewer` |
| MD | 模組化 | 模組邊界和職責清晰嗎？ | `modularity-reviewer` |
| RU | 可重用性 | 有重複程式碼或錯過的抽象嗎？ | `reusability-reviewer` |

## 開始前

建立 todo list 追蹤各階段進度：
- [ ] Phase 0: 確定審查範圍與風險分級
- [ ] Phase 1: 建立共用脈絡（含專案審查規則）
- [ ] Phase 2: 平行審查（依分級啟動 2–6 個 agent）
- [ ] Phase 3: 彙整報告

---

## Phase 0: 確定審查範圍與風險分級

**Goal**: 明確審查目標，並依風險決定要啟動哪些視角，避免範圍過大或成本浪費。

**Required References**:
- `references/risk-tiering.md` — 規模計算、敏感路徑、分級表

**Actions**:

1. 使用 `AskUserQuestion` 確認：
   - 審查目標：整個專案 / 特定模組 / 特定檔案？
   - 技術堆疊：框架、ORM、資料庫、快取等
   - 重點關注：是否有特別在意的面向？（例如安全性、可測試性）；有無專案自己的敏感路徑要補充
   - 輸出格式：預設「嚴重＋重要（建議）」/ 「完整（含輕微與建議）」/ 僅特定視角

2. 若使用者指定特定檔案，直接使用。若指定模組或整個專案，使用 Glob/Grep 識別核心檔案：
   - 按行數排序，找出最大的 service/controller
   - 識別安全關鍵路徑（auth、jwt、token、password）
   - 識別核心商業邏輯檔案

3. 確認最終的審查檔案清單（建議 10-20 個檔案為一批）。

4. 風險分級：
   - 若 `$ARGUMENTS` 或使用者訊息含 `--full` 或「全跑」，直接判 full。
   - 否則依 `references/risk-tiering.md` 計算規模與敏感路徑，決定 trivial／lite／full。
   - 以一行告知使用者分級結果（格式見 risk-tiering.md）。

5. 更新 todo，標記 Phase 0 完成。

---

## Phase 1: 建立共用脈絡

**Goal**: 建立所有 reviewer agent 共享的脈絡資訊，包含專案自己的審查規則。

**Required References**:
- `references/shared-context-template.md` — 共用脈絡模板、嚴重度定義、輸出門檻

**Actions**:

1. 讀取 `references/shared-context-template.md`。

2. 收集專案資訊（按 `references/shared-context-template.md` 的步驟執行）：
   - 掃描 `package.json` 取得技術堆疊
   - 統計程式碼行數
   - 列出模組結構
   - 識別最複雜的檔案（行數最多、依賴最多）

3. 讀取專案審查規則：
   - 依 `references/risk-tiering.md` 的規則算出 base。
   - 用 `git show <base>:REVIEW.md`、`git show <base>:AGENTS.md`、`git show <base>:CLAUDE.md` 讀取；檔案不存在就跳過。
   - 不是 git repo 時，改讀工作樹的同名檔，並註明「取自工作樹」。
   - 依模板填入「專案審查規則」區塊（優先序 REVIEW.md > AGENTS.md > CLAUDE.md，每檔最多前 150 行）。
   - 為什麼從 base 讀：避免 PR 作者在自己的分支改掉審查標準。

4. 組裝共用脈絡區塊，包含：
   - 專案資訊與技術堆疊
   - 專案審查規則
   - 審查範圍（確切的檔案清單）
   - 嚴重度評級系統（來自 references）
   - 發現報告模板與輸出門檻（來自 references）

5. 更新 todo，標記 Phase 1 完成。

---

## Phase 2: 平行審查

**Goal**: 依分級表啟動對應的 reviewer agent 同時執行審查（full 才是 6 個）。

**CRITICAL**: 分級表指定的 agent 必須**同時啟動**（在同一個訊息中發出所有 Agent tool call），以最大化平行效率。

**Required References**:
每個 agent 的 checklist 由你在組裝 prompt 時讀取並嵌入。

**Actions**:

1. 同時啟動分級表指定的 agent（使用 Agent 工具，在**同一個回應**中發出所有呼叫）：

   | 分級 | 啟動的 agent |
   |---|---|
   | trivial | AS、HM |
   | lite | AS、HM、TB、MD |
   | full | RD、TB、AS、HM、MD、RU |

   每個 agent 的 prompt 格式：
   ```
   請對以下程式碼執行 [視角名稱] 審查。

   ## 共用脈絡
   [Phase 1 組裝的共用脈絡]

   ## 專案審查規則
   [從共用脈絡帶入；若與審查指引衝突，以專案規則為準]

   ## 審查指引
   [直接將對應 checklist reference 的完整內容嵌入此處，
    而非讓 agent 自行讀取 reference 檔案，以避免路徑問題]

   ## 審查目標檔案
   [檔案清單]

   ## 輸出門檻
   [將 shared-context-template.md 的「輸出門檻」原文帶入；
    使用者選「完整」模式時，改為「回報所有嚴重度，輸出完整報告」]

   ## 輸出要求
   1. 摘要表格（ID、檢查項、檔案、行號、嚴重度、工作量、摘要）
   2. 每個發現的詳細說明（使用發現報告模板）
   3. 使用繁體中文
   ```

   **IMPORTANT**: 在組裝 agent prompt 時，先讀取對應的 reference 檔案內容，
   將其完整嵌入 prompt 中。不要讓 agent 自行讀取 reference 檔案，
   因為 agent 的工作目錄是使用者的專案目錄，無法存取 plugin 內的 reference。

2. 等待所有已啟動的 agent 完成。

3. 更新 todo，標記 Phase 2 完成。

---

## Phase 3: 彙整報告

**Goal**: 合併各份報告為統一的品質審查紀錄，主報告只放嚴重與重要發現。

**Actions**:

1. 收集已啟動 agent 的輸出。

2. 建立總覽摘要表格，只列有跑的視角；沒跑的視角列為「未執行（分級：<級別>）」：

   ```markdown
   | 審查視角 | 狀態 | 嚴重 | 重要 | 輕微 | 建議 | 合計 |
   |----------|------|------|------|------|------|------|
   | 可讀性 (RD) | 未執行（分級：trivial） | - | - | - | - | - |
   | 避免意外 (AS) | 已完成 | X | X | X | X | X |
   | ... | ... | ... | ... | ... | ... | ... |
   | **合計** | **N/N 完成** | **X** | **X** | **X** | **X** | **X** |
   ```

3. 提取所有「嚴重」等級的發現，按影響範圍排序為**最高優先問題清單**。

4. 去重：若不同視角發現了相同檔案、相同行號的相同問題，保留嚴重度較高的版本，並在另一份中標記「見 [ID]」。

5. 組裝報告，結構為：
   - 總覽摘要（表格 + 最高優先問題）
   - 各視角報告（只放嚴重＋重要；摘要表 + `<details>` 包裹的詳細發現）
   - 「可選改善」：輕微與建議收進 `<details>`，每項一行（ID、檔案:行號、一句話）；使用者選「完整」模式時，改為在各視角報告中完整呈現
   - 共用脈絡（程式碼統計、技術堆疊、嚴重度系統）

6. 將報告寫入 `code-quality-review-record.md`，檔案第一行加上：
   `> 分級：<級別>（<規模摘要>）｜啟動 agent：<清單>｜門檻：嚴重＋重要`
   （使用者選完整模式時，門檻寫「完整」。）

7. 向使用者呈現摘要和最高優先問題。

8. 更新 todo，標記 Phase 3 完成。

---

## 流程總覽

```
Phase 0: 確定審查範圍與風險分級
  ↓ AskUserQuestion (目標範圍、技術堆疊、重點面向、輸出格式)
  ↓ 識別核心檔案清單
  ↓ 風險分級：trivial / lite / full（--full 直接 full）

Phase 1: 建立共用脈絡
  ↓ 收集專案資訊
  ↓ 從 base branch 讀 REVIEW.md / AGENTS.md / CLAUDE.md
  ↓ 組裝共用脈絡區塊

Phase 2: 平行審查（agent 數依分級：trivial 2 / lite 4 / full 6）
  ┌──────────┬──────────┬──────────┐
  │ RD       │ TB       │ AS       │
  │ 可讀性    │ 可測試性  │ 避免意外  │
  ├──────────┼──────────┼──────────┤
  │ HM       │ MD       │ RU       │
  │ 難以誤用  │ 模組化    │ 可重用性  │
  └──────────┴──────────┴──────────┘
  trivial: AS、HM ／ lite: AS、HM、TB、MD ／ full: 全部

Phase 3: 彙整報告
  ↓ 合併各份報告（未執行的視角標註）
  ↓ 建立總覽摘要 + 最高優先問題
  ↓ 主報告僅嚴重＋重要，其餘收進「可選改善」
```

## 參考文件索引

- **`references/risk-tiering.md`** — 風險分級：規模計算、敏感路徑、分級表
- **`references/shared-context-template.md`** — 共用脈絡模板、嚴重度評級系統、發現報告模板、輸出門檻
- **`references/readability-checklist.md`** — 可讀性 (RD) 檢查項目與指導原則
- **`references/testability-checklist.md`** — 可測試性 (TB) 檢查項目與指導原則
- **`references/surprises-checklist.md`** — 避免意外 (AS) 檢查項目與指導原則
- **`references/misuse-checklist.md`** — 難以誤用 (HM) 檢查項目與指導原則
- **`references/modularity-checklist.md`** — 模組化 (MD) 檢查項目與指導原則
- **`references/reusability-checklist.md`** — 可重用性 (RU) 檢查項目與指導原則

## Agent 索引

- **`readability-reviewer`** — 可讀性審查 agent
- **`testability-reviewer`** — 可測試性審查 agent
- **`surprises-reviewer`** — 避免意外審查 agent
- **`misuse-reviewer`** — 難以誤用審查 agent
- **`modularity-reviewer`** — 模組化審查 agent
- **`reusability-reviewer`** — 可重用性審查 agent
