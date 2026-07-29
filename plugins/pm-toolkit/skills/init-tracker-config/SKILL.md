---
name: init-tracker-config
description: >-
  Register the CURRENT project into the global pm-toolkit config
  (`~/.config/pm-toolkit/config.yaml`) so issue tooling knows this repo's
  conventions — issues root, immutable ID prefix, grouping axis, status enum,
  body sections, and whether the project has its own create-script. Works by
  scanning the repo for evidence, confirming the judgement calls with the user
  (never guessing an ID prefix, which is an immutable primary key), then writing
  and verifying the profile. Also registers non-file-based projects
  (`provider: jira / github / linear`) so tooling routes them away instead of
  creating stray `issues/` folders. Use when `issue-new.mjs` or
  `pm-config.mjs` exits with code 4 / says 「找不到對應的 profile」or 「找不到設定檔」,
  and whenever the user says 登記這個專案 / 設定 pm-toolkit / 初始化 issue 設定 /
  這個專案還沒登記 / 建 config / init config / 設定 tracker / register this repo /
  setup issue tracker config. NOT for creating issues themselves — that is
  `file-based-issues`.
---

# 登記專案到 pm-toolkit 設定檔（init-tracker-config）

`file-based-issues` 的工具鏈靠一份全域設定檔認得每個專案的慣例。這個 skill 負責**把一個專案登記進去**——
掃 repo 找證據、跟使用者確認判斷題、寫入、驗證。登記一次，之後建單就不必再探勘。

> **為什麼要有這個 skill 而不是讓腳本自己猜**：`id_prefix` 是**不可變主鍵**，它會散進資料夾名、
> commit message、branch 名。猜錯的收拾成本遠高於問一句。腳本只做確定性的推斷與寫入，
> 判斷題交給這裡跟人確認。

## 什麼時候會走到這

| 觸發 | 情境 |
|---|---|
| `issue-new.mjs` 回傳 **exit 4** | 這台機器沒設定檔，或這個專案沒登記 |
| `pm-config.mjs show` 說「找不到對應的 profile」 | 同上 |
| 使用者直接說「登記這個專案」「設定一下 pm-toolkit」 | 主動登記 |

---

## Step 1 — 掃描（唯讀，不寫任何東西）

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/pm-config.mjs detect --json
```

它從 repo 根往下掃 5 層，找形如 `<PREFIX>-<n>-<slug>/` 的資料夾，推斷出：

| 欄位 | 推斷依據 |
|---|---|
| `idPrefix` | 現存 issue 資料夾出現最多次的前綴 |
| `issuesRoot` | 所有 issue 資料夾父目錄的最長共同前綴 |
| `grouping` | 分組目錄名去比對現存 `index.md` 的 frontmatter，**哪個欄位的值等於目錄名**就是它 |
| `status` | 現存 `index.md` 實際出現過的 `status:` 值 |
| `sections` | 最新一張 issue 的 `##` 標題 |
| `createCmd` | `package.json` 有沒有 `issue:new` 之類的 script（順便認 pnpm/yarn/npm） |
| `match` | 有 origin 就用 `owner/repo`，否則用 repo 絕對路徑 |

`evidence.issuesFound` 告訴你推斷有多少證據撐著——**這個數字是判讀的關鍵**。

## Step 2 — 確認判斷題（用 AskUserQuestion，別自己決定）

依 `detect` 的結果分三種走法：

### (a) `ok: true` 且 `issuesFound` 夠多 → 確認即可
把推斷結果整理成表給使用者看，用 **AskUserQuestion** 問一題「照這樣登記，還是要改哪一項？」。
證據充足時 `idPrefix` 幾乎不會錯（它是從現存資料夾數出來的），重點反而是確認：
- `grouping` 推對了嗎？（`null` = 不分組；推成 `milestone` 但實際叫 `epic` 要改）
- `status.initial` 是不是真的新單起始值——detect 只看得到「出現過的值」，看不出哪個是起點
- 有 `createCmd` 的話提醒使用者：登記後內建發號會**讓位**給那支（這通常是對的）

### (b) `ok: false, need: "id_prefix"`（exit 4）→ **必須問**
repo 裡一張 issue 都沒有，沒有任何證據可推。用 **AskUserQuestion** 問前綴，選項給：
- 專案名縮寫（如 `admission-radar` → `AR`）
- 專案名全大寫去符號（`ADMISSIONRADAR`）
- 沿用團隊既有 Jira/Linear key（若使用者有）

問的時候**明講這是不可變主鍵**，之後改名等於斷掉所有 commit／branch 的連結。
拿到答案後可以 `detect --json --id-prefix <X>` 再跑一次補齊其餘欄位。

### (c) 這個專案根本不是檔案式 tracker → 登記成轉介用的 profile
使用者說「這專案用 Jira」之類時，不要建 `issues/`。直接跳 Step 3，payload 寫：

```json
{"profileName": "some-backend", "provider": "jira",
 "match": {"git_remote": "yourorg/some-backend"},
 "settings": {"project_key": "ABC"}}
```

之後 `issue-new.mjs` 在這個 repo 會以 exit 2 拒絕並指向 `jira-cli`——這正是目的。

## Step 3 — 寫入

把 Step 2 確認過的 JSON 交給 `add`（**附加**寫入，不會洗掉設定檔裡既有的註解與排版）：

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/pm-config.mjs add --json '<確認過的 json>'
```

- 設定檔不存在會自動建。
- profile 同名已存在會拒絕（要改請直接編輯設定檔，別重複登記）。
- 寫完會立刻讀回驗證，壞掉的 config 不會留在磁碟上。

## Step 4 — 驗證（一定要做，別只信寫入成功）

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/pm-config.mjs show --json     # 確認 cwd 真的解析到新 profile
node ${CLAUDE_PLUGIN_ROOT}/scripts/issue-new.mjs "驗證用" --dry-run   # 不消耗號碼
```

`show` 的 `matched_by` 會說是靠什麼命中的（git remote／路徑／目錄同名）。如果顯示「找不到」，
代表 `match` 寫得不對——常見是 repo 有多個 remote，或使用者實際工作在 worktree 而非主 clone。

`--dry-run` 印出的路徑與 ID 就是真的建單時會落地的位置。跟使用者確認長得對，才算完成。

---

## 邊界

- 只管**登記設定**。建 issue、改狀態、對帳是 `file-based-issues` skill。
- 只寫 `~/.config/pm-toolkit/config.yaml`（或 `$PM_TOOLKIT_CONFIG`）。不碰專案 repo 裡的任何檔案。
- 想把某個專案綁死不靠推測，可在專案根放 `.pm-toolkit-profile`（內容 = profile 名）——
  它的優先序高於所有 `match` 規則。

設定檔完整 schema 見
[`../file-based-issues/references/config.md`](../file-based-issues/references/config.md)。
