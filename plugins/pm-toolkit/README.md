# pm-toolkit

個人專案管理工具集（personal PM toolkit）。收納在此 marketplace，供跨機器安裝使用。

> 命名說明：刻意**不**叫 `project-management`，以免與已安裝的 Nani 工作用 `project-management`
> plugin（owner: Nani Team, bitbucket rd-oneclass/nani_skill）撞 plugin 名／skill 命名空間。

## Skills

| Skill | 用途 |
|---|---|
| [`file-based-issues`](skills/file-based-issues/SKILL.md) | 操作**檔案式／本地化 issue tracker**（issue = git 追蹤的 markdown+frontmatter 資料夾、repo 即 SSOT）的通用方法論：探出專案慣例後套用建單／結構／修改／模板／狀態對帳。附一份 admission-radar 的完整實例。 |

## Scripts

零依賴（只要 node），不需 `npm install`。

| 腳本 | 用途 |
|---|---|
| [`scripts/pm-config.mjs`](scripts/pm-config.mjs) | 管理 `~/.config/pm-toolkit/config.yaml`：`init` 產範本、`list` 列出所有專案 profile、`show --json` 解析當下 cwd 對應哪個 |
| [`scripts/issue-new.mjs`](scripts/issue-new.mjs) | 通用防撞建單：發號＋建資料夾＋依 profile 產 frontmatter。專案自帶工具時會自動讓位 |
| [`scripts/smoke-test.sh`](scripts/smoke-test.sh) | 上述兩支的煙霧測試（28 項，含 8 路併發不撞號） |
| [`scripts/spec-frontmatter.sh`](scripts/spec-frontmatter.sh) | `spec-writing` 用 |

設定檔 schema 見 [`skills/file-based-issues/references/config.md`](skills/file-based-issues/references/config.md)。

## 邊界

- 針對「issue 存在 repo 檔案裡」的 tracker，**不是** Jira（用 `jira-cli`）、不是 Linear、不是走 API 的 GitHub Issues。
  設定檔可以把這些專案登記成 `provider: jira` / `github` / `linear`，`issue-new.mjs` 會拒絕執行並指向正確工具。
- 只管 tracker **操作**；user story / AC 的**內容品質**方法論見 `spec-writing` skill。
