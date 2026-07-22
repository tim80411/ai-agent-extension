---
name: code-quality-review
version: 1.0.0
description: >-
  This skill should be used when the user asks to "審查程式碼品質", "code quality review",
  "程式碼品質檢查", "六維度審查", "review code quality", "全面品質審查",
  "可讀性審查", "可測試性審查", "模組化審查", "避免意外審查",
  "難以誤用審查", "可重用性審查",
  "run code quality review", "品質掃描", "code review 六個面向",
  "code review", "review my code",
  or needs a comprehensive, multi-perspective code quality analysis
  covering readability, testability, surprises, misuse prevention,
  modularity, and reusability.
---

# 六維度程式碼品質審查

對目標程式碼執行六個獨立視角的平行審查，產出結構化的品質報告。

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
- [ ] Phase 0: 確定審查範圍
- [ ] Phase 1: 建立共用脈絡
- [ ] Phase 2: 平行審查（6 個 agent 同時執行）
- [ ] Phase 3: 彙整報告

---

## Phase 0: 確定審查範圍

**Goal**: 明確審查目標，避免範圍過大導致品質下降。

**Actions**:

1. 使用 `AskUserQuestion` 確認：
   - 審查目標：整個專案 / 特定模組 / 特定檔案？
   - 技術堆疊：框架、ORM、資料庫、快取等
   - 重點關注：是否有特別在意的面向？（例如安全性、可測試性）
   - 輸出格式：完整報告 / 僅嚴重+重要 / 僅特定視角？

2. 若使用者指定特定檔案，直接使用。若指定模組或整個專案，使用 Glob/Grep 識別核心檔案：
   - 按行數排序，找出最大的 service/controller
   - 識別安全關鍵路徑（auth、jwt、token、password）
   - 識別核心商業邏輯檔案

3. 確認最終的審查檔案清單（建議 10-20 個檔案為一批）。

4. 更新 todo，標記 Phase 0 完成。

---

## Phase 1: 建立共用脈絡

**Goal**: 建立所有 reviewer agent 共享的脈絡資訊。

**Required References**:
- `references/shared-context-template.md` — 共用脈絡模板與嚴重度定義

**Actions**:

1. 讀取 `references/shared-context-template.md`。

2. 收集專案資訊（按 `references/shared-context-template.md` 的步驟執行）：
   - 掃描 `package.json` 取得技術堆疊
   - 統計程式碼行數
   - 列出模組結構
   - 識別最複雜的檔案（行數最多、依賴最多）

3. 組裝共用脈絡區塊，包含：
   - 專案資訊與技術堆疊
   - 審查範圍（確切的檔案清單）
   - 嚴重度評級系統（來自 references）
   - 發現報告模板（來自 references）

4. 更新 todo，標記 Phase 1 完成。

---

## Phase 2: 平行審查

**Goal**: 啟動 6 個 reviewer agent 同時執行審查。

**CRITICAL**: 六個 agent 必須**同時啟動**（在同一個訊息中發出 6 個 Agent tool call），以最大化平行效率。

**Required References**:
每個 agent 會自行讀取對應的 checklist reference。

**Actions**:

1. 同時啟動以下 6 個 agent（使用 Agent 工具，在**同一個回應**中發出所有 6 個呼叫）：

   每個 agent 的 prompt 格式：
   ```
   請對以下程式碼執行 [視角名稱] 審查。

   ## 共用脈絡
   [Phase 1 組裝的共用脈絡]

   ## 審查指引
   [直接將對應 checklist reference 的完整內容嵌入此處，
    而非讓 agent 自行讀取 reference 檔案，以避免路徑問題]

   ## 審查目標檔案
   [檔案清單]

   ## 輸出要求
   1. 摘要表格（ID、檢查項、檔案、行號、嚴重度、工作量、摘要）
   2. 每個發現的詳細說明（使用發現報告模板）
   3. 使用繁體中文
   ```

   **IMPORTANT**: 在組裝 agent prompt 時，先讀取對應的 reference 檔案內容，
   將其完整嵌入 prompt 中。不要讓 agent 自行讀取 reference 檔案，
   因為 agent 的工作目錄是使用者的專案目錄，無法存取 plugin 內的 reference。

2. 等待所有 6 個 agent 完成。

3. 更新 todo，標記 Phase 2 完成。

---

## Phase 3: 彙整報告

**Goal**: 合併 6 份報告為統一的品質審查紀錄。

**Actions**:

1. 收集 6 個 agent 的輸出。

2. 建立總覽摘要表格：

   ```markdown
   | 審查視角 | 狀態 | 嚴重 | 重要 | 輕微 | 合計 |
   |----------|------|------|------|------|------|
   | 可讀性 (RD) | 已完成 | X | X | X | X |
   | ... | ... | ... | ... | ... | ... |
   | **合計** | **6/6 完成** | **X** | **X** | **X** | **X** |
   ```

3. 提取所有「嚴重」等級的發現，按影響範圍排序為**最高優先問題清單**。

4. 去重：若不同視角發現了相同檔案、相同行號的相同問題，保留嚴重度較高的版本，並在另一份中標記「見 [ID]」。

5. 組裝完整報告，結構為：
   - 總覽摘要（表格 + 最高優先問題）
   - 各視角報告（摘要表 + `<details>` 包裹的詳細發現）
   - 共用脈絡（程式碼統計、技術堆疊、嚴重度系統）

6. 將報告寫入 `code-quality-review-record.md`。

7. 向使用者呈現摘要和最高優先問題。

8. 更新 todo，標記 Phase 3 完成。

---

## 流程總覽

```
Phase 0: 確定審查範圍
  ↓ AskUserQuestion (目標範圍、技術堆疊、重點面向)
  ↓ 識別核心檔案清單

Phase 1: 建立共用脈絡
  ↓ 收集專案資訊
  ↓ 組裝共用脈絡區塊

Phase 2: 平行審查（6 個 agent 同時執行）
  ┌──────────┬──────────┬──────────┐
  │ RD       │ TB       │ AS       │
  │ 可讀性    │ 可測試性  │ 避免意外  │
  ├──────────┼──────────┼──────────┤
  │ HM       │ MD       │ RU       │
  │ 難以誤用  │ 模組化    │ 可重用性  │
  └──────────┴──────────┴──────────┘

Phase 3: 彙整報告
  ↓ 合併 6 份報告
  ↓ 建立總覽摘要 + 最高優先問題
  ↓ 去重 + 輸出完整報告
```

## 參考文件索引

- **`references/shared-context-template.md`** — 共用脈絡模板、嚴重度評級系統、發現報告模板
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
