# CLAUDE.md

此專案是 Claude Code Plugin Marketplace，包含多個 plugin。
以下是在此 repo 開發時的 Must-Go 與 No-Go 規則。

---

## Must-Go（一定要做）

### 目錄結構與命名

- Plugin、Skill、Agent、Command 名稱一律使用 **kebab-case**
- 每個 plugin 必須包含 `.claude-plugin/plugin.json`
- 遵循標準目錄結構：
  ```
  plugins/<plugin-name>/
  ├── .claude-plugin/plugin.json
  ├── skills/<skill-name>/
  │   ├── SKILL.md
  │   ├── references/
  │   ├── assets/        （選用）
  │   └── scripts/       （選用）
  ├── agents/<agent>.md  （選用）
  └── commands/<cmd>.md  （選用）
  ```

### plugin.json

- 必須包含 `name`、`version`、`description`、`author` 四個欄位
- 版本號使用 SemVer（`MAJOR.MINOR.PATCH`）
- `author` 格式統一為 `{ "name": "Timothy Liao", "email": "tim80411@gmail.com" }`
- 新增 plugin 時，同步在根目錄 `.claude-plugin/marketplace.json` 的 `plugins` 陣列中註冊

### SKILL.md

- 必須有 YAML frontmatter，至少包含 `name` 和 `description`
- `description` 中要列出觸發詞（中英文皆可），讓 Claude 能正確匹配
- 長篇 domain knowledge 放在 `references/*.md`，SKILL.md 只做流程編排與引用
- Phase-based 的 skill 要在每個 phase 標明 **Goal** 和 **Actions**

### Agent .md

- 必須有 YAML frontmatter：`name`、`description`、`model`、`color`、`tools`
- `description` 中包含 `<example>` 區塊說明觸發情境
- `tools` 明確列出該 agent 可使用的工具清單

### Command .md

- 必須有 YAML frontmatter：`name`、`description`
- 使用 `allowed-tools` 限制可用工具範圍
- 需要使用者輸入時加上 `argument-hint` 提示格式

### 版本管理與 Git

- 專案有 PreToolUse hook（`.claude/scripts/bump-plugin-version.sh`），git commit 時會自動 bump 受影響 plugin 的 patch 版本
- hook deny commit 後，要先 stage 更新後的 `plugin.json` 再重新 commit
- `marketplace.json` 中的 plugin 版本要與對應 `plugin.json` 保持同步

### Reference 文件

- Reference 放在 `skills/<skill-name>/references/` 下
- 多份 reference 時使用編號前綴命名（如 `01-story-types.md`、`02-scoping.md`）
- 計劃文件與分析文件放在 `docs/plans/` 和 `docs/analyses/`，以日期前綴命名（`YYYY-MM-DD-topic.md`）

### Skill Symlinks

- `.claude/skills/` 和 `.cursor/skills/` 內放的是 symlink，指向 `plugins/<plugin>/skills/<skill>/`
- 真實檔案一律在 `plugins/` 下，symlink 僅供在此專案內直接測試 skill 用
- 新增 skill 時，同步在 `.claude/skills/` 和 `.cursor/skills/` 建立 symlink

---

## No-Go（一定不要做）

### 目錄結構與命名

- 不要使用 camelCase、snake_case 或其他非 kebab-case 的命名方式
- 不要在標準結構外隨意新增頂層目錄

### plugin.json

- 不要手動修改 `plugin.json` 的 `version` 欄位 —— PreToolUse hook 會自動處理
- 不要使用不完整的 `author` 格式（如只有 `name` 沒有 `email`）
- 不要忘記在 `marketplace.json` 中同步註冊新 plugin

### SKILL.md

- 不要在 SKILL.md 裡塞大量 domain knowledge 內容，應拆到 `references/` 下
- 不要省略 YAML frontmatter 中的 `description`（會導致 Claude 無法觸發該 skill）

### Agent .md

- 不要省略 `tools` 清單（agent 必須明確宣告可用工具）
- 不要假設 agent 能存取 SKILL.md 的 context —— agent 是獨立執行環境，必須在任務描述中傳入所有必要資訊

### Command .md

- 不要在 command 裡寫複雜邏輯，command 只負責入口與委派，行為放在 skill 或 agent 中

### 版本管理與 Git

- 不要在 git commit 時跳過 hook（不要用 `--no-verify`）
- 不要讓 `marketplace.json` 與 `plugin.json` 的版本不同步
