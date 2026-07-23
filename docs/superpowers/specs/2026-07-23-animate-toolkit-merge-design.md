# 設計：`animate-toolkit` 合併 + 命名閘門

- **日期**：2026-07-23
- **狀態**：設計定案，待寫實作計畫（writing-plans）
- **主導決策者**：Timothy Liao
- **影響 repo**：`tim-private-skills`（目的地）、`ai-agent-extension`（來源，移出 animate-dev）

---

## 1. 背景與問題

`animate-dev`（CreateJS runtime 開發，現於 `ai-agent-extension`）與 `animate-jsfl`
（命令列驅動 Animate 跑 JSFL，現於 `tim-private-skills` 的 `outsourcing` plugin）
是同一條生產線的兩半，但目前分屬兩個 repo、兩個 plugin。

觀察到的實際痛點：**animate-dev 開發出來的東西，常漏掉「大部分 MovieClip 是 state 化元件、
不操作時應停在 frame 0（或特定 frame）」這個概念。**

根因分析（已用第一手證據驗證）：
- 這個概念其實**已經**寫在 references（`component-rules.md` Type 2、`best-practices.md`
  初始化順序、`err-frame-not-paused.md`）。
- 但所有敘述都是**條件式**：「if state-based 才 stop」。內建心智模型是
  「MovieClip 預設會 play，你要*正面辨識*為 state 才加 `.stop()`」。
- `createjs-developer` agent（真正寫 code 的地方）在**獨立 context** 執行、讀不到 SKILL.md /
  references，自身 prompt 帶的也是條件式框架（`if state-based`）。曖昧時就 default 放它 play。

**兩條規則其實是一條鏈**：一個 `instance_23` 這種自動編號 / 無名實例，(a) 無法穩定引用
（republish 會重編號），(b) 沒有 `{type}_` 前綴 → 無法判斷該不該停在 frame 0。所以：

> **命名（先）→ 用前綴分類 → 非 `anim_` 停在 frame 0。**

少了第一步，第二步在技術上無從施力。合併兩個 skill、把這條鏈做成顯式閘門，才能根治。

---

## 2. 已鎖定決策

| 項目 | 決策 | 理由 |
|---|---|---|
| Plugin 家 | `tim-private-skills`（私有 repo） | JSFL 帶大量私有 infra（Windows watcher、`OutSourcingWorkingGroup` 中央佇列、接案流程）；兩者實際一起用的場景就是接案。animate-dev 從公開 marketplace 移出。 |
| Plugin 名 | `animate-toolkit` | 對齊使用者 `*-toolkit` 命名慣例（如 `pm-toolkit`）；JSFL 並非「開發」，罩在 `-dev` 名下不精確。 |
| 收錄 skill | `animate-dev`、`animate-performance`、`animate-jsfl` | 同主題三 skill 收斂為一 toolbox。 |
| 執行力道 | **深**：流程 + agent + review 全採 | 唯一能接到「實際寫 code 的 agent 路徑」的做法，才擋得住漏洞。 |
| JSFL 依賴 | **建議、不假設** | 見 §4 通用 vs 小眾原則。 |

---

## 3. 目標結構

`tim-private-skills/animate-toolkit/`（沿用私有 repo 的扁平佈局：plugin dir 在 root）：

```
animate-toolkit/
├── .claude-plugin/plugin.json          # name: animate-toolkit；合併 keywords；author {name,email}
├── README.md
├── skills/
│   ├── animate-dev/         SKILL.md    # ← 加「Phase 2.5 命名閘門」+ frame-0 預設
│   ├── animate-performance/ SKILL.md
│   └── animate-jsfl/                    # 整包從 outsourcing 搬入（SKILL + assets + scripts + references）
│       └── SKILL.md                     # ← 加一節「作為命名閘門被呼叫時」
├── agents/                             # 5 個 agent（從 animate-dev 搬入，prompt 加硬規則）
│   ├── createjs-developer.md            # ← 拒絕對浮動物件寫 code；frame-0 預設
│   ├── component-analyzer.md            # ← 報告新增「浮動 / 無名實例」專節
│   ├── code-reviewer.md                 # ← 新增兩項檢查
│   ├── issue-finder.md                  # ← 新增診斷模式
│   └── performance-analyzer.md
├── references/                         # plugin 層共用（從 animate-dev 搬入）
│   ├── naming-and-state-contract.md    # ★ 新增 SSOT
│   ├── component-rules.md / best-practices.md / …
│   └── errors/ …
└── docs/
```

> 註：`animate-jsfl` 保留其 skill-scoped references（`skills/animate-jsfl/references/jsfl-gotchas.md`）。
> plugin 層 references 與 skill 層 references 可並存。

---

## 4. 行為核心設計

### 4.1 通用原則 vs 小眾工具（使用者明確要求的分寸）

- **通用知識（一定編碼進規則，與工具無關）**：「不要對沒有穩定名稱的浮動物件寫 code，
  應優先命名」；「非 `anim_` MovieClip 預設停在 frame 0」。這些是任何 CreateJS/Animate
  開發都成立的好習慣。
- **小眾知識（只建議、不假設）**：`animate-jsfl` skill 需要 Windows + Animate + 私有 infra，
  不能假設每個情境都有。

所以命名閘門的**擋下**與**理由**是硬的、通用的；**解法**是軟的、建議性的。
animate-dev 在沒有 JSFL 的機器上依然完整可用。

### 4.2 命名閘門（Naming Gate）

animate-dev 開工前的硬檢查：

1. **偵測**：掃 `index.js` / lib，找出「浮動物件」= 自動編號 `instance_N` / 無 `.name` /
   不符 `{type}_{name}` 的實例。
2. **擋下（通用、硬）**：不准對浮動物件寫 `this.instance_23` 這種脆弱引用。
3. **說明 + 建議優先命名（通用、硬）**：解釋為何不穩（republish 會失效 / 無法穩定引用），
   建議先命名為 `{type}_{name}`。
4. **建議工具（可選、軟、不假設）**：「若你有 `animate-jsfl` skill，可用它自動化命名 +
   重發佈 `index.js`；沒有的話也可以在 Animate 裡手動命名。」
5. **對帳**（若走 JSFL 路徑，沿用 JSFL 硬規則）：grep 重生的 `index.js` 確認名字進匯出；
   grep 手寫 `js/*.js` 找殘留舊名引用。
6. **命名後**（不論用什麼方式）→ 回到 animate-dev 對穩定名稱開發，並套 frame-0 預設。

### 4.3 Frame-0 預設（命名後可施行，通用、硬）

- `anim_*`（或使用者確認的動畫）→ 可 `gotoAndPlay`。
- **其餘一律**（`btn_` / `state_` / `area_` / 任何非 `anim_` MovieClip）→ `addChild` 後
  `gotoAndStop(0)`（或確認的靜止 label）。
- 這是**極性反轉**：rest-by-default、play-by-exception（現況相反）。
- createjs-developer 對每個非 anim MovieClip 都要吐出靜止呼叫，並在回報標注
  「已假設為靜止態，若為動畫請告知」。

### 4.4 各處編碼（深度做法）

| 位置 | 變更 |
|---|---|
| `references/naming-and-state-contract.md`（新） | SSOT：`{type}_{name}` 慣例、浮動物件定義、命名優先原則（通用）、frame-0 預設、JSFL 為「建議自動化」的指標（非硬依賴）。animate-dev 與 animate-jsfl 都引用它。 |
| `skills/animate-dev/SKILL.md` | 插入「Phase 2.5 命名閘門」；Phase 6 明述 frame-0 預設；引用新 contract。 |
| `agents/createjs-developer.md` | 硬規則：拒絕對浮動物件寫 code → 回報為命名 blocker、建議命名（提及 JSFL 為選項，不假設）；frame-0 預設。 |
| `agents/component-analyzer.md` | 報告新增「浮動 / 無名實例」專節，標「建議先命名」。 |
| `agents/code-reviewer.md` | 新增檢查：(a) 任何引用 `instance_N` / 自動編號 = finding；(b) 任何非 anim MovieClip 未帶靜止 frame = finding。 |
| `agents/issue-finder.md` | 新增診斷模式：「auto-playing state 元件」「code 綁自動生成名」。 |
| `skills/animate-jsfl/SKILL.md` | 新增一節「作為 animate-dev 命名閘門被呼叫時」，用 dev 期望的 `{type}_{name}` 詞彙命名，並回指 contract。 |

---

## 5. 跨 repo 搬遷步驟

1. 在 `tim-private-skills` 組出 `animate-toolkit/`（複製 animate-dev plugin 全部內容 +
   搬入 `animate-jsfl` skill）。
2. 改寫 `plugin.json` → `animate-toolkit`；合併 keywords；author 保留 `{name,email}`。
3. 套用 §4 行為編輯。
4. `outsourcing`：移除 `skills/animate-jsfl/`；更新其 `plugin.json` 描述 / keywords（去除 jsfl）；
   bump 版本。
5. `ai-agent-extension`：移除 `plugins/animate-dev/`；移除 `marketplace.json` 條目；
   移除 `.claude/skills/` 與 `.cursor/skills/` 兩處 symlink（animate-dev、animate-performance）。
6. `tim-private-skills/.claude-plugin/marketplace.json`：註冊 `animate-toolkit`；
   **順手修正既有 stale 的 `outsourcing` 條目**（marketplace 顯示 v1.4.3 / 3 skill，
   實際 plugin.json 為 v1.6.0 / 5 skill — 兩者已漂移；此次去除 jsfl 後一併校正為實際內容）。
7. 同步 `~/.claude/plugins/marketplaces/tim-private-skills/` cache 讓變更生效；reload。
8. 驗證（見 §6）。

---

## 6. 驗證

- 兩份 `marketplace.json` 為合法 JSON；`animate-toolkit` 與更新後 `outsourcing` 條目與各自
  `plugin.json` 一致。
- `animate-toolkit` 三個 skill 觸發正常；SKILL.md 內 `references/*` 相對路徑解析成功
  （搬完須驗證 plugin 層 references 的路徑 quirk 仍成立）。
- 5 個 agent 載入正常。
- `ai-agent-extension` 無斷掉的 symlink（`.claude/skills`、`.cursor/skills`）。
- 抽查行為：給一段含 `instance_N` 的匯出 code，animate-dev 應觸發命名閘門而非直接寫 code；
  給一個 `state_x` MovieClip，createjs-developer 應輸出 `gotoAndStop(0)`。

---

## 7. 風險 / 待決

- **跨 repo git**：兩 repo 各自 commit。`ai-agent-extension` 有 version-bump PreToolUse hook，
  移除 plugin 時要留意其行為（memory: bump hook 對 staged plugin.json 會 skip）。
- **JSFL 平台限制**：animate-jsfl 是 Windows/接案專屬 → `animate-toolkit` plugin 描述須誠實標注
  JSFL 為 Windows-only 自動化，避免誤導。
- **references 路徑 quirk**：animate-dev 的 SKILL.md 用 `references/x.md`，但檔案在 plugin root
  的 `references/`（非 skill dir 下）。搬到 animate-toolkit 後須驗證仍能解析；必要時調整。
- **cache 同步機制**：tim-private-skills「編輯 source + 同步 cache」流程需確認（memory 有記）。
- **author email 慣例**：私有 repo 現有 plugin 只用 `{name}`；animate-dev 帶 `{name,email}`。
  移入後保留 email（較完整），不強制對齊私有 repo 的簡略格式。

---

## 8. 被否決 / 未採方案

- **執行力道「中」（只改 agent）/「淺」（只改文件）**：淺方案基本等於現況（規則在 agent 讀不到的
  地方），中方案缺流程編排。均無法根治「開發出來會漏」。已選「深」。
- **合併後留在 `ai-agent-extension`（公開）**：會把 JSFL 私有 infra 帶進公開 repo。已選私有。
- **硬 routing 到 JSFL**：會假設使用者一定有 JSFL 小眾 skill。改為「建議、不假設」。
