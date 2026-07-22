---
name: file-based-issues
description: >-
  Methodology for operating a **file-based / local issue tracker** — a project
  where requirements/issues live as git-tracked folders of markdown + YAML
  frontmatter (the repo IS the SSOT), not in Jira / Linear / GitHub Issues.
  Covers the full lifecycle: 建單 with the project's collision-safe ID allocator
  (never hand-guess numbers), the issue-as-folder 結構 + frontmatter schema,
  in-place status 修改 / subtask nesting / milestone moves, the issue-body 模板,
  and status-drift 對帳 against release tags. It is discover-then-apply: it
  learns THIS repo's conventions (issues root, create-script, schema, reconcile
  tool) then applies portable invariants. Use this whenever a repo keeps issues
  as local markdown files and the user mentions 開 issue / 建單 / 開需求單 / 新增
  issue / 開子單 / 加 subtask / 改 issue 狀態 / 標 Done / issue 歸 milestone /
  狀態漂移 / 對帳 issue / issue 格式 / 本地 issue / 檔案式 issue / local issue
  tracker / issue:new-style script, even if they don't say the word "skill".
  NOT for Jira/Linear (use `jira-create-ticket` for Jira) and NOT for GitHub
  Issues driven through the API.
---

# 操作檔案式 / 本地化 Issue Tracker（file-based-issues）

有些專案不用 Jira/Linear，而是把需求／issue 當成**受 git 追蹤的 markdown + YAML frontmatter
資料夾**存在 repo 裡——repo 本身就是唯一真實來源（SSOT），狀態、關係、歷史全在檔案與 commit
裡。這種 tracker 靠人手維護，好處是零外部依賴、可 grep、改動即版本歷史；代價是**熵**：號碼會撞、
狀態會漂、frontmatter 會缺欄位。這個 skill 把「怎麼在這種 tracker 裡正確操作」的慣例編碼起來。

> **核心價值不是重講機制，而是編碼「陷阱」**：用專案的發號工具、別手動猜號；改狀態就地改、別搬
> 資料夾；完成的判定對得上 release。這些是每個檔案式 tracker 都會踩的雷，值得寫下來。

這是 **discover-then-apply**：不同專案的 ID 格式、建立腳本、schema 都不同，所以本 skill 先
**探出這個 repo 的慣例**（Step 0），再套用對所有檔案式 tracker 都成立的**不變量**。

## 什麼時候用（與不該用）

| 情境 | 用這個 skill？ | 改用 |
|---|---|---|
| repo 內 `issues/`（或類似）目錄，issue = markdown+frontmatter 資料夾、受 git 追蹤 | ✅ 是 | — |
| Jira 工單 | ❌ 否 | `jira-create-ticket` skill |
| Linear（已退役的專案） | ❌ 否 | 唯讀歷史，不要開/改 |
| GitHub Issues（透過 API/gh 操作） | ❌ 否 | `gh issue` / 對應工具 |
| 撰寫 user story / AC / story mapping 的方法論 | ❌ 否 | `spec-writing` skill（本 skill 只管 tracker 操作，不管內容品質） |

**判準**：issue 的真實來源是不是 **repo 內的檔案**？是 → 用本 skill。

---

## Step 0 — 探出這個 repo 的慣例（一律先做）

因為是通用 skill，動手前先花 1 分鐘讀出這個專案的具體規則，別假設：

1. **issues 根目錄**：通常 `issues/`；找找有無 `issues/README.md`（多半就是格式權威）與 `INDEX.md`（導覽）。
2. **建立工具**：`package.json` 的 `scripts` 裡找 `issue:new` 之類；或 `scripts/`、`bin/`、`.tools/`。
   有工具 → 一律用它建（它負責防撞發號）。**沒有工具才**退回手動。
3. **ID 格式與骨架**：開一個現有 issue 的 `index.md`，讀出 ID 前綴（如 `TIM-`、`PROJ-`）、
   frontmatter 欄位、內文分段慣例（如 背景／AC／範圍外）。
4. **狀態模型**：status 有哪些值（enum）？完成要不要補 `completed:`？「進行中」怎麼查（grep pattern）？
5. **對帳工具**：有沒有 reconcile / status-drift 腳本（如 `scripts/reconcile-*.mjs`）？

> 讀到的專案規則若與本 skill 的通則衝突，**以專案的 `issues/README.md` 與腳本為準**——本 skill 是通則，專案檔是特例權威。

已探明的專案可直接引用其設定；一份完整的實例見
[`references/example-admission-radar.md`](references/example-admission-radar.md)（`pnpm issue:new` + `TIM-` 的完整實作）。

---

## 通用不變量（所有檔案式 tracker 都成立）

這些是本 skill 最該記住的「別做」清單：

1. **用專案的發號工具，別手動猜號。** 好的實作會跨 worktree 原子防撞發號；手動 `find` 最大號 +1
   在多 worktree/多人並行時**必撞**。工具壞了才退回 fallback（見下）。
2. **ID 是不可變主鍵。** 它散落於 commit／branch／docs，改名＝斷連結。slug 可有損、可改，ID 不可。
3. **改狀態就地改，別搬資料夾。** issue = 資料夾＝穩定路徑；狀態只是 frontmatter 一行。搬檔會斷附件與連結。
4. **frontmatter 欄位補齊。** 缺欄位讓 grep/工具失準。用工具產骨架就有齊全欄位；手改別漏 `updated:`。
5. **狀態欄是 SSOT，INDEX 只是快照。** 別信 INDEX，信各 issue 的 frontmatter。
6. **變更走 git commit** ——修改紀錄即版本歷史，不需外部工具。

---

## 建單（create）

**Goal**：在對的位置、用防撞號建骨架，再填內容。

**Actions**：
1. 用專案的建立工具（探出的那支）。典型介面：
   `<tool> "<title>" [--<grouping> <m>] [--parent <ID>] [--label <l> ...]`
   （grouping 常叫 milestone/epic；parent 表示建成巢狀子單、群組多半繼承父的）。
2. title 建議帶類型前綴（`[Bug]`／`[Enabler]`／`[Epic]` 等，若專案有此慣例）；slug 通常會自動去前綴。
3. 工具會印出新 ID 與 `index.md` 路徑 → **打開它填內容**（見「模板」）。**別自己 mkdir 建資料夾。**
4. **Fallback（僅當工具真的不可用）**：掃現有最大號（如 `find issues -type d -name '<PREFIX>-*'`），
   交叉查遠端（`git ls-remote origin`）確認沒撞，手動建並照 schema 補齊 frontmatter。

## 結構（structure）

**Goal**：放對層級、命名一致。
**Actions**：
- 佈局通常是 `issues/<grouping>/<ID>-<slug>/index.md`，子單再巢狀一層。
- 父子關係用**目錄巢狀**表達，不寫進 frontmatter。
- slug 僅為可讀、可有損；唯一性由 ID 保證。
- 該 issue 的附件（截圖等）直接放進它的資料夾，路徑跟著 issue 走。

## 模板（template）

**Goal**：`index.md` 內文照專案慣例，需求／AC／範圍一眼可讀。
**Actions**：
- 工具產出的骨架含齊全 frontmatter（ID、title、status 預設值、時間戳、關係欄位）＋一行待填註解。
- 把待填註解換成專案的內文分段慣例。若專案無明訂，預設用可驗收的三段：
  ```markdown
  ## 背景
  <為什麼要做、現況、觸發此需求的問題>

  ## AC
  1. <可驗收、可勾稽的條件>

  ## 範圍外
  <明確排除，避免範圍蔓延>
  ```
- 只填該填的欄位；`completed:` 留空到真正 Done。

## 修改（modify）

**Goal**：改狀態、開子單、搬群組、維護關係，且不破壞主鍵與路徑穩定。
**Actions**：
- **改狀態**：就地編輯 `status:` 一行（用專案的 enum）；同步更新 `updated:`。**不搬資料夾。**
- **完成**：`status` 設完成值，並補 `completed: <YYYY-MM-DD>`（若專案有此欄）。
- **查詢**：`grep -rl 'status: <進行中值>' issues/`；找 label 同法 grep frontmatter。
- **開子單**：用建立工具的 `--parent <ID>`。
- **搬群組（milestone/epic）**：`git mv issues/<old>/<ID>-<slug> issues/<new>/`，並同步 frontmatter 的群組欄位。
- **關係欄位**：`related` / `blocks` / `blocked_by` 等平鋪陣列，值為 ID。

## 對帳（reconcile status drift）

檔案式 tracker 靠人手翻狀態，必然累積「早上線卻沒翻完成」的漂移。若專案有 reconcile 工具：

**Actions**：
- 先跑**唯讀報告**模式盤點候選（通常有個 `--fix` 開關做自動修）。
- 高精度判準通常是：status 仍未完成，但同名 ID 的**實作 commit**（`feat|fix|perf|refactor` 開頭、
  且該 ID 是 commit subject 第一個號）已進某個 release tag。
- **⚠ 候選 ≠ 一定該完成**：母單/Epic 只上線一片也會命中。自動修前先確認該 issue 範圍**全數完成**，
  改完 `git diff` 檢視再 commit。
- 沒有工具時，此步是人工 tidy-up；別自己臆測完成，需有 commit/release 證據。

---

## 速查

| 想做 | 做法 |
|---|---|
| 新增 issue | 專案建立工具 `"<title>" [--<grouping> <m>]`（別手動猜號） |
| 新增子單 | 建立工具 `"<title>" --parent <ID>` |
| 改狀態 | 就地改 `index.md` 的 `status:`（完成補 `completed:`、更新 `updated:`；不搬檔） |
| 看進行中 | `grep -rl 'status: <進行中值>' issues/` |
| 搬群組 | `git mv issues/<old>/<ID>-<slug> issues/<new>/` + 改 frontmatter |
| 狀態對帳 | 專案 reconcile 工具（先唯讀報告，再確認範圍後 `--fix`） |

## 權威來源

疑問一律先查該 repo 的 `issues/README.md`（格式）、`INDEX.md`（導覽）、`CLAUDE.md`（開發規則），
不要憑記憶。本 skill 是通則，三者衝突時**以 repo 內檔案為準**。
