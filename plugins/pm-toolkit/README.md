# pm-toolkit

個人專案管理工具集（personal PM toolkit）。收納在此 marketplace，供跨機器安裝使用。

> 命名說明：刻意**不**叫 `project-management`，以免與已安裝的 Nani 工作用 `project-management`
> plugin（owner: Nani Team, bitbucket rd-oneclass/nani_skill）撞 plugin 名／skill 命名空間。

## Skills

| Skill | 用途 |
|---|---|
| [`file-based-issues`](skills/file-based-issues/SKILL.md) | 操作**檔案式／本地化 issue tracker**（issue = git 追蹤的 markdown+frontmatter 資料夾、repo 即 SSOT）的通用方法論：探出專案慣例後套用建單／結構／修改／模板／狀態對帳。附一份 admission-radar 的完整實例。 |

## 邊界

- 針對「issue 存在 repo 檔案裡」的 tracker，**不是** Jira（用 `jira-create-ticket`）、不是 Linear、不是走 API 的 GitHub Issues。
- 只管 tracker **操作**；user story / AC 的**內容品質**方法論見 `spec-writing` skill。
