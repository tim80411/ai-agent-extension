# pm-toolkit

個人專案管理工具集（personal PM toolkit）。收納在此 marketplace，供跨機器安裝使用。

> 命名說明：刻意**不**叫 `project-management`，以免與已安裝的 Nani 工作用 `project-management`
> plugin（owner: Nani Team, bitbucket rd-oneclass/nani_skill）撞 plugin 名／skill 命名空間。

## Skills

| Skill | 用途 |
|---|---|
| [`file-based-issues`](skills/file-based-issues/SKILL.md) | 操作**檔案式／本地化 issue tracker**（issue = git 追蹤的 markdown+frontmatter 資料夾、repo 即 SSOT）的通用方法論：建單／結構／修改／模板／狀態對帳。附一份 admission-radar 的完整實例。 |
| [`init-tracker-config`](skills/init-tracker-config/SKILL.md) | 把一個專案**登記進全域設定檔**：掃 repo 推斷慣例 → 跟使用者確認（ID 前綴是不可變主鍵，不猜） → 寫入 → 驗證。建單遇到 exit 4 就是要走這裡。 |
| [`spec-writing`](skills/spec-writing/SKILL.md) | Spec／User Story 撰寫方法論：釐清需求、Given-When-Then 驗收、INVEST 檢查與反模式掃描，產出給 coding agent 照著做的檔案式 Story。 |
| [`jira-ticket-authoring`](skills/jira-ticket-authoring/SKILL.md) | **規劃型 Jira 工單**（Story／Task）的撰寫與開單：查 → 集中提問 → 出草稿並確認 → 列待裁示 → 建單 → 回查回報，含 9 節描述格式、九條寫法規則與批次草稿交付。專案參數記在本機的專案快照 `~/.config/pm-toolkit/jira/{專案代號小寫}.md`（不進 repo）。 |

## Scripts

零依賴（只要 node），不需 `npm install`。

| 腳本 | 用途 |
|---|---|
| [`scripts/pm-config.mjs`](scripts/pm-config.mjs) | 管理 `~/.config/pm-toolkit/config.yaml`：`init`／`list`／`show --json`／`detect --json`（唯讀推斷 repo 慣例）／`add --json`（附加寫入，保留註解） |
| [`scripts/issue-new.mjs`](scripts/issue-new.mjs) | 通用防撞建單：發號＋建資料夾＋依 profile 產 frontmatter。專案自帶工具時讓位，未登記時導向 `init-tracker-config` |
| [`scripts/issue-check.mjs`](scripts/issue-check.mjs) | 結構稽核：frontmatter 缺欄、status 不在 enum、grouping 欄與資料夾不符、`done`⇔`completed`、**關係欄單向**、INDEX 漏卡。exit 1 = 有問題 |
| [`scripts/issue-reconcile.mjs`](scripts/issue-reconcile.mjs) | 狀態漂移對帳：卡沒標完成但實作 commit 已進 main／release。`--fix` 自動翻。專案自帶對帳工具時讓位 |
| [`scripts/smoke-test.sh`](scripts/smoke-test.sh) | 上述四支的煙霧測試（71 項，含 8 路併發不撞號、推斷、登記端到端、每種結構漂移各一條） |
| [`scripts/spec-frontmatter.sh`](scripts/spec-frontmatter.sh) | `spec-writing` 用 |

設定檔 schema 見 [`skills/file-based-issues/references/config.md`](skills/file-based-issues/references/config.md)。

## 邊界

tracker 相關的三件事分開管：

| 要做的事 | 用 |
|---|---|
| 操作「issue 存在 repo 檔案裡」的 tracker（建單、改狀態、稽核、對帳） | `file-based-issues` |
| 撰寫並開 Jira 的規劃型工單（故事、任務；新建、修正、一次一批） | `jira-ticket-authoring` |
| 操作既有 Jira 工單（查詢、轉狀態、記工時、改指派） | `jira-cli` |

- `file-based-issues` 不處理 Jira、Linear、走 API 的 GitHub Issues。設定檔可以把這些專案登記成
  `provider: jira` / `github` / `linear`，`issue-new.mjs` 會拒絕執行並指向正確工具。
- `jira-ticket-authoring` 不處理 Bug、客訴、維運回報；環境裡有對應的開單 skill 就用它。
- user story / AC 的**內容品質**方法論見 `spec-writing` skill；它產出的是給 coding agent 的檔案式 Story。
  要在 Jira 開規劃型工單時改用 `jira-ticket-authoring`。
