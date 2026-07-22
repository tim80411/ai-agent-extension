# 完整實例：admission-radar 的檔案式 issue tracker

SKILL.md 描述的是**通則**；這裡是一份**完整實作**，示範 Step 0 探完後長什麼樣、通用不變量
對應到哪些具體命令。其他專案的細節會不同——把這當「一個填好的範本」，不是唯一答案。

## 這個實例的 Step 0 對照表

| 通則概念 | admission-radar 的具體 |
|---|---|
| issues 根目錄 | `issues/`（`issues/README.md` 為格式權威、`INDEX.md` 為導覽） |
| SSOT | 本地 `issues/`（2026-06 從 Linear 全量遷移，Linear 退役、僅留 `linear_url` 歷史連結） |
| 建立工具 | `pnpm issue:new`（`src/modules/issues/issue-new.ts` + `allocator.ts`） |
| ID 格式 | `TIM-<n>`（保留 Linear 原編號，主鍵、不可改） |
| 群組軸 | milestone 資料夾：`uncategorized/`、`m1-billing/`、`m2-goal-discovery/`、`m3-placement/`、`m4-growth-marketing/` |
| status enum | `Backlog \| Todo \| In Progress \| In Review \| Done \| Canceled \| Duplicate` |
| 內文慣例 | `## 背景`、`## AC`、`## 範圍外` |
| 對帳工具 | `pnpm issue:reconcile`（`scripts/reconcile-issue-status.mjs`） |

## 目錄結構（3 層）

```
issues/
  README.md                      # 格式權威
  INDEX.md                       # 導覽（依 status 分組；產生物、可能落後、可重建）
  <milestone>/                   # layer 1
    TIM-<n>-<slug>/              # layer 2：story（一 issue = 一資料夾）
      index.md
      <assets...>                #   截圖／附件
      TIM-<m>-<slug>/            # layer 3：subtask（巢狀、非必須）
        index.md
```

## 建單

```bash
pnpm issue:new "<title>" [--milestone <m>] [--parent TIM-<n>] [--label <l> ...]
```
- `--milestone` 預設 `uncategorized`；目標資料夾須已存在（否則工具列出可用值報錯）。
- `--parent TIM-<n>`：建成子單、巢狀在父下；milestone 繼承父的 layer-1 目錄，`--milestone` 被忽略。
- `--label` 可重複。title 帶 `[類型]` 前綴，slug 自動去前綴。
- 印出 `TIM-<n>` 與 `index.md` 路徑到 stdout。
- **防撞發號機制**：號碼由 `<git-common-dir>/admission-radar-issue-counter` 共享計數檔 + lock-dir
  （`mkdir` 當鎖、30s 視殘留、2s timeout）原子分配，跨所有 worktree；`next = max(counter, scanMax)+1`
  （`scanMax` 遞迴掃現有 `TIM-<n>-` 取最大，計數檔遺失也不退號）。Env override：`ISSUES_ROOT`、`ISSUE_COUNTER_PATH`。
- Fallback（工具壞了）：`find issues -type d -name 'TIM-*'` 找最大號，交叉查 `git ls-remote origin` 後手動建。

## frontmatter schema

```yaml
---
id: TIM-349                      # 主鍵，= 資料夾前綴
title: "..."                     # 原始標題（含 [類型] 前綴）
status: Backlog                  # 見上 enum
milestone: uncategorized         # = layer-1 資料夾名（搬檔時兩者同步）
labels: ["P1", "Feature"]        # 平鋪；P0/P1/P2 + user-story/Enabler + Feature/Improvement/Bug
created: 2026-06-28
updated: 2026-06-28              # 每次實質修改都更新
completed:                       # 完成日（Done 才填）
related: ["TIM-300"]
blocks: []
blocked_by: []
linear_url: "https://..."        # 僅遷移的舊單有；新單無此欄
git_branch: "tim80411/tim-349-..."   # issue:new 建立時的當前分支
---
```

新單骨架（`renderIndexMd`）：frontmatter 齊全、`status: Backlog`、`# 標題` + 一行 `<!-- 描述、AC、範圍寫這裡 -->`。

## 修改

- 改狀態：就地編輯 `status:` + `updated:`；**不搬檔**。完成補 `completed:`。
- 看進行中：`grep -rl 'status: In Progress' issues/`；找 label：`grep -rl 'labels:.*P0' issues/`。
- 搬 milestone：`git mv issues/<old>/TIM-<n>-<slug> issues/<new>/` + 改 frontmatter `milestone:`。

## 對帳 `pnpm issue:reconcile`（`scripts/reconcile-issue-status.mjs`）

```bash
pnpm issue:reconcile                 # 唯讀報告漂移候選
pnpm issue:reconcile --fix           # 自動把非-Epic 候選翻 Done + 補 completed
node scripts/reconcile-issue-status.mjs --released v1.22.0   # 只看單一版（release 自動化用）
```
- 零外部依賴（只讀 git 與 `issues/*.md`），CI 免 `pnpm install`。
- 漂移＝status ∈ 未完成，但同名實作 commit（`feat|fix|perf|refactor` 開頭、且該 `TIM-<n>` 是 subject
  第一個號）已進 `v*` release tag。`[Epic]` 開頭 title 一律排除。旗標另有 `--github-summary`。
- 候選 ≠ 一定該 Done：增量修復也會命中；翻新前確認範圍全完成，`git diff` 後再 commit。

## 相關（住在 admission-radar repo 的 `.claude/skills/`，非本 marketplace）

`admission-source-build`、`admission-history-crawl`、`admission-taxonomy-design`——admission-radar 的
資料層方法論 skill。另 `catalog:apply-issue`（`catalog:*` 命名空間）是每張 issue 的資料修正腳本，
**不屬**本 skill 範圍。
