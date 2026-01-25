---
name: animate-dev
description: Adobe Animate + CreateJS development expert for interactive HTML5 Canvas projects. Use when working with Adobe Animate, CreateJS, MovieClips, timeline animations, frame-based states, or when debugging CreateJS issues like "gotoAndStop undefined", scope problems, memory leaks, or event handling issues.
---

# Adobe Animate + CreateJS Development

協助開發、修改、除錯 Adobe Animate + CreateJS 互動應用程式。

## 開始前

1. **檢查 Project Memory**：讀取 `CLAUDE.md` 或 `.claude/project-memory.md`
2. **使用已知知識**：避免重複詢問已記錄的元件資訊
3. **Critical Check**：確認 `createjs-[version].min.js` 存在於 js/ 目錄

## 流程

### Phase 1: Discovery

**Goal**: 理解用戶需求

**Actions**:
1. 建立 todo list 追蹤進度
2. 判斷需求類型：
   - **新功能**：「幫我加一個下一頁按鈕」
   - **修改功能**：「把 menu 改成可拖曳」
   - **行為不對**：「click 沒反應」「動畫跑太快」
3. 如果需求不清楚，詢問用戶：
   - 要做什麼？
   - 影響哪些元件？
   - 預期行為是什麼？

---

### Phase 2: Codebase Exploration

**Goal**: 理解相關程式碼結構

**Required References**:
- `references/component-rules.md` - 元件命名規則與類型定義
- `references/createjs-web-patterns.md` - CreateJS 架構模式（當需要理解 Container/MovieClip 結構時）

**Actions**:
1. 啟動2-3個 `component-analyzer` agent 分析相關元件
2. Agent 任務範例：
   - 「分析 menu_1 到 menu_14 的元件結構、層級關係、事件綁定」
   - 「分析 SceneManager 如何管理場景切換」
3. Agent 須回傳：
   - 元件層級圖
   - 元件類型對照表
   - Frame label 定義
   - 關鍵檔案清單（5-10 個）
4. 讀取 agent 回報的關鍵檔案
5. 整理發現，向用戶確認理解是否正確
6. 更新 Project Memory

---

### Phase 3: Clarifying Questions

**Goal**: 在設計前釐清所有模糊之處

**CRITICAL**: 這是最重要的階段之一，不可跳過。

**Required References**:
- `references/component-rules.md` - 元件類型詢問模板、state/scene 確認流程

**Actions**:
1. 回顧 codebase 分析結果和原始需求
2. 根據 component-rules.md 識別需要確認的元件定義：
   - 不符合 `{type}_{name}` 規則的元件類型
   - State 元件的各 frame 意義
   - Scene 數量和用途
   - 缺少 frame label 的元件
3. 識別其他未明確的面向：
   - 邊界情況（edge cases）
   - 錯誤處理
   - 整合點
   - 設計偏好
   - 效能需求
4. **將所有問題以清晰、有組織的列表呈現給用戶**
5. **等待用戶回答後再進入下一階段**
6. 將確認的資訊儲存到 Project Memory

若用戶說「你覺得怎樣就怎樣」，請提供你的建議並取得明確確認。

---

### Phase 4: Architecture Design（僅當「新功能」或「修改功能」時）

**Goal**: 設計多種實作方案，提供不同權衡選擇

**Actions**:
1. 根據 codebase 分析結果，設計 2-3 種實作方案：
   - **最小變動方案**：改動最少、最大程度重用現有程式碼
   - **乾淨架構方案**：可維護性優先、優雅抽象
   - **務實平衡方案**：速度與品質兼顧
2. 考量因素：小修改 vs 大功能、緊迫性、複雜度、專案脈絡
3. 向用戶呈現：
   - 每種方案的簡要說明
   - 權衡比較
   - **你的建議及理由**
   - 具體實作差異
4. **詢問用戶偏好哪種方案**

---

### Phase 5: Issue Analysis（僅當「行為不對」時）

**Goal**: 定位問題根源

**Required References**:
- `references/common-mistakes.md` - 常見錯誤模式診斷（功能性錯誤：TypeError、scope 問題、初始化順序）
- `references/common-patterns.md` - 效能反模式診斷（效能問題：memory leak、event listener leak）

**Actions**:
1. 啟動 `issue-finder` agent
2. Agent 任務範例：
   - 「用戶反映 menu_1 的 click 沒反應，根據 component-analyzer 的分析，找出問題根源」
3. Agent 須回傳：
   - 問題位置（file:line）
   - 根本原因
   - 信心度（需 ≥ 70）
   - 修復建議
4. 向用戶報告問題原因
5. 確認用戶是否要修復

---

### Phase 6: Implementation

**Goal**: 執行開發或修復

**DO NOT START WITHOUT USER APPROVAL**

**Required References**:
- `references/best-practices.md` - 程式碼組織、狀態管理、初始化順序規範
- `references/fix-strategies.md` - 具體修復程式碼範例（當修復問題時）
- `references/createjs-web-patterns.md` - CreateJS API 使用模式（當開發新功能時）

**Actions**:
1. 等待用戶明確同意
2. 啟動 `createjs-developer` agent
3. Agent 任務範例：
   - 「根據 CreateJS 慣例，為 SceneManager 加入下一頁按鈕功能」
   - 「修復 menu_1 的 mouseChildren 問題」
4. Agent 須遵循：
   - 初始化順序（addChild → gotoAndStop → events）
   - Scope 保留（var self = this 或 .on() scope 參數）
   - Cleanup 模式
   - 優先使用 frame label
5. 更新 todo 進度

---

### Phase 7: Quality Review

**Goal**: 確保程式碼品質

**Required References**:
- `references/best-practices.md` - 審查清單、最佳實踐標準
- `references/common-patterns.md` - 效能反模式檢查

**Actions**:
1. 啟動 `code-reviewer` agent
2. 審查重點：
   - 最佳實踐（JS 分離、State 管理）
   - CreateJS 慣例遵循
   - 程式碼組織
   - 命名規範
3. Agent 須回傳：
   - 問題清單（信心度 ≥ 80）
   - 嚴重程度分類
   - 修復建議
4. 向用戶報告審查結果
5. 詢問用戶：立即修復 / 稍後修復 / 維持現狀

---

### Phase 8: Summary

**Goal**: 總結完成的工作

**Actions**:
1. 標記所有 todo 完成
2. 總結：
   - 完成了什麼
   - 修改了哪些檔案
   - 關鍵決策
   - 建議的後續步驟
3. 更新 Project Memory（如有新發現）

---

## 效能優化

開發完成後，可使用 `animate-performance` skill 進行效能檢查（觸發語句：「優化效能」、「檢查效能」）。
