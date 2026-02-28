# spec-writer plugin: AC 即 Test Cases 強化設計

## 背景

參考文章[【產品規劃系列】寫下使用者的心聲！搞懂 User Story 和 Acceptance Criteria Test Cases 的關係](https://medium.com/pm%E7%9A%84%E7%94%9F%E7%94%A2%E5%8A%9B%E5%B7%A5%E5%85%B7%E7%AE%B1/%E7%94%A2%E5%93%81%E8%A6%8F%E5%8A%83%E7%B3%BB%E5%88%97-%E5%AF%AB%E4%B8%8B%E4%BD%BF%E7%94%A8%E8%80%85%E7%9A%84%E5%BF%83%E8%81%B2-96b8f0dc116c)的核心觀點：

- User Story 寫完後，必須轉換成 Acceptance Criteria Test Cases
- Given-When-Then 是核心格式（Given 可多條件，When 只一個觸發）
- AC 和 Test Cases 是一體的，每條 AC 就是可執行的測試規格

## 方案選擇

選擇 **方案 C：融合式 — AC 即 Test Cases**。不新增流程階段，而是強化 AC 格式與品質審查。

## 改動清單

### 1. `references/03-acceptance-criteria.md` — 強化 AC 格式

**改動要點：**

- Given-When-Then 從「可選格式」提升為 **AC 的主要撰寫格式**
- 新增規則：Given 可多條件（用 AND 串接），When 只一個觸發動作
- 新增 **情境分組** 概念：
  - Happy Path（正常流程）— 必要
  - Error Path（錯誤處理）— 視需求
  - Edge Case（邊界情境）— 視需求
- 新增「AC 即 Test Case」概念：每條 Given-When-Then 都應可被 QA 直接轉為測試案例
- 保留 Outcome-Focused 原則（Given-When-Then 一樣不能洩漏實作細節）

**範例：**

```
情境 1: 正常查詢年資超過 5 年的員工（Happy Path）
GIVEN 現在時間是 2019/01/01
  AND 系統中有年資超過 5 年的員工資料
WHEN 我撈取年資超過 5 年的員工資料
THEN 報表資料筆數應為 2
  AND 第一筆資料應為 Bob（年資 6 年）

情境 2: 查無符合條件的員工（Edge Case）
GIVEN 現在時間是 2019/01/01
  AND 系統中沒有年資超過 10 年的員工
WHEN 我撈取年資超過 10 年的員工資料
THEN 報表顯示「查無資料」提示
```

### 2. 目錄結構調整 — Templates 移至 `assets/`

**Before：**
```
skills/spec-writing/
├── SKILL.md
└── references/
    ├── 01-story-types.md ~ 08-workflow-conventions.md
    ├── user-story.md      ← template
    ├── enabler-story.md   ← template
    └── spike.md           ← template
```

**After：**
```
skills/spec-writing/
├── SKILL.md
├── references/            ← 方法論文件
│   ├── 01-story-types.md ~ 08-workflow-conventions.md
└── assets/                ← 模板（新目錄）
    ├── user-story.md
    ├── enabler-story.md
    └── spike.md
```

### 3. Templates 改動（`assets/user-story.md` / `assets/enabler-story.md`）

驗收標準區塊從 bullet points 改為 Given-When-Then 情境格式：

**Before：**
```
h2. 驗收標準

* 驗收條件 1
* 驗收條件 2
* 驗收條件 3
```

**After：**
```
h2. 驗收標準

情境 1: ＿＿（Happy Path）
GIVEN ＿＿
WHEN ＿＿
THEN ＿＿

情境 2: ＿＿（Error Path）
GIVEN ＿＿
WHEN ＿＿
THEN ＿＿

情境 3: ＿＿（Edge Case）
GIVEN ＿＿
WHEN ＿＿
THEN ＿＿
```

情境數量不固定，但至少需要 Happy Path。Error/Edge 視需求決定。

### 4. `SKILL.md` Phase 2 改動

在 Story Writing 步驟中新增 AC 撰寫指引：

> **撰寫驗收標準時，以 Given-When-Then 情境格式撰寫（參照 `references/03-acceptance-criteria.md`）：**
> - 每個 Story 至少包含 Happy Path 情境
> - 評估是否需要 Error Path 和 Edge Case 情境
> - Given 可包含多個前提條件（用 AND 串接），When 只有一個觸發動作
> - 每條情境都應可被 QA 直接轉為測試案例

同時更新所有 template 路徑引用，從 `references/` 改為 `assets/`。

### 5. `agents/spec-reviewer.md` 改動

品質審查新增「AC 情境覆蓋度檢查」維度：

**新增檢查項目：**
- 是否至少有 Happy Path 情境？
- 是否有考慮 Error Path？（若明顯有錯誤情境但未涵蓋，標記為「需補充」）
- Given-When-Then 格式是否正確？（Given 多條件 OK、When 是否只有一個觸發？）
- 每條情境是否具體到 QA 可直接寫測試？

**新增輸出區塊：**
```
### AC 情境覆蓋度
- Happy Path: ✅/❌
- Error Path: ✅/❌/N/A [說明]
- Edge Case: ✅/❌/N/A [說明]
- Given-When-Then 格式正確性: ✅/❌ [說明]
```

## 不做什麼（No-gos）

- 不新增流程階段（不加 Phase 2.5）
- 不建立獨立的 Test Cases 產出文件
- 不改動 Phase 0、Phase 1、Phase 3 的流程邏輯
- Spike template 不改（Spike 沒有驗收標準）

## 影響的檔案

| 檔案 | 動作 |
|------|------|
| `references/03-acceptance-criteria.md` | 改寫 |
| `assets/user-story.md` | 從 references/ 搬移 + 改寫 |
| `assets/enabler-story.md` | 從 references/ 搬移 + 改寫 |
| `assets/spike.md` | 從 references/ 搬移（不改內容） |
| `SKILL.md` | 修改 Phase 2 + 更新 template 路徑 |
| `agents/spec-reviewer.md` | 新增 AC 情境覆蓋度檢查 |
| `references/08-workflow-conventions.md` | 更新 template 路徑引用（若有） |
