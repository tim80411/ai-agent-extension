# animate-toolkit 合併 + 命名閘門 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `animate-dev`（含 `animate-performance` + 5 agent）與 `animate-jsfl` 合併成單一 plugin `animate-toolkit`（落在私有 repo `tim-private-skills`），並植入「命名閘門 + frame-0 靜止預設」的深度執行力道。

**Architecture:** 先在 `tim-private-skills` 組出 `animate-toolkit`（`git mv` 搬 jsfl、跨 repo 複製 animate-dev）→ 就地做行為編輯（新 SSOT contract、SKILL 命名閘門、agent 硬規則、index 驅動的新 error）→ 更新兩 repo 的 manifest / marketplace / symlink → 同步 cache 並驗證。設計 SSOT：`docs/superpowers/specs/2026-07-23-animate-toolkit-merge-design.md`。

**Tech Stack:** Claude Code plugin（Markdown SKILL/agent、`plugin.json`、`marketplace.json`）、git（跨兩 repo）、bash 驗證（grep / python json / ls symlink）。

## Global Constraints

- **路徑變數（全程沿用）**：
  - `AAE` = `/Users/tim80411/self/misc/ai-agent-extension`（來源，移出 animate-dev）
  - `TPS` = `/Users/tim80411/self/misc/tim-private-skills`（目的地）
  - `NEW` = `$TPS/animate-toolkit`（新 plugin）
- **命名一律 kebab-case**；plugin/skill/agent 名稱不變（`animate-dev`、`animate-performance`、`animate-jsfl`、5 個 agent 保留原 name frontmatter）。
- **JSFL 是建議、不假設**：任何「命名解法」的敘述都必須是「建議可用 animate-jsfl skill / 也可手動命名」，**不得**假設使用者一定有 JSFL（Windows + Adobe Animate + 私有 infra）。
- **通用規則要硬**：「不對浮動物件寫 code」「非 anim_ 預設 frame 0」是與工具無關的通用原則，必須硬編碼。
- **references 保持 plugin 層**：`animate-dev` 與 `animate-performance` 共用 `references/`（含 `errors/`），一律放 `$NEW/references/`，不下放到 skill dir。
- **commit / push 需使用者指示**：本 plan 每個 Task 附 commit 步驟，但依使用者 harness 規則，實際 commit/push 在執行階段先取得同意；跨兩 repo 各自 commit。
- **不要 `--no-verify`**：`AAE` 有 version-bump PreToolUse hook，遵守既有 git 規範。
- **浮動物件判準（統一定義）**：符合任一即是——(a) 匯出 code 以 `instance_<數字>` 自動編號引用；(b) 無 `.name` 的匿名 shape/movieclip；(c) 有名字但不符 `{type}_{name}` 慣例。

---

## Task 1: 組出 animate-toolkit 骨架（搬檔 + plugin.json）

**Files:**
- Move (git mv, within `$TPS`): `$TPS/outsourcing/skills/animate-jsfl/` → `$NEW/skills/animate-jsfl/`
- Copy (cross-repo, from `$AAE`): `plugins/animate-dev/skills/animate-dev`, `skills/animate-performance`, `agents/`, `references/`, `README.md`, `docs/` → under `$NEW/`
- Create: `$NEW/.claude-plugin/plugin.json`

**Interfaces:**
- Produces: 目錄 `$NEW/{skills/{animate-dev,animate-performance,animate-jsfl},agents,references}`、`$NEW/.claude-plugin/plugin.json`（name=`animate-toolkit`, version=`1.0.0`）。後續所有 Task 都在 `$NEW/` 內編輯。

- [ ] **Step 1: 建目錄並跨 repo 複製 animate-dev plugin 內容**

```bash
mkdir -p "$TPS/animate-toolkit/.claude-plugin"
cp -R "$AAE/plugins/animate-dev/skills/animate-dev"          "$TPS/animate-toolkit/skills/animate-dev"
cp -R "$AAE/plugins/animate-dev/skills/animate-performance"  "$TPS/animate-toolkit/skills/animate-performance"
cp -R "$AAE/plugins/animate-dev/agents"                       "$TPS/animate-toolkit/agents"
cp -R "$AAE/plugins/animate-dev/references"                   "$TPS/animate-toolkit/references"
cp    "$AAE/plugins/animate-dev/README.md"                    "$TPS/animate-toolkit/README.md"
cp -R "$AAE/plugins/animate-dev/docs"                         "$TPS/animate-toolkit/docs" 2>/dev/null || true
```

（先用 `AAE`/`TPS` 實際絕對路徑替換；或於 shell `export AAE=… TPS=…`。）

- [ ] **Step 2: 用 git mv 把 animate-jsfl 從 outsourcing 搬進 toolkit（保留 history）**

```bash
cd "$TPS"
git mv outsourcing/skills/animate-jsfl animate-toolkit/skills/animate-jsfl
```

- [ ] **Step 3: 寫 `$NEW/.claude-plugin/plugin.json`**

```json
{
  "name": "animate-toolkit",
  "version": "1.0.0",
  "description": "Adobe Animate + CreateJS 工具組 — 開發（animate-dev：CreateJS 互動/遊戲邏輯，含命名閘門與 frame-0 靜止預設）、效能（animate-performance：7 大效能問題掃描與修復）、JSFL 自動化（animate-jsfl：命令列驅動 Animate 標籤化／命名 instance／重發佈 index.js，需 Windows + Adobe Animate）",
  "author": {
    "name": "Timothy Liao",
    "email": "tim80411@gmail.com"
  },
  "keywords": [
    "adobe-animate", "createjs", "animation", "canvas", "performance",
    "jsfl", "animate-jsfl", "automation", "標籤化", "命名", "frame-label",
    "movieclip", "state", "命名閘門", "frame-0"
  ]
}
```

- [ ] **Step 4: 驗證結構與 JSON**

```bash
cd "$TPS"
find animate-toolkit -maxdepth 3 -type d | sort
python3 -c "import json; json.load(open('animate-toolkit/.claude-plugin/plugin.json')); print('plugin.json OK')"
ls animate-toolkit/skills   # 期望：animate-dev  animate-jsfl  animate-performance
ls animate-toolkit/agents   # 期望：5 個 .md
test ! -e outsourcing/skills/animate-jsfl && echo "jsfl removed from outsourcing OK"
```

Expected: 三個 skill 目錄齊、5 個 agent、plugin.json OK、jsfl 已不在 outsourcing。

- [ ] **Step 5: Commit（TPS）**

```bash
cd "$TPS"
git add -A
git commit -m "feat(animate-toolkit): scaffold merged plugin (move jsfl, copy animate-dev)"
```

---

## Task 2: 新增 SSOT — naming-and-state-contract.md

**Files:**
- Create: `$NEW/references/naming-and-state-contract.md`

**Interfaces:**
- Produces: 供 Task 4（animate-dev SKILL）、Task 5（createjs-developer）、Task 8（animate-jsfl SKILL）引用的 SSOT 檔名與內含定義（浮動物件判準、`{type}_{name}` 表、frame-0 預設）。

- [ ] **Step 1: 寫檔**

`$NEW/references/naming-and-state-contract.md`：

```markdown
# 命名與狀態契約（Naming & State Contract）

本檔是 animate-toolkit 的單一事實來源（SSOT），定義「浮動物件」判準、`{type}_{name}`
命名慣例、命名優先原則，以及 MovieClip 的 frame-0 靜止預設。animate-dev 與 animate-jsfl
都引用本檔。

## 通用原則（與工具無關，一定成立）

### 原則 1：不對「浮動物件」寫 code，先命名

**浮動物件** ＝ 沒有穩定 instance name 的物件，判準（符合任一即是）：
- 匯出 code 以自動編號引用：`instance_1`、`instance_23`（Animate 對未命名 instance 的預設名）。
- 無 `.name`（匿名 shape / movieclip）。
- 有名字但不符 `{type}_{name}` 慣例 → 無法從名稱判斷類型。

**為何不能碰**：自動編號會在每次 republish 重新分配 → 對它寫的引用（`this.instance_23`）
脆弱，改天重發佈就變 `undefined`、runtime TypeError。

**正確做法**：先把要操作的物件命名為 `{type}_{name}`，再寫 code 引用穩定名稱。

### 原則 2：非 anim_ 的 MovieClip 預設停在 frame 0

大部分 MovieClip 是 **state 化元件**（用 frame 表示離散狀態），不操作時應停在 frame 0
或特定靜止 frame。極性是 **rest-by-default、play-by-exception**：

- `anim_*`（或使用者確認的動畫）→ 可 `gotoAndPlay`。
- 其餘（`btn_` / `state_` / `area_` / 任何非 `anim_` MovieClip）→ `addChild` 後立即
  `gotoAndStop(0)`（或確認的靜止 label）。

曖昧時預設「靜止」，並回報「已假設為靜止態，若為動畫請告知」——不要預設放它 play。

## `{type}_{name}` 命名慣例

| type | 用途 | 預設 frame 行為 |
|---|---|---|
| `btn_` | 可點擊按鈕 | 靜止（gotoAndStop） |
| `state_` | 多 frame 狀態 | 靜止（gotoAndStop） |
| `area_` | 容器 placeholder | 靜止 |
| `anim_` | 連續動畫 | 可 gotoAndPlay |
| `scene_` | 場景頁（需 new） | 依場景 |

（完整型別處理見 `component-rules.md`。）

## 命名的建議工具（可選、不假設）

把浮動物件命名成 `{type}_{name}`：
- **建議**用 `animate-jsfl` skill 自動化：寫 driver 設 instance name、貼 frame label、
  重發佈 `index.js`，並對帳（grep 重生 `index.js` + grep 手寫 `js/`）。**需 Windows +
  Adobe Animate + 對應 infra**。
- 沒有 JSFL 環境時，**手動**在 Animate 裡命名 instance 也完全可行。

animate-dev 只**建議**、不假設你有 JSFL。命名一旦完成（不論用什麼方式），開發即可對穩定
名稱進行。
```

- [ ] **Step 2: 驗證**

```bash
grep -q "浮動物件" "$TPS/animate-toolkit/references/naming-and-state-contract.md" && \
grep -q "rest-by-default" "$TPS/animate-toolkit/references/naming-and-state-contract.md" && echo "contract OK"
```

- [ ] **Step 3: Commit（TPS）**

```bash
cd "$TPS"; git add animate-toolkit/references/naming-and-state-contract.md
git commit -m "feat(animate-toolkit): add naming-and-state SSOT contract"
```

---

## Task 3: issue-finder 擴充 — 新增浮動物件 error（index 驅動）

**Files:**
- Create: `$NEW/references/errors/err-floating-instance.md`
- Modify: `$NEW/references/error-index.md`（Functional Errors 表加一列）

**Interfaces:**
- Consumes: `error-index.md` 既有表格式（`| ID | Error Type | Symptoms Keywords | File |`）。
- Produces: `ERR-FLOATING-INSTANCE` 條目，讓 issue-finder（純 index 驅動，其 prompt 不需改）可自動比對到「code 綁自動編號名」症狀。`ERR-FRAME-NOT-PAUSED`（auto-play）已存在於 index 第 13 行，不需新增。

- [ ] **Step 1: 建 error 檔** `$NEW/references/errors/err-floating-instance.md`

```markdown
# ERR-FLOATING-INSTANCE: Code Bound to Unnamed / Auto-Numbered Instance

## Quick Summary
Code 引用了沒有穩定名稱的「浮動物件」（`instance_N` 自動編號 / 匿名），republish 後引用失效。

## Symptoms
- `this.instance_23 is undefined`、`Cannot read property of undefined`（重發佈後才壞）
- 改天重匯出就壞、之前好好的
- 元件「有時抓得到有時抓不到」
- code 裡出現 `instance_1` / `instance_23` 這種名字

## Detection
### Grep Patterns
- `instance_[0-9]+` in 手寫 `js/*.js` — code 綁了自動編號名
- 目標操作物件在 `index.js` 是否只有自動編號、無 `{type}_{name}`

### Code Pattern (Wrong)
```javascript
// index.js 未命名 → 自動編號
this.instance_23.gotoAndStop(0);   // republish 後 instance_23 可能變別的東西
```

## Fix Strategy
先命名，再引用（見 references/naming-and-state-contract.md 原則 1）：
1. 把該物件在 .fla 命名為 `{type}_{name}`（建議用 animate-jsfl skill 自動化；或手動在 Animate 命名）。
2. 重發佈 index.js。
3. code 改引用穩定名稱：`this.state_feedback.gotoAndStop(0);`
4. 對帳：grep 重生 index.js 確認新名進匯出；grep 手寫 js/ 找殘留舊名。

## Verification
- 手寫 js/ 不再出現 `instance_[0-9]+` 引用
- 目標物件皆具 `{type}_{name}` 穩定名稱
```

- [ ] **Step 2: 在 error-index.md 的 Functional Errors 表末列加一列**

在 `$NEW/references/error-index.md` 的 `ERR-CJK-PATH-RESOURCE` 那列之後、`## Performance Anti-Patterns` 之前，插入：

```markdown
| ERR-FLOATING-INSTANCE | Code Bound to Unnamed Instance | `instance_23 is undefined`, 重發佈後壞, republish breaks, 自動編號, instance_N, 浮動物件, 元件有時抓不到 | `errors/err-floating-instance.md` |
```

- [ ] **Step 3: 驗證**

```bash
cd "$TPS/animate-toolkit"
test -f references/errors/err-floating-instance.md && echo "error file OK"
grep -q "ERR-FLOATING-INSTANCE" references/error-index.md && echo "index row OK"
grep -c "ERR-FRAME-NOT-PAUSED" references/error-index.md   # 期望 >=1（本來就有）
```

- [ ] **Step 4: Commit（TPS）**

```bash
cd "$TPS"; git add animate-toolkit/references/errors/err-floating-instance.md animate-toolkit/references/error-index.md
git commit -m "feat(animate-toolkit): add ERR-FLOATING-INSTANCE for issue-finder"
```

---

## Task 4: animate-dev SKILL.md — 命名閘門 + frame-0 預設

**Files:**
- Modify: `$NEW/skills/animate-dev/SKILL.md`

**Interfaces:**
- Consumes: `references/naming-and-state-contract.md`（Task 2）。
- Produces: 新 `Phase 2.5: Naming Gate`；Phase 6 Actions 新增 frame-0 bullet。

- [ ] **Step 1: 在 `Phase 2: Codebase Exploration` 段落結束（其 `---` 分隔線）之後、`Phase 3` 之前，插入新段落**

```markdown
### Phase 2.5: Naming Gate（命名閘門）

**Goal**: 確保開發只對「有穩定名稱」的物件進行；浮動物件先命名再操作。

**CRITICAL**: 不可跳過。對浮動物件寫 code 是「開發出來會漏掉 / 之後壞掉」的主因。

**Required References**:
- `references/naming-and-state-contract.md` - 浮動物件判準、命名優先原則、frame-0 預設

**Actions**:
1. 掃相關匯出 code（`index.js` / lib / 手寫 `js/`）偵測「浮動物件」（判準見 contract 原則 1）：
   - `grep -nE 'instance_[0-9]+' <目標檔>` — 自動編號引用
   - 目標要操作的物件是否具 `{type}_{name}` 穩定名稱？
2. **若發現要操作的物件是浮動物件**：
   - **停**，不要對 `instance_N` 寫脆弱引用。
   - 向用戶說明：這些物件沒有穩定名稱，republish 會失效；應先命名為 `{type}_{name}`。
   - **建議（不假設）**：「若你有 `animate-jsfl` skill，我可以用它自動化命名 + 重發佈 +
     對帳；沒有的話你也可以在 Animate 手動命名。要走哪條？」
   - 命名完成後（走 JSFL 就依其對帳硬規則：grep 重生 index.js + grep 手寫 js/）再繼續。
3. **若全部已具穩定名稱** → 進 Phase 3。

---
```

- [ ] **Step 2: 在 `Phase 6: Implementation` 的 `Actions` 第 4 點（Agent 須遵循清單）中，於「初始化順序」bullet 之下新增一行**

在 `4. Agent 須遵循：` 底下、「優先使用 frame label」附近，加入：

```markdown
   - **Frame-0 預設（rest-by-default）**：非 `anim_` 的 MovieClip 一律 `addChild` 後
     `gotoAndStop(0)`（或確認的靜止 label）；只有 `anim_`／使用者確認的動畫才 `gotoAndPlay`。
     曖昧時預設靜止並回報。（見 `references/naming-and-state-contract.md` 原則 2）
```

- [ ] **Step 3: 驗證**

```bash
cd "$TPS/animate-toolkit/skills/animate-dev"
grep -q "Phase 2.5" SKILL.md && grep -q "命名閘門" SKILL.md && echo "gate OK"
grep -q "rest-by-default" SKILL.md && echo "frame-0 default OK"
```

- [ ] **Step 4: Commit（TPS）**

```bash
cd "$TPS"; git add animate-toolkit/skills/animate-dev/SKILL.md
git commit -m "feat(animate-dev): add naming gate phase + frame-0 rest-by-default"
```

---

## Task 5: createjs-developer agent — 硬規則

**Files:**
- Modify: `$NEW/agents/createjs-developer.md`

**Interfaces:**
- Produces: agent prompt 內 `## Hard Rules` 區塊（R1 浮動物件、R2 frame-0），並修掉既有 `if state-based` 條件偏誤。agent 讀不到 SKILL/contract，故規則必須內含於 prompt。

- [ ] **Step 1: 在 `## Core Mission` 之後、`## Before Starting` 之前，插入 Hard Rules 區塊**

```markdown
## Hard Rules（最高優先，不可違反）

### R1: 不對浮動物件寫 code
「浮動物件」＝以 `instance_N` 自動編號引用、無 `.name`、或不符 `{type}_{name}` 的實例。
- **禁止**寫 `this.instance_23` 這種脆弱引用（republish 會重編號 → 之後 `undefined`）。
- 遇到要操作的浮動物件 → **停止**，回報為「命名 blocker」：列出哪些物件、建議命名成什麼
  `{type}_{name}`，並**建議（不假設）**可用 `animate-jsfl` skill 自動化命名，或手動在 Animate
  命名。命名完成後再開發。

### R2: Frame-0 預設（rest-by-default）
- `anim_*`／使用者確認的動畫 → 可 `gotoAndPlay`。
- **其餘所有 MovieClip**（`btn_` / `state_` / `area_` / 任何非 `anim_`）→ `addChild` 後立即
  `gotoAndStop(0)`（或確認的靜止 label）。
- 曖昧時預設靜止，並在回報標注「已假設為靜止態，若為動畫請告知」。
```

- [ ] **Step 2: 修掉既有條件偏誤**

把 `### 1. Initialization Order (CRITICAL)` 程式碼區塊中的：
```javascript
// 3. THEN control frames (if state-based)
component.stop();  // or component.gotoAndStop("labelName");
```
改為：
```javascript
// 3. THEN rest the frame (rest-by-default; 見 Hard Rule R2)
component.gotoAndStop(0);  // 非 anim_：預設靜止。anim_/確認動畫才用 gotoAndPlay。
```

- [ ] **Step 3: 驗證**

```bash
cd "$TPS/animate-toolkit/agents"
grep -q "Hard Rules" createjs-developer.md && grep -q "R1: 不對浮動物件" createjs-developer.md && \
grep -q "rest-by-default" createjs-developer.md && echo "developer rules OK"
```

- [ ] **Step 4: Commit（TPS）**

```bash
cd "$TPS"; git add animate-toolkit/agents/createjs-developer.md
git commit -m "feat(createjs-developer): add floating-object + frame-0 hard rules"
```

---

## Task 6: component-analyzer agent — 浮動實例專節

**Files:**
- Modify: `$NEW/agents/component-analyzer.md`

**Interfaces:**
- Produces: `## Output Guidance` 內新增「浮動 / 無名實例（必列）」項，作為 animate-dev 命名閘門的輸入。

- [ ] **Step 1: 在 `## Output Guidance` 的清單中（`- **Component hierarchy diagram**` 那組 bullet 內）新增一項**

```markdown
- **浮動 / 無名實例（必列）**：掃出以 `instance_N` 自動編號、無 `.name`、或不符
  `{type}_{name}` 的實例，列成表並標「建議先命名（見 references/naming-and-state-contract.md）」。
  這是 animate-dev 命名閘門的輸入；不要略過。
```

- [ ] **Step 2: 驗證**

```bash
grep -q "浮動 / 無名實例" "$TPS/animate-toolkit/agents/component-analyzer.md" && echo "analyzer section OK"
```

- [ ] **Step 3: Commit（TPS）**

```bash
cd "$TPS"; git add animate-toolkit/agents/component-analyzer.md
git commit -m "feat(component-analyzer): report floating/unnamed instances"
```

---

## Task 7: code-reviewer agent — 兩項新檢查

**Files:**
- Modify: `$NEW/agents/code-reviewer.md`

**Interfaces:**
- Produces: `### 3. CreateJS Conventions` 的 `**Check**` 清單新增兩項高嚴重檢查（浮動物件引用、frame-0 靜止）。

- [ ] **Step 1: 在 `### 3. CreateJS Conventions` 的 `**Check**:` bullet 清單末端新增兩項**

```markdown
- **浮動物件引用（高嚴重）**：code 是否引用 `instance_N` 等自動編號名稱？
  → finding：改名為 `{type}_{name}`（見 references/naming-and-state-contract.md 原則 1）。
- **靜止預設（高嚴重）**：非 `anim_` 的 MovieClip 是否都在 `addChild` 後停在 frame 0 /
  靜止 label？漏停 → finding：補 `gotoAndStop(0)`（見 contract 原則 2）。
```

- [ ] **Step 2: 驗證**

```bash
cd "$TPS/animate-toolkit/agents"
grep -q "浮動物件引用" code-reviewer.md && grep -q "靜止預設" code-reviewer.md && echo "reviewer checks OK"
```

- [ ] **Step 3: Commit（TPS）**

```bash
cd "$TPS"; git add animate-toolkit/agents/code-reviewer.md
git commit -m "feat(code-reviewer): add floating-ref + frame-0 rest checks"
```

---

## Task 8: animate-jsfl SKILL.md — 作為命名閘門被呼叫

**Files:**
- Modify: `$NEW/skills/animate-jsfl/SKILL.md`

**Interfaces:**
- Consumes: `references/naming-and-state-contract.md`（plugin 層，路徑從 skill dir 為 `../../references/naming-and-state-contract.md`）。
- Produces: 新一節，說明被 animate-dev 命名閘門呼叫時要用 `{type}_{name}` 詞彙命名。

- [ ] **Step 1: 在 `## 與其他 skill 的關係` 之前，插入新節**

```markdown
## 作為 animate-dev 命名閘門被呼叫時

當 animate-dev 因遇到「浮動物件」把命名工作交來時：

- **用 `{type}_{name}` 詞彙命名**（`btn_` / `state_` / `area_` / `anim_` / `scene_`），
  讓 dev 之後能靠前綴分類、套 frame-0 預設。命名慣例與 frame-0 規則的權威定義在
  plugin 層 `references/naming-and-state-contract.md`。
- 命名後照本 skill 既有硬規則對帳：grep 重生的 `index.js` 確認新名進匯出；若改了既有
  instance 名，另 grep 手寫 `js/`（排除重生 `index.js`）找殘留舊名引用並更新。
- 完成後把「已命名清單（舊名 → 新 `{type}_{name}`）」回報給 dev，dev 才對穩定名稱開發。

```

- [ ] **Step 2: 驗證**

```bash
grep -q "作為 animate-dev 命名閘門被呼叫時" "$TPS/animate-toolkit/skills/animate-jsfl/SKILL.md" && echo "jsfl section OK"
```

- [ ] **Step 3: Commit（TPS）**

```bash
cd "$TPS"; git add animate-toolkit/skills/animate-jsfl/SKILL.md
git commit -m "feat(animate-jsfl): add naming-gate handoff section"
```

---

## Task 9: 更新 outsourcing manifest + TPS marketplace

**Files:**
- Modify: `$TPS/outsourcing/.claude-plugin/plugin.json`（移除 jsfl、bump `1.6.0`→`1.7.0`）
- Modify: `$TPS/.claude-plugin/marketplace.json`（註冊 animate-toolkit；修正 stale 的 outsourcing 條目）

**Interfaces:**
- Consumes: Task 1 已 `git mv` 移走 jsfl skill 目錄。
- Produces: 兩份 manifest 與實際檔案一致。

- [ ] **Step 1: 改 `$TPS/outsourcing/.claude-plugin/plugin.json`**

把 `version` 改為 `"1.7.0"`；`description` 改為（移除 JSFL 子句、renumber，保留 intake-triage）：

```
外包接案工具組 — 涵蓋接案四階段：(1) 估價：Adobe Animate 轉 Canvas (CreateJS) 外包報價流程，產出結構化報價、澄清清單、技術方案比較與降價方案 (animate-estimator)；(2) 版本／檔案處理：以 GitHub private repo 為唯一真實來源 (SSOT)、Git LFS 管理大型二進位檔，把每次客戶回檔的完整資料夾原地吃進對應 repo (project-handoff)；(3) 乾淨交付：打包專案上傳 Google Drive 前，用兩層排除（穩定名單＋AI 補抓）移除 .git／CLAUDE.md／.env 等開發鷹架與身份痕跡 (project-deliver)；(4) 接單判讀：拿到派工上下文時，用三軸判讀（訊息軸守門／負載軸分類／歷史軸校準完整度）判斷任務類型與資料是否夠開工 (intake-triage)
```

`keywords`：移除 jsfl 相關（`jsfl`, `JSFL`, `animate-jsfl`, `Animate 自動化`, `命令列`, `標籤化`, `發佈`, `publish`, `automation`），保留其餘（含 intake-triage 相關）。

- [ ] **Step 2: 改 `$TPS/.claude-plugin/marketplace.json`**

(a) 在 `plugins` 陣列新增 animate-toolkit 條目（比照 TPS 既有條目格式：僅 name/source/description/version/keywords）：

```json
{
  "name": "animate-toolkit",
  "source": "./animate-toolkit",
  "description": "Adobe Animate + CreateJS 工具組 — 開發（animate-dev：CreateJS 互動/遊戲邏輯，含命名閘門與 frame-0 靜止預設）、效能（animate-performance：7 大效能問題掃描與修復）、JSFL 自動化（animate-jsfl：命令列驅動 Animate 標籤化／命名 instance／重發佈 index.js，需 Windows + Adobe Animate）",
  "version": "1.0.0",
  "keywords": ["adobe-animate","createjs","animation","canvas","performance","jsfl","animate-jsfl","automation","標籤化","命名","movieclip","state","命名閘門"]
}
```

(b) 修正既有 `outsourcing` 條目（目前 stale：`version` 1.4.3、描述缺 intake-triage）：`version` 改 `"1.7.0"`，`description` 與 keywords 同步為 Step 1 的內容。

- [ ] **Step 3: 驗證**

```bash
cd "$TPS"
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); json.load(open('outsourcing/.claude-plugin/plugin.json')); print('JSON OK')"
python3 - <<'PY'
import json
mk=json.load(open('.claude-plugin/marketplace.json'))
names=[p['name'] for p in mk['plugins']]
assert 'animate-toolkit' in names, names
ot=[p for p in mk['plugins'] if p['name']=='outsourcing'][0]
pj=json.load(open('outsourcing/.claude-plugin/plugin.json'))
assert ot['version']==pj['version']=='1.7.0', (ot['version'],pj['version'])
assert 'animate-jsfl' not in ot['description'] and 'animate-jsfl' not in pj['description']
print('marketplace consistency OK')
PY
```

- [ ] **Step 4: Commit（TPS）**

```bash
cd "$TPS"; git add outsourcing/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore(marketplace): register animate-toolkit; drop jsfl from outsourcing; fix stale entry"
```

---

## Task 10: 從 ai-agent-extension 移除 animate-dev

**Files:**
- Delete: `$AAE/plugins/animate-dev/`（整個）
- Modify: `$AAE/.claude-plugin/marketplace.json`（移除 animate-dev 條目）
- Delete symlinks: `$AAE/.claude/skills/animate-dev`, `$AAE/.claude/skills/animate-performance`, `$AAE/.cursor/skills/animate-dev`, `$AAE/.cursor/skills/animate-performance`

**Interfaces:**
- Consumes: animate-toolkit 已在 TPS 完成並驗證（Task 1–9）。
- Produces: AAE 不再含 animate-dev；無斷掉 symlink。

- [ ] **Step 1: 移除 plugin 目錄與 symlink**

```bash
cd "$AAE"
git rm -r plugins/animate-dev
rm -f .claude/skills/animate-dev .claude/skills/animate-performance
rm -f .cursor/skills/animate-dev .cursor/skills/animate-performance
```

- [ ] **Step 2: 從 `$AAE/.claude-plugin/marketplace.json` 的 `plugins` 陣列移除 `name==animate-dev` 的條目**

（用編輯器移除該物件；保持 JSON 合法。）

- [ ] **Step 3: 驗證**

```bash
cd "$AAE"
test ! -e plugins/animate-dev && echo "plugin dir removed OK"
python3 -c "import json; d=json.load(open('.claude-plugin/marketplace.json')); assert not any(p['name']=='animate-dev' for p in d['plugins']); print('marketplace entry removed OK')"
# 無斷掉 symlink：
for l in .claude/skills/animate-dev .claude/skills/animate-performance .cursor/skills/animate-dev .cursor/skills/animate-performance; do
  test ! -e "$l" && echo "symlink gone: $l"; done
find .claude/skills .cursor/skills -xtype l -print   # 期望：無輸出（無斷鏈）
```

- [ ] **Step 4: Commit（AAE）**

注意：AAE 有 version-bump PreToolUse hook；本次無修改任何 plugin.json（是刪除 plugin），hook 不應阻擋。若被擋，讀 hook 訊息依指示處理，勿 `--no-verify`。

```bash
cd "$AAE"; git add -A
git commit -m "refactor: remove animate-dev (merged into animate-toolkit in tim-private-skills)"
```

---

## Task 11: 同步 cache、reload、端對端驗證

**Files:** 無（啟用與驗證）

**Interfaces:**
- Consumes: Task 1–10 全部完成並各自 commit。

- [ ] **Step 1: 判斷 TPS cache 同步機制**

```bash
CACHE=~/.claude/plugins/marketplaces/tim-private-skills
git -C "$CACHE" remote -v 2>/dev/null || echo "(cache 非 git clone)"
git -C "$CACHE" log --oneline -1 2>/dev/null
```

- 若 cache 是 TPS 遠端的 clone：`cd "$TPS" && git push`（先取得使用者同意）後，於 Claude Code 執行 `/plugin` → 更新 marketplace → 重裝 animate-toolkit。
- 若 cache 直接指向本機 source / 需手動同步：依既有慣例同步（memory：「編輯 source + 同步 cache」）。

- [ ] **Step 2: Reload plugins（使用者端動作）**

請使用者執行 `/plugin`（更新 tim-private-skills marketplace、安裝 `animate-toolkit`、移除舊 `animate-dev`）後 `/reload-plugins`。

- [ ] **Step 3: 行為抽查（給定輸入驗規則）**

- 給一段含 `this.instance_23.gotoAndStop(0)` 的匯出片段 → 觸發 `animate-dev`，應在 Phase 2.5 命名閘門**擋下**並建議命名（提及 JSFL 為選項、不假設），而非直接改 code。
- 給一個 `state_feedback` MovieClip → `createjs-developer` 應輸出 `addChild` 後 `gotoAndStop(0)`，並標注「已假設靜止態」。
- 對含 `instance_N` 引用的 code 跑 `code-reviewer` → 應回報浮動物件引用 finding。

- [ ] **Step 4: 最終一致性驗證**

```bash
# TPS
python3 -c "import json; json.load(open('$TPS/.claude-plugin/marketplace.json')); print('TPS marketplace OK')"
ls "$TPS/animate-toolkit/skills"   # animate-dev animate-jsfl animate-performance
# AAE
python3 -c "import json; json.load(open('$AAE/.claude-plugin/marketplace.json')); print('AAE marketplace OK')"
grep -q "naming-and-state-contract" "$TPS/animate-toolkit/skills/animate-dev/SKILL.md" && echo "contract referenced OK"
```

- [ ] **Step 5: 清理**：完成後刪除任何任務 state file（若執行時建立過）。

---

## Self-Review（plan vs spec）

- **Spec §2 決策**（家/名/skill/力道/JSFL 依賴）→ Task 1（家、名、skill）、Task 4–8（深力道）、全程 Global Constraints（JSFL 建議不假設）。✅
- **Spec §3 結構** → Task 1 組出，references 保持 plugin 層（Global Constraints）。✅
- **Spec §4.2 命名閘門** → Task 4（SKILL Phase 2.5）+ Task 5 R1（agent）。✅
- **Spec §4.3 frame-0** → Task 4（SKILL Phase 6）+ Task 5 R2 + Task 7（reviewer 檢查）。✅
- **Spec §4.4 各處編碼** → contract(Task2)、animate-dev SKILL(Task4)、createjs-developer(Task5)、component-analyzer(Task6)、code-reviewer(Task7)、issue-finder(Task3, index 驅動)、animate-jsfl(Task8)。✅
- **Spec §5 搬遷** → Task1（組）、Task9（outsourcing+TPS marketplace）、Task10（AAE 移除）、Task11（cache/reload）。✅
- **Spec §6 驗證** → Task 11 Step 3–4。✅
- **Spec §7 風險** → bump hook（Task10 note）、JSFL 平台（plugin.json 描述標注 Windows）、references 路徑 quirk（Task11 grep 驗證 + Global Constraints 保持 plugin 層）、cache 同步（Task11 Step1）。✅
- **Placeholder scan**：無 TBD/TODO；每個編輯步驟含實際內容。✅
- **一致性**：`{type}_{name}`、`gotoAndStop(0)`、`instance_N`、`naming-and-state-contract.md`、`ERR-FLOATING-INSTANCE` 全文一致。✅
