# workflow-lab — 設計文件

- **日期**：2026-06-16
- **狀態**：設計通過，待寫實作計畫
- **作者**：Timothy Liao（與 Claude 協作）

---

## 1. 目的與動機

Workflow（多代理人編排）執行成本高（會開十幾個背景 agent、耗大量 token）。使用者希望：

- **平時（有空構思時）**：把「想大量驗證或製作」的 workflow 想法**囤起來**，甚至直接寫到「完整可跑」的程度，但**先不執行**。
- **忙碌的早上（沒空構思時）**：從囤好的清單裡**挑一個拿出來跑**，幾乎零思考。

本專案提供一個 plugin（`workflow-lab`）含兩個 skill，把「記錄想法」與「運行想法」這兩個動作工具化，並把想法資料庫存在 repo 外的固定資料夾。

### 查證過的關鍵事實（第一手證據，影響設計）

| # | 事實 | 對設計的影響 |
|---|------|------------|
| 1 | 每次 Workflow 執行落地到 `<project>/<session-uuid>/workflows/`：`scripts/<name>-wf_<id>.js`（完整 script）與 `wf_<id>.json`（journal，含完整 `result`、`totalTokens`、`agentCount`、`durationMs`、`status`） | 成本統計與結果已被保存；run 收尾時可直接讀取並複製回 lab 資料夾 |
| 2 | Resume（`resumeFromRunId`）綁在 session UUID 目錄下，**僅同 session 有效** | 「今天囤、改天早上跑」屬不同 session → 每次都是**全新執行**；resume 只救「同次 session 內跑到一半失敗」 |
| 3 | **本機 `args` 注入失效**：Workflow 的 `args` 進到 script 是 `undefined`（使用者 memory `workflow-args-not-passed`，2026-06-11） | script **不可依賴 `args` global**；用頂部 `CONFIG` const 取代，run 以編輯 const 的方式填參數 |
| 4 | Workflow agent 可呼叫所有 session 連線的 MCP 工具，但互動授權的 MCP（如 claude.ai 系）在背景/headless 可能缺席 | 對外動作（建單、部署、發通知）預設放在使用者前景 session 執行較可靠 |

---

## 2. 整體架構

```
程式碼（在此 marketplace repo 內）          想法資料庫（repo 外，固定路徑）
plugins/workflow-lab/                       ~/workflow-lab/            ← 預設，可在 skill 設定
├── .claude-plugin/plugin.json              └── <idea-slug>/
├── skills/                                     ├── README.md          想法卡（metadata）
│   ├── workflow-capture/SKILL.md               ├── workflow.js        完整可跑 script（CONFIG const）
│   └── workflow-run/SKILL.md                   └── runs/
                                                     └── <timestamp>.md 每次執行的結果＋成本＋動作紀錄
```

- **Skill 程式碼**住在 repo，照本專案慣例：kebab-case、`plugin.json` 四欄位、註冊進 `marketplace.json`、`.claude/skills/` 與 `.cursor/skills/` 建 symlink。
- **想法資料庫**住在 repo 外的 `~/workflow-lab/`。使用者固定**從這個資料夾啟動 session 來跑**（因為記不住當初在哪個 project 的 session 跑的）；好處是 journal/結果都落在可預期的同一處。

---

## 3. 元件：一個「囤起來的想法」資料夾

### 3.1 `README.md`（想法卡）

YAML frontmatter：

| 欄位 | 值 | 說明 |
|------|----|----|
| `status` | `draft` / `skeleton` / `ready` / `run-before` | 成熟度，run 清單依此排序與標示 |
| `goal` | 字串 | 這個 workflow 要驗證或產出什麼 |
| `output.kind` | `artifact` / `action` / `both` | 產出是文件、導向動作、或兩者 |
| `output.execution` | `post-run`（預設） / `in-workflow` | 動作型 output 的執行方式（見 §5） |
| `output.description` | 字串 | 具體產出物，或會導向什麼動作 |
| `cost_estimate` | 例：`~10 agents / ~150k tokens` | 預估成本，供早上挑選 |
| `config` | 鍵值清單 | 跑之前要填哪些值，對應 `workflow.js` 頂部 CONFIG const |

frontmatter 之後的內文放想法的詳細敘述、為什麼值得跑、注意事項。

### 3.2 `workflow.js`（可跑 script）

- 開頭 `export const meta = {...}`（純 literal，依 Workflow 規範）。
- **頂部一個明確的 `CONFIG` const 區塊**承載所有「跑之前要填的參數」與靜態資料（清單、路徑、日期）——**取代 `args`**（事實 #3）。
- 完整度依 capture 當下決定（使用者預設選「完整可跑」）；也允許停在 `skeleton`。

### 3.3 `runs/<timestamp>.md`

每次執行後寫一份：`result` 摘要、`totalTokens`/`agentCount`/`durationMs` 成本、status；若是動作型，記錄 action-plan 與「實際執行了什麼」。

---

## 4. Skill：`workflow-capture`（記錄想法）

- **Goal**：把一個想法落地成 §3 的資料夾，**不執行**。
- **Actions**：
  1. 互動問清：`goal`、`output`（kind + execution + 描述）、`cost_estimate`、要填哪些 `config`。
  2. 產生 kebab-case `slug`，建立 `~/workflow-lab/<slug>/`。
  3. 寫 `README.md`（frontmatter + 內文）。
  4. 產 `workflow.js`：依規範寫 `meta`，頂部放 `CONFIG` const，靜態資料內嵌，**不依賴 `args`**；依使用者要的完整度寫到「完整可跑」或「skeleton」。
  5. 設定 `status`。
- **不做**：不呼叫 `Workflow`、不執行任何外部動作。

---

## 5. Skill：`workflow-run`（運行想法）

- **Goal**：挑一個囤好的想法，安全地跑，結果存回。
- **Actions**：
  1. **列清單**：掃 `~/workflow-lab/`，列出各想法的 `status` 與 `cost_estimate`，讓使用者挑（browse 併在此步，不另開 skill）。
  2. **填參數**：讀該 idea 的 `README.md` + `workflow.js`，把 `config` 值**寫進 script 的 `CONFIG` const**（編輯檔案，不傳 args）。
  3. **預檢確認**：顯示預估成本；若 `output.kind` 含 `action` 且 `output.execution == in-workflow`，**額外強制確認**「將執行 N 個外部動作」。
  4. **啟動**：`Workflow({ scriptPath: "~/workflow-lab/<slug>/workflow.js" })`。
  5. **收尾**：把 `result` + 成本統計寫到 `runs/<timestamp>.md`；更新 `status = run-before`。
     - 若 `output.execution == post-run` 且含動作：把 workflow 產出的 **action-plan 攤給使用者確認 → 點頭後才執行對外動作**（在使用者前景的 workflow-lab session 內）→ 一併記進該 run 檔。

### 動作型 output 的執行策略（§5 預設）

- **預設 `post-run`**：workflow 全程**不碰外部世界**，只產結構化 action-plan；由使用者所在的 workflow-lab session 確認後執行。理由：可逆/安全（對外動作有確認關卡，不讓 16 個並行 agent 無煞車動作）、配合 args 地雷與成本（side-effect-free 失敗可安心重跑，不會重複建單）、可追溯（plan 與執行結果都存回 lab 資料夾）、MCP 可用性（事實 #4）。
- **`in-workflow` 為 per-idea opt-in**：僅用於「動作量本身就是工作」的想法（例：一次建 50 張子任務）。README 標清楚，run 預檢強制確認。

---

## 6. 慣例與邊界情況

- **args 地雷（事實 #3）**：所有 capture 產的 script 一律用頂部 `CONFIG` const；run 以編輯 const 填參數，永不依賴 `args` global。
- **狀態生命週期**：`draft → skeleton → ready → run-before`。
- **重跑**：同 session 內失敗可 `resumeFromRunId`（編輯 persisted script 後續跑，已完成 agent 吃快取）；跨天重跑屬全新執行（事實 #2）。
- **成本把關**：run 在啟動前一律顯示 `cost_estimate` 並要求確認，呼應「workflow 很貴」這個核心動機。
- **MCP 依賴**：動作型想法的 README 應註明需要哪些 MCP（如 Atlassian/Jira）；run 從 workflow-lab session 執行時須確保已連線。

---

## 7. 範圍界線（YAGNI）

- **不做** 獨立的 `workflow-list` skill（browse 併進 run 第一步）。
- **不做** 跨 session 自動 resume（事實 #2 已說明不可行）。
- **不做** 想法資料庫的版本控管/同步機制（單純資料夾即可；使用者要的話可自行 git init）。
- 預設路徑 `~/workflow-lab/`，需要時於 skill 內提供設定點。
