# data-converter Plugin 設計文件

**日期**：2026-04-16
**狀態**：Draft

---

## 概述

`data-converter` 是一個資料轉換工具箱 plugin，收納各種格式互轉的 skill。第一個 skill 為 `md-to-pdf`，將含 Mermaid 圖的 Markdown 檔案轉換為 PDF。

## 目標

- 提供穩定、可重複的 Markdown → PDF 轉換流程
- 正確處理 Mermaid 圖（預處理為 PNG 再嵌入）
- 支援單檔或多檔批次轉換
- Plugin 架構可擴充，未來可加入其他轉換 skill

## Plugin 結構

```
plugins/data-converter/
├── .claude-plugin/plugin.json
├── skills/
│   └── md-to-pdf/
│       ├── SKILL.md
│       ├── scripts/
│       │   ├── preprocess.cjs
│       │   └── convert.sh
│       └── references/
│           └── 01-troubleshooting.md
```

- 無 agent、無 command
- 未來新增 skill 放在 `skills/<skill-name>/` 下

## plugin.json

```json
{
  "name": "data-converter",
  "version": "1.0.0",
  "description": "資料轉換工具箱，收納各種格式互轉的 skill",
  "author": {
    "name": "Timothy Liao",
    "email": "tim80411@gmail.com"
  },
  "repository": "https://github.com/tim80411/ai-agent-extension",
  "license": "MIT",
  "keywords": ["converter", "markdown", "pdf", "mermaid", "data"]
}
```

## md-to-pdf Skill 設計

### 觸發方式

SKILL.md 的 `description` 包含觸發詞：「轉成 PDF」「產生 PDF」「markdown 轉檔」「md to pdf」「md-to-pdf」「Markdown 轉 PDF」「把 md 轉成 pdf」。

### 支援內容

- 一般 Markdown 文字與格式
- Markdown 表格
- Mermaid 圖（`` ```mermaid ``` `` code block）

不支援：數學公式（KaTeX/MathJax）、程式碼語法高亮保留。

### 執行流程

#### Phase 1：解析輸入（SKILL.md 負責）

- 從使用者訊息中取得 .md 檔路徑（一或多個）
- 驗證檔案存在
- 若未提供路徑，用 AskUserQuestion 詢問

#### Phase 2-5：轉換（convert.sh 負責）

SKILL.md 呼叫 `convert.sh <md-file-1> [md-file-2] ...`，腳本內部執行：

**Phase 2：預處理 Mermaid**
- 建立暫存目錄 `/tmp/md2pdf-<timestamp>/`
- 對每個 .md 呼叫 `preprocess.cjs`
- 掃描 `` ```mermaid ``` `` block，抽出 .mmd 檔到 `<tmp>/imgs/`
- 替換為 `![mmd-<basename>-<n>](imgs/mmd-<basename>-<n>.png)` 引用
- 若無 Mermaid block 則直接複製原檔到暫存目錄

**Phase 3：渲染 Mermaid PNG**
- 對暫存目錄中所有 .mmd 檔執行 `npx -p @mermaid-js/mermaid-cli mmdc -i input.mmd -o output.png -b white -w 1400`
- 若 mmdc 報錯，將錯誤訊息納入輸出

**Phase 4：轉換 PDF**
- 在暫存目錄下執行 `npx md-to-pdf`（讓相對路徑對上 PNG 引用）
- 將產出的 PDF 搬回原檔同目錄（檔名相同，副檔名改 .pdf）

**Phase 5：清理與回報**
- 刪除暫存目錄
- stdout 輸出成功/失敗的檔案清單

### 腳本介面

#### `convert.sh`

```
用法：convert.sh <md-file-1> [md-file-2] ...
範例：convert.sh /path/to/q1.md /path/to/q2.md

退出碼：
  0 = 全部成功
  1 = 部分或全部失敗（stderr 有錯誤訊息）

stdout 輸出格式：
  OK: /path/to/q1.pdf
  OK: /path/to/q2.pdf
  FAIL: /path/to/q3.md - <錯誤訊息>
```

#### `preprocess.cjs`

```
用法：node preprocess.cjs <source.md> <output.md> <imgs-dir>
範例：node preprocess.cjs /path/q1.md /tmp/md2pdf/q1.md /tmp/md2pdf/imgs

行為：
  1. 讀取 source.md
  2. 找所有 ```mermaid``` block
  3. 每個 block 寫成 <imgs-dir>/mmd-<basename>-<n>.mmd
  4. 替換為 ![mmd-<basename>-<n>](imgs/mmd-<basename>-<n>.png)
  5. 寫出處理後的 md 到 output.md
  6. stdout 輸出抽取的 mermaid block 數量

若無 mermaid block，直接複製原檔到 output.md，輸出 0
```

### 外部依賴

以下工具在腳本中透過 `npx --yes` 按需安裝，不需使用者預先安裝：

- `md-to-pdf`：Markdown → PDF 轉換（底層 puppeteer）
- `@mermaid-js/mermaid-cli`（mmdc）：Mermaid → PNG 渲染

系統需求：Node.js（v18+）

### 已知限制與踩坑紀錄（→ 01-troubleshooting.md）

| 問題 | 原因 | 解法 |
|------|------|------|
| Mermaid edge label 含括號 mmdc 報錯 | `(` 被 parser 當 shape 定義 | label 加雙引號 |
| md-to-pdf 直接轉 Mermaid 變純文字 | md-to-pdf 不會執行 Mermaid JS 渲染 | 預處理為 PNG |
| 預處理為 SVG 後 PDF 中空白 | puppeteer file:// 載入 SVG 有 cross-origin 限制 | 改用 PNG |
| PNG 引用用絕對路徑 PDF 中不顯示 | md-to-pdf/puppeteer 路徑解析問題 | 用相對路徑 + 在暫存目錄下執行 |

## Symlink 設置

新增 skill 時同步建立：
- `.claude/skills/md-to-pdf` → `../../plugins/data-converter/skills/md-to-pdf/`
- `.cursor/skills/md-to-pdf` → `../../plugins/data-converter/skills/md-to-pdf/`

## marketplace.json 註冊

在根目錄 `.claude-plugin/marketplace.json` 的 `plugins` 陣列中新增 `data-converter` 條目。
