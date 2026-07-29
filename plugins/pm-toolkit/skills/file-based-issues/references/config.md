# 設定檔 schema（`~/.config/pm-toolkit/config.yaml`）

設定檔存的是**每個專案的 tracker 慣例**，讓 skill 不必每次重新探勘，也讓內建的發號腳本知道
該用什麼 ID 前綴、建在哪、frontmatter 長怎樣。

**位置優先序**：`$PM_TOOLKIT_CONFIG` > `$XDG_CONFIG_HOME/pm-toolkit/config.yaml` >
`~/.config/pm-toolkit/config.yaml`。

刻意不放 `~/.claude/`——那是 Claude Code 管理的目錄，會被安裝／更新流程動到；使用者自己的
設定不該跟工具的安裝狀態綁在一起。

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/pm-config.mjs init          # 產範本
node ${CLAUDE_PLUGIN_ROOT}/scripts/pm-config.mjs list          # 列出所有 profile
node ${CLAUDE_PLUGIN_ROOT}/scripts/pm-config.mjs show --json   # 解析當下 cwd 對應哪個
```

---

## 頂層結構

```yaml
version: 1

defaults:            # 每個 profile 先繼承這裡，再用自己的欄位覆蓋
  provider: file-based

profiles:
  <profile-name>:
    provider: file-based | jira | github | linear
    match: { ... }
    # …provider 專屬欄位
```

## profile 怎麼跟「當下的專案」對上

由明確到推測，命中就停：

| 順位 | 機制 | 寫在哪 |
|---|---|---|
| 1 | `--profile <name>` 參數 | 指令列 |
| 2 | `$PM_TOOLKIT_PROFILE` | 環境變數 |
| 3 | `.pm-toolkit-profile` 檔（內容 = profile 名） | 專案內，會往上找到檔案系統根 |
| 4 | `match.git_remote` | 對 `origin` URL 做子字串比對 |
| 5 | `match.path` | 對 cwd 做前綴比對，支援 `~` |
| 6 | profile 名 == repo 目錄名 | — |

全部落空 → **報錯，不猜**。猜錯專案去發號會把號碼寫進別人的序列，比停下來貴得多。

`match.git_remote` 只做子字串比對，所以填 `owner/repo` 就能同時吃 `git@github.com:owner/repo.git`
與 `https://github.com/owner/repo.git` 兩種形式。

## `provider: file-based` 的欄位

| 欄位 | 預設 | 說明 |
|---|---|---|
| `issues_root` | `issues` | 相對 repo 根（沒有 git 就相對 cwd） |
| `id_prefix` | **必填** | ID 主鍵前綴，`TIM` → `TIM-1`。只能英數與底線、開頭為字母 |
| `grouping` | `null` | layer-1 資料夾的語意（`milestone`／`epic`…）。同時是 frontmatter 的欄位名。`null` = 不分組 |
| `default_group` | `uncategorized`（有 grouping 時） | 沒給 `--group` 時落腳處 |
| `require_existing_group` | `true` | `true` = 分組目錄不存在就報錯並列出可用值；`false` = 自動建 |
| `status.initial` | `Backlog` | 新單的 status |
| `status.done` | `Done` | 完成值（對帳與 `completed:` 用） |
| `status.enum` | `[Backlog, Todo, In Progress, Done]` | 合法值；`initial`／`done` 不在裡面會直接擋下 |
| `sections` | `["背景", "AC", "範圍外"]` | `index.md` 的內文分段 |
| `create_cmd` | `null` | 專案自帶的建立工具。設了之後內建發號會**讓位**（exit 3），除非 `--force` |
| `record_branch` | `true` | 是否記 `git_branch:` |
| `frontmatter_extra` | `{}` | 額外固定欄位，原樣寫進 frontmatter |

## 非 file-based 的 provider

只記錄「這個專案不歸本 skill 管」以及該轉去哪，欄位自由：

```yaml
  some-jira-project:
    provider: jira
    match: { git_remote: yourorg/some-backend }
    project_key: ABC        # 自由欄位，show --json 會原樣吐出來
```

`issue-new.mjs` 碰到這種 profile 會 **exit 2** 並印出該用的工具。

---

## 發號狀態放哪

```
~/.config/pm-toolkit/
  config.yaml
  counters/
    <profile>.counter      # 最後發出去的號
    <profile>.lock/        # mkdir 當鎖（原子），30 秒視為殘留
```

計數檔**不在 `.git` 裡**，因為不是每個專案都有 git。代價是它不跨機器同步——但這不影響正確性：
真正的地板是 `next = max(計數檔, 掃描 issues_root 的最大號) + 1`，所以換機器、砍計數檔、
clone 一份新的，都只會讓它退回掃描結果，不會退號重發。

計數檔的價值在**掃描看不到的那些號**：worktree A 在未合併的分支上建了 `X-350`，worktree B
掃自己的工作目錄看不到它——共用的計數檔補上這個盲點。

## YAML 支援範圍

parser 是自寫的受控子集（零依賴），**支援**：巢狀 map、block sequence、flow sequence `[a, b]`、
單／雙引號、數字、`true`/`false`/`null`/`~`、`#` 註解。

**不支援且會明確報錯**（而非安靜解析錯）：tab 縮排、anchor/alias、multi-line scalar（`|` `>`）、
flow map `{}`、多文件 `---`。config 解錯會導致發錯號，所以寧可吵也不要猜。
