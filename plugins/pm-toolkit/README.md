# pm-toolkit

個人專案管理工具集（personal PM toolkit）。收納在此 marketplace，供跨機器安裝使用。

> 命名說明：刻意**不**叫 `project-management`，以免與已安裝的 Nani 工作用 `project-management`
> plugin（owner: Nani Team, bitbucket rd-oneclass/nani_skill）撞 plugin 名／skill 命名空間。

## Skills

| Skill | 用途 |
|---|---|
| [`file-based-issues`](skills/file-based-issues/SKILL.md) | 操作**檔案式／本地化 issue tracker**（issue = git 追蹤的 markdown+frontmatter 資料夾、repo 即 SSOT）的通用方法論：建單／結構／修改／模板／狀態對帳。附一份 admission-radar 的完整實例。 |
| [`init-tracker-config`](skills/init-tracker-config/SKILL.md) | 把一個專案**登記進全域設定檔**：掃 repo 推斷慣例 → 跟使用者確認（ID 前綴是不可變主鍵，不猜） → 寫入 → 驗證。建單遇到 exit 4 就是要走這裡。 |

## Scripts

零依賴（只要 node），不需 `npm install`。

| 腳本 | 用途 |
|---|---|
| [`scripts/pm-config.mjs`](scripts/pm-config.mjs) | 管理 `~/.config/pm-toolkit/config.yaml`：`init`／`list`／`show --json`／`detect --json`（唯讀推斷 repo 慣例）／`add --json`（附加寫入，保留註解） |
| [`scripts/issue-new.mjs`](scripts/issue-new.mjs) | 通用防撞建單：發號＋建資料夾＋依 profile 產 frontmatter。專案自帶工具時讓位，未登記時導向 `init-tracker-config` |
| [`scripts/smoke-test.sh`](scripts/smoke-test.sh) | 上述兩支的煙霧測試（48 項，含 8 路併發不撞號、推斷、登記端到端） |
| [`scripts/spec-frontmatter.sh`](scripts/spec-frontmatter.sh) | `spec-writing` 用 |

設定檔 schema 見 [`skills/file-based-issues/references/config.md`](skills/file-based-issues/references/config.md)。

## 邊界

- 針對「issue 存在 repo 檔案裡」的 tracker，**不是** Jira（用 `jira-cli`）、不是 Linear、不是走 API 的 GitHub Issues。
  設定檔可以把這些專案登記成 `provider: jira` / `github` / `linear`，`issue-new.mjs` 會拒絕執行並指向正確工具。
- 只管 tracker **操作**；user story / AC 的**內容品質**方法論見 `spec-writing` skill。
