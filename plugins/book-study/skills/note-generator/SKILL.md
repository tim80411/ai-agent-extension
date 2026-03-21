---
name: note-generator
description: >-
  Use this skill when the user asks to "製作筆記", "建立學習筆記", "產生筆記",
  "generate notes", "create study notes", "做筆記", "讀書筆記",
  "幫我整理這份文件", "summarize this chapter",
  or provides a PDF/document and wants structured learning notes created from it.
  This skill reads source material and produces well-organized study notes
  in Traditional Chinese following strict formatting rules.
---

# 學習筆記生成器

從原始素材（PDF、網頁、文件）產生結構化的學習筆記。筆記以繁體中文撰寫，格式針對 Notion 最佳化。

## Phase 0: 資訊收集

**Goal**: 確認所有必要參數，避免腦補。

**Actions**:

1. 檢查當前目錄是否有 `.study-progress.json`，若有則從中讀取 `source` 和 `chapter` 作為預設值
2. 使用 `AskUserQuestion` 一次確認以下資訊（有預設值的顯示預設，讓用戶確認或修改）：

   - **原始素材路徑**（必填，無法推斷時必問）：PDF 檔案路徑、網頁 URL、或本地文件路徑
   - **學習單元名稱**（預設：從素材檔名推斷，如 `postgresql-17-ch11-indexes.pdf` → `ch11-indexes`）
   - **輸出目錄**（預設：當前工作目錄）

3. 讀取 `references/note-format-rules.md` 了解格式規範

## Phase 1: 素材讀取與結構分析

**Goal**: 完整讀取原始素材，識別章節結構。

**Actions**:

1. 根據素材格式讀取內容：
   - **PDF**: 使用 Read 工具的 `pages` 參數分批讀取（每次最多 20 頁）
   - **網頁**: 使用 WebFetch 取得內容
   - **本地文件**: 直接 Read
2. 識別主要章節、子章節的層次結構
3. 記錄各章節的核心主題

## Phase 2: 筆記生成

**Goal**: 根據格式規範產生結構化筆記。

**Actions**:

1. 讀取 `references/note-format-rules.md` 中的格式規範
2. 依照章節順序，為每個章節產生筆記內容
3. 對每個章節，根據內容性質決定適用的子區塊結構：

   **適合拆分為完整結構的章節**（描述具體功能/技術的章節）：
   - 定義
   - 使用情境
   - 優點
   - 缺點
   - 注意事項（列點格式）
   - Anti-Pattern（若原文有明確的「不要這樣做」）
   - 範例

   **不適合強制套用完整結構的章節**（入門說明、簡短概念、操作指南等）：
   - 保持原有的自然段落結構
   - 僅在需要時使用部分子區塊

4. 對於同一抽象層次的多個概念（如多種索引類型），建立比較表格
5. 從原文找出明確的 Anti-Pattern，嵌入到對應章節中（不集中到文末）
6. 去除重複：確保注意事項與 Anti-Pattern 之間沒有正反兩面重複描述同一件事

## Phase 3: 初次比對（可選）

**Goal**: 呼叫 note-reviewer agent 做一次快速比對。

**Actions**:

1. 若用戶同意，spawn `note-reviewer` agent 比對筆記與原文的覆蓋度
2. 根據 agent 回報的缺漏決定是否補充

## 輸出

- 檔案命名：`{chapter-name}-notes.md`
- 存放位置：當前工作目錄或用戶指定的目錄
- 若存在 `.study-progress.json`，更新 Phase 1 狀態為 completed
