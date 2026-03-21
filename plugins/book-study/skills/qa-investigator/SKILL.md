---
name: qa-investigator
description: >-
  Use this skill when the user asks to "調查問題", "研究這個概念",
  "為什麼會這樣", "深入了解", "investigate", "research this",
  "回答問題", "Q&A", "幫我查", "這是什麼意思",
  or raises questions about study material that need deeper investigation
  beyond what the notes cover. Also triggered when user has a list of
  questions in a notes file and wants them all investigated.
---

# Q&A 調查器

接收用戶的疑問，調查原始碼、文件、網路資源，產生結構化的 Q&A 回答。

## Phase 0: 資訊收集

**Goal**: 確認所有必要參數。

**Actions**:

1. 檢查當前目錄是否有 `.study-progress.json`，若有則讀取：
   - `source`（原始素材路徑）
   - `chapter`（學習單元名稱，用於推斷檔案名稱）
   - Phase 1 的 `output`（筆記檔案路徑）
   - Phase 4 的 `output`（已存在的 Q&A 檔案路徑）

2. 使用 `AskUserQuestion` 確認：

   - **疑問來源**（必填）：
     - 直接在對話中提問
     - 疑問清單檔案（提供路徑）
   - **原始素材路徑**（預設：從 `.study-progress.json` 的 `source` 取得）
   - **筆記檔案路徑**（預設：從 `.study-progress.json` 的 Phase 1 output 取得。用於提供 agent 調查的背景脈絡）
   - **Q&A 檔案處理方式**（若已存在 Q&A 檔案）：追加新問題 / 覆蓋重寫

## Phase 1: 收集疑問

**Goal**: 確定所有需要調查的問題。

**Actions**:

1. 若用戶直接提問：記錄問題，進入 Phase 2
2. 若用戶指向疑問清單檔案：
   - 讀取檔案，列出所有問題
   - 使用 `AskUserQuestion` 確認是否全部調查，或讓用戶挑選

## Phase 2: 平行調查

**Goal**: 以原文為基礎，對每個問題進行深入調查。

**Actions**:

1. 對每個問題 spawn 一個 agent（使用 `Agent` 工具，`run_in_background: true`）
2. 每個 agent 的 prompt 必須包含：
   - 原始問題文字
   - 相關的原文段落（從筆記或原始素材中擷取）
   - 調查指令：以原文為基礎，用 WebSearch/WebFetch 查找更深入的資訊
   - 引用要求：所有內容必須有可參考的來源
   - 語言要求：繁體中文
3. 等待所有 agent 完成

## Phase 3: 整合輸出

**Goal**: 將所有調查結果整合為結構化的 Q&A 文件。

**Actions**:

1. 彙整各 agent 的調查結果
2. 以統一格式寫入 Q&A 檔案

## 輸出格式

檔案命名：`{chapter-name}-qa.md`

```markdown
# {章節標題} Q&A

---

## Q1: {問題標題}

### {子標題}

{回答內容}

- 使用表格比較不同情境
- 使用程式碼區塊示範具體案例
- 粗體標記關鍵概念

> **來源**：{引用來源，如文件章節、原始碼路徑、技術文章 URL}

---

## Q2: {問題標題}
...
```

### 格式規則

- 標題：`## Q{N}: {問題標題（繁體中文）}`
- 子標題：`###` 用於組織回答的不同面向
- 表格：比較不同情境、選項、行為差異
- 程式碼區塊：具體範例，指定語言
- 粗體：關鍵概念和強調
- 來源引用：每個問題結尾用 `> **來源**：...` 格式標註
- 分隔線：問題之間用 `---` 分隔
- 語言：繁體中文，技術術語保留英文

## 進度更新

若存在 `.study-progress.json`，更新 Phase 4 狀態。
