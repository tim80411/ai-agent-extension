---
story_id: ＿＿
title: "＿＿"
type: enabler
priority: P_
labels: []
tracker_type: ＿＿
tracker_id: ＿＿
synced_at: ＿＿
---

<!-- 內文標題用 Jira wiki 語法 h2.，方便整段貼進 Jira description；SPEC.md 用一般 Markdown。 -->

# [Story ＿＿] ＿＿ (Enabler)

h2. 描述

作為開發團隊，我們需要＿＿，使＿＿。

h2. 價值陳述

此項變更＿＿（說明賦能了哪些 User Story 或消除了什麼風險）。

h2. 範圍與限制

*涵蓋*

* （本 Story 涵蓋的具體範圍）

*範圍外（No-gos）*

* 不做的事項 1
* 不做的事項 2

h2. 相關檔案與上下文

* 已知會碰到的模組／檔案路徑：＿＿
* 相關既有行為：＿＿
* 相關 Story：＿＿

（不確定就寫「待 agent 探索」）

h2. 驗收標準（Acceptance Criteria）

AC-1: ＿＿（Happy Path）
GIVEN ＿＿
WHEN ＿＿
THEN ＿＿

AC-2: ＿＿（Error Path）
GIVEN ＿＿
WHEN ＿＿
THEN ＿＿

AC-3: ＿＿（Edge Case）
GIVEN ＿＿
WHEN ＿＿
THEN ＿＿

（情境數量不固定，至少需要 Happy Path。Error/Edge 視需求增減。）

h2. Done when

（以下全部為真才算完成）

* 每條 AC 都有對應且通過的測試（測試名或 tag 帶 story_id 與 AC 編號）
* 既有測試、typecheck、lint 全綠
* 未改動 No-gos 涉及的範圍；「相關檔案」以外新碰到的檔案要在 PR 說明列出

h2. 歧義清單

* （無）

（有未決項時改寫為 `* Q1: ＿＿ → 決定：＿＿`，一題一行。實作前必須由 PM 決定，不可留給 agent 猜。）

h2. 依賴

* Story N — 名稱（說明依賴原因）

h2. 優先序

P_ — 一句話說明排序理由
