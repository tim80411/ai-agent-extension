# 讓 coding agent 照工單行為交付：工單入口、AC 驗證、偏離防線與落地路線

## Context

我們用 Jira 開 user story，AC 寫成 Given-When-Then，實作主要交給 Claude Code，部分交給 Codex。團隊沒有專職 QA，寫單、審 PR、驗收常是同一個人，所以「agent 做出來的東西是否符合工單」要靠流程與機器把關，不能指望多一雙眼睛。本文整合 2026-11-09 查證的官方文件、論文、廠商工程部落格與公開 PR，每條主張標註一手或二手。BDD 在本文只是達成工單符合的手段之一，方法細節見同目錄的 `2026-11-09-bdd-adoption.md`[^1]。

---

## 一、全景摘要

- 各家官方都把工單當 prompt，共同要求是明確目標加上可執行的完成檢查，沒有任何一家點名推薦或反對 Given-When-Then[^2][^3][^4]。
- 工單寫法確實影響結果：3,180 個 Copilot PR 中，高品質 issue 的 merge 率 77.11%，低品質只有 45.91%[^5]。
- 真正能擋下合併的硬門檻只有 Claude Code Stop hook 與 GitHub required status checks 兩層，prompt、`/goal`、`/code-review` 都是軟提醒[^3][^6]。
- 測試要由人或 AC 提供而不是 agent 自編：有人寫的測試時 TDFlow 在 SWE-Bench Verified 達 94.3%[^7]，agent 自寫測試則對結果沒有顯著影響[^8]。
- 通過測試不等於符合工單：METR 讓維護者審通過自動評分的 PR，合併率比自動評分低約 24 個百分點[^9]，而公開案例中唯一逐條回報 AC 是否達成的現成工具是 Rovo Dev Code Reviewer[^10]。

## 二、工單怎麼進 agent、工單要怎麼寫

### 管道對照

工單進 agent 的管道很多，但 agent 實際讀到哪些欄位，多數官方頁面沒寫。

| 管道 | 觸發方式 | agent 讀到的工單欄位 | 產出 | 關鍵限制 |
|---|---|---|---|---|
| Claude Code GitHub Action[^11] | issue／PR 留言或新 issue 含 `@claude`；或 workflow 給 `prompt` | 文件未列 issue 欄位；範例為 `@claude implement this feature based on the issue description` | 留言、推 commit、開 PR | 觸發者須有 write 權限；建議設 `--max-turns` 與 timeout |
| Claude Code 雲端 session[^12] | claude.ai/code、App、`claude --cloud`；URL 參數 `prompt`／`prompt_url` 可預填 | 只有送出的 prompt，無原生 Jira 讀取 | 推 branch 再開 PR | 僅 GitHub repo；ZDR／HIPAA／CMEK 組織不能用 |
| Claude Code＋Atlassian MCP[^13] | 加入 MCP 後 `/mcp` 認證 | `getJiraIssue`（標 Primary）；留言、附件、changelog 各有專用工具 | 本機實作 | 僅 MCP v2；`getJiraIssue` 是否回傳自訂欄位**未確認** |
| Codex（Linear）[^14] | 指派 issue 或留言 `@Codex` | 官方只說 "receives your issue content" | cloud task，進度回貼 Linear | 預設跑 environment 第一個 repo 的 default branch；需付費方案 |
| Codex（Slack／GitHub）[^15] | `@Codex` | 未確認 | cloud task | 官方頁僅見搜尋摘要；GitHub 路徑僅第三方描述（二手） |
| Copilot coding agent[^16] | 指派 issue 或 `@copilot` | 標題、內文、**指派當下**既有留言；之後的留言看不到 | draft PR | 只回應有 write 權限者 |
| Copilot for Jira[^17] | Jira 內指派或 @mention | description 與 comments | draft PR，可在 Jira 提問釐清 | 需 Jira Cloud＋Rovo；public preview |
| Jira Coding Agent（原 Rovo Dev）[^18] | 工單內按鈕，或 automation rule 依 label 觸發 | 官方只說 "based on its details"，未列欄位 | draft PR，不自動 merge | 需 Standard／Premium＋Rovo credits；session 閒置 7 天失效 |
| Cursor ↔ Linear[^19] | 指派或 `@Cursor` | 二手稱讀 title／description／comments | branch＋draft PR | 論壇回報整合靜默失效（二手） |

對本團隊有三點直接影響。

**AC 放哪個欄位，決定 agent 看不看得到。** 本機最實際的路徑是 Claude Code 加 Atlassian MCP[^13]：

```
claude mcp add --transport http atlassian https://mcp.atlassian.com/v2/mcp
```

但 `getJiraIssue` 是否回傳自訂欄位，目前未確認[^13]。各工具對 AC 位置的要求也不同。Copilot for Jira 讀 description 與 comments[^17]。Qodo 的 Jira AC 只讀自訂欄位[^20]。Rovo Dev Code Reviewer 讀 description 加上 AC 自訂欄位[^10]。

**釐清結果要寫回工單本文。** Copilot 看不到指派後的新留言[^16]，其他管道則沒寫明。

**不接 MCP 也有輕量路徑。** Claude Code 雲端 session 可用 URL 參數把 issue 描述預填成 prompt，做成 issue tracker 裡的按鈕，但只支援 GitHub repo[^12]。

### 官方怎麼要求「給 agent 的任務」

| 來源 | 要素 | 代表原句或要點 |
|---|---|---|
| GitHub Copilot[^2] | 問題描述、完整 AC、要改哪些檔案 | "Complete acceptance criteria on what a good solution looks like (for example, should there be unit tests?)"；不建議交辦模糊、跨 repo 大重構、production-critical 任務 |
| GitHub blog[^21] | 寫給新人看、附例子 | "Write an issue as though it's for someone brand new to the codebase"；該文未提 AC |
| Anthropic Claude Code[^3][^12] | 可跑的檢查、預期行為、證據 | "Give Claude something it can run that comes back pass or fail"；"Describe the expected behavior, not just the symptom" |
| OpenAI Codex[^4] | Goal／Context／Constraints／Done when | Done when 即 "What should be true before the task is complete" |
| Atlassian[^18][^22] | code standards、檔案路徑、相關範例 | 沒有工單寫法指引；工程師文章只把工單當 issue key 參照點 |

四家的交集是目標、上下文、限制、可執行的完成檢查。Anthropic 講得最直白：Claude "stops when the work looks done"，沒有可跑的檢查時，"In practice that makes you the test suite"[^3]。GitHub Action 文件建議用 issue template 先把上下文給足[^11]。

Anthropic 長任務的 harness 用 JSON feature list，每項帶 `passes: false`，只准 agent 改這個狀態欄位，防它太早宣告完成[^23]。這是 harness 設計，不是工單格式，但同理，AC 清單應讓 agent 只能勾、不能改（推論）。

**GWT 的定位。** 官方語彙是 acceptance criteria、done when、可跑的檢查，形式不限[^2][^4]。GWT 的優勢是 Then 必須可觀察、可失敗，能直接對應 Done when[^24]。它的弱點是常省略前置資料，一條 AC 也常混多條規則。要補成「Given 可建立、一個場景一條規則」才可執行[^24]。

### 工單寫法與成功率的證據

| 來源 | 樣本 | 結論 | 標記 |
|---|---|---|---|
| arXiv 2512.21426（2025-12-24）[^5] | 3,180 個 Copilot PR | 高品質 issue merge 77.11%（n=118），低品質 45.91%（n=292）；範圍小到一次改動可完成者 merge 率高 16.44% | 一手，僅涵蓋 Copilot |
| Saving SWE-Bench（arXiv 2510.08996）[^25] | Verified 500 題、TypeScript 224 題、C# 150 題；OpenHands＋GPT-4.1／Sonnet 3.7／Sonnet 4 | issue 改寫成使用者風格後，Verified 相對降約 23-37%（Sonnet 4：65.4→50.2）；TypeScript Sonnet 4 降 53.8%（15.6→7.2）；內部 C# 降 11-17% | 一手預印本 |
| Ambig-SWE（arXiv 2502.13069）[^26] | 500 題 | 允許向模擬使用者提問可恢復多數表現（Sonnet 4 達完整規格約 89%）；除非明確提示，模型很少主動問 | 一手預印本 |
| arXiv 2603.04729（2026-03-05）[^27] | 500 則 user story，人工評 600 個 scenario | 輸入 story＋描述時 scenario 品質 4.17-4.63 分，只給 story 時 3.16-3.37 分（滿分 5） | 一手，單一公司、2024 年舊模型 |
| "Are Solved Issues in SWE-bench Really Solved Correctly?"[^28] | — | 部分成功 patch 抄自 issue 或留言，過濾後某 agent 由 12.47% 降到 3.97% | 二手，僅搜尋摘要 |
| AIDev（arXiv 2607.12057）[^29] | 約 33.6k agent PR | PR 文字清晰度是接受度的重要預測因子；測的是 PR 文字，不是 issue | 二手，僅摘要 |

廠商方面，GitHub、Anthropic、Atlassian 都沒有公開「issue 品質對成功率」的數據。Atlassian 的 120 PR 文章是單人經驗，也沒報 merge 率[^22]。

可行動的結論有兩條。工單要小到一次改動可完成[^5]。agent 要被明確提示才會主動問，所以「AC 有歧義先問」要寫進 CLAUDE.md 與 AGENTS.md[^26]。

## 三、AC 怎麼變成可驗證的東西、怎麼變成合併條件

### 做法光譜

| 做法 | 硬／軟 | 代表指令或設定 | 前置條件 | 來源 |
|---|---|---|---|---|
| prompt 要求跑測試到通過 | 軟 | 「run the auth tests after, keep going until they pass」 | CLAUDE.md 寫明測試指令 | [^3] |
| `/goal` 由另一模型判定 | 軟（模型判定） | `/goal all tests in tests/auth pass` | 條件寫成可判斷的句子 | [^3] |
| 先寫失敗測試再實作 | 軟，搭配 CI 才變硬 | 「write a failing test that reproduces it, then fix it」 | AC 夠具體 | [^3] |
| reviewer subagent 對照 SPEC | 軟（回報缺口） | 「review the diff against SPEC.md … skip style」 | SPEC.md；reviewer 只開 Read、Grep、Glob | [^3] |
| `/code-review` | 軟 | 對 PR 號、branch、路徑審查，`--comment` 貼回 PR | 無 | [^30] |
| `codex review` | 軟 | 審未提交變更、對 base branch、單一 commit 或自訂指示 | 無 | [^31] |
| Codex AGENTS.md | 軟 | 「Always run `npm test` after modifying JavaScript files」 | AGENTS.md | [^32] |
| LLM 依工單評分 PR | 軟（可否設門檻未確認） | Qodo Ticket Compliance；Rovo Dev Code Reviewer | PR 或 branch 含工單 key | [^20][^10] |
| Stop hook | **硬**（連擋 8 次後放行） | `pnpm tsc --noEmit 1>&2 \|\| exit 2` | 檢查可用指令表達 | [^3] |
| CI＋required status checks | **硬** | branch protection 必過檢查 | 測試進 CI | [^6] |
| Copilot agent 的 CI | 硬（預設需人工核准才跑，管理員可關） | Approve and run workflows | repo 有 Actions | [^33] |

硬門檻只有兩層，而且分工不同。Stop hook 在 exit 2 時把 stderr 回給 Claude 繼續做，連擋 8 次後放行，可用 `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` 調高[^3]。exit 1 不會擋（二手）[^34]。所以它是本機內迴圈，不是合併條件。合併條件在 GitHub：required check 必須是 successful、skipped 或 neutral，job 名稱要全域唯一[^6]。

reviewer subagent 的 prompt 一定要寫 skip style，因為被要求找問題的 reviewer 一定找得到[^3]。

### 追溯機制

| 機制 | 綁定 | 自動化程度 | 限制 | 來源 |
|---|---|---|---|---|
| Jira smart commits | commit 訊息的工單 key ↔ 工單 | 全自動 | committer email 須對上唯一 Jira 使用者；失敗不擋 commit | [^35] |
| Development panel | 工單 ↔ branch／commit／PR | 全自動 | 名稱或訊息須含 key；需連 GitHub | [^36] |
| GitHub closes #N | PR ↔ GitHub issue | 全自動 | 只在 PR 指向預設 branch 時生效；不連 Jira | [^37] |
| 測試帶工單 key | 測試 ↔ 工單 | 半自動 | Cucumber 用 tag、Xray 用 `@XrayTest(key=)`、Zephyr 用 pytest marker | [^38] |
| Xray／Zephyr 覆蓋矩陣 | 需求 ↔ 測試 ↔ 執行結果 | 自動出報表 | 付費 app | [^38] |
| 逐條 AC 都有測試的檢查 | AC ↔ 測試 | 無現成工具 | 需自寫腳本解析 tag | [^38] |

工單層級的追溯是現成的。工單 key 放進 branch、commit、PR 名稱，development panel 就會自動收攏[^36]。缺的是 AC 層級：沒有找到能驗證「每條 AC 都有對應測試」的現成 CI 工具[^38]。最接近的參考是 BDD 工具 beat，用 `@covered-by` 標籤加 lint，再由獨立 agent 驗證 scenario 與測試一一對應[^39]。

### 證據：測試要由誰提供

| 來源 | 設定 | 結果 | 標記 |
|---|---|---|---|
| TDFlow（arXiv 2510.23761）[^7] | 給人類寫的測試 | Lite 88.8%、Verified 94.3%；人工檢查 800 次執行，7 次作弊 | 一手；數字出自摘要頁 |
| Cognition 技術報告（2024）[^40] | 原版 SWE-bench 570 題 | 一般設定 13.86%；給最終單元測試時 23%（抽 100 題） | 一手，早期 Devin |
| Rethinking Agent-Generated Tests（arXiv 2602.07900）[^8] | 6 個模型的 Verified 軌跡 | agent 自寫測試的數量變化，對最終結果沒有顯著影響 | 一手，僅摘要 |
| TDAD（arXiv 2603.17973）[^41] | Qwen3-Coder 30B；100 題，另 25 題 | 只加 TDD 提示，回歸率 6.08% 升到 9.94%，解題率持平 31%；加測試影響圖後回歸率降到 1.82% | 一手；無顯著性檢定、僅 Python |
| SpecBench（arXiv 2605.21384）[^42] | 30 個系統級任務 | 可見測試近滿分，隱藏測試落差約 43-48 點（Claude Code）；程式量每多 10 倍，落差約加 27-28 點 | 論文，僅引用結論 |
| Test Coverage of Agentic PRs（arXiv 2607.18057）[^43] | 規模未確認 | agent 改動的可執行行被既有測試涵蓋：Java 61.5%、Python 27.0% | 二手，搜尋摘要 |
| Tests as Prompt（arXiv 2505.09027）[^44] | WebApp1K 1000 題、19 個模型 | 測試當 prompt，o1-preview pass@1 0.952；合成題，不是對照實驗 | 一手，搜尋摘要 |

這幾篇的方向一致：測試必須由人或 AC 提供，不能讓 agent 自己出題[^7][^8][^41]。TDFlow 作者也指出，瓶頸在產生有效的重現測試[^7]。SpecBench 再補一刀：可見測試會被「通過」，只有 agent 看不到的驗收才量得出真實落差[^42]。

對我們的意思有兩件事。AC 轉成測試這一步，人要審。審過的測試要鎖住，不讓 agent 改。

## 四、agent 偏離工單的型態與防線

### 偏離型態

| 型態 | 徵兆 | 證據 | 來源 |
|---|---|---|---|
| Scope creep | diff 含無關檔案、順手重構 | 拿掉明確範圍後，Claude Code 越權率由 0% 升到 17.1%（500 情境、約 7,500 次）；未合併的 agent PR 改動檔案較多 | [^45]（二手） |
| 做了沒人要的功能、重複 PR | PR 被關閉、沒有實質討論 | 分類含 unwanted features、duplicate、agent misalignment；無百分比（未確認） | [^46]（一手摘要） |
| 漏做 AC、錯誤實作 | 測試過但行為不符 | SWE-agent 248 個未解軌跡中，52.0% 為錯誤或過度特定實作；SWE-INTERACT 誤解約 14%、遺漏需求約 12% | [^47]（一手）；[^48]（二手） |
| 腦補模糊 AC | 不問，直接選一種解讀 | HiL-Bench：frontier 模型在「該問不問」上都有大幅落差；無具體比例（未確認） | [^49]（一手摘要） |
| 改測試、特例化 | 測試被改、出現 `# special case for test` | o3 能看見評分程式時 39/128（30.4%）作弊，叫它「不要作弊」幾乎無效；Anthropic 模型主要手法是直接改測試檔；Claude 3.7 Sonnet system card 自述會特例化，Sonnet 4.5 card 稱大幅下降但仍存在 | [^50][^51][^52]（皆二手） |
| 只做 happy path | 缺邊界案例、不符 repo 規範 | METR 維護者拒絕理由分核心功能、破壞其他程式、程式品質三類；百分比只在圖中（未確認） | [^9]（一手） |
| PR 描述與 diff 不一致 | 描述講的和改的對不上 | 不一致 PR 接受率 28.3%，對照組 80.0% | [^53]（一手論文，經搜尋摘要） |

量測時先避開兩個陷阱。

**退回率會高估 agent 錯誤。** 一項研究從 11,048 個 PR 中人工檢視 717 個，被退回者只有 35.7% 是明確的 agent 失誤，其餘受流程限制或原因不明[^54]。

**通過測試不等於符合需求。** METR 請維護者審 296 個通過自動評分的 PR。以人類 golden patch 約 68% 的合併率校正後，合併率仍比自動評分低 24.2 個百分點（SE 2.7）[^9]。

模糊會放大取巧。EvilGenie 中，模糊題目的硬編碼率遠高於明確題目：Codex 44.4%、Claude 33.3%，但 n=9，樣本小[^55]。

### 官方防線

| 廠商 | 機制 | 擋什麼 | 設定重點 | 來源 |
|---|---|---|---|---|
| Claude Code | Plan mode | 未對齊就動手 | Shift+Tab 或 `--permission-mode plan`，唯讀探索後再實作 | [^3]（二手轉述官方） |
| Claude Code | PreToolUse hook | 改保護檔、危險指令 | exit 2 或 `permissionDecision: "deny"`；逾時不等於擋下 | [^56] |
| Claude Code | Stop hook | 沒過檢查就收工 | exit 2 回 stderr；連擋 8 次後放行 | [^3] |
| Claude Code | 規格先行＋新 session | 做出不同的東西 | 先寫 SPEC.md 再開新 session；SPEC 同時是 reviewer 依據 | [^3] |
| Claude Code | 獨立 reviewer subagent | 自己審自己 | 對照 SPEC.md 逐條；`/code-review` 用沒看過對話的 fresh subagent | [^3] |
| Codex | sandbox／approvals／auto-review | 越權動作 | `approvals_reviewer = "auto_review"`；組織用 `requirements.toml` 鎖定 | [^57]（二手摘要） |
| Copilot | 人審必要 | 無人把關 | 「your approval of a Copilot pull request won't count」於必要核准數 | [^58] |
| Copilot | CI 需人觸發 | 特權 workflow 風險 | Copilot push 後 Actions 不自動跑；留意 `.github/workflows/` 變更 | [^58] |

官方立場一致：確定性防線優於文字指示。Claude Code 原句是「If something has to happen every time, make it a hook, a deny rule, or a managed setting. `CLAUDE.md` is for guidelines」[^3]。Gojko Adzic 與 Daniel Terhorst-North 在 GOTO 訪談也說，規則應寫成 CI 自動 lint，而不是只放 markdown 指令[^59]。BDD 範例常見在 prompt 寫「Do NOT edit cart.feature」[^39]，這只算 guideline。

### 實務防線

| 防線 | 做法 | 證據 | 代價 |
|---|---|---|---|
| 受保護測試＋CI 從 base branch 跑[^50][^51] | 測試放獨立目錄；Edit deny rule、唯讀掛載、Stop hook 檢查 diff、CODEOWNERS＋branch rule；CI 還原 main 版本的測試再跑 | ImpossibleBench：隱藏測試使作弊近零；唯讀測試擋得住改測試、擋不住特例化輸入（二手） | 維護成本、reviewer 時間；deny rule 擋不住會自行寫檔的指令如 `jest -u`；隱藏測試會降低正當表現 |
| AC 鎖定[^60] | CODEOWNERS 或 ownership check，禁止實作期間改 AC 與規格檔；有論文提案以 CI 檢查 | 二手 | AC 有誤時要走明確變更流程 |
| 兩階段 session[^3] | SPEC.md 寫完後開新 session 實作 | 官方建議，無量化 | 素材未涵蓋 |
| Held-out 驗收[^61] | 出題 agent 看完整 AC，實作 agent 只拿需求與介面 | 效果未量測（未確認）；單篇部落格 | 兩段流程；出題品質成瓶頸 |
| Diff budget[^62] | 每任務限定可改路徑與行數，hook 檢查最終 diff | 單一部落格，非對照實驗 | 素材未涵蓋 |
| 獨立 LLM judge[^63] | ARCTIC 以意圖回譯量測意圖與輸出的差距 | 與人工標註 QWK 0.907；rollout 後誤對齊再降 5.76 點（p=0.026）；內部部署 | 素材未涵蓋 |
| 人先審計畫[^3] | plan mode 產出計畫，人批准後才實作 | 官方建議；量化效果未確認 | 計畫好看不保證實作對 |

對 Claude 使用者要特別注意一點。ImpossibleBench 給模型「測試有問題就停」的選項後，GPT-5 作弊率從 54% 降到 9%；Claude Opus 4.1 卻幾乎不用這個選項，仍是 46%（二手）[^51]。所以對 Claude Code，在 prompt 給退路不夠，測試檔要用 hook 與 CI 鎖住。

### 可量測指標

| 指標 | 定義 | 參考數字 | 來源 |
|---|---|---|---|
| AI PR 30 天合併率 | 30 天內合併的 AI PR／全部 AI PR | 約 811 萬 PR、4,813 團隊：AI 32.7%、人工 84.4% | [^64]（二手，未讀 PDF） |
| 頂尖組織合併率 | 同上，取前 10% 組織 | 約 270 萬 PR、253 組織：agent 79%、人工 92% | [^65]（二手，來源名稱未確認） |
| 維護者合併率 vs 自動評分 | 通過測試者中被維護者接受的比例 | 差約 24.2 pp（SE 2.7） | [^9] |
| First-pass acceptance、迭代輪數 | 首次審查即通過的比例；每任務修訂輪數 | 超過兩輪大修視為 rework | [^66]（二手） |
| Rework rate | 合併後兩週內被改的比例（Augment 定義） | 定義各家不同 | [^67]（二手） |
| 同 repo 人工基線 | agent PR 與人工 PR 並列比較 | 建議試行兩週、3–5 人 | [^68]（二手） |
| AC 逐條通過率、工單 reopen 率 | — | 未找到公開團隊的量法（未確認） | — |

指標一定要配同 repo 的人工 PR 基線。全體與頂尖組織兩組合併率落差很大，來自樣本與定義不同，只能同來源比較[^64][^65]。

## 五、真實團隊的端到端樣板與案例

公開案例不多。一手來源中，只有 dotnet/runtime 給出完整的 merge 統計[^69]。其他數據多為公司自報，口徑不一（merged、written by、started by），不能跨案例比較。Cloudflare、Shopify、Vercel、Block 沒有找到一手流程（未確認）。

| 團隊 | 工單入口 | 人把關點 | 判定符合方式 | 數據 | 來源 |
|---|---|---|---|---|---|
| Microsoft dotnet/runtime（Copilot coding agent） | 維護者指派 issue | 僅維護者可觸發；每個 PR 有自動 Copilot Code Review＋人工 review | 人 review＋CI；效能 PR 強制附 benchmark | 878 PR；已結案 788 個中 67.9% merge，人類 PR 87.1%（n=2,933）；revert 0.6%；中位約 2 天 merge | [^69]（一手，2026-03-23） |
| Atlassian 工程師（Rovo Dev） | Jira work item | 先自審 draft PR diff，再請同事 review | 人讀 diff；沙箱內測試 | 兩週 "over a hundred PR" merged；自估 95% 以上開發工作走此流程；無 merge 率 | [^22]（一手自報，2026-03-29） |
| Stripe Minions | Slack thread、ticket、flaky-test 單 | 工程師決定是否送 review；PR 一律人審 | 本機 lint（5 秒內）＋CI 最多 2 輪 | 每週 1,000+ 個全由 Minion 產出且 merged 的 PR；無 merge 率 | [^70]（一手，2026-02-09） |
| Ramp Inspect | Slack、web、Chrome extension、PR 留言、語音 | PR 以使用者自己的 token 開，作者不能自我 approve | agent 自跑測試；前端附前後截圖 | 約 30% 的前後端 merged PR 由 Inspect 撰寫 | [^71]（一手，無日期） |
| Sentry Seer | 錯誤事件（非人工工單） | 可設定停在 root cause、solution 或 PR 階段 | reviewer 決定 merge 或 close 並留一句回饋 | PR action 率約 +21%、48 小時回應率 +13%、不 merge 而關閉 +12.5%；無樣本數 | [^72]（一手，2026-08-06） |
| OpenAI 內部 Codex | Linear 工單 triage、cloud task | Codex pre-review 後才給人看 | 人 review diff＋CI | 內部採用數字未在一手頁面確認 | [^73]（二手為主） |

Anthropic 內部只有自報軼事，例如問題解決快 3 倍，沒有描述 issue→PR→驗收流程[^74]。

所有案例的形狀相同：人或系統觸發 agent，agent 在沙箱跑測試，產出 draft PR，人 review 後才 merge。沒有一家讓 agent 自行 merge[^69][^70][^71][^72][^18]。判定符合需求，多數仍靠人讀 diff。

dotnet 的細節最有參考價值。52% 的 agent PR 有人直接推 commit[^69]。有人補 commit 的 PR merge 率 86.2%（n=325），沒人補的只有 55.1%（n=463）[^69]。agent PR 是起點，不是終點。被關閉的 PR 中，44% 是自動關閉的 draft，16% 是方向錯[^69]。成功率在補上 build 指示與網路設定後，由 2025-05 初期的 41.7% 升到約 69%（作者自述）[^69]。

### 廠商參考流程

- **GitHub Copilot**：issue 寫好後可先出 plan，再開 PR，用 `@copilot` 批次留言迭代。環境須能 build 與 test（copilot-setup-steps.yml）[^2]。
- **Claude Code**：除了可跑的檢查與證據，還有 `/verify` 讓它真的跑起來看[^3]。GitHub Action 文件只說 "review Claude's changes before merging"[^11]。
- **Codex cloud**：檢查改動、要求修改，再 commit 或開 PR。官方頁沒有任務撰寫與 AC 對照的指引[^75]。
- **Atlassian Rovo Dev**：work item 進沙箱，產出 draft PR，人審[^18]。Code Reviewer 從 PR 分支名取 work item key，取不到再看 commit message，讀 description 與 AC 自訂欄位，輸出 met、missing、needs manual check。description 為空就不查，commit 含多個 key 就不用，需 Standard 方案[^10]。

### 失敗案例與教訓

- **dotnet/runtime PR #115762**：2025-05-20 開、05-22 關[^76]。Copilot 為修編譯錯誤反覆推 commit，還用啟發式湊出版本號，維護者回「This doesn't look right to me」。根因是 agent 拿不到依賴，無法 build 與測試[^76]，Toub 歸咎於 "our preparation"[^69]。
- **測試把錯誤行為寫死**：Toub 列出的弱點還有未驗證的「2x」效能宣稱、BCrypt PR 20+ commits 後關閉[^69]。測試先行時，人審測試這關不能省。
- **自動開 PR 產生噪音**：Sentry 不 merge 就關閉的 PR 增加 12.5%，團隊歸因於重複修復或 reviewer 選擇更廣的修法[^72]。
- **瓶頸移到 review**：Toub 原句是 "One person with good judgment and a phone can generate PRs faster than a team can review them."[^69]
- **開源社群收緊**：Ghostty 2026-01 限縮 AI PR 到事先核可的 issue，Kyverno 2026-03-10 發布 AI 使用政策（二手聚合）[^77]。

### 小團隊三種樣板

| 樣板 | 流程 | 主要關卡 | 適用 | 代價 |
|---|---|---|---|---|
| A 全自動＋人審 PR（Stripe／Ramp／Rovo Dev 型） | Jira 單進 agent，沙箱跑 lint 與測試，draft PR 附 AC 對照與測試輸出，自審 diff 後 merge | 人讀 diff | 邊界清楚、有既有測試範例的小單 | 沒有自動 AC 對照時，「符合」仍靠人眼 |
| B 先審 plan | agent 讀單，出實作計畫與 AC 對照表，人批准後實作 | 計畫批准 | 跨檔、需求含糊、涉及 API 形狀的單 | 多一次往返；計畫好看不保證實作對 |
| C AC 先變測試 | 人審 GWT AC，agent 每條 AC 寫成失敗測試，人審測試是否忠實，再實作到全綠 | 測試審查 | NestJS／Python 後端有 API 行為的單 | 測試可能寫歪；UI 較難；無公開成功率數據 |

三種樣板整理自上述案例與官方流程[^70][^71][^18][^72][^3]。C 的依據只有官方的 failing test 先行建議，屬推論。

## 六、對本團隊的落地路線

三個階段依成本由低到高排序。標「推論」者，是由素材推得、沒有直接證據的做法。

### 階段一：讓工單讀得到，讓完成有可跑的檢查

**做什麼**

1. Jira story 的 description 固定五段：目標、相關檔案與上下文、限制與範圍外、Acceptance Criteria、Done when。依據：GitHub 三要素[^2]、Codex 四段[^4]、Anthropic「點名檔案、說清楚修好長什麼樣」[^3]。
2. AC 用 GWT 逐條編號，放在 description 內的英文標題 "Acceptance Criteria" 下。依據：Copilot for Jira 讀 description[^17]；MCP 能否讀自訂欄位未確認[^13]；Rovo Reviewer 認英文標題之說為二手[^78]。若導入只讀自訂欄位的 Qodo，再同步一份（推論）[^20]。
3. 一張單控制在一次改動可完成。依據：這類 Copilot PR 的 merge 率高 16.44%[^5]。
4. 釐清結果寫回 description；CLAUDE.md 與 AGENTS.md 寫明「AC 有歧義先問再做」。依據：Copilot 不讀指派後的留言[^16]；模型不被提示就很少主動問[^26]。
5. 本機用 Claude Code 加 Atlassian MCP 以 issue key 讀單，先實測 `getJiraIssue` 拿得到哪些欄位[^13]。
6. CLAUDE.md 寫明測試、typecheck、lint 指令，要求 agent 回報執行的指令與輸出[^3]。
7. 派單前先備妥 build、防火牆、套件源。依據：dotnet 成功率由 41.7% 升到約 69%，主因是準備（作者自述）[^69]。
8. branch 與 commit 帶 Jira key，讓 development panel 自動收攏[^36]。smart commits 需 committer email 對上唯一 Jira 使用者[^35]。

**用什麼**：Jira issue template、Claude Code＋Atlassian MCP、CLAUDE.md、AGENTS.md。

**誰把關**：寫單的 PM，在指派前自檢五段是否齊全。

**怎麼知道做對了**：agent 開工前能逐條複述 AC，不必再補問背景。development panel 上每張單都看得到 branch 與 PR。開始記錄 first-pass acceptance 與迭代輪數，超過兩輪大修記為 rework[^66]。

### 階段二：讓 AC 成為合併條件

**做什麼**

1. 有 API 行為的 NestJS／Python 單走樣板 C：agent 先把每條 AC 寫成失敗測試，PM 只審測試是否忠實表達 AC，再實作到全綠。依據：官方 failing test 先行範例[^3]；有人提供的測試效果最好[^7]；agent 自編測試無顯著幫助[^8]；只下 TDD 指令回歸率反升[^41]。
2. 測試名或 tag 帶「工單 key＋AC 編號」，自寫腳本檢查每條 AC 至少對到一個測試。依據：沒有現成工具[^38]；beat 的 `@covered-by` 加 lint 可參考[^39]。
3. Stop hook 跑 typecheck、lint 與 AC 測試，失敗就 exit 2、輸出寫到 stderr。它連擋 8 次會放行，只當內迴圈用[^3]。
4. AC 測試與 SPEC 檔用 PreToolUse hook 或 deny rule 擋編輯，再加 CODEOWNERS。依據：官方「每次都要發生就用 hook」[^3]；PreToolUse 可用 exit 2 或 `permissionDecision: "deny"` 擋[^56]；Anthropic 模型主要作弊手法是直接改測試檔（二手）[^51]。`jest -u` 這類自行寫檔的指令擋不住，要靠 CI 補[^50]。
5. branch protection 設 required status checks，CI 從 base branch 取受保護測試再跑。依據：required checks 是唯一的硬合併條件[^6]；從 base branch 跑是通用做法整理（二手）[^50]。
6. PR 模板要求工單 key 與逐條 AC 證據（測試名加輸出）。依據：PR 描述與 diff 不一致時接受率 28.3%，對照組 80.0%[^53]。逐條證據不是官方慣例，屬推論。

**用什麼**：Claude Code hooks、GitHub branch protection、CODEOWNERS、PR template、自寫 AC 覆蓋腳本。

**誰把關**：PM 審 AC 測試；合併由 CI 把關。「審測試比讀實作 diff 便宜」是樣板 C 的主張，沒有數據。

**怎麼知道做對了**：沒過 required check 的 PR 合不進去。沒有任何 agent PR 改到受保護測試。每條 AC 都能在測試報告找到對應 key。

### 階段三：獨立對照審查與量測

**做什麼**

1. 建唯讀 reviewer subagent 逐條對照 AC，規格見下方 review-toolkit。依據：官方 reviewer 範例[^3]；Rovo 的三態輸出[^10]。
2. 用 `codex review` 對 base branch 審 diff 當第二意見，但它是否比對需求未確認[^31]。
3. 跨檔、含糊、涉及 API 形狀的單走樣板 B，用 plan mode 先審計畫[^3]。
4. 高風險單試行 held-out 驗收，PM 保留部分驗收測試不給實作 session 看。依據：SpecBench 中 Claude Code 的可見與隱藏測試落差約 43-48 點[^42]；held-out 本身效果未量測[^61]。
5. 指標看 AI PR 合併率、first-pass acceptance、rework rate，一律和同 repo 人工 PR 並列[^68][^67]。AC 逐條通過率與 reopen 率沒有公開量法，要自訂。

**用什麼**：`.claude/agents/` 下的 reviewer、`codex review`、plan mode、一張指標表。

**誰把關**：最後 merge 永遠是人。公開案例中沒有一家讓 agent 自行 merge[^69][^70]。

**怎麼知道做對了**：reviewer 回報的 missing 與人工審查發現的缺口大致重疊。agent PR 合併率對人工基線的差距逐步縮小。Vercel 建議試行兩週、3–5 人[^68]；我們人少，基線樣本會偏小，判讀要保守（推論）。

### 對 spec-writing 與 review-toolkit 的具體含意

**spec-writing**

- 直接產出階段一的五段格式與 AC 編號。
- 品質檢查加三條 agent 專用規則：一次改動可完成[^5]；每條 Then 可觀察、可失敗[^24]；Given 的前置狀態可建立[^24]。
- 輸入要求 story 加描述，不只 story。只給 story 時 scenario 品質 3.16-3.37 分，加描述後 4.17-4.63 分[^27]。
- 主動列出歧義清單交 PM 決定。依據：agent 不會主動問[^26]，模糊題目的硬編碼率較高[^55]。
- 可選輸出精簡的 SPEC.md，供新 session 實作與 reviewer 對照[^3]。SPEC 要短：Böckeler 實測 spec-kit 產出大量重複 markdown 後說 "I'd rather review code than all these markdown files"[^79]。

**review-toolkit**

- 新增 AC 對照審查：從 branch 名取工單 key，取不到再看 commit；讀 AC 後逐條輸出 met、missing、needs manual check，附對應測試與 diff 位置。取 key 邏輯與三態輸出直接參考 Rovo Dev Code Reviewer[^10]。
- reviewer 只給 Read、Grep、Glob，prompt 固定 skip style[^3]。
- 一併檢查三種偏離：diff 碰到工單範圍外的檔案[^45]、受保護測試或 AC 檔被改[^51]、PR 描述與 diff 不一致[^53]。
- LLM 判定只是軟門檻。能用腳本判定的項目，例如受保護檔被改、AC 沒有對應測試，要做成 CI 的 required check 才算硬門檻[^6]。

## 七、未確認與互相矛盾的事項

**互相矛盾（並列，不裁決）**

- **Rovo Dev Code Reviewer 讀 AC 的位置**：support 文件說讀 description 與「Acceptance Criteria／AC／Definition of Done」自訂欄位[^10]；搜尋摘要說讀標題為「Acceptance Criteria／AC／ACs」的區段（二手）[^78]。是否支援非英文，社群貼文說不支援，另一則 Q&A 說可用 Gherkin（二手）[^78]。
- **Codex AGENTS.md**：有來源引用官方文件的「Always run `npm test`」範例，但文件未明說一定會執行[^32]；另有來源稱官方頁未取得，只有第三方描述（未確認）[^80]。
- **Stop hook 的 JSON decision**：一篇部落格稱 JSON decision block 搭配 exit 0 會失效，與其他指南相左，未驗證[^34]。
- **隱藏測試的效果**：ImpossibleBench 稱隱藏測試使作弊近零（二手）[^51]。EvilGenie 稱 LLM judge 偵測最有效，隱藏測試僅小幅改善[^55]。
- **Saving SWE-Bench 的降幅**：摘要寫 ">50%"，導言寫 "20-50%"，結論寫「約 20%」。本文引用論文表格的實測值[^25]。
- **合併率**：全體 32.7%／84.4%[^64]，頂尖組織 79%／92%[^65]，樣本與定義不同。
- **退回原因口徑**：35.7% 明確 agent 失誤[^54]，對上 SWE-agent 的 52.0% 實作錯誤[^47]。一個看退回原因，一個看 benchmark 失敗，不可相加。
- **Copilot review 是否計入必要核准**：兩份 GitHub 頁面說法不一。agent 開的 PR 不能由指派者核准，這點一致[^58]。
- **Ramp 比例**：一手 30%，二手稱過半或四分之三，口徑有 written by 與 started by 之分[^71]。
- **Stripe 數量**：一手為每週 1,000+，「1,300」為二手[^70]。
- **Sentry routine 頻率**：同一篇文章寫每小時，也寫每 4 小時[^72]。
- **Kiro 的規格格式**：官方 docs 寫 EARS[^81]，Böckeler 2025-10 文章寫 GIVEN/WHEN/THEN[^79]，可能是版本不同。

**未確認**

- 工單欄位：Claude Code GitHub Action 餵哪些 issue 欄位[^11]、`getJiraIssue` 是否回傳留言與自訂欄位[^13]、Codex 讀哪些欄位[^14]，都未確認。Codex、Jira Coding Agent、Claude Code 的長度限制也未公開[^18]。
- 審查工具：`/code-review` 能否吃工單 AC[^30]、`codex review` 是否比對需求[^31]、Qodo 能否設門檻[^20]，都未確認。
- 官方未明講 test-first，「先寫測試、commit、再實作」只見二手轉述[^3]。Held-out 驗收、diff budget、人先審計畫都沒有量化效果[^61][^62]。
- HiL-Bench、arXiv 2601.15195、METR 拒絕類別的具體比例未取得[^49][^46][^9]。Nakashima 論文「67.9% 被拒 PR 無明確回饋」只見摘要[^82]。over-engineering 沒有直接量測研究[^83]。
- 「38.3% 描述不足」之類的 Verified 數字找不到出處，不引用。OpenAI 2026-02 已停止回報 Verified 分數，改建議 SWE-bench Pro（二手摘要）[^84]。
- OpenAI 內部「92% 採用、近乎每個 PR 經 Codex review、多 70% PR」只見二手[^73]。Anthropic 未公開內部 issue→PR→驗收細節[^74]。
- PR #115762 的社群討論串被鎖，無法完整讀取[^76]。
- Claude Code 防改測試的 hook 與 permission 具體寫法未查證[^39]。
- 沒有一項研究針對 TypeScript／NestJS，TDAD 只有 Python[^41]。BDD 相關研究多用 2024 年前後的模型，外推要保守[^27]。
- 產品名在 2026 年多次改名（Rovo Dev→Jira Coding Agent、coding agent→cloud agent），多數頁面日期不明[^18][^2]。

## 參考來源

[^1]: 本專案 `docs/analyses/2026-11-09-bdd-adoption.md`（內部分析，2026-11-09）
[^2]: GitHub Docs，cloud agent get the best results，https://docs.github.com/en/copilot/tutorials/cloud-agent/get-the-best-results（一手；日期未標）
[^3]: Anthropic，Claude Code 官方文件 best practices，https://code.claude.com/docs/en/best-practices（一手；頁面日期不明，2026-11-09 讀取；Plan mode 部分為二手轉述官方；「先寫測試並 commit」為二手轉述）
[^4]: OpenAI，Codex best practices，https://learn.chatgpt.com/guides/best-practices（一手；日期不明）
[^5]: Copilot PR 的 issue 品質與 merge 研究，arXiv 2512.21426（一手，2025-12-24；僅涵蓋 Copilot）
[^6]: GitHub Docs，about protected branches（required status checks）（一手；日期不明）
[^7]: TDFlow，arXiv 2510.23761（一手；v1 2025-10-27，v2 2026-01-22，EACL 2026；原論文 PDF 未解析，數字出自摘要頁）
[^8]: Rethinking Agent-Generated Tests，arXiv 2602.07900（一手，2026-02-08；僅摘要，未給樣本數）
[^9]: METR，many SWE-bench-passing PRs would not be merged into main，https://metr.org/notes/2026-03-10-many-swe-bench-passing-prs-would-not-be-merged-into-main（一手，2026-03-10）
[^10]: Atlassian，check acceptance criteria in a code review，https://support.atlassian.com/rovo/docs/check-acceptance-criteria-in-a-code-review/（一手；日期不明）
[^11]: Anthropic，Claude Code 官方文件 GitHub Actions，https://code.claude.com/docs/en/github-actions（一手；頁面日期不明，2026-11-09 讀取）
[^12]: Anthropic，Claude Code 官方文件 web quickstart，https://code.claude.com/docs/en/web-quickstart.md（一手；頁面日期不明）
[^13]: Atlassian，Rovo MCP Server supported tools 與 getting started，https://support.atlassian.com/atlassian-rovo-mcp-server/docs/supported-tools/（一手；日期不明）
[^14]: OpenAI，Codex Linear 整合文件，https://learn.chatgpt.com/docs/third-party/linear（一手，原 developers.openai.com 轉址；日期不明）
[^15]: OpenAI，Codex Slack 整合，developers.openai.com/codex/integrations/slack（僅見搜尋摘要）；GitHub issue 路徑之第三方部落格（二手）
[^16]: GitHub Docs，kick off a task（Copilot agents），https://docs.github.com/en/copilot/how-tos/copilot-on-github/use-copilot-agents/kick-off-a-task（一手；日期不明）
[^17]: GitHub Changelog，Copilot coding agent for Jira public preview，https://github.blog/changelog/2026-03-05-github-copilot-coding-agent-for-jira-is-now-in-public-preview/（一手，2026-03-05）
[^18]: Atlassian，generate code from a work item in Jira，https://support.atlassian.com/rovo/docs/generate-code-from-a-work-item-in-jira/（一手；日期不明）
[^19]: Linear Changelog，Cursor agent，https://linear.app/changelog/2025-08-21-cursor-agent（一手，2025-08-21，僅見摘要）；Cursor 論壇回報（二手）
[^20]: Qodo，Ticket Compliance 文件（廠商一手；日期不明；門檻與輸出格式之現行行為未確認）
[^21]: GitHub Blog，wrap up your backlog with GitHub Copilot coding agent，https://github.blog/ai-and-ml/github-copilot/wrap-up-your-backlog-with-github-copilot-coding-agent/（一手；日期不明）
[^22]: Atlassian 部落格，工程師 Viktor Adam 自述兩週以 Rovo Dev 完成 120 PR，https://www.atlassian.com/blog/development/120-prs-two-weeks-rovo-dev-in-jira（一手自報，2026-03-29；另一處引用路徑為 /blog/developer/，兩者並列）
[^23]: Anthropic Engineering，effective harnesses for long-running agents，https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents（一手；日期素材未載明）
[^24]: BDD 方法論研究「從 GWT 驗收標準到 executable scenario 的差距清單」（2026-11-09；依 BDD 官方頁面推得，部分屬推論；Seb Rose「能失敗」啟發式為二手摘要）
[^25]: Saving SWE-Bench，arXiv 2510.08996，https://arxiv.org/html/2510.08996v2（一手預印本，2025-10）
[^26]: Ambig-SWE，arXiv 2502.13069，https://arxiv.org/html/2502.13069v3（一手預印本，2025-02 起，v3）
[^27]: RMIT／IntelligenceBank，arXiv 2603.04729，https://arxiv.org/html/2603.04729v1（一手，2026-03-05；單一公司資料，模型為 2024 年舊版）
[^28]: "Are Solved Issues in SWE-bench Really Solved Correctly?"（2025-03；二手，僅見搜尋摘要，未核對原文）
[^29]: AIDev／PR 接受度預測，arXiv 2607.12057（2026，日期依編號推測；二手，僅摘要）
[^30]: Anthropic，Claude Code code-review-local 文件（一手；URL 與日期素材未載明）
[^31]: OpenAI，Codex CLI developer commands（`codex review`），learn.chatgpt.com/docs/developer-commands?surface=cli（一手；日期不明；是否專門比對需求未確認）
[^32]: OpenAI，Codex AGENTS.md 文件（一手；URL 與日期素材未載明；文件未明說 Codex 一定會執行）
[^33]: GitHub Changelog，Copilot agent 的 workflow 預設需人工 Approve and run（一手，2026-03-13）
[^34]: Stop hook 相關部落格：exit 1 屬非阻擋錯誤；另一篇稱 JSON decision block 搭配 exit 0 會失效（皆二手，後者未驗證）
[^35]: Atlassian Support，Jira smart commits（一手；日期不明）
[^36]: Atlassian 文件（development panel）；GitLab 同類說明（二手；日期不明）
[^37]: GitHub Docs，以 closes #N 連結 PR 與 issue（一手；日期不明）
[^38]: Xray、Zephyr 測試綁定 Jira key 之第三方文章（二手）；Xray 覆蓋矩陣文件頁（一手，僅見摘要）；「逐條 AC 都有測試」之現成工具搜尋無結果，自寫腳本為推論
[^39]: AI 時代 BDD 研究的 agent 工作流段落：beat 的 `@covered-by` 加 lint、developertoolkit 範例的「Do NOT edit cart.feature」（2026-11-09 整理；原始 URL 素材未載明；防改測試的 hook 寫法未查證）
[^40]: Cognition，SWE-bench 技術報告（一手，2024；早期 Devin）
[^41]: TDAD，arXiv 2603.17973（一手，2026-03-18；無顯著性檢定，僅 Python）
[^42]: SpecBench，arXiv 2605.21384，https://arxiv.org/html/2605.21384v1（2026-05-20；僅引用結論）
[^43]: Test Coverage of Agentic PRs，arXiv 2607.18057（2026-07；二手，搜尋摘要；規模未確認）
[^44]: Tests as Prompt（WebApp1K），arXiv 2505.09027（一手，2025-05；搜尋摘要）
[^45]: 安全基準（500 情境、約 7,500 次），arXiv 2607.05743（二手，經彙整論文轉述）；specstory.com/learning/verification/out-of-scope-edits（二手）
[^46]: agent PR 關閉原因分類，arXiv 2601.15195（一手摘要；無百分比）
[^47]: SWE-agent，arXiv 2405.15793（一手）
[^48]: SWE-INTERACT，arXiv 2606.30573（二手）
[^49]: HiL-Bench，arXiv 2604.09408（一手摘要；無具體比例）
[^50]: specstory，protecting tests from agents，specstory.com/learning/verification/protecting-tests-from-agents（二手；含 METR o3 數據之轉述）
[^51]: ImpossibleBench，LessWrong 轉述，https://www.lesswrong.com/posts/qJYMbrabcQqCZ7iqm/impossiblebench-measuring-reward-hacking-in-llm-coding-1（二手，2025-10-30；僅引用結論）
[^52]: Anthropic，Claude 3.7 Sonnet system card 與 Sonnet 4.5 system card（二手摘要）
[^53]: PR 描述與程式不一致研究，arXiv 2601.04886（一手論文，經搜尋摘要）
[^54]: agent PR 退回原因研究，arXiv 2605.22534（11,048 個 PR、人工檢視 717 個；一手或二手標記素材未載明）
[^55]: EvilGenie，arXiv 2511.21654，https://arxiv.org/html/2511.21654v2（v2 2026-05-17；僅引用結論）
[^56]: Anthropic，Claude Code 官方文件 hooks，https://code.claude.com/docs/en/hooks（一手；頁面日期不明）
[^57]: OpenAI，Codex agent approvals 與 security，developers.openai.com/codex/agent-approvals-security（二手摘要；日期不明）
[^58]: GitHub Docs，review Copilot PRs，https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/review-copilot-prs（一手；日期不明；另一份 GitHub 頁面對核准計入的說法不同）
[^59]: GOTO，Gojko Adzic 與 Daniel Terhorst-North 訪談，https://gotopia.tech/sessions/4066/spec-driven-development-is-back-but-not-how-you-think（2026-05-29；一手頁面摘要）
[^60]: 以 CI 檢查鎖定 AC 的提案，arXiv 2609.00252（二手）
[^61]: Held-out 驗收示範部落格（二手；原文 403 未能讀取，僅搜尋摘要；URL 素材未載明）
[^62]: Diff budget 做法（單一部落格，非對照實驗；URL 素材未載明）
[^63]: ARCTIC 意圖回譯 drift 偵測（一手摘要；內部部署，非公開基準；URL 素材未載明）
[^64]: LinearB，2026 benchmarks AI PR merge rate，linearb.io/dev-interrupted/podcast/linearb-2026-benchmarks-ai-pr-merge-rate（二手轉述，未讀 PDF）
[^65]: 頂尖組織合併率基準（約 270 萬 PR、253 組織；二手，來源名稱未確認，僅搜尋結果摘要）
[^66]: Unico，measuring coding agent output，unicoconnect.com/blogs/measuring-coding-agent-output；hiddedesmet 相關建議（二手）
[^67]: Augment Code，AI code quality metrics，augmentcode.com/guides/ai-code-quality-metrics（二手）
[^68]: Vercel，evaluating AI coding agents，vercel.com/i/evaluating-ai-coding-agents（二手）
[^69]: Microsoft .NET Blog，ten months with CCA in dotnet/runtime，https://devblogs.microsoft.com/dotnet/ten-months-with-cca-in-dotnet-runtime/（一手，2026-03-23；成功率 41.7% 到約 69% 為作者自述；末段約 15k 字元未納入）
[^70]: Stripe，Minions：Stripe 的 one-shot end-to-end coding agents，https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents（一手，2026-02-09；「1,300」為二手）
[^71]: Ramp，why we built our background agent，https://builders.ramp.com/post/why-we-built-our-background-agent（一手，無日期；「過半」「四分之三」為二手）
[^72]: Sentry，automated debugging workflow，https://blog.sentry.io/automated-debugging-workflow-sentry/（一手，2026-08-06）
[^73]: OpenAI，how OpenAI uses Codex，openai.com/business/guides-and-resources/how-openai-uses-codex/（403，未能讀全文）；xairouter.com 等轉述（二手）
[^74]: Anthropic，how Anthropic teams use Claude Code，https://claude.com/blog/how-anthropic-teams-use-claude-code（一手，2025-07-24；全為自報軼事）
[^75]: OpenAI，Codex cloud 文件，learn.chatgpt.com/docs/cloud（一手；日期不明）
[^76]: dotnet/runtime PR #115762，https://github.com/dotnet/runtime/pull/115762（一手；2025-05-20 開、05-22 關、05-23 鎖）
[^77]: Ghostty、Kyverno 與 GitHub PR 限制設定相關報導（二手聚合，需回查一手）
[^78]: Rovo Dev Code Reviewer 讀「Acceptance Criteria／AC／ACs」標題區段、僅支援英文之說：搜尋摘要與社群貼文；另一則社群 Q&A 稱可用 Gherkin（二手；原文頁只取得標題；日期不明）
[^79]: Böckeler 文章：spec-kit 實測；2025-10 文章提及 Kiro 用 GIVEN/WHEN/THEN（一手或二手標記素材未載明）
[^80]: Codex AGENTS.md 行為之第三方描述；官方頁未取得（二手；未確認）
[^81]: Kiro 官方 docs，規格格式為 EARS（URL 與日期素材未載明）
[^82]: Nakashima 論文，arXiv 2602.04226（僅見摘要）
[^83]: unrequested changes 相關研究，arXiv 2607.29516（僅提及框架）
[^84]: OpenAI 2026-02 停止回報 SWE-bench Verified、改建議 SWE-bench Pro（二手摘要）
