# 2026 年 code review 工作流現況分析

## Context

這份分析整理 2026 年 11 月業界 code review 工作流的樣貌，用來設計本團隊的 review 流程與「程式碼品質審查」plugin。資料蒐集於 2026-11-09，來源是工具與平台官方文件、公司工程部落格、研究報告與新聞報導，多數官方頁沒有日期。範圍以 GitHub／GitLab 上的 PR／MR 流程為主。標為「二手」「未確認」的內容一律保留標記。

---

## 一、全景摘要

- **AI 給意見、人拍板，是所有主流產品的共同設計**：Claude Code Review 不核准也不擋 PR [2]，GitHub 讓 Copilot 正式核准的功能預設關閉 [51]。
- **瓶頸從寫程式移到等 review**：Faros 2026 遙測顯示 review 中位時間 +441.5% [32]，Harvard 工作論文稱 PR 提交到合併從 7.03 天拉長到 10.48 天（二手）[34]。
- **降噪是 AI reviewer 的出廠設定**：Claude 預設只看 correctness [2]，Codex 只標 P0／P1 [4]，Gemini 只貼 MEDIUM 以上 [10]。
- **人類流程最大的變化是 stacked PR 進入平台原生**：GitHub 2026-07-30 起公開預覽（細節多為二手）[16]，Mergify 2026-08-12 起能把原生 stack 送進 merge queue [20]。
- **量化門檻沒有共識**：PR size 的最高級門檻，LinearB 2026 是 100 行以下 [36]，Swarmia 是 200 行以下 [68]，Google 只說約 100 行合理 [14]。

## 二、AI 輔助 review 工具的現況

AI reviewer 已分成兩條路。一條是 SaaS，隨 PR 事件自動跑。另一條是自己在 CI 跑 agent。下表的官方頁大多沒有日期，例外是 GitLab blog（2026-03-19）、GitLab docs（2026-10-05）與 Graphite 定價頁尾（2026）[12][11][7]。

| 工具 | 觸發 | 預設範圍 | 計價 | 調校檔 | 出處 |
|---|---|---|---|---|---|
| Copilot code review | 指派 reviewer；ruleset 可設開 PR、新 push 自動跑 | 任意語言；排除依賴檔、log、SVG | AI credits，估計 Lite 約 $0.25、Balanced 約 $1.50、Max 約 $10，另計 Actions minutes | `.github/copilot-instructions.md`、AGENTS.md；effort 三級 | [1] |
| Claude Code Review（託管） | 開 PR 一次／每次 push／僅 `@claude review` | 只看 correctness；多 agent 加驗證步驟；不 build、不執行 | token 用量走 usage credits，可設月上限；Team／Enterprise | `REVIEW.md`、`CLAUDE.md`；Quick／Standard／Deep | [2] |
| claude-code-action | `@claude`，或 workflow 在任何事件自動跑 | 取決於 prompt | Actions minutes 加 API token | `CLAUDE.md`、`claude_args` | [3] |
| Codex | `@codex review`；可開 Automatic review | 只標 P0／P1；security review 為 research preview | 官方頁未載（未確認） | AGENTS.md 的 `## Code Review Rules`，就近者優先 | [4] |
| Cursor Bugbot | PR 建立或更新時自動；`bugbot run` | 以 bug 為主，另有 Autofix | 官方頁未列價（未確認） | `.cursor/BUGBOT.md` | [5] |
| CodeRabbit | PR 自動 | 逐行審查、摘要、自訂檢查 | Essentials $30、Team $60、Advanced $90 每人月（月繳）；公開 repo 免費；超額 $0.25／檔 | `.coderabbit.yaml`；自動讀 AGENTS.md | [6] |
| Graphite | 未確認 | 未確認 | Starter $20、Team $40 每人月（年繳）；Team 起 AI review 無限 | Team 方案含 AI review customizations | [7] |
| Greptile | PR 自動；`@greptile review` 強制 | logic、syntax、style 可選 | credits；Pro 每 credit $1，無 seat fee；Starter 每月 50 credits 免費 | `.greptile/`、`greptile.json` | [8] |
| Qodo（PR-Agent） | 發布 PR 或每次 push | 官方頁未細列 | 官方頁未載；第三方價格互相矛盾（未確認） | `.pr_agent.toml`；severity 門檻 | [9] |
| Gemini Code Assist | PR 開啟時依設定 | 審查、摘要 | 官方頁未載（未確認） | `.gemini/config.yaml`、`styleguide.md`；門檻預設 MEDIUM | [10] |
| GitLab Duo Code Review Flow | 指派或 `@GitLabDuo`；新 MR 自動 | diff 加 repo context，inline 留言 | $0.25／review | `mr-review-instructions.yaml` | [11][12] |

表外有幾個細節會影響選型：

- **調校檔向 AGENTS.md 收斂。** Copilot、CodeRabbit、Codex 都讀 AGENTS.md [1][6][4]。Bugbot 是反例。Cursor 的 `.mdc` 規則對它無效，要另寫 BUGBOT.md [5]。
- **計價從 per seat 走向用量。** Copilot、Claude、Greptile 用 credits，GitLab 每次 review 收 $0.25 [1][2][8][12]。仍以 per seat 為主的只剩 CodeRabbit 與 Graphite [6][7]。
- **觸發頻率就是成本。** Claude 託管版預設每次 push 都審，成本最高，官方建議先用 Once 或 Manual 試點 [2]。Copilot 的費用記在 PR 作者或請求者，預算用完會直接擋審查 [1]。
- **限制寫得最具體的是 GitLab Duo。** 超過 10,000 行的檔案只送 diff，預掃描 context 截到約 800 KiB [11]。
- **CodeRabbit 有少見的自我調校。** `@coderabbitai emit path instructions` 會把近 7 天的建議開 PR 併進設定檔 [6]。
- **合規要先查。** Claude 託管版與 ZDR、HIPAA 組織不相容。本機 `/code-review` 則任何方案都能用 [2]。

嵌入模式可歸納成四種：

| 模式 | 代表工具 | 特性 | 限制 |
|---|---|---|---|
| 平台原生 reviewer | Copilot、GitLab Duo、Gemini Code Assist | 權限與計費和平台整合 | 模型不可選，Copilot 明說不支援切換 [1] |
| 獨立 SaaS reviewer | CodeRabbit、Greptile、Bugbot、Graphite、Qodo、Claude 託管版 | 裝 App、跨平台，自帶索引與學習 | 調校分散在各家規則檔與 severity 設定 |
| 自管 CI agent | claude-code-action、PR-Agent | 自己掌控 prompt 與觸發 | 付 Actions minutes 加 token；降噪全靠自己寫 prompt [3] |
| 隨叫與本機型 | `@codex review`、`@claude review`、`/code-review`、`/security-review` | 人主動呼叫，常跟獨立 SaaS 並用補刀 | 要有人記得觸發 |

## 三、人類 review 流程的主流做法

### Google Engineering Practices：基準仍在，但已停更

- **做法**：變更「明確提升 code health」就核准，不求完美。次要意見加 "Nit:"，代表可選。回覆最長一個工作日。小 CL 約 100 行合理，約 1000 行通常太大，沒有硬性上限 [14]。
- **證據**：repo 於 2025-11-21 封存，最後一次內容更新是 2024-05-10 [15]。之後的 commit 看起來只是網站設定，這點是推論 [15]。
- **適用與代價**：通用。代價是 reviewer 要自律，CL 拆分要靠 stack 工具 [14]。

### Stacked PR：2026 年進入平台原生

- **做法**：把大變更拆成有序、相依的小 PR，每層獨立審查。
- **證據**：GitHub 原生 stack 2026-07-30 起公開預覽，逐步對所有 repo 開放（二手）[16]。PR 頂端有 stack map，reviewer 只看該層 diff。合併最上層可一次帶走下方各層，上層會自動 rebase 或 retarget。既有 required reviews 與 branch protection 照常適用 [16]。GitHub Docs 入口頁沒標明是 preview 還是 GA [17]。Mergify 2026-08-12 起可佇列原生 stack 並依序合併，前提是目標分支 ruleset 的 bypass mode 設為 Exempt [20]。
- **工具**：Graphite 的 gt CLI，2025-12-19 被 Cursor 收購（二手）[13]。另有 Sapling 的 `sl pr` 與 Jujutsu 社群的 jj-stack（皆二手）[30]。
- **適用與代價**：適合大變更與多人平行審。代價是底層 PR 一改，整串都要 rebase，必須靠工具。GitHub 版的方案限制與 merge queue 完整支援時程都未確認 [16]。

### Merge queue：已是標準件

- **做法**：核准後進佇列。CI 在「base 加前面所有項目」的組合上跑，失敗者移出。
- **證據**：GitHub 在 base branch 規則啟用 "Require merge queue"，每組在臨時分支 `gh-readonly-queue/...` 驗證，並行 build 可設 1 到 100 [18]。GitLab merge trains 預設並行 20 條 pipeline，可設 Allow bypass 或 Enforce [19]。Mergify 2026-06 起可依變更目錄自動分組 [20]。
- **適用與代價**：主幹變動頻繁的團隊。GitLab 版限 Premium／Ultimate，且要啟用 merged results pipelines [19]。最常見的坑是 Actions workflow 沒監聽 `merge_group`，required check 就永遠不會回報 [18][63]。

### 平台政策：rulesets 疊加 CODEOWNERS

- **做法**：CODEOWNERS 自動請求 owner 審查，再用 rulesets 與 required reviews 疊出合併條件。
- **證據**：CODEOWNERS 以最後一個匹配規則為準 [22]。Rulesets 可多組同時套用，取最嚴格者，沒有優先序 [23]。GitLab 預設作者不能核准自己的 MR，committer 卻可以 [24]。
- **適用與代價**：Rulesets 需 Team／Enterprise [23]，GitLab approval rules 需 Premium／Ultimate [24]。最大風險是靜默失效。CODEOWNERS 檔超過 3 MB 會整個失效，無 write 權限的 owner 會被忽略，沒列 owner 的路徑任何有 write 權限者都能核准 [22]。

### 審查深度分級與留言規範

- **做法**：Ship／Show／Ask 依信任度分三級。Ship 直接進 mainline，Show 開 PR 但立即合併，Ask 開 PR 等回饋 [25]。留言用 Conventional Comments 的 `<label> [decorations]: <subject>`，以 (blocking)、(non-blocking) 標明是否擋合併 [26]。Sentry 用 LOGAF 標籤，`h` 代表合併前必改 [64]。
- **證據**：Ship／Show／Ask 是 2021-09-08 的文章，不是新趨勢 [25]。高信任團隊多用 Ship，新團隊多用 Show 與 Ask [25]。
- **適用與代價**：適合想縮短等待的團隊。代價的實證比較，素材未涵蓋。兩段式 review（作者自審再同儕審）沒有一手文件，標未確認。

### Pair／mob programming

- **做法**：審查在寫的當下發生。TBD 常見的 review 做法有三種：pair／mob、分支少於一天的短命 PR、post-commit review [28]。
- **證據**：Crisp 團隊自述把 AI 帶進 mob programming（二手）[29]。沒有系統性比較研究。
- **適用與代價**：適合關鍵程式與 onboarding。代價是要同時在場。post-commit review 則需要高覆蓋率與成熟 CI [28]。

### 速度門檻：一手數字只有 Google

Google 的「一個工作日」與「約 100 行」是唯一的一手數字 [14]。其他都是只見搜尋摘要的廠商數字，第六節並列比較 [27]。例如一份 2,189 PR 的廠商自述分析稱，50 行以下與 1,000 行以上 PR 的首次回覆中位數差約 9 倍 [27]。trunkbaseddevelopment.com 不給時數，只說等 review 的時間要算進分支壽命 [21]。Reviewer 輪替與負載平衡沒有一手資料（未確認）。

## 四、AI 生成程式碼之後，review 發生了什麼變化

### 量化證據

| 來源 | 樣本 | 關鍵數字 | 可信度 |
|---|---|---|---|
| Faros 2025 [31] | 1,255 teams、逾 10,000 devs | 高 AI 採用團隊：合併 PR +98%、PR 大小 +154%、review 時間 +91%、每人 bug +9% | 一手（廠商） |
| Faros 2026 [32] | 22,000 devs、逾 4,000 teams | 首次 review 中位數 +156.6%、review 中位時間 +441.5%、未經任何 review 就合併的 PR +31.3%、每人 bug +54% | 一手（廠商） |
| DORA 2025 [33] | 近 5,000 位受訪者 | AI 採用與吞吐量轉為正相關，與交付穩定性仍負相關；90% 使用 AI，30% 幾乎不信任 AI 程式碼 | 一手 |
| Harvard 工作論文 [34] | 約 700 家公司（二手摘要） | PR +23%；提交到合併 7.03 天增為 10.48 天（+49%）；完成的工作無顯著增加 | 二手，未經同行審查 |
| LinearB 2026 [35] | 810 萬+ PR、4,800 teams | agentic AI PR 的 pickup time 是人工 PR 的 5.3 倍；30 天合併率 32.7% 對 84.4% | 搜尋摘要，未讀 PDF |
| METR [38] | 2025：16 位資深開發者；2026：57 位 | 2025 用 AI 慢 19%，事後仍自認快 20%；2026 更新轉為小幅加速，但信賴區間含零 | 2025 一手；2026 細節二手 |
| Google [39][40] | Google 內部 | 已預覽的 ML 建議編輯有 40–50% 被採用；新程式碼 75% 由 AI 產生並經工程師核准，2024 年為 25% | 前者一手；後者二手 |
| Anthropic [41] | 內部 | 有實質 review 留言的 PR 從 16% 升到 54%；誤報率低於 1% | 二手，廠商自報 |
| OpenAI [43] | 內部 | 「幾乎每個 PR」都經 Codex review；工程師每週多完成 70% PR | 二手 |
| GitClear [42] | 2.11 億行變更（2020–2024） | 2024 年複製貼上量首次超過重構；5 行以上重複區塊成長八倍 | 二手（廠商） |

怎麼讀這張表：

- **方向一致，但不能串成一條線。** Faros 的 review 時間從 +91% 擴大到 +441.5% [31][32]。Harvard 是另一個資料集，不能直接相接 [34]。
- **個人加速不等於交付加速。** DORA 說吞吐量轉正 [33]，Harvard 卻顯示完成的工作沒有顯著增加 [34]。METR 的減速結果，到 2026-02 也變得不確定 [38]。
- **DORA 沒有直接談 code review。** 它把不穩定歸因於變更量增加、卻缺乏控制系統 [33]。
- **AI 留言的占比仍低。** 到 2026-03 約 80% 的公司用了某種 AI review，但 AI 只占 23.3% 的 review 留言（二手）[34]。

### 開源與平台政策

一篇 2026-09-07 的論文統計 281 份開源 AI 政策：83.3% 允許或鼓勵，14.9% 禁止 [53]。其中 48.8% 要求揭露，67.3% 要求高度人工參與，43.4% 明訂由人負責 [53]。主流是「允許、揭露、人負全責」。

| 專案／平台 | 政策 | 日期 | 出處 |
|---|---|---|---|
| Linux kernel | AI 不可加 Signed-off-by；人類提交者要審過全部 AI 程式碼並負全責 | 2025 年起，RFC 於 2025-07 | [44] |
| QEMU | 拒絕相信含 AI 生成內容的貢獻，理由是版權與 DCO 無法誠實聲明 | 2025-06；2026-05 的放寬提案是否合併未確認 | [45] |
| NetBSD | LLM 生成程式碼視為 tainted，不可 commit | 2024-05 | [46] |
| Gentoo | Council 禁止 AI 生成內容的貢獻 | 2024-04（二手） | [47] |
| Ghostty | AI 使用須在 PR 揭露；首次貢獻者須經 vouch 才能開 PR | 約 2025-08（只見鏡像與二手） | [48] |
| curl | 結束 HackerOne bug bounty，移除 AI slop 的金錢誘因 | 2026-01 底 | [49] |
| GitHub Copilot code review | 可正式 Approve；預設關閉，管理員逐層授權，可限路徑；推新 commit 後核准失效 | 2026-09-01（public preview） | [51] |
| GitHub Copilot cloud agent | 官方要求合併前徹底審查 Copilot 開的 PR | 日期未確認 | [52] |

### 新興 review 模式

| 模式 | 做法 | 推動者 | 證據狀態 |
|---|---|---|---|
| AI 先審、人後審 | AI 先掃 diff 找 bug，人專注架構與業務邏輯 | Anthropic、OpenAI Codex、GitHub Copilot | 廠商自報，例如 Anthropic 的 16%→54% [41] |
| 對照 spec 審 | 先寫 SPEC.md，再讓 subagent 對照 spec 檢查需求與邊界測試 | Claude Code 文件、JetBrains Research（2026-10） | 無對照實驗；JetBrains 只見搜尋摘要 [56][55] |
| 寫審分離 | 由沒看過寫作過程的 subagent 或另一個 session 審 | Anthropic 的 `/code-review` | 設計理念，無量化對照 [56] |
| 可程式化的核准權限 | AI 核准限縮到特定路徑，人類 approval 才滿足合併規則 | GitHub、Anthropic | 產品設計層面 [51][2] |
| 入口控管 | review 之前先擋低品質來源：vouch、揭露、關閉 PR | Ghostty、curl | 281 份政策中最常見的處置是關閉 PR（48.4%）[53] |

### 風險

- **開放 AI 核准，等於把 review 責任委外。** Faros 2026 已看到未經任何 review 就合併的 PR 增加 31.3% [32]。
- **沒發現問題，不代表沒有問題。** Anthropic 文件明說 review 只讀 diff 與周邊程式碼，不建置也不執行 [2]。
- **被要求找問題的 reviewer，一定會找到東西。** 這容易引發過度修正。Claude Code 文件因此建議在 review 指令加上 skip style [56]。
- **Spec 錯了，整條驗證鏈都會偏。** 對照 spec 審的模式目前沒有對照實驗 [56]。
- **Rubber-stamp 還沒有直接量測。** Sonar 2026 調查（二手引用）稱 96% 不完全信任 AI 程式碼，只有 48% 提交前一定驗證 [54]。Stack Overflow 在 2026-05 認為，判斷自己沒寫的程式碼更難 [54]。

## 五、端到端工作流樣板

一手資料裡，完整寫出 PR 流程的只有 Cloudflare、Microsoft、Anthropic 三家，再加上 Sentry 的公開準則 [65][66][57][64]。共同骨架是：本機快檢查，CI 跑 linter 與 AI 審，AI 只提意見不決定合併，人類保留最終核准。

### 樣板 A：小團隊 trunk-based

1. 依風險選 Ship、Show 或 Ask。PR 只做一件事，分支只活幾天 [25][21]。
2. 本機 pre-commit 用 lefthook 跑 lint 與 typecheck。AI 自審放 pre-push 或手動，預設 warn 不 block [59]。
3. 推送前手動跑 `/security-review` 或 Codex 自審 [58][59]。Claude Code 的 PreToolUse hook 可擋 `--no-verify`（社群做法，二手）[60]。
4. 開 PR 後跑輕量 AI review，例如 claude-code-action，只留言 [3]。
5. 人類 reviewer 用 Conventional Comments 或 LOGAF 標明輕重 [26][64]。
6. CODEOWNERS、required review 與 CI 必過 check，再搭配 auto-merge [22][23]。
7. 首次回覆以一個工作日為上限 [14]。來回卡住就改用結對 [28]。

**案例：Sentry** [64]。作者 @mention 團隊，指定 1 到 3 位 reviewer。可以先開 WIP 確認 CI 通過。風格與覆蓋率盡量交給自動化。schema、API、新框架這類長期變更，要知會資深工程師。Sentry 沒有正式 SLA，只說每次要求修改通常延誤 24 小時以上。

### 樣板 B：中大型 stacked PR + merge queue

1. 功能拆成 stack，每層單一職責。用 GitHub 原生 stack 或 Graphite、Sapling、jj 管理 [16][13][30]。
2. CI 跑 Danger 規則，例如 PR 超過 600 行就警告、缺 test 就判失敗 [61]。reviewdog 把 linter 輸出過濾成 diff 行再回報 [62]。
3. 依風險分級跑多代理 AI review，只留言 [65]。
4. CODEOWNERS 依層自動指派不同 reviewer，平行審查 [22]。
5. 核准後進 merge queue 或 merge train，CI 必須訂閱 `merge_group` [18][19][63]。
6. 保留人工放行的逃生口，每次放行都記錄 [65]。
7. 用 LinearB 或 Swarmia 追蹤 pickup time、review time、rework rate [36][68]。

**案例：Cloudflare**（2026-04-20）[65]

- 開 MR 後由 GitLab CI component 觸發。
- 依行數、檔數、是否動到 `auth/` 或 `crypto/`，分成 trivial、lite、full 三級。
- 濾掉 lock 檔與生成檔，但保留 migration。
- 最多七個專家 agent 平行審，coordinator 去重後只發一則結構化留言。
- 結論分四態，只有「significant concerns」會送出 request changes。新 commit 觸發增量重審。
- 人類留言 "break glass" 可強制放行，並記錄在 telemetry。
- 2026-03-10 到 04-09 共 131,246 次審查、48,095 個 MR、5,169 個 repo。中位數 3 分 39 秒，平均每次 1.19 美元，break glass 占 0.6%。
- 該文沒有寫明人類核准是否為 merge 的設定要求。

**案例：Microsoft**（2025-07-14）[66]。開 PR 時 AI 自動加為 reviewer，直接在原有 PR thread 行內留言並標類別。AI 可以提修正，但要作者自己按 "apply change"。各 repo 可加自己的準則與 prompt。涵蓋超過 90% 的 PR，每月超過 60 萬個。5,000 個 repo 的 PR 完成時間中位數改善 10–20%，屬自報。

**案例：Anthropic**（2026-03-09）[57]。管理員裝 GitHub App 並選 repo。開 PR 後多個 agent 平行找 bug，驗證並濾掉誤報，再依嚴重度排序。最後發一則總覽留言加行內留言，核准仍由人決定。單次約 15–25 美元，另有較輕量的開源 GitHub Action。

**受管制企業的變體。** 用 ruleset 與 GitLab approval policies 強制指定人類核准者 [23][24]，merge train 開 Enforce [19]。trunkbaseddevelopment.com 也認為，需要分權的企業可以保留具名人類核准的 PR [21]。

**Shopify 只有廠商說法。** Graphite 客戶頁稱 virtual queue 依 zone 分區，merge 等待從數小時降到數分鐘，每年省 27,000 工時。這是廠商行銷數字，不是 Shopify 自家文章 [67]。

### 樣板 C：開源專案

1. 入口先控管。Ghostty 要求揭露 AI 使用，首次貢獻者要經 vouch [48]。Linux kernel 把責任綁在人類的 Signed-off-by [44]。
2. CI annotation 顯示 linter 與 SAST 結果。fork PR 的 token 沒有寫入權限，reviewdog 要降級為 annotations [62]。
3. 維護者人審，用 LOGAF 或 request-changes，從寬處理 [64]。
4. 低品質來源直接關閉 PR。這是 281 份政策中最常見的處置，占 48.4% [53]。
5. 留意 bot 留言過量造成的 friction（Archgate 對 Sentry 的第三方研究，二手）[72]。

## 六、指標與 benchmark

| 指標 | 定義 | benchmark | 出處 |
|---|---|---|---|
| Pickup time | PR 開出到首次 review 開始 | LinearB 2026：Elite 小於 1 小時、Good 1–4 小時、Fair 5–16 小時 | [36] |
| Pickup time（2025 版） | 同上 | LinearB 2025：Elite 小於 75 分鐘、Good 75 分鐘至 5 小時 | [37]（搜尋摘要） |
| Time to first human review | 要求 review 到首次人類 review，排除 bot | Swarmia：Great 4 小時內、Good 24 小時內 | [68] |
| 首次回覆時限 | reviewer 回覆 | Google：最長一個工作日 | [14] |
| Review time | 首次 review 到核准 | LinearB 2026：Elite 小於 3 小時、Good 3–14 小時 | [36] |
| Cycle time | 整體週期 | LinearB 2026：Elite 小於 25 小時、Good 25–72 小時 | [36] |
| PR cycle time | 開 PR 到合併 | Swarmia：Great 小於 24 小時、Good 小於 5 天 | [68] |
| Median time to merge | 發布到合併 | Graphite：全部 PR 3.5 小時；活躍開發者 9 小時 | [70] |
| PR size | 變更行數 | LinearB 2026：Elite 小於 100 行、Good 100–155 行 | [36] |
| Batch size | PR 行數 | Swarmia：Great 小於 200、Good 小於 500 | [68] |
| CL 大小 | 行數與檔案數 | Google：約 100 行合理，約 1000 行通常太大 | [14] |
| Median PR size | 活躍開發者的 PR 行數 | Graphite：47 行；多次 review 的 PR 為 94 行 | [69] |
| Rework rate | 重工比例 | LinearB 2026：Elite 小於 3%、Good 3–5% | [36] |
| Diffs per engineer | 每人每週合併 PR 數 | DX Core 4：數值未取得 | [71] |

數字不一致的地方：

- **PR size 至少有四套門檻。** Google 約 100 行 [14]，LinearB Elite 小於 100 行 [36]，Swarmia Great 小於 200 行 [68]，SmartBear 稱 200–400 行效果最好（二手）[27]。Danger 文件的範例規則，則到 600 行才警告 [61]。
- **首次回覆的期待從 1 小時到一個工作日不等。** LinearB Elite 小於 1 小時 [36]，Swarmia Great 4 小時內 [68]，Google 最長一個工作日 [14]。Augment Code 的 1h／4h／24h 分級宣稱源自 DORA，但沒有 DORA 一手出處（二手）[27]。SmartBear 研究（2,500 PR）另稱審查效果在 60 分鐘達高點（二手）[27]。
- **定義不同。** Swarmia 的 time to first human review 排除 bot [68]，LinearB 的 pickup time 定義沒提 bot [36]。AI reviewer 普及後，有沒有排除 bot 會影響可比性。
- **同一家不同年不能比。** LinearB 2025 與 2026 的分級不同 [37][36]。
- **廠商資料有內部矛盾。** Swarmia 表格的 Needs attention 欄寫小於 24 小時，與 Good 的 24 小時內重疊 [68]。Graphite「僅計有 review 的 PR」的中位數，摘要寫 6 小時、內文寫 10 小時，資料集大小與發布日期都沒寫 [70]。

## 七、對本團隊與 review plugin 的啟示

1. **預設只報高嚴重度問題，style 與格式交給 CI。** 依據是主流 reviewer 都把降噪當預設。Claude 只看 correctness [2]，Codex 只標 P0／P1，並建議格式與 lint 留給 CI [4]，Gemini 只貼 MEDIUM 以上 [10]。Claude Code 文件也提醒，不加 skip style，reviewer 一定會挑出一堆小問題 [56]。做法：品質審查 plugin 預設設一道 severity 門檻，低嚴重度意見收進可選段落。

2. **規則檔讀 AGENTS.md 與 CLAUDE.md，不另造格式。** 依據是 Copilot、CodeRabbit、Codex 都讀 AGENTS.md [1][6][4]。Bugbot 是反例，Cursor 的 `.mdc` 對它無效，使用者得多維護一份 BUGBOT.md [5]。做法：plugin 要明定從 base 還是 head branch 讀規則。Copilot 讀 head [1]，Claude 只讀 base [2]，兩種都有人用。

3. **依風險分級決定審查深度。** 依據是 Cloudflare 依行數、檔數與 `auth/`、`crypto/` 路徑分 trivial、lite、full [65]。Claude 託管版有 Quick／Standard／Deep [2]，Copilot 有三級 effort [1]。成本落差也大：Cloudflare 平均每次 1.19 美元 [65]，Anthropic 單次約 15–25 美元 [57]。兩者設計與規模不同，不能直接比。做法：plugin 先判斷 diff 規模與敏感路徑，再決定跑幾個審查面向。

4. **AI 只留言，人類核准設成合併條件，並保留有紀錄的逃生口。** 依據是 Anthropic 的 review 不核准也不擋 PR [2]，GitHub 的 Copilot 核准預設關閉，推新 commit 後就失效 [51]。Faros 2026 看到未經任何 review 就合併的 PR 增加 31.3% [32]。Cloudflare 的 break glass 只占 0.6%，而且每次都記在 telemetry [65]。做法：團隊 ruleset 要求人類核准。導入 merge queue 前，先確認 CI 監聽 `merge_group` [18]。

5. **寫審分離、對照 spec 審，但當成待驗證的假設。** 依據是 `/code-review` 用沒看過對話的 subagent，讓 reviewer 不受寫作時的推理影響 [56]。Claude Code 文件也建議先寫 SPEC.md，再讓 subagent 對照 spec review [56]。這兩點都沒有量化對照。做法：導入後追蹤兩個數字。一是有實質留言的 PR 比例，Anthropic 自報從 16% 升到 54% [57][41]。二是排除 bot 的 time to first human review，Swarmia 的 Great 是 4 小時內 [68]。

## 八、未確認與互相矛盾的事項

| 事項 | 狀況 | 出處 |
|---|---|---|
| Copilot 計價 | 官方頁是 AI credits 加 Actions minutes；二手文章仍寫 premium requests，應為舊資料 | [1] |
| Bugbot 價格 | 一說 $40／月、上限 200 PR，一說每 PR 約 $1.25；官方頁沒列價，兩者皆未確認 | [5] |
| Qodo 價格、PR-Agent 現況 | 只有二手來源且彼此不一致；PR-Agent 改由社群維護、Qodo 贊助，同屬二手 | [9] |
| Codex、Gemini 計價；Graphite 觸發與覆蓋 | 官方頁未載 | [4][10][7] |
| Graphite 改名與收購後路線 | 定價頁沒有 Diamond 或 Graphite Agent 字樣；與 Bugbot 整合的現況未確認 | [7][13] |
| Gemini `/gemini review` | 官方頁沒提，是否仍支援未確認 | [10] |
| Claude Code Review 的 check run | docs 記載 check run 不判失敗；另有說法稱此點只見二手摘要，官方只說不核准 | [2][57] |
| `/code-review`、`/security-review` 文件 | docs 的 code-review 頁列有兩者；另有說法稱 `/code-review` 找不到對應文件，`/security-review` 只有 support 頁摘要 | [2][58] |
| AI review 誤報率與速度 | 沒有可靠的使用者回報數據；Anthropic「誤報率低於 1%」為廠商自報、二手 | [41] |
| Anthropic 16%→54% | 一處標為只來自二手報導，另一處列在 Anthropic blog 案例中；GA 日期 2026-10-15 只見二手 | [41][57] |
| Anthropic「65% 產品工程 PR 由系統處理」 | 只見二手轉述 | 無一手來源 |
| GitHub 原生 stack | 方案要求與 merge queue 完整支援時程未確認；「About stacked pull requests」頁抓取 404，細節主要來自二手 | [16][17] |
| jj 與 GitHub 原生 stack 相容 | 只見搜尋摘要，未在 GitHub Docs 確認 | [30] |
| 首次回覆 SLA、PR 行數 | 除 Google 外都是廠商或二手數字，各源不一致 | [14][27] |
| 兩段式 review、reviewer 輪替 | 沒有一手來源 | 素材未涵蓋 |
| SAST 註解能否設為 required | GitHub code scanning 頁沒寫 | 素材未涵蓋 |
| DORA 與 code review | 官方頁與 blog 沒談 code review；完整 PDF 未讀，七種團隊類型只見二手 | [33] |
| DORA 2026 | 單一來源稱可能不出新報告，未驗證 | 未附 URL |
| Faros PR 大小 | 2025 報告 +154%，FAQ 頁 +51.3%，2026 摘要 +51%，口徑未對齊 | [31][32] |
| METR 後續 | 有來源稱後續研究擱置，與 2026-02 的更新矛盾；更新細節只見搜尋摘要 | [38] |
| Harvard 論文 | 只有二手報導，樣本數與日期未確認 | [34] |
| LinearB AI PR 倍數 | 5.3 倍與 4.6 倍口徑不同；數字來自搜尋摘要 | [35] |
| Linux kernel Assisted-by | 搜尋結果稱有此標籤，現行文件頁沒有；以 kernel tree 現行檔案為準 | [44] |
| QEMU 放寬 | master 文件仍禁止；Phoronix 稱 2026-05 有放寬 patch，是否合併未確認 | [45] |
| NetBSD | 一說全面禁止，一說需 core team 核准 | [46] |
| OpenAI | 「幾乎每個 PR」與「100%」措辭不同，只有二手 | [43] |
| curl | 2026-07 停止讀報告一事無第二來源；真報告比例約六分之一或低於 5%，互相矛盾 | [49] |
| Stripe、Vercel、Shopify 自家流程 | 沒有一手文章；Stripe Minions「每週合併超過一千個 PR」只見二手指南 | [67] |
| Ghostty、Gentoo、EFF | Ghostty 只見鏡像與二手；Gentoo 只有二手；EFF 政策內容未讀 | [48][47][50] |

素材未涵蓋：DX 與 Jellyfish 的 2025–26 一手報告與 benchmark、Meta 內部 AI review 現況、Python 的 AI 政策。

## 參考來源

1. GitHub Docs：Copilot code review 概念頁（日期不明，一手）。<https://docs.github.com/en/copilot/concepts/agents/code-review>
2. Claude Code Docs：Code Review 與 Code Review 費用頁（日期不明，一手）。<https://code.claude.com/docs/en/code-review.md>、<https://code.claude.com/docs/en/code-review-costs.md>
3. Claude Code Docs：GitHub Actions 頁（日期不明，一手）。<https://code.claude.com/docs/en/github-actions>
4. OpenAI：Codex 的 GitHub 整合頁（日期不明，一手）。<https://learn.chatgpt.com/docs/third-party/github>
5. Cursor Help：Bugbot（日期不明，一手；價格說法為二手、未確認）。<https://cursor.com/help/ai-features/bugbot>
6. CodeRabbit：定價頁與 review instructions 文件（日期不明，一手）。<https://coderabbit.ai/pricing>、<https://docs.coderabbit.ai/guides/review-instructions>
7. Graphite：定價頁（頁尾 2026，一手）。<https://graphite.com/pricing>
8. Greptile：定價頁與 code-review-bot/custom-context 文件（日期不明，一手）。<https://greptile.com/pricing>
9. Qodo Docs：Code Review（日期不明，一手；價格與 PR-Agent 現況為二手）。<https://docs.qodo.ai/code-review>
10. Google Cloud Docs：Gemini Code Assist 的 repo review 客製化（日期不明，一手）。<https://docs.cloud.google.com/gemini/docs/code-review/customize-repo-review>
11. GitLab Docs：Duo Code Review Flow 頁，docs.gitlab.com（最近紀錄 2026-10-05，一手；未附完整 URL）。
12. GitLab Blog：agentic code review 改為固定費率（2026-03-19，一手）。<https://about.gitlab.com/blog/agentic-code-reviews-with-flat-rate-pricing>
13. SiliconANGLE、TechCrunch：Cursor 收購 Graphite 的報導，另有 devops.com（2025-12-19，二手）。<https://siliconangle.com/2025/12/19/cursor-acquires-ai-code-review-startup-graphite/>、<https://techcrunch.com/2025/12/19/cursor-continues-acquisition-spree-with-graphite-deal>
14. Google Engineering Practices：reviewer/standard、reviewer/speed、developer/small-cls 三頁（頁面無日期，一手）。<https://google.github.io/eng-practices/review/reviewer/standard.html>
15. google/eng-practices commit 紀錄（2025-11-21 封存，一手；「其後僅網站設定」為推論）。<https://github.com/google/eng-practices/commits/master>
16. ITBrief：GitHub stacked PR 公開預覽報導（2026-07-31，二手）。<https://itbrief.co.uk/story/github-puts-stacked-pull-requests-into-public-preview>
17. GitHub Docs：stacked pull requests 入口頁（日期不明，一手；未標 preview 或 GA）。<https://docs.github.com/en/pull-requests/how-tos/stacked-pull-requests>
18. GitHub Docs：managing a merge queue（日期不明，一手）。<https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue>
19. GitLab Docs：merge trains（日期不明，一手）。<https://docs.gitlab.com/ci/pipelines/merge_trains/>
20. Mergify changelog：依變更檔案自動分組、佇列 GitHub 原生 stack（2026-06-02、2026-08-12，一手）。<https://docs.mergify.com/changelog/2026-06-02-auto-group-queued-pull-requests-by-changed-files/>、<https://docs.mergify.com/changelog/2026-08-12-merge-github-stacked-pull-requests-with-the-merge-queue/>
21. trunkbaseddevelopment.com：short-lived feature branches（版權 2017–2020，AI 段落更新日期不明，一手）。<https://trunkbaseddevelopment.com/short-lived-feature-branches/>
22. GitHub Docs：about code owners（日期不明，一手）。<https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners>
23. GitHub Docs：about rulesets（日期不明，一手）。<https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets>
24. GitLab Docs：merge request approval rules（日期不明，一手）。<https://docs.gitlab.com/ee/user/project/merge_requests/approvals/rules.html>
25. Rouan Wilsenach：Ship / Show / Ask，martinfowler.com（2021-09-08，一手）。<https://martinfowler.com/articles/ship-show-ask.html>
26. Paul Slaughter：Conventional Comments（© 2025，無版本號，一手）。<https://conventionalcomments.org/>
27. 廠商 review 速度數字：Augment Code 首次回覆分級、SmartBear 2,500 PR 研究、一份 2,189 PR 廠商自述分析（未附 URL，只見搜尋摘要，二手）。
28. Learn Agile Practices：trunk-based 的 code review 做法（2025-05-06，二手）。<https://learnagilepractices.substack.com/p/code-review-approaches-for-trunk>
29. Crisp Blog：高績效團隊的 AI mob programming 自述（2025-06-02，二手）。<https://blog.crisp.se/2025/06/02/michaelgothe/mob-programming-with-ai-inside-a-high-performing-teams-journey>
30. Stack 工具：jj-stack 發布文，以及 jjpr、jj-vine、Sapling `sl pr` 的第三方描述（二手）。<https://www.serpentine.com/posts/2026/announcing-jj-stack/>
31. Faros AI：AI Productivity Paradox 報告（2025-07-23，一手，廠商）。<https://www.faros.ai/blog/ai-productivity-paradox-report-2025>
32. Faros AI：Engineering Report 2026 重點（2026-04-12，一手，廠商）。<https://faros.ai/blog/ai-acceleration-whiplash-takeaways>
33. Google Cloud Blog：2025 DORA 報告發布文（2025-09-24，一手）。<https://cloud.google.com/blog/products/ai-machine-learning/announcing-the-2025-dora-report>
34. Complex Discovery：Chen & Stratton 工作論文（Jellyfish 客戶資料）報導（2026，日期未確認，二手）。<https://complexdiscovery.com/harvard-researchers-find-ai-coding-agents-shifted-the-bottleneck-to-code-review/>
35. LinearB 2026 Software Engineering Benchmarks Report PDF（2025-12 發布，只見搜尋摘要）。<https://assets.linearb.io/image/upload/v1765300694/resources/LinearB_2026_Software_Engineering_Benchmarks_Report.pdf>
36. LinearB：engineering benchmarks 頁，2026 報告（8.1M PR、4,800 團隊；2026，一手，廠商）。<https://linearb.io/engineering-benchmarks/>
37. LinearB 2025 Benchmark Report PDF（6.1M PR、3,000 團隊；只見搜尋摘要，PDF 未讀）。<https://assets.linearb.io/image/upload/v1731970015/resources/LinearB_2025_Benchmark_Report.pdf>
38. METR：資深開源開發者 AI 隨機對照試驗（2025-07-10，一手；2026-02-24 更新細節為二手）。<https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/>
39. Google Research：用 ML 處理 code review 留言（2023-05-23，一手）。<https://research.google/blog/resolving-code-review-comments-with-ml/>
40. TechSpot：Google 新程式碼 75% 由 AI 產生（2026-04，二手）。<https://www.techspot.com/news/112152-google-ai-now-generates-75-new-code-up.html>
41. InfoQ：Claude Code Review 報導（2026-04，二手，廠商自報）。<https://www.infoq.com/news/2026/04/claude-code-review/>
42. I Programmer：GitClear 程式碼品質報告（2025-02，二手，廠商）。<https://www.i-programmer.info/news/105-artificial-intelligence/17871-gitclear-reveals-ais-negative-impact-on-code-quality.html>
43. Analytics India Magazine：OpenAI 內部 Codex 使用（2025 DevDay，二手）。<https://analyticsindiamag.com/ai-news-updates/almost-all-new-code-written-at-openai-today-is-from-codex-users/>
44. Linux kernel 文件：coding assistants（頁面無日期，一手）。<https://docs.kernel.org/process/coding-assistants.html>
45. QEMU 文件：code provenance（2025-06 起，一手；2026-05 放寬 patch 出自 Phoronix，未確認）。<https://www.qemu.org/docs/master/devel/code-provenance.html>
46. Linuxiac：NetBSD 禁用 AI 程式碼的新政策（2024-05，二手）。<https://linuxiac.com/netbsd-new-policy-prohibits-usage-of-ai-code/>
47. Tom's Hardware：Linux 發行版禁用 AI 生成程式碼（2024-04，二手）。<https://www.tomshardware.com/software/linux/linux-distros-ban-tainted-ai-generated-code>
48. Ghostty：AI_POLICY.md（約 2025-08，只見鏡像與二手）。<https://github.com/ghostty-org/ghostty>
49. The Register：curl 結束 bug bounty（2026-01-21，二手）。<https://www.theregister.com/2026/01/21/curl_ends_bug_bounty/>
50. EFF：開源專案的 LLM 輔助貢獻政策（2026-02，內容未讀）。<https://www.eff.org/deeplinks/2026/02/effs-policy-llm-assisted-contributions-our-open-source-projects>
51. GitHub Changelog：Copilot code review 可核准 PR（2026-09-01，一手）。<https://github.blog/changelog/2026-09-01-copilot-code-review-can-now-approve-pull-requests>
52. GitHub Docs：審查 Copilot cloud agent 開的 PR（日期未確認，一手）。<https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/review-copilot-prs>
53. arXiv 2609.07542：281 份開源 AI 政策統計（2026-09-07，一手）。<https://arxiv.org/html/2609.07542>
54. Stack Overflow 文章（2026-05）與 Sonar 2026 調查（未附 URL；Sonar 為二手引用）。
55. JetBrains Research（2026-10；原文無法存取，只見搜尋摘要，未附 URL）。
56. Anthropic Claude Code 文件：best practices 與 `/code-review` 說明（日期不明，未附 URL）。
57. Anthropic Blog：Code Review 發布文（2026-03-09，一手）。<https://claude.com/blog/code-review>
58. Anthropic Support：Claude Code 自動安全審查（日期不明，二手摘要）。<https://support.claude.com/en/articles/11932705-automated-security-reviews-in-claude-code>
59. 社群文章：Codex CLI 的 git hooks 自審（2026-04-27，二手）。<https://codex.danielvaughan.com/2026/04/27/codex-cli-git-hooks-pre-commit-review-commit-msg-pre-push-validation/>
60. 社群 skill：擋 `--no-verify` 的 hook（日期不明，二手）。<https://hackernoon.com/skills/wshobson-block-no-verify-hook>
61. Danger JS 官方文件（日期不明，一手）。<https://danger.systems/js/>
62. reviewdog 官方 repo（日期不明，一手）。<https://github.com/reviewdog/reviewdog>
63. GitHub Docs：troubleshooting required status checks（日期不明，一手）。<https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks>
64. Sentry Engineering Practices：code review（無日期，一手）。<https://develop.sentry.dev/engineering-practices/code-review/>
65. Cloudflare Blog：AI code review（2026-04-20，一手）。<https://blog.cloudflare.com/ai-code-review/>
66. Engineering at Microsoft：大規模 AI code review（2025-07-14，一手，數據為自報）。<https://devblogs.microsoft.com/engineering-at-microsoft/enhancing-code-quality-at-scale-with-ai-powered-code-reviews/>
67. Graphite 客戶案例：Shopify（日期不明，廠商行銷；就 Shopify 流程而言屬二手）。<https://graphite.com/customer/shopify>
68. Swarmia Help：benchmarks and comparisons（日期不明，一手，廠商）。<https://help.swarmia.com/guides/benchmarks-and-comparisons>
69. Graphite Research：median PR size（日期不明，一手，廠商）。<https://graphite.com/research/median-pr_size>
70. Graphite Research：median time to merge（資料自 2023-01 起，發布日期不明，一手，廠商）。<https://graphite.com/research/median-time-to-merge-prs>
71. DX：benchmarks（Core 4；日期不明，數值未取得）。<https://getdx.com/research/benchmarks/>
72. Archgate 對 Sentry 的第三方研究（未附 URL，二手）。
