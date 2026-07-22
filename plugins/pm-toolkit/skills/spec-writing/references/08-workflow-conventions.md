# Workflow Conventions

這份文件記錄 spec-writing 流程的操作規範，包含命名規則、Label 規則、Story ID 編號規則、檔案結構、Frontmatter 規格，以及模板對應關係。

---

## 檔案結構規範

每個 Story 獨立成一個 `.md` 檔案，放在所屬 spec 的子目錄中：

```
.project/specs/{spec-slug}/
├── _overview.md                    # spec 總覽（Story Map、No-gos、修訂紀錄）
├── story-{N}-{slug}.md             # 各 Story 獨立檔案
├── story-{N}-{slug}.md
└── ...
```

### 命名規則

| 檔案類型 | 命名格式 | 範例 |
|----------|---------|------|
| Spec 總覽 | `_overview.md` | `_overview.md` |
| User Story | `story-{N}-{slug}.md` | `story-82-qr-code.md` |
| Enabler Story | `story-{N}-{slug}.md` | `story-76-lan-ip.md` |
| Spike | `spike-{slug}.md` | `spike-ipc-bridge.md` |

- `{N}` 為 Story 流水號
- `{slug}` 為標題的簡短 kebab-case 表示

---

## Frontmatter 規格

每個 Story 檔案**必須**有 YAML frontmatter，包含以下欄位：

```yaml
---
story_id: 82                    # Story 流水號（必填）
title: "在站點區網分享區域顯示 QR Code"  # 完整標題（必填）
type: user-story                # user-story | enabler | spike（必填）
priority: P1                    # P0 | P1 | P2 | P3（必填）
labels: []                      # 額外 Labels（選填）
tracker_type: linear            # linear | jira | null（選填，sync 後填入）
tracker_id: TIM-51              # 外部系統 Issue ID（選填，sync 後填入）
synced_at: 2026-03-21T07:06:51Z # 最後同步時間 ISO-8601（選填，sync 後填入）
---
```

### 欄位說明

| 欄位 | 必填 | 說明 |
|------|------|------|
| `story_id` | 是 | Story 流水號，全域唯一 |
| `title` | 是 | 完整中文標題 |
| `type` | 是 | Story 類型：`user-story`、`enabler`、`spike` |
| `priority` | 是 | 優先序：`P0`、`P1`、`P2`、`P3` |
| `labels` | 否 | 額外標籤陣列 |
| `tracker_type` | 否 | Issue Tracker 類型，sync 後自動填入 |
| `tracker_id` | 否 | 外部系統的 Issue ID，sync 後自動填入 |
| `synced_at` | 否 | 最後同步時間（ISO-8601），sync 後自動填入 |

**sync 相關欄位**（`tracker_type`、`tracker_id`、`synced_at`）在撰寫階段留空或省略，由 Phase 2.5 的 Tracker Sync 步驟自動填入。

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
| User Story | `assets/user-story.md` |
| Enabler Story | `assets/enabler-story.md` |
| Spike | `assets/spike.md` |

**使用方式**：用 `Read` 工具讀取對應模板，以模板結構為基底，將所有佔位符替換為實際內容。若某段落對當前 Story 不適用，整段移除（不保留空白佔位符）。驗收標準須使用 Given-When-Then 情境格式（詳見 `references/03-acceptance-criteria.md`）。

### Frontmatter 填寫規則

- `story_id`、`title`、`type`、`priority` 在 Phase 2 撰寫時填入
- `tracker_type`、`tracker_id`、`synced_at` 在 Phase 2.5 Tracker Sync 時填入
- 模板中的佔位符 `＿＿` 必須全部替換為實際值
