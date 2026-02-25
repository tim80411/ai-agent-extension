---
name: spec-writing
description: >-
  This skill should be used when the user asks to "撰寫 spec", "寫 user story",
  "寫 story", "撰寫需求規格", "write spec", "write user story",
  "撰寫驗收標準", "寫 acceptance criteria", "拆分 story", "拆解需求",
  "檢查 story 品質", "INVEST 檢查", "反模式掃描",
  "review my user stories", "break down a feature into stories",
  or needs guidance on spec writing methodology, story types,
  scoping, acceptance criteria, prioritization, or INVEST quality checks.
---

# Spec 撰寫方法論

遵循以下三階段流程撰寫高品質的 User Story 與 Enabler Story：釐清目標、撰寫 Stories、品質檢查。

## 流程總覽

```
Phase 1: 釐清目標
  1.1 辨識受益者 → 1.2 定義期望成果 → 1.3 劃定範圍邊界

Phase 2: 撰寫 Stories
  2.1 分類 Story 類型 → 2.2 撰寫 Story 本體
  → 2.3 撰寫驗收標準（可與 2.4、2.5 平行）
  → 2.4 撰寫價值陳述（可與 2.3、2.5 平行）
  → 2.5 標記優先序（可與 2.3、2.4 平行）

Phase 3: 品質檢查（以下三項可平行，任一不通過回到 Phase 2）
  3.1 INVEST 逐條檢查
  3.2 反模式掃描
  3.3 利害關係人審閱
```

---

## Phase 1: 釐清目標

### Step 1.1 — 辨識受益者

確保每個 Story 有明確的受益者。受益者不限於終端使用者。

| 受益者類型 | 適用情境 | 範例 |
|-----------|----------|------|
| 終端使用者 | 功能性需求 | 老師、學生、家長 |
| 開發團隊 | 技術賦能型需求 | 開發者、維運人員 |
| 管理者 | 營運可視化需求 | PM、主管 |

> 詳見 → `references/01-story-types.md`

### Step 1.2 — 定義期望成果

用一句話描述：「完成這個 Story 後，世界有什麼不同？」

檢查點：
- 成果是否可被受益者直接感知或使用？
- 成果描述中是否不含任何技術實作手段？

### Step 1.3 — 劃定範圍邊界

明確寫出「不做什麼」（No-gos），避免範圍蔓延。

> 詳見 → `references/02-scoping.md`（Shape Up pitch 中的 Rabbit Holes & No-gos）

---

## Phase 2: 撰寫 Stories

### Step 2.1 — 分類 Story 類型

先判斷這是哪一類 Story，再選擇對應的撰寫格式。

| 類型 | 格式 | 何時使用 |
|------|------|----------|
| User Story | 「身為 ___，我需要 ___，以便 ___」 | 需求有明確的使用者價值 |
| Enabler Story | 標題 + 價值陳述 + 驗收標準 | 基礎設施、安全、效能等技術性工作 |

判斷流程：
```
這項工作完成後，終端使用者能直接感受到嗎？
  ├── 是 → User Story
  └── 否 → 這項工作賦能了哪些 User Story？
           ├── 能明確指出 → Enabler Story（附上關聯）
           └── 指不出來 → 重新思考這項工作是否必要
```

> 詳見 → `references/01-story-types.md`

### Step 2.2 — 撰寫 Story 本體

- User Story 使用三段式：身為 / 我需要 / 以便
- Enabler Story 使用：標題 + 一段價值陳述（這項工作賦能了什麼）

檢查點：
- Story 是否可以有多種實作方式？（若只有一種，可能在規定 How）
- 非技術的利害關係人是否能讀懂？

### Step 2.3 — 撰寫驗收標準

以「What」而非「How」撰寫驗收標準。採用 Outcome-Focused 寫法。

> 詳見 → `references/03-acceptance-criteria.md`

### Step 2.4 — 撰寫價值陳述

Enabler Story 專用。說明這項技術工作如何賦能後續的 User Story。

### Step 2.5 — 標記優先序

基於依賴關係和使用者價值排序，標記為 P0 / P1 / P2 / P3。

> 詳見 → `references/04-prioritization.md`

---

## Phase 3: 品質檢查

以下三項檢查可平行進行。任一項不通過則回到 Phase 2 修正。

### Check 3.1 — INVEST 逐條檢查

對每個 Story 逐一檢驗六項標準：Independent、Negotiable、Valuable、Estimable、Small、Testable。

> 詳見 → `references/05-invest-checklist.md`

### Check 3.2 — 反模式掃描

比對常見反模式清單，確認沒有踩坑：洩漏實作細節、任務偽裝成 Story、模糊的受益者、Feature-First、按技術層切分、驗收標準規定 UI 設計、所有 Story 都是 P0。

> 詳見 → `references/06-anti-patterns.md`

### Check 3.3 — 利害關係人審閱

將 Stories 交由工程、設計、業務等角色審閱，確認：
- 工程團隊認為可估算且不被過度限制
- 業務/管理者認為價值描述準確
- 沒有遺漏的邊界案例

---

## 參考文件索引

### Reference Files

詳細內容請參閱以下文件：

- **`references/01-story-types.md`** — User Story vs. Enabler Story 的定義、格式、範例
- **`references/02-scoping.md`** — 範圍界定方法（Shape Up pitch、No-gos、Appetite）
- **`references/03-acceptance-criteria.md`** — 驗收標準撰寫原則與好壞對比範例
- **`references/04-prioritization.md`** — 優先序排定方法
- **`references/05-invest-checklist.md`** — INVEST 六項檢查標準與實際操作方式
- **`references/06-anti-patterns.md`** — 常見反模式清單與修正方式
- **`references/07-frameworks-comparison.md`** — 各方法論比較（JTBD、Shape Up、Working Backwards）
