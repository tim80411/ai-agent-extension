---
name: notion-publisher
description: >-
  Use this skill when the user asks to "發布到 Notion", "推送 Notion",
  "publish to Notion", "整合到 Notion", "上傳筆記", "放到 Notion",
  "sync to Notion", "更新 Notion",
  or needs to publish study notes, Q&A, and reading guides to Notion.
---

# Notion 發布器

將筆記、Q&A、導讀建議整合並推送到 Notion workspace。

## Phase 0: 資訊收集

**Goal**: 確認所有必要參數。

**Actions**:

1. 確認 Notion MCP 工具可用（嘗試列出 `mcp__claude_ai_Notion__*` 工具）。若不可用，通知用戶並停止

2. 檢查當前目錄是否有 `.study-progress.json`，若有則讀取所有已完成 Phase 的 output 檔案路徑

3. 使用 `AskUserQuestion` 一次確認以下資訊：

   - **目標 Notion 資料庫 URL**（必填，無法推斷）
   - **要發布的檔案**（預設：所有已完成 Phase 的 output 檔案。讓用戶確認或取消勾選）：
     - 筆記（`{chapter}-notes.md`）
     - Q&A（`{chapter}-qa.md`）
     - 導讀建議（`{chapter}-guide.md`）
   - **頁面標題**（預設：從筆記檔案的 `#` 標題取得）
   - **Concepts 標籤**（必填，無法推斷。例如 `PostgreSQL`、`Indexes`）
   - **日期**（預設：今天）

## Phase 1: 取得 Notion 資料庫結構

**Goal**: 了解目標資料庫的 schema。

**Actions**:

1. 使用 `mcp__claude_ai_Notion__notion-fetch` 取得資料庫結構
2. 記錄：
   - `data_source_id`（後續建立頁面用）
   - 資料庫屬性（Name、concepts、date 等）
   - 現有的 multi-select 選項

## Phase 2: 讀取 Notion Markdown 規格

**Goal**: 了解 Notion 的 Markdown 語法差異。

**Actions**:

1. 使用 `ReadMcpResourceTool` 讀取 `notion://docs/enhanced-markdown-spec`
2. 關鍵轉換規則：
   - **表格**：必須用 Notion XML 格式（`<table header-row="true"><tr><td>...</td></tr></table>`），不能用 Markdown pipe tables
   - **Toggle 區塊**：用 `<details><summary>標題</summary>` + tab 縮排的子內容 + `</details>`
   - **Toggle 標題**：用 `# heading {toggle="true"}` + 縮排子內容
   - **程式碼區塊**：保持原樣，不需要跳脫特殊字元
   - **跳脫字元**：一般文字中需跳脫 `\ * ~ \` $ [ ] < > { } | ^`，但程式碼區塊內不需要
   - **空行**：用 `<empty-block/>`（裸換行會被 Notion 吃掉）
   - **表格欄位內的角括號**：用 `&lt;` 和 `&gt;`

## Phase 3: 內容轉換

**Goal**: 將標準 Markdown 轉換為 Notion 相容格式。

**Actions**:

1. 讀取所有要發布的本地檔案（筆記、Q&A、導讀）
2. Spawn 一個 agent 做批量轉換（內容可能很長）：
   - 表格 → Notion XML table
   - Q&A 條目 → toggle 區塊（`<details><summary>Q1: 問題</summary>...`）
   - 保留 blockquote、粗體、程式碼區塊
   - 跳脫一般文字中的特殊字元
3. Agent 將轉換結果寫入 `.tmp` 暫存檔

## Phase 4: 建立或更新 Notion 頁面

**Goal**: 推送內容到 Notion。

**Actions**:

1. 使用 `mcp__claude_ai_Notion__notion-search` 檢查是否已有同名頁面
2. 若不存在：使用 `mcp__claude_ai_Notion__notion-create-pages` 建立新頁面
3. 若已存在：使用 `mcp__claude_ai_Notion__notion-update-page` 更新內容

### 建立頁面的參數結構

```json
{
  "parent": {
    "data_source_id": "{從 Phase 1 取得}"
  },
  "pages": [{
    "properties": {
      "Name": "{章節標題}",
      "concepts": "[\"主題1\", \"主題2\"]",
      "date:date:start": "YYYY-MM-DD",
      "date:date:is_datetime": 0
    },
    "icon": "{適當的 emoji}",
    "content": "{轉換後的 Notion Markdown 內容}"
  }]
}
```

### 資料庫屬性格式

- `Name`：頁面標題（字串）
- `concepts`：multi-select，使用 JSON 陣列字串格式 `"[\"PostgreSQL\"]"`
- `date:date:start`：ISO 日期（`YYYY-MM-DD`）
- `date:date:is_datetime`：`0` 表示僅日期，`1` 表示日期+時間

## Phase 5: 驗證

**Goal**: 確認發布結果。

**Actions**:

1. 使用 `mcp__claude_ai_Notion__notion-fetch` 讀回已建立的頁面
2. 確認內容結構正確
3. 回報頁面 URL 給用戶

## 進度更新

若存在 `.study-progress.json`，更新 Phase 6 狀態。
