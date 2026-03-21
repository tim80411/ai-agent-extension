---
name: reading-guide
description: >-
  Use this skill when the user asks to "產生導讀", "導讀建議", "讀書會準備",
  "generate reading guide", "prepare for book club", "討論重點",
  "怎麼報告", "怎麼分享", "presentation guide", "reading group",
  or needs to prepare discussion materials for a reading group session.
---

# 導讀建議產生器

為讀書會成員產生導讀建議，包含章節深度標記、開場句、重點列表、時間分配。

## Phase 0: 資訊收集

**Goal**: 確認檔案位置與分享情境。

**Actions**:

1. 檢查當前目錄是否有 `.study-progress.json`，若有則讀取：
   - Phase 1 的 `output`（筆記檔案路徑）
   - Phase 4 的 `output`（Q&A 檔案路徑）

2. 若無法從 `.study-progress.json` 取得，使用 `AskUserQuestion` 詢問：
   - **筆記檔案路徑**（必填）
   - **Q&A 檔案路徑**（選填，沒有就跳過 Q&A 交叉引用）

## Phase 1: 情境確認

**Goal**: 了解分享場景和聽眾特性。

**Actions**:

使用 `AskUserQuestion` 一次詢問以下問題：

1. **分享場景**：
   - 讀書會分享
   - 團隊 Tech Talk
   - 部落格文章
   - 書面摘要

2. **聽眾程度**：
   - 初學者
   - 有經驗的工程師（日常有使用但沒系統性閱讀過）
   - 混合程度

3. **聽眾是否已讀過原文**：
   - 大部分已讀
   - 大部分沒讀
   - 不確定

4. **預計時間**：
   - 20 分鐘以內
   - 30-50 分鐘
   - 1 小時以上

## Phase 2: 深度標記

**Goal**: 為每個章節決定展開深度。

**Actions**:

1. 讀取筆記檔案，列出所有章節
2. 根據以下標準決定深度：
   - ⭐ **展開**（5-7 分鐘）：有 Anti-Pattern、有比較表格、與日常工作高度相關、容易踩坑
   - ⚡ **快速帶過**（1-2 分鐘）：概念簡單、聽眾已熟悉、或屬於進階特殊場景
3. 計算總時間是否符合預計時間，調整深度分配

## Phase 3: 產生導讀

**Goal**: 產生獨立的導讀檔案。

**Actions**:

1. **不修改原始筆記**，產生獨立的 `{chapter-name}-guide.md`
2. 按章節順序排列（不按深度分組），方便報告時順著筆記走
3. 為每個章節撰寫：
   - 深度標記（⭐ 或 ⚡）
   - 開場句（一句話框定主題，用日常語言）
   - 重點列表（該章節要帶的核心點）
   - Anti-Pattern（若有，從筆記中引用）
   - Q&A 交叉引用（若有 Q&A 檔案，標註可延伸的問題編號）

## 輸出格式

```markdown
# {章節標題} 導讀建議

**預計時間**：{N} 分鐘
**搭配檔案**：`{notes-file}`、`{qa-file}`

**標記說明**：
- ⭐ 展開（5-7 分鐘）
- ⚡ 快速帶過（1-2 分鐘）

---

## ⭐ 11.2 索引類型

**開場**：「PostgreSQL 有六種索引，但九成情況你只會用到 B-tree。剩下一成才是選對索引能救命的時候。」

**重點**：
- 六種索引的適用場景比較表
- B-tree 與 LIKE 的關係（常見踩坑）

**Anti-Pattern**：
- 不要期望 `LIKE '%bar'` 使用 B-tree 索引

**延伸**：Q9（B-tree 與 LIKE 的 locale 影響）

---

## ⚡ 11.4 索引與 ORDER BY

**開場**：「只有 B-tree 能直接給你排好的結果，其他索引做不到。」

**重點**：
- ORDER BY + LIMIT n 是索引的甜蜜點

---
...

## 收尾（3 分鐘）

{一句話總結全章核心}
```

### 格式規則

- 開場句用口語、直覺的方式表達，讓沒讀過原文的人 30 秒內進入狀況
- 若聽眾沒讀過原文，每節開頭加 30 秒的背景脈絡
- 導讀是「節奏控制工具」，不是筆記的複本

## 進度更新

若存在 `.study-progress.json`，更新 Phase 5 狀態。
