---
name: study
description: >-
  讀書會學習流程的主要入口。引導用戶依序完成筆記產生、閱讀、比對增補、Q&A 調查、導讀建議、Notion 發布等階段。
  支援進度追蹤，可隨時查看或跳轉到特定階段。
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
  - Skill
  - Bash
argument-hint: "[chapter-name] 或不帶參數查看進度"
---

# /study Command

## 行為

1. **讀取進度檔案**：在當前工作目錄尋找 `.study-progress.json`。若不存在，詢問用戶建立新的學習單元。

2. **顯示進度總覽**：列出所有 Phase 及其狀態（未開始 / 進行中 / 已完成）。

3. **引導下一步**：使用 `AskUserQuestion` 讓用戶選擇要執行的 Phase。

## Phase 定義

| Phase | 名稱 | 執行方式 | 產出 |
|-------|------|---------|------|
| 1 | 產生筆記 | 呼叫 `note-generator` skill | `{chapter}-notes.md` |
| 2 | 人工閱讀 | 用戶自行標記完成 | 無（狀態更新） |
| 3 | 比對增補 | 呼叫 `note-reviewer` agent | 筆記更新 |
| 4 | Q&A 調查 | 呼叫 `qa-investigator` skill | `{chapter}-qa.md` |
| 5 | 導讀建議 | 呼叫 `reading-guide` skill | `{chapter}-guide.md` |
| 6 | 發布 Notion | 呼叫 `notion-publisher` skill | Notion 頁面 |

## 進度檔案格式

`.study-progress.json` 結構：

```json
{
  "chapter": "ch11-indexes",
  "source": "docs/postgresql-17-ch11-indexes.pdf",
  "created_at": "2026-03-15",
  "phases": {
    "1_note_generation": { "status": "completed", "output": "ch11-indexes-notes.md" },
    "2_reading": { "status": "completed" },
    "3_review": { "status": "in_progress" },
    "4_qa": { "status": "not_started" },
    "5_guide": { "status": "not_started" },
    "6_publish": { "status": "not_started" }
  }
}
```

## 初始化流程

若沒有 `.study-progress.json`，或用戶帶了新的 chapter-name 參數：

1. 使用 `AskUserQuestion` 詢問：
   - 學習單元名稱（例如 `ch11-indexes`）
   - 原始素材路徑或 URL（支援 PDF、網頁、其他格式）
2. 建立 `.study-progress.json`
3. 詢問是否立即開始 Phase 1

## Phase 切換規則

- Phase 1 完成後，自動 spawn `note-reviewer` agent 做初次比對（背景執行）
- Phase 2 → 3 → 4 → 5 → 6 可任意跳轉，不強制順序
- 用戶可隨時重新執行任何 Phase（覆蓋或追加）
