# Workflow Conventions

這份文件記錄 spec-writing 流程的操作規範，包含命名規則、Label 規則、Story ID 編號規則，以及模板對應關係。

---

## Story 標題命名規則

| Story 類型 | 標題格式 |
|-----------|----------|
| User Story | `[Story N] 名稱` |
| Enabler Story | `[Story N] 名稱 (Enabler)` |
| Spike | `[Spike] 名稱` |

- **N** 為專案流水號（全域唯一）
- 新增時取當前所有 Stories 中最大的 N 值 +1
- Spike 不佔用 Story 流水號

### 範例

```
[Story 1] 老師可透過專屬網址存取 AI 教學工具
[Story 2] API Key 安全化 (Enabler)
[Spike] 評估 Streaming Proxy 可行性
[Story 3] 學生可提交作業並即時收到 AI 回饋
```

---

## Labels 規則

每個 Story 應標記兩類 Label：

### 優先序

| Label | 意義 |
|-------|------|
| `P0` | 本 Sprint 必須完成，無此功能不可交付 |
| `P1` | 本 Sprint 高優先，應盡力完成 |
| `P2` | 本 Sprint 次優先，時間許可再做 |
| `P3` | 未來考慮，本 Sprint 不承諾 |

P3 可額外加 `optional` label。

### Story 類型

| Label | 對應類型 |
|-------|---------|
| `user-story` | User Story |
| `enabler` | Enabler Story |
| `spike` | Spike |

---

## Story ID 編號規則

1. 若 Phase 0 的 Context Summary 已記錄現有最大 ID，直接從該值 +1 開始
2. 若無既有資訊，詢問使用者：「目前 Backlog 中最大的 Story 編號是幾？若沒有則從 1 開始」
3. 同一次撰寫多個 Stories 時，按撰寫順序遞增分配，不跳號

---

## 模板對應關係

| Story 類型 | 模板檔案 |
|-----------|---------|
| User Story | `references/user-story.md` |
| Enabler Story | `references/enabler-story.md` |
| Spike | `references/spike.md` |

**使用方式**：用 `Read` 工具讀取對應模板，以模板結構為基底，將所有佔位符替換為實際內容。若某段落對當前 Story 不適用，整段移除（不保留空白佔位符）。
