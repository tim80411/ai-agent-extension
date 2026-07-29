---
name: file-based-issues
description: >-
  Methodology for operating a **file-based / local issue tracker** — a project
  where requirements/issues live as git-tracked folders of markdown + YAML
  frontmatter (the repo IS the SSOT), not in Jira / Linear / GitHub Issues.
  Covers the full lifecycle: 建單 with the project's collision-safe ID allocator
  (never hand-guess numbers), the issue-as-folder 結構 + frontmatter schema,
  in-place status 修改 / subtask nesting / milestone moves, the issue-body 模板,
  and status-drift 對帳 against release tags. Ships a zero-dependency
  collision-safe allocator (`issue-new.mjs`) for repos that have no create-script
  of their own, driven by per-project profiles in a global config
  (`~/.config/pm-toolkit/config.yaml`, managed via `pm-config.mjs`) that also
  records which projects use jira/github instead so they get routed away.
  It is config-first then discover-then-apply: it reads THIS repo's profile if
  registered, otherwise learns its conventions (issues root, create-script,
  schema, reconcile tool), then applies portable invariants. Use this whenever a repo keeps issues
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

運作方式是 **config-first, then discover**：不同專案的 ID 格式、建立腳本、schema 都不同，所以
先查全域設定檔有沒有這個專案的 profile（命中就直接拿設定），沒有才**探出這個 repo 的慣例**
（Step 0），最後套用對所有檔案式 tracker 都成立的**不變量**。

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

## Step 0a — 先問設定檔（最先做，一秒的事）

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/pm-config.mjs show --json
```

它會依 cwd 解析出對應的 profile，直接吐出 `issues_root`／`id_prefix`／`grouping`／`status`／
`sections`／`create_cmd`。**命中就跳過 Step 0b 的探勘**——設定檔就是已經探過的結果。

- **exit 4**（「找不到對應的 profile」或「找不到設定檔」）→ 這個專案還沒登記。
  **改用 [`init-tracker-config`](../init-tracker-config/SKILL.md) skill 走一次引導式登記**：
  它會掃 repo 推斷慣例、跟使用者確認 ID 前綴（不可變主鍵，不猜）、寫進設定檔並驗證。
  登記完再回來建單。使用者不想登記才退回 Step 0b 人工探勘。
- `handled_by_this_plugin: false` → 這個專案根本不是檔案式 tracker（見下方「跨 provider 路由」）。
- schema 見 [`references/config.md`](references/config.md)。

## Step 0b — 探出這個 repo 的慣例（設定檔沒命中才做）

動手前先花 1 分鐘讀出這個專案的具體規則，別假設：

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

## 跨 provider 路由

設定檔的 profile 有 `provider` 欄位，因為同一個人手上不會只有檔案式 tracker。本 skill
**只處理 `file-based`**；其餘只做辨識與轉介，不要硬套：

| `provider` | 本 skill | 該用什麼 |
|---|---|---|
| `file-based` | ✅ 全程處理 | 就是這份文件 |
| `jira` | ❌ 轉介 | `jira-cli` skill（或 Atlassian MCP） |
| `github` | ❌ 轉介 | `gh issue` / GitHub MCP |
| `linear` | ❌ 轉介 | Linear 自己的工具 |

`issue-new.mjs` 遇到非 file-based 的 profile 會**以 exit code 2 拒絕執行**並印出該用的工具——
這是刻意的閘門，避免在 Jira 專案的 repo 裡莫名其妙長出一個 `issues/` 資料夾。

---

## 通用不變量（所有檔案式 tracker 都成立）

這些是本 skill 最該記住的「別做」清單：

1. **絕不手動猜號。** 手動 `find` 最大號 +1 在多 worktree／多人並行時**必撞**，而且撞號後
   ID 已散進 commit 與 branch，收拾成本極高。依序找一個會原子發號的工具用（見「建單」的三階順序）。
2. **ID 是不可變主鍵。** 它散落於 commit／branch／docs，改名＝斷連結。slug 可有損、可改，ID 不可。
3. **改狀態就地改，別搬資料夾。** issue = 資料夾＝穩定路徑；狀態只是 frontmatter 一行。搬檔會斷附件與連結。
4. **frontmatter 欄位補齊。** 缺欄位讓 grep/工具失準。用工具產骨架就有齊全欄位；手改別漏 `updated:`。
5. **狀態欄是 SSOT，INDEX 只是快照。** 別信 INDEX，信各 issue 的 frontmatter。
6. **變更走 git commit** ——修改紀錄即版本歷史，不需外部工具。

---

## 建單（create）

**Goal**：在對的位置、用防撞號建骨架，再填內容。

**發號的三階順序**——由上而下，能用上一階就別用下一階：

**① 專案自帶的建立工具**（`create_cmd`，或 Step 0b 探到的那支）。它才是該專案的權威，
發號規則、schema、副作用都可能跟通用版不同。典型介面：
`<tool> "<title>" [--<grouping> <m>] [--parent <ID>] [--label <l> ...]`

**② 本 plugin 內建的通用發號**（專案沒有自己的工具時）：

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/issue-new.mjs "<title>" \
     [--group <g>] [--parent <ID>] [--label <l>]... [--dry-run] [--json]
```

依 profile 發號 + 建資料夾 + 產 frontmatter 骨架，印出 ID 與 `index.md` 路徑。防撞靠兩層：
`mkdir` 原子鎖 + `next = max(計數檔, 掃描最大號) + 1`——所以計數檔被砍、換機器、多 worktree
都不會退號重發。計數檔在 `~/.config/pm-toolkit/counters/<profile>.counter`（不在 `.git` 裡，
沒有 git 的專案照樣能用）。
**退出碼分流**——別只看訊息，看碼決定下一步：

| 碼 | 意思 | 下一步 |
|---|---|---|
| 0 | 建好了 | 打開印出的 `index.md` 填內容 |
| 2 | profile 的 provider 不是 file-based | 轉介到對應工具（見「跨 provider 路由」） |
| 3 | 專案自帶 `create_cmd` | 改跑它印出來的那支指令；真要覆寫才加 `--force` |
| 4 | 這個專案還沒登記 | 走 [`init-tracker-config`](../init-tracker-config/SKILL.md) skill |

`issues_root` 與分組目錄**不存在會自動建**，並把既有的兄弟目錄一起印出來——`--group` 打錯字時
一眼就看得到（例如既有 `m2-goal-discovery` 卻打成 `m2`）。要換回「打錯就擋下」的嚴格模式，
在 profile 設 `require_existing_group: true`。

**③ 手動建**——只在前兩階都不可用時。掃現有最大號（`find issues -type d -name '<PREFIX>-*'`）、
交叉查 `git ls-remote origin` 確認沒撞，再照 schema 補齊 frontmatter。
**這一階本質不安全**（掃描與建立之間有空窗），做完要立刻 commit 縮小撞號視窗，
並考慮把這個專案登記進設定檔，下次就能走 ②。

**其餘要點**：
- title 建議帶類型前綴（`[Bug]`／`[Enabler]`／`[Epic]` 等，若專案有此慣例）；slug 會自動去前綴。
- 拿到路徑後 **打開 `index.md` 填內容**（見「模板」）。**別自己 mkdir 建資料夾。**
- 不確定會建在哪，先 `--dry-run` 看一眼——它不會消耗號碼。

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
| 看這個專案的慣例 | `node ${CLAUDE_PLUGIN_ROOT}/scripts/pm-config.mjs show --json` |
| 列出所有登記的專案 | `pm-config.mjs list`（含各自的 provider） |
| 產設定檔範本 | `pm-config.mjs init` → `~/.config/pm-toolkit/config.yaml` |
| 新增 issue | ① 專案建立工具 ② `issue-new.mjs "<title>" [--group <g>]` ③ 手動（別手動猜號） |
| 新增子單 | 同上加 `--parent <ID>` |
| 先看會建在哪 | `issue-new.mjs "<title>" --dry-run`（不消耗號碼） |
| 改狀態 | 就地改 `index.md` 的 `status:`（完成補 `completed:`、更新 `updated:`；不搬檔） |
| 看進行中 | `grep -rl 'status: <進行中值>' issues/` |
| 搬群組 | `git mv issues/<old>/<ID>-<slug> issues/<new>/` + 改 frontmatter |
| 狀態對帳 | 專案 reconcile 工具（先唯讀報告，再確認範圍後 `--fix`） |

## 權威來源

由高到低：

1. **該 repo 內的檔案**——`issues/README.md`（格式）、`INDEX.md`（導覽）、`CLAUDE.md`（開發規則）、
   專案自帶的建立／對帳腳本。疑問一律先查這裡，不要憑記憶。
2. **設定檔的 profile**（`~/.config/pm-toolkit/config.yaml`）——它是「已經探過一次的結果」的快取，
   不是規則的來源。跟 repo 內檔案對不上時**以 repo 為準**，並順手把 profile 改正。
3. **本 skill**——只是通則，最先被推翻的一層。
