# User Story 方法論比較分析：朱騏文章 vs spec-writer Plugin

## Context

比較朱騏 Medium 文章《產品規劃系列(一)》的 User Story 方法論與 `plugins/spec-writer/` 的撰寫體系，評估各自的方法論深度、顆粒度控制、以及適用場景。

---

## 一、方法論摘要

### 朱騏文章的方法論

| 面向 | 內容 |
|------|------|
| **Story 公式** | As a [角色], I want [需求], so that [價值] |
| **AC 格式** | 條列式 pass/fail（如：登入成功/登入失敗） |
| **顆粒度控制** | User Story Mapping（Jeff Patton）三層結構：Activity > Task > Story |
| **品質檢查** | 無 |
| **Story 分類** | 無（僅有 User Story 一種） |
| **優先序** | 透過 Story Mapping 的「時間切片」隱含 release 優先序 |
| **流程** | 無正式流程，屬於概念介紹 |

### spec-writer Plugin 的方法論

| 面向 | 內容 |
|------|------|
| **Story 公式** | 身為＿＿，我需要＿＿，以便＿＿ |
| **AC 格式** | Given-When-Then 情境式，含 Happy Path / Error Path / Edge Case 分組 |
| **顆粒度控制** | INVEST-S 原則（一個 Sprint 內可完成）+ 拆分指引 |
| **品質檢查** | INVEST 六項逐條檢查 + 7 大反模式掃描 + AC 情境覆蓋度 + spec-reviewer agent |
| **Story 分類** | User Story / Enabler Story / Spike 三類，各有專屬模板 |
| **優先序** | P0-P3 四級，依賴 / 用戶價值 / 風險 / 成本價值比 四維度排序 |
| **流程** | 四階段 gated workflow：Context → Clarification → Writing → Review |

---

## 二、逐項比較

### 2.1 Story 撰寫公式

**相同點：** 兩者都採用經典三段式（角色-需求-價值）。

**差異：**
- 朱騏：僅示範 User Story 一種類型，beneficiary 未限制具體程度
- spec-writer：明確區分三種 Story 類型，且警告「身為使用者」太模糊（反模式 #3），要求具體角色如「身為國小老師」

### 2.2 AC（驗收標準）

| | 朱騏 | spec-writer |
|--|------|-------------|
| 格式 | 條列式（登入成功：…、登入失敗：…） | Given-When-Then 結構化情境 |
| 情境分類 | 無 | Happy Path（必要）/ Error Path / Edge Case |
| 可測試性 | 隱含 | 明確要求「QA 能直接寫測試案例」 |
| 結果導向 | 未特別強調 | 明確區分 Outcome-Focused vs Implementation-Focused |

**顆粒度差異最大的地方。** 朱騏的 AC 是「登入成功：輸入正確帳密，成功登入會員畫面」，spec-writer 會要求寫成：

```
情境 1: 正常登入（Happy Path）
GIVEN 使用者在登入頁面
  AND 已註冊帳號 user@example.com
WHEN 使用者輸入正確帳號密碼並點擊登入
THEN 頁面導向會員首頁
  AND 顯示使用者名稱
```

### 2.3 顆粒度控制

| | 朱騏 | spec-writer |
|--|------|-------------|
| 方法 | User Story Mapping 三層（Activity → Task → Story） | INVEST-S（Sprint 內完成）+ 拆分指引 |
| 視角 | **全局鳥瞰**：從使用者旅程出發，由上往下拆解 | **單一 Story 品質**：確保每個 Story 大小適中 |
| 拆分策略 | 按使用者行為階層自然拆分 | 按用戶步驟 / 資料類型 / happy-error 路徑 / 平台拆分 |

**這是兩者最互補的地方。** 朱騏的 Story Mapping 解決「如何從模糊需求拆出 Stories」，spec-writer 解決「每個 Story 是否寫得夠好」。

### 2.4 品質保證

- **朱騏：** 無品質檢查機制。文章性質為入門介紹，未涉及。
- **spec-writer：** 三層品質防線：
  1. INVEST 六項逐條 pass/fail
  2. 7 大反模式掃描（洩漏實作細節、任務偽裝成 Story、模糊受益者等）
  3. AC 情境覆蓋度檢查 + spec-reviewer agent 自動審查

### 2.5 Scope 管理

- **朱騏：** Story Mapping 的「時間切片」概念（Release 1 / Release 2），屬於隱含的 scope 管理
- **spec-writer：** 明確的 Scoping 方法論：
  - Appetite vs Estimate 區分（固定時間 vs 固定範圍）
  - No-gos 清單（明確列出不做的事）
  - Rabbit Holes 風險標記

---

## 三、優缺點評估

### 朱騏文章

**優點：**
1. **入門友善**：公式簡單、範例直觀，5 分鐘可理解核心概念
2. **全局視角**：User Story Mapping 提供從「模糊目標」到「具體功能」的結構化拆解路徑，這是 spec-writer 目前缺少的
3. **Release 規劃**：Story Mapping 天然支援「哪些先做、哪些後做」的 release planning 視角
4. **溝通工具**：Story Map 作為視覺化工具，適合跨團隊對齊共識

**缺點：**
1. **AC 過於粗糙**：條列式 AC 無法直接轉化為測試案例，容易遺漏邊界情境
2. **無品質標準**：沒有檢驗機制，無法判斷寫出的 Story 好不好
3. **不區分 Story 類型**：技術性工作（如建 CI/CD）勉強套 User Story 格式會很彆扭
4. **顆粒度判斷主觀**：「什麼時候該繼續往下拆」缺乏明確標準
5. **無 Scope 邊界意識**：未提及 No-gos、Rabbit Holes 等防範 scope creep 的機制

### spec-writer Plugin

**優點：**
1. **AC 結構嚴謹**：Given-When-Then + 情境分組，每條 AC 可直接轉測試案例
2. **品質可量化**：INVEST + 反模式提供客觀的 pass/fail 標準，減少主觀判斷
3. **Story 類型完整**：User Story / Enabler Story / Spike 覆蓋不同性質的工作項目
4. **流程完整**：四階段 gated workflow 確保不跳步，每階段有明確產出
5. **Scope 防護**：No-gos、Appetite、Rabbit Holes 防止需求蔓延
6. **自動化審查**：spec-reviewer agent 提供一致的品質審查

**缺點：**
1. **缺乏全局拆解指引**：沒有類似 Story Mapping 的方法從「大目標」系統性拆解出 Stories，Phase 1 依賴使用者自行帶入需求
2. **學習曲線陡**：INVEST、反模式、Given-When-Then、三種 Story 類型——新手一次要消化太多概念
3. **過度工程化風險**：小型專案或探索性工作可能不需要如此嚴格的流程
4. **缺少使用者旅程視角**：專注於單一 Story 品質，但缺乏「Stories 之間如何構成完整使用者體驗」的全局對照
5. **框架引用多但整合鬆散**：提及 JTBD、Shape Up、Working Backwards 但未深度整合進流程中，偏向「知道有這些」的參考

---

## 四、總結

| 維度 | 朱騏 | spec-writer |
|------|------|-------------|
| 定位 | 概念入門 + 全局拆解 | 實戰撰寫 + 品質保證 |
| 最大優勢 | Story Mapping 的鳥瞰拆解能力 | AC 結構化 + INVEST 品質閘門 |
| 最大缺口 | 缺品質標準和 AC 結構 | 缺全局拆解（Story Mapping）指引 |
| 適合誰 | PM 新手、需要快速理解 Story 概念的人 | 已理解 Story 概念、需要提升撰寫品質的團隊 |
| 適合何時 | 專案初期的需求探索和功能拆解 | Sprint planning 階段的 Story 撰寫和審查 |

**兩者互補性高：** 朱騏的 Story Mapping 適合解決「從 0 到 Stories」的拆解問題；spec-writer 適合解決「Stories 寫得好不好」的品質問題。理想流程是先用 Story Mapping 拆解全局，再用 spec-writer 的方法論撰寫每個 Story。
