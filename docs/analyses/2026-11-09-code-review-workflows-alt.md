# 2026 年 Code Review 工作流現況分析

> 本檔是同一份研究素材的另一寫作版本（writing-ab 盲測平手，兩版並存）。正式版見 `2026-11-09-code-review-workflows.md`。

## Context

本文件旨在釐清 2026 年 11 月業界的 code review 工作流全貌、主流工具、量化證據與制度變化，供後續設計團隊審查流程與開發 Claude Code 程式碼品質審查 plugin 時作為決策依據。分析內容完全基於截至 2026-11-09 彙整之官方技術文件、工程部落格、基準測試報告與學術論文，不推演素材未涵蓋之假設。適用範圍涵蓋本機自審、CI 自動化、AI 輔助審查、平台保護規則（rulesets、merge queue、stacked PR）及工程指標定義。

---

## 一、全景摘要

- AI 大量產出程式碼後，工程瓶頸已正式轉移至審查端，Faros 2026-04-12 報告（22,000 位開發者、逾 4,000 個團隊）顯示首次 review 中位時間上升 156.6% `[28]`、整體 review 中位時間暴增 441.5% `[28]`，Harvard 工作論文（二手、日期未確認，約 700 家公司）亦指出 PR 從提交到合併由 7.03 天拉長至 10.48 天（+49%）`[30]`。
- 2026 年的 AI 審查工具已分化為「隨 PR 事件觸發的託管／平台 reviewer」與「自管 CI agent」兩條路線，且官方預設皆將「降噪」與「人類拍板」列為核心，例如 Claude Code Review（日期不明）預設僅檢查 correctness 且不核准也不阻擋 PR `[2]`，OpenAI Codex（日期不明）預設僅標示 P0/P1 問題 `[4]`。
- 人類審查基礎設施在 2026 年迎來 stacked PR 平台原生化與 merge queue 標準化，GitHub 於 2026-07-30 啟動 stacked PR 公開預覽（二手，2026-07-31）`[14]`，Mergify 於 2026-08-12 支援佇列合併 GitHub 原生 stack `[18]`。
- 開源專案與企業平台對 AI 生成程式碼的治理已收斂為「允許使用、強制揭露、人類負全責」，2026-09-07 針對 281 份開源政策的統計指出 83.3% 允許或鼓勵 AI 貢獻、67.3% 要求高度人工參與 `[45]`，典型代表為 Linux kernel（2025 年起，頁面日期不明）禁止 AI 簽署 `Signed-off-by` 並要求人類提交者負完全責任 `[38]`。
- 企業端到端工作流已定型為「本機快篩、CI 風險分級與多代理審查、人類核准加逃生口」，例如 Cloudflare（2026-04-20）依變更風險分 3 級並派最多 7 個專家 agent 平行審查，在 48,095 個 MR 中達到中位審查時間 3 分 39 秒、單次成本 1.19 美元，且保留人類留言 `break glass` 強制放行（占 0.6%）`[51]`。

---

## 二、AI 輔助 review 工具的現況

2026 年的 AI code review 工具市場已明確分成兩條路徑。第一條是隨 PR 或 MR 事件自動執行的 SaaS 與平台內建 reviewer，包含 GitHub Copilot、Claude Code Review、OpenAI Codex、Cursor Bugbot、CodeRabbit、Greptile、Gemini Code Assist、GitLab Duo 與 Graphite `[1][2][4][5][6][7][8][10][11]`。第二條是在自家 CI 管線中執行 agent，代表工具為 `claude-code-action` 與 Qodo（PR-Agent）`[3][9]`。

### 1. 主流工具對照表

多數官方文件頁面未標示更新日期，於表中保留「日期不明」標記。

| 工具 | 觸發方式 | 覆蓋範圍 | 計價模式 | 調校機制 | 來源 |
|---|---|---|---|---|---|
| Copilot code review | 指派 reviewer；ruleset 或個人設定自動跑（開 PR、draft 轉 open、新 push） | 任意語言，含修正建議、agentic 抓 repo context；排除依賴檔、log、SVG | AI credits 加 Actions minutes；估計 Lite 約 $0.25、Balanced 約 $1.50、Max 約 $10 | `.github/copilot-instructions.md`、`.github/instructions/**/*.instructions.md`、`AGENTS.md`、skills；effort 分 3 級 | `[1]`（一手，日期不明） |
| Claude Code Review（託管） | repo 層級設定：開 PR 一次／每次 push／僅 `@claude review` | 預設只看 correctness；多 agent 並行加驗證步驟；不 build、不跑程式 | 無固定單價，token 用量走 usage credits，可設月上限；限 Team／Enterprise | `REVIEW.md`、`CLAUDE.md`；深度分 Quick／Standard／Deep | `[2]`（一手，日期不明） |
| claude-code-action | `@claude` 提及，或 workflow 設 `prompt` 在任何事件自動跑 | 取決於 prompt，可執行 `/code-review:code-review --comment` | 自付 Actions minutes 加 API token（或訂閱 OAuth） | `CLAUDE.md`、`claude_args`、`--max-turns` | `[3]`（一手，日期不明） |
| `/code-review`、`/security-review` | 本機手動執行 | 當前 branch diff；後者針對安全面向 | 含在使用者自身 Claude 用量 | 可客製（二手來源說明） | `[2][47]`（一手／二手，日期不明） |
| OpenAI Codex | `@codex review`；設定中開啟 Automatic review | 預設僅標 P0/P1；另有 security review（research preview） | 該頁未載（未確認） | `AGENTS.md` 的 `## Code Review Rules`，就近檔案優先 | `[4]`（一手，日期不明） |
| Cursor Bugbot | PR 建立或更新自動跑；留言 `cursor review` 或 `bugbot run` | 以 bug 為主；另有 Autofix | 官方頁未列價（未確認；二手稱 $40／月上限 200 PR 或每 PR 約 $1.25） | `.cursor/BUGBOT.md`（單檔 3 萬字元、每次 10 萬）；Automations 設團隊規則 | `[5]`（一手，日期不明；價格二手未確認） |
| CodeRabbit | PR 自動執行 | 逐行審查、摘要、自訂檢查 | 月繳：Essentials $30、Team $60、Advanced $90／人月；公開 repo 免費；超額 $0.25／檔 | `.coderabbit.yaml`（`path_instructions`、`path_filters`）；自動讀 `AGENTS.md`、`.cursorrules` | `[6]`（一手，日期不明） |
| Graphite | 未確認 | 未確認 | 年繳：Hobby 免費、Starter $20、Team $40／人月；Team 起 AI review 無限 | Team 方案含 AI review customizations | `[7]`（一手，頁尾 2026） |
| Greptile | PR 自動跑；`@greptile review` 強制觸發 | logic、syntax、style 可選 | 扣 credits：Base 1、Plus 3、Apex 10；Pro 每 credit $1 無 seat fee；Starter 免費 50 credits／月 | `.greptile/config.json`、`rules.md`、`files.json`、`greptile.json`（含 strictness、ignorePatterns） | `[8]`（一手，日期不明） |
| Qodo（PR-Agent） | PR 發布或每次 push 自動；Per commit 觸發 | 未在該頁細列 | 該頁未載；第三方價格互相矛盾（未確認） | `.pr_agent.toml`；Review Standards、Rule Miner、severity 門檻、ignore | `[9]`（一手，日期不明；價格二手未確認） |
| Gemini Code Assist | PR 開啟時依設定自動跑 | 程式碼審查、摘要 | 該頁未載（未確認） | `.gemini/config.yaml`、`styleguide.md`；`comment_severity_threshold` 預設 MEDIUM；`ignore_patterns`；`max_review_comments` | `[10]`（一手，日期不明） |
| GitLab Duo Code Review Flow | 指派或 `@GitLabDuo`；新 MR 自動；push 可再審 | diff 加 repo context 預掃描，inline 留言 | $0.25／review（2026-03-19 官方 blog） | `mr-review-instructions.yaml`；`.gitlab/duo/mr-review-automated-rules.yaml` 排除分支與作者 | `[11]`（一手，2026-03-19、2026-10-05） |

### 2. 工具設計的四大共通演進

第一，預設嚴格降噪。廠商將減少誤報視為產品核心。Claude Code Review 預設只檢查 correctness，透過多 agent 並行找問題、驗證步驟過濾誤報，再去重排序 `[2]`。OpenAI Codex 預設只標示 P0 與 P1 問題，官方建議團隊先寫 2 到 3 條規則，將格式與 lint 交給 CI `[4]`。Gemini Code Assist 則將 `comment_severity_threshold` 預設為 `MEDIUM`，並提供 `max_review_comments` 限制留言數量 `[10]`。

第二，調校設定檔高度趨同但讀取分支邏輯分歧。`AGENTS.md` 已成為跨工具通用標準，GitHub Copilot、CodeRabbit、OpenAI Codex 皆直接讀取 `AGENTS.md` `[1][4][6]`。工具專屬檔案則有 Claude 的 `REVIEW.md` 與 `CLAUDE.md` `[2]`、Cursor 的 `.cursor/BUGBOT.md`（單檔上限 3 萬字元、單次執行上限 10 萬字元，且 Cursor 既有的 `.mdc` 規則對 Bugbot 無效）`[5]`，以及 GitLab Duo 的 `mr-review-instructions.yaml` `[11]`。需要特別注意安全性差異：GitHub Copilot 從 PR 的 head branch 讀取指令與 skills `[1]`；Claude Code Review 則相反，只讀取 base 或 default branch 的 `REVIEW.md` `[2]`。CodeRabbit 另提供 `@coderabbitai emit path instructions` 指令，可將近 7 天的審查建議自動開 PR 寫回設定檔 `[6]`。Greptile 則規定 `.greptile/` 與 `greptile.json` 並存時以前者為準，且與儀表板規則同時生效 `[8]`。

第三，計價模式從固定人頭費（per seat）轉向按次或用量計費。GitLab Duo 定價為每次審查 $0.25 美元 flat rate（2026-03-19）`[11]`。GitHub Copilot 改採 AI credits 加計 Actions minutes（Lite 約 $0.25、Balanced 約 $1.50、Max 約 $10，費用記在自動觸發的 PR 作者或手動請求者帳上，預算用盡直接阻擋審查）`[1]`。Greptile 採 credit 制（每 credit $1 美元，依深度扣 1、3、10 credits，無 seat fee）`[8]`。Claude 託管版則消耗 token usage credits，內部自報單次成本約 15 至 25 美元（二手廠商自報，2026-03-09 起）`[2][35]`；其預設 repo 觸發條件為成本最高的 `After every push`，官方建議先以 `Once` 或 `Manual` 試點 `[2]`。目前僅 CodeRabbit（月繳 $30 至 $90／人月，且設每人每小時審查上限：Essentials 5 次、Enterprise 12 次）`[6]` 與 Graphite（年繳 $20 至 $40／人月）`[7]` 維持 per seat 為主。

第四，定位嚴守「輔助而非取代人類」。Claude 官方明言「A review never approves or blocks the pull request」，其 check run 不會判定失敗 `[2]`。GitHub Copilot 文件亦寫明「Supplement Copilot's feedback with a human review」`[1]`，且預設只在被指派時審查 1 次，未開 push 設定則重審需手動請求 `[1]`。OpenAI Codex 同樣聲明不取代 branch protection，但支援留言 `@codex fix the P1 issue` 開啟雲端 session 推送修正 `[4]`。此外，工具仍有明確的技術邊界：Claude 託管版不執行 build 與測試，且與 ZDR、HIPAA 組織不相容（本機 `/code-review` 則不限方案）`[2]`；GitLab Duo 在 2026-10-05 底層切換為 Claude Sonnet 5.5，但對超過 10,000 行的檔案僅送 diff，預掃描 context 約 1 MiB 並截斷至約 800 KiB，且不會自動回覆或 resolve 自己的討論串 `[11]`。

### 3. 四種嵌入模式歸納

1. **平台原生 reviewer**：直接在程式碼託管平台開啟，包含 GitHub Copilot、GitLab Duo、Gemini Code Assist `[1][10][11]`。優勢是權限控管與帳單直接整合；限制是無法自由切換底層模型（例如 Copilot 明文不支援切換模型）`[1]`。
2. **獨立 SaaS reviewer**：以 GitHub／GitLab App 形式安裝，自帶跨 repo 索引與規則學習，包含 CodeRabbit、Greptile、Cursor Bugbot、Graphite、Qodo、Claude 託管版 `[2][5][6][7][8][9]`。導入核心在於維護專屬規則檔與調整 severity 門檻。註：Cursor 於 2025-12-19 宣布收購 Graphite（二手報導），計畫整合兩者 AI reviewer，但整合現況未確認 `[12]`。
3. **自管 CI agent**：在 GitHub Actions 等 CI 定義 workflow，如 `claude-code-action` 與開源 PR-Agent `[3][9]`。團隊完全掌控觸發事件、`--max-turns` 與 prompt，成本為自付 Actions minutes 與 API token，但降噪責任完全由團隊自行承擔 `[3]`。
4. **隨叫與本機型（On-demand / Local）**：由開發者手動呼叫，包含本機執行 `/code-review`、`/security-review` `[2]`，或在 PR 留言 `@codex review`、`@claude review` `[2][4]`。實務上常與第 2 種模式搭配，作為推進 PR 前的自檢或針對高風險變更的二次確認。

---

## 三、人類 review 流程的主流做法

儘管 AI 工具普及，人類審查的基礎規範與平台機制在 2025 至 2026 年間不但沒有退場，反而透過 stacked PR 與 merge queue 進一步制度化。

### 1. Google Engineering Practices（基準凍結）
- **做法**：只要變更「明確提升整體 code health」即可核准，不要求完美 `[13]`。非必要的次要建議以 `Nit:` 標記為可選 `[13]`。首次回覆時限最長為 1 個工作日 `[13]`。CL（變更集）大小以約 100 行視為合理，約 1,000 行通常過大，且須一併考量檔案數，但無硬性上限 `[13]`。
- **證據**：Google 官方公開指南（一手，頁面日期不明）`[13]`。檢視其 GitHub repo commit 紀錄，該專案已於 2025-11-21 封存，最後一次實質內容更新為 2024-05-10（其後 commit 推論為網站設定變更）`[13]`。
- **適用與代價**：適用於所有規模團隊。代價是要求 reviewer 具備高度自律，且要把功能拆成約 100 行的小變更，高度依賴分支堆疊（stacking）工具支援 `[13]`。

### 2. Stacked PRs / Stacked Diffs（2026 最大基礎設施變化）
- **做法**：將大型變更拆解為一系列有序、相依的小型 PR，每一層 PR 獨立送審與測試。
- **證據**：2026 年 stacked PR 正式進入平台原生階段。根據 IT Brief UK 報導（二手，2026-07-31），GitHub 於 2026-07-30 推出原生 stacked PR 公開預覽並逐步向全 repo 開放 `[14]`（GitHub Docs 入口頁日期不明且未標明 preview 或 GA 狀態，`About stacked pull requests` 頁面則回傳 404 `[14]`）。GitHub 原生 stack 在 PR 頂端顯示 stack map，reviewer 只需看該層 diff；合併最上層時可一次合併下方所有層，若只合併下層，上層會自動 rebase 與 retarget，且既有的 required reviews 與 branch protection 照常運作 `[14]`。第三方工具方面，Graphite 以 `gt` CLI 管理 stacked branches 並附帶 merge queue（2025-12-19 被 Cursor 收購，二手報導稱產品維持獨立運作，後續路線圖未確認）`[12]`；Meta 體系的 Sapling 提供 `sl pr` 將 stack 內每個 commit 開成 PR（二手描述）`[15]`；Jujutsu 生態系則在 2026 年出現 `jj-stack`、`jjpr`、`jj-vine` 等社群工具（二手）`[15]`。
- **適用與代價**：適用於中大型團隊或複雜重構，能落實小 PR 原則並讓不同模組 reviewer 平行審查。代價是底層 PR 一旦依審查意見修改，整串上層分支都必須 rebase，不能沒有工具輔助。

### 3. Trunk-based Development + Merge Queue
- **做法**：維持短命分支（short-lived feature branches），並在合併前透過 merge queue（或 GitLab merge trains）將排隊中的 PR 組合起來跑 CI，防止兩個各自通過測試的 PR 合併後弄壞主幹。
- **證據**：Trunk Based Development 官方網站（一手，版權標示 2017-2020，AI 段落更新日期不明）強調「等待 review 的時間必須算進分支壽命」，分支只應存活幾天 `[19]`。GitHub merge queue（一手，日期不明）在 base branch 保護規則啟用 `Require merge queue`（分支規則名稱不可含 `*`），將每組 PR 放進 `gh-readonly-queue/...` 臨時分支驗證，失敗即移出佇列，並行 build 數可設 1 至 100，支援 merge、rebase、squash；關鍵限制是 GitHub Actions workflow 必須同時監聽 `merge_group` 事件，否則 required check 永遠不會回報 `[16]`。GitLab merge trains（一手，日期不明，限 Premium／Ultimate 方案）需啟用 merged results pipelines，讓每個 MR 與排在前面的所有 MR 組合測試，預設並行 20 條 pipeline，可設 Allow bypass 或 Enforce `[17]`。獨立廠商 Mergify（一手 changelog）則在 2026-06-02 支援依變更目錄自動分組（auto-group）`[18]`，並於 2026-08-12 支援將 GitHub 原生 stacked PR 排入佇列依序合併（目標分支 ruleset 的 bypass mode 須設為 `Exempt`）`[18]`。
- **適用與代價**：高頻率合併的中大型 repo 必備。代價是 CI 成本隨測試組合增加，且設定漏掉 `merge_group` 會直接卡死合併流程 `[16]`。

### 4. 平台層政策（Rulesets、CODEOWNERS、Approval Rules）
- **做法**：在平台層以宣告式規則強制執行人類審查門檻與所有權指派。
- **證據**：GitHub Rulesets（一手，日期不明，限 Team／Enterprise）支援多組規則同時套用，無優先順序而是直接取最嚴格條件，具 Active／Disabled 狀態且有讀取權限者即可檢視，正逐步取代舊版單一 branch protection `[21]`。GitHub `CODEOWNERS`（一手，日期不明）採「最後一個匹配規則優先」，勾選 `Require review from Code Owners` 後任一 owner 核准即滿足條件；但有三個實務陷阱：檔案超過 3 MB 會整個失效、不存在或無 write 權限的 owner 會被系統靜默忽略、未列 owner 的路徑任何具 write 權限者皆可核准 `[20]`。GitLab approval rules（一手，日期不明，限 Premium／Ultimate）支援專案預設、單一 MR 覆寫、全站規則與 approval policies；預設禁止作者核准自己的 MR，但預設允許 committer 核准 `[22]`。
- **適用與代價**：適用於需確保關鍵路徑（如 `auth/`、基礎設施）有人類把關的團隊與受管制企業。代價是 `CODEOWNERS` 維護不當會因超過 3 MB 或權限變動而無預警失效 `[20]`。

### 5. 審查深度分級、留言規範與結對審查
- **做法**：依變更風險決定是否需要等待審查（Ship／Show／Ask），並在留言時使用結構化標籤區分阻塞性問題與一般討論（Conventional Comments、LOGAF），或以即時結對取代非同步 PR。
- **證據**：Ship／Show／Ask 由 Rouan Wilsenach 於 2021-09-08 提出（一手，非新近趨勢）：Ship 直接進主幹、Show 開 PR 但立即合併、Ask 開 PR 等待回饋 `[23]`。Conventional Comments（一手，© 2025 Paul Slaughter，無版本號）定義 `<label> [decorations]: <subject>` 語法，label 含 `praise`、`nitpick`、`suggestion`、`issue`、`todo`、`question`、`thought`、`chore`、`note`，decoration 含 `(blocking)`、`(non-blocking)`、`(if-minor)` `[24]`。Sentry 工程準則（一手，日期不明）則採用 LOGAF 標籤區分輕重，其中 `h`（high）代表合併前必改，並規定每次要求修改通常會造成 24 小時以上的延誤 `[50]`。即時審查方面，Learn Agile Practices（二手，2025-05-06）將 trunk-based 審查分為 pair/mob、短命 PR（分支小於 1 天、數小時內審完）與 post-commit review 三種 `[26]`；Crisp 團隊部落格（二手，2025-06-02）則記錄結合 AI 的 mob programming 實踐 `[26]`。至於業界常提的「兩段式 review（author self-review 後再交 peer）」與「reviewer 自動輪替／負載平衡」，本次素材均未找到一手文件（未確認）。
- **適用與代價**：結構化留言能大幅降低非同步溝通摩擦，且零工具成本。結對審查適合關鍵邏輯與新人 onboarding，但代價是成員必須同時在場，且缺乏系統性比較研究 `[26]`。

---

## 四、AI 生成程式碼之後，review 發生了什麼變化

當開發者普遍使用 AI coding agent 產生程式碼，軟體工程的產出結構與審查壓力出現了劇烈位移。

### 1. 量化證據表

以下整理素材中關於 AI 導入後對產出、審查時間與品質影響的實證數據。

| 來源 | 日期 | 樣本規模 | 關鍵數字與結論 | 證據屬性 | 出處 |
|---|---|---|---|---|---|
| Faros AI Productivity Paradox | 2025-07-23（資料至 2025-06） | 1,255 團隊、逾 10,000 開發者 | 高 AI 採用團隊：合併 PR +98%、PR 大小 +154%、review 時間 +91%、每人 bug +9%、完成任務 +21% | 一手（廠商遙測） | `[27]` |
| Faros AI Engineering Report 2026 | 2026-04-12 | 22,000 開發者、逾 4,000 團隊、2 年遙測 | 首次 review 中位數 +156.6%、review 中位時間 +441.5%、未經任何 review 就合併的 PR +31.3%、每人 bug +54% | 一手（廠商遙測） | `[28]` |
| DORA 2025（Google Cloud blog） | 2025-09-24 | 近 5,000 受訪者、逾 100 小時質性資料 | 90% 使用 AI，30% 對 AI 程式碼幾乎不信任；AI 採用與吞吐量轉為正相關，但與交付穩定性仍呈負相關 | 一手（完整 PDF 未讀） | `[29]` |
| Harvard 工作論文（Chen & Stratton） | 2026 年（日期未確認） | 約 700 家公司（Jellyfish 客戶資料） | 程式碼行數 +30%、PR 數 +23%，但完成的工作無顯著增加；PR 提交到合併從 7.03 天增至 10.48 天（+49%）；AI 留言僅占所有 review 留言 23.3% | 二手（未讀原文、未經同行審查） | `[30]` |
| LinearB 2026 Benchmarks | 2025-12 發布 | 810 萬+ PR、4,800 團隊 | Agentic AI PR 的 pickup time 是人工 PR 的 5.3 倍；AI 輔助 PR 的 review 時間為 3.2 小時對人工 4.2 小時；AI PR 的 30 天合併率僅 32.7%（人工為 84.4%） | 二手（搜尋摘要，未讀 PDF） | `[31]` |
| METR RCT 與後續更新 | 2025-07-10／2026-02-24 | 初版 16 人、246 issue；更新 57 人、143 repo、800+ 任務 | 2025 初版：用 AI 慢 19%（事前預期快 24%、事後自認快 20%）。2026-02 更新：轉向小幅加速但信賴區間含 0，自稱因選擇偏誤不可靠 | 初版一手；更新為二手摘要 | `[32]` |
| Google ML 建議編輯研究 | 2023-05-23／2024 | Google 內部每年數百萬則留言 | 離線 52% 留言可處理（目標精確度 50%），預覽建議 40–50% 被採用；ICSE 2024 報告作者以 ML 處理約 5% 留言（新版約 7.5%） | 2023 一手；2024 二手議程頁 | `[33]` |
| Google 新程式碼 AI 占比 | 2026-04（Cloud Next） | Sundar Pichai 發言 | 新程式碼 75% 由 AI 產生並經工程師核准（2024 年為 25%）；官方措辭從 reviewed 改為 approved | 二手 | `[34]` |
| Anthropic Code Review 內部數據 | 2026-03-09 起 | Anthropic 內部 | 有實質 review 留言的 PR 從 16% 升至 54%；誤報率低於 1%；單次 review 成本約 15–25 美元 | 二手（廠商自報，未對照官方頁） | `[35]` |
| GitClear 程式碼品質報告 | 2025-02 | 2.11 億行變更（2020–2024） | 2024 年複製貼上量首次超過重構；5 行以上重複區塊成長 8 倍；moved code 從 24.8% 降至 9.5% | 二手（廠商報告） | `[36]` |
| OpenAI 內部 Codex 數據 | 2025 DevDay | OpenAI 內部 | 「幾乎每個 PR」都經 Codex review；工程師每週多完成 70% PR | 二手 | `[37]` |

從上述證據可歸納出三個硬事實。第一，個人產出膨脹直接塞爆下游審查隊列：Faros 兩份報告、Harvard 工作論文與 LinearB 數據一致顯示 PR 數量與行數上升，但等待審查與合併的時間大幅惡化 `[27][28][30][31]`；更有甚者，Faros 2026 觀察到「未經任何 review 就直接合併的 PR」增加了 31.3%，每人 bug 數上升 54% `[28]`。第二，AI 生成的 PR 品質與可接受度明顯偏低，LinearB 2026 數據（二手搜尋摘要）指出 Agentic AI PR 等待被拾起審查（pickup time）的時間是人工 PR 的 5.3 倍，且 30 天內成功合併的比例僅 32.7%，遠低於人工 PR 的 84.4% `[31]`。第三，程式碼結構趨向重複與肥胖，GitClear（二手，2025-02）統計 2.11 億行變更發現 5 行以上重複區塊暴增 8 倍，代表重構行為的 moved code 比例從 24.8% 跌至 9.5% `[36]`。DORA 2025（一手）則將「吞吐量轉正、交付穩定性仍受損」歸因於變更量增加卻缺乏配套控制系統（原文未直接討論 code review）`[29]`。

### 2. 開源專案與平台政策

面對大量湧入的 AI 貢獻（包含低品質 AI slop），開源社群與託管平台在 2025 至 2026 年迅速確立了治理邊界。根據 2026-09-07 發布的 arXiv 論文（一手，統計 281 份開源政策），83.3% 的專案允許或鼓勵使用 AI，僅 14.9% 禁止；但高達 48.8% 要求強制揭露、67.3% 要求高度人工參與、43.4% 明訂人類負最終責任，而違反政策最常見的處置是直接關閉 PR（48.4%），另有 13.8% 採取關閉 PR、封鎖使用者或禁止全自主 agent `[45]`。

| 專案／平台 | 政策核心規定 | 生效／更新日期 | 證據屬性 | 來源 |
|---|---|---|---|---|
| Linux kernel | AI 不可簽署 `Signed-off-by`；人類提交者必須審完所有 AI 程式碼並負全責，授權須相容 GPL-2.0-only | 2025 年起（RFC 2025-07，頁面日期不明） | 一手 | `[38]` |
| QEMU | 拒絕「相信包含或衍生自 AI 生成內容」的貢獻，理由為版權與 DCO 無法誠實聲明 | 2025-06（master 現仍為禁止；2026-05 放寬提案未確認） | 一手（提案為二手） | `[39]` |
| NetBSD | LLM 生成程式碼視為「tainted（受污染）」，禁止 commit（另一處稱需 core team 核准，見第八節） | 2024-05 | 二手 | `[40]` |
| Gentoo | Council 決議禁止包含 AI 生成內容的貢獻 | 2024-04 | 二手 | `[40]` |
| Ghostty | 所有 AI 使用須在 PR 揭露且由人驗證邏輯；首次貢獻者須經 vouch（擔保）才能開 PR | 約 2025-08 起 | 二手（鏡像與二手報導） | `[41]` |
| curl | 結束 HackerOne bug bounty 計畫，消除提交 AI slop 假漏洞的金錢誘因 | 2026-01-21（2026-01 底） | 二手 | `[42]` |
| EFF | 訂有 LLM 輔助貢獻政策（具體內容未讀取，未確認） | 2026-02 | 未確認 | `[43]` |
| GitHub Copilot code review | 可提交正式 Approve，但預設關閉，須由管理員逐層授權並可限定路徑；僅有評估不算數，推新 commit 後核准即失效 | 2026-09-01（公開預覽） | 一手 | `[44]` |
| GitHub Copilot cloud agent | 官方文件要求人類在合併前必須徹底審查 Copilot 開出的 PR | 日期未確認 | 一手 | `[44]` |

### 3. 六種新興 review 模式與風險

1. **AI 先審、人後審（AI as first-pass）**：由 AI 先掃描 diff 抓語法、漏條件與潛在 bug，人類專注於架構與業務邏輯。Anthropic Code Review、OpenAI Codex、GitHub Copilot 皆主推此模式 `[1][2][4]`。Anthropic 自報內部有實質留言的 PR 比例從 16% 提升至 54%（二手）`[35]`；Harvard 論文（二手，日期未確認）則指出截至 2026-03 約 80% 公司採用某種 AI review，但 AI 僅占整體 review 留言的 23.3% `[30]`。風險在於 AI 不執行建置與測試，Anthropic 文件亦明言「無發現不代表沒問題」`[2]`。
2. **審 spec 與測試，而非逐行審 diff**：先撰寫規格（如 `SPEC.md`），開新 session 實作後，交由 subagent 對照 spec 與邊界測試進行審查。此做法由 Anthropic Claude Code best practices 與 JetBrains Research（2026-10，僅讀搜尋摘要，原文 403）倡議。Anthropic 文件特別提醒對照 spec 審查時必須加上 `skip style` 指示，否則 reviewer 必定會挑出一堆瑣碎風格問題。核心風險是若 spec 本身寫錯，整條驗證鏈就會跟著偏離，且目前缺乏對照實驗數據。
3. **獨立 reviewer（寫與審分離）**：使用從未看過實作對話脈絡的 fresh subagent 或獨立 session 執行審查（如 Claude `/code-review` 的設計）`[2]`。理由是避免審查者被生成程式碼時的推理過程帶偏。風險是當 prompt 要求 agent「找出問題」時，模型傾向硬挑毛病，容易引發過度修正。此模式目前僅有設計理念，無量化對照實驗。
4. **人類 in-the-loop 門檻（可程式化核准權限）**：平台開放 AI 在受限路徑下給出 Approve（如 GitHub 2026-09-01 公開預覽的 Copilot approve 功能，預設關閉且推新 commit 即失效）`[44]`，但主幹合併仍強制要求人類 approval。風險是一旦團隊為求快而放寬 AI 核准範圍，等同將品質責任外包，直接加劇 Faros 2026 所揭露「無審查合併 PR 增加 31.3%」的失控現象 `[28]`。
5. **貢獻入口控管（輸入端治理）**：在進入 code review 前先攔截低品質來源。例如 Ghostty（約 2025-08 起，二手）要求新貢獻者必須先獲得社群成員 vouch 才能開 PR `[41]`，curl（2026-01 底，二手）直接取消漏洞獎金 `[42]`，以及 48.4% 開源專案直接關閉違規 PR `[45]`。代價是大幅拉高新進正常貢獻者的參與門檻。
6. **Reviewer 疲勞與 rubber-stamp（橡皮圖章）風險**：Stack Overflow（2026-05，二手）指出替自己沒寫過的 AI 程式碼除錯比以前更困難 `[46]`；Sonar 2026 調查（二手引用）顯示 96% 開發者不完全信任 AI 程式碼，卻只有 48% 在提交前一定會驗證 `[46]`；連 Google 宣稱 75% 新程式碼由 AI 生成時（2026-04，二手），措辭也從 2024 年的「reviewed」改為「approved by engineers」`[34]`。不過，目前業界尚無直接量測 rubber-stamp 比例的一手研究，仍屬推論與軼事。

---

## 五、端到端工作流樣板

綜合各階段工具與企業實踐，2026 年的端到端工作流可拆解為「本機自審 → CI 自動審 → 平台 gate → 人類審查」四道關卡。

### 1. 端到端階段與機制表

| 階段 | 可用機制 | 代表工具 | 證據屬性 | 來源 |
|---|---|---|---|---|
| 本機自審 | commit 前手動執行安全與差異審查 | Claude Code `/security-review` | 二手摘要（日期不明） | `[47]` |
| 本機自審 | `pre-commit` 放快速檢查，AI review 放 `pre-push` 或手動（預設 warn 不 block） | lefthook、husky、`codex exec` | 二手社群文章（2026-04-27） | `[48]` |
| 本機自審 | `PreToolUse` hook 攔截代理偷加 `--no-verify` 跳過檢查 | Claude Code hooks | 二手社群 skill（日期不明） | `[48]` |
| CI 自動審 | 宣告式 `warn`／`fail` 規則（如 PR 逾 600 行警告、缺測試失敗） | Danger | 一手官方文件（日期不明） | `[49]` |
| CI 自動審 | 將 linter 輸出過濾至 diff 行範圍，轉為 PR 行內留言或 check | reviewdog | 一手官方文件（日期不明） | `[49]` |
| CI 自動審 | 多代理平行找 bug、驗證過濾誤報，只留言不核准 | Claude Code Review、Cloudflare 自建管線 | 一手（2026-03-09、2026-04-20） | `[35][51]` |
| 平台 gate | required status checks 加 merge queue（CI 必訂閱 `merge_group`） | GitHub merge queue | 一手官方文件（日期不明） | `[16]` |
| 平台 gate | merge train 對前方所有排隊變更做組合測試，失敗即移出 | GitLab merge trains | 一手官方文件（日期不明） | `[17]` |
| 人類審查 | 指派 1–3 位 reviewer，以 LOGAF 或 Conventional Comments 分級回饋 | Sentry 工程準則、Conventional Comments | 一手（日期不明、© 2025） | `[24][50]` |

註：SAST 工具（如 Semgrep、CodeQL）的行內註解與是否可設為 required check，因本次抓取之 GitHub code scanning 頁面未載明，標為「未確認」。

### 2. 三種團隊端到端工作流樣板

#### 樣板 A：小團隊 Trunk-based 工作流（10 人內、高信任）
1. **風險分流**：依 Ship／Show／Ask 分級 `[23]`。例行小修正走 Ship 或 Show，架構與核心邏輯走 Ask `[23]`。分支壽命控制在 1 到 2 天內 `[19]`。
2. **本機防線**：用 lefthook 在 `pre-commit` 跑 lint 與 typecheck，並用 Claude Code `PreToolUse` hook 擋掉 `--no-verify`（二手）`[48]`；推送前手動跑 `/security-review` 或 `codex exec` 自審（二手）`[47][48]`。
3. **輕量 CI 審查**：開 PR 後觸發輕量 AI review（如 GitHub Action 跑 `claude-code-action` 或設定只標 P0/P1 的 Codex），僅留行內意見、不擋合併 `[3][4]`。
4. **快速人審與合併**：指派 1 位人類 reviewer，留言採用 Conventional Comments 或 LOGAF 標明是否為 blocking `[24][50]`。首次回覆以 Google 建議的 1 個工作日為上限（或直接結對審查）`[13][26]`，通過 required checks 後開啟 auto-merge，若合併後主幹失敗則立即 rollback。

#### 樣板 B：中大型團隊 Stacked PR + Merge Queue 工作流
1. **功能拆分與本機自檢**：作者利用 GitHub 原生 stack（二手，2026-07-30 預覽）或 Graphite `gt` CLI 將大功能拆成單一職責的 stacked PR `[12][14]`，並在 `pre-push` 完成自審 `[48]`。
2. **CI 規則與風險分級 AI 審**：PR 開出後，Danger 先檢查 PR 行數與測試覆蓋 `[49]`，reviewdog 將 linter 結果貼入 diff 行 `[49]`；接著依變更行數、檔案數與敏感目錄（如 `auth/`、`crypto/`）決定 AI 審查深度，跳過 lock 檔與生成檔 `[6][51]`。
3. **平行人審與所有權把關**：透過 GitHub Rulesets 與 `CODEOWNERS`（注意檔案須小於 3 MB）自動將不同層 PR 分派給對應領域 owner 平行審查 `[20][21]`。
4. **佇列驗證與逃生口**：人類核准後進入 GitHub merge queue（搭配 Mergify 處理 stacked PR 佇列，且 CI 必須監聽 `merge_group` 事件）或 GitLab merge train `[16][17][18]`。管線同時保留緊急人工放行指令（如留言 `break glass`）並寫入遙測紀錄 `[51]`。

#### 樣板 C：開源專案與受管制企業工作流
1. **開源專案（輸入治理＋權限降級）**：在入口處以 Ghostty 式的 vouch 制度或 AI 揭露範本過濾低品質 PR `[41][45]`，並如 Linux kernel 要求人類提交者簽署 `Signed-off-by` 負全責 `[38]`。因外部 fork PR 的 CI token 無寫入權限，reviewdog 需降級為 GitHub annotations 顯示結果 `[49]`。維護者以 LOGAF 標籤審核，並嚴控 bot 留言頻率，避免如第三方研究（Archgate 對 Sentry 的研究，二手）所指出的 bot 過量留言造成貢獻摩擦。
2. **受管制企業（強制分權）**：依 `trunkbaseddevelopment.com` 建議保留具名人類核准的 PR `[19]`，透過 GitHub Rulesets 或 GitLab approval policies 強制要求外部獨立人類核准者，並將 merge queue／merge trains 設為 `Enforce` 不可繞過 `[17][21][22]`。

### 3. 真實公司案例拆解

- **Cloudflare（一手，2026-04-20 發布，統計 2026-03-10 至 2026-04-09）**`[51]`：於 GitLab CI component 建立自動化審查。MR 開啟後，系統依行數、檔案數及是否觸碰 `auth/` 或 `crypto/` 分為 `trivial`、`lite`、`full` 3 級；先濾除 lock 檔與生成檔（但保留 migration 檔），再派出最多 7 個專家 agent（涵蓋資安、效能、品質、文件等）平行審查，最後由 coordinator 去重並發出一則結構化留言。結論分為 4 態，僅在發現 `significant concerns` 時送出 request changes；後續新 commit 只做增量重審。若遇誤報或緊急修復，人類可留言 `break glass` 強制放行並記錄於 telemetry。在 1 個月內於 5,169 個 repo、48,095 個 MR 執行了 131,246 次審查，中位數耗時 3 分 39 秒，平均每次成本 1.19 美元，`break glass` 觸發率僅 0.6%（文中聲明不取代人審，但未明寫人類核准是否為 merge 系統強制要求）`[51]`。
- **Microsoft（一手自報，2025-07-14）**`[52]`：開 PR 時自動將 AI 加為 reviewer，直接沿用既有 PR thread 留言並標註類別，產生 PR 摘要供人類 reviewer 在討論串追問，且允許各 repo 自訂準則與 prompt。AI 提出程式碼修正時，必須由作者親自點擊 `apply change` 才會套用。該系統涵蓋內部超過 90% 的 PR、每月處理逾 60 萬個 PR；在 5,000 個 repo 的早期實驗與資料科學研究中，自報 PR 完成時間中位數縮短 10% 至 20% `[52]`。
- **Anthropic（一手 blog 2026-03-09／二手 InfoQ 2026-04）**`[35]`：管理員安裝 GitHub App 後，開 PR 即由多個 agent 平行搜尋 bug，經獨立驗證步驟濾除誤報、按嚴重度排序後，貼出一則總覽留言與行內留言，最終核准權留給人類。其自報內部「有實質 review 留言的 PR」由 16% 升至 54%，誤報率低於 1%，單次成本約 15 至 25 美元 `[35]`。
- **Sentry（一手工程準則，日期不明）**`[50]`：作者開 PR 時 `@mention` 團隊並指定 1 至 3 位 reviewer（可先開 WIP 等 CI 綠燈）；程式風格與覆蓋率全交自動化；人類回饋強制使用 LOGAF 標籤（`h` 為必改），涉及 schema、API、新框架等長期變更須知會資深工程師 `[50]`。
- **Shopify（二手，Graphite 客戶案例頁，日期不明）**`[53]`：使用 Graphite virtual queue 依 repo 的 zone 分區處理合併，廠商頁面宣稱將 merge 等待時間由數小時降至數分鐘，每年節省 27,000 工時（屬廠商行銷數字，查無 Shopify 自家技術文章驗證）`[53]`。至於 Stripe 與 Vercel 的內部流程，本次素材查無一手文章（未確認）。

---

## 六、指標與 benchmark

評估 code review 效率與品質時，不同平台與工程效能廠商的定義與分級門檻存在顯著落差，不可混為一談。

### 1. 核心指標與廠商 Benchmark 對照表

| 指標名稱 | 定義 | Benchmark 分級與數值 | 出處與樣本 | 日期與屬性 |
|---|---|---|---|---|
| Pickup time（2026 版） | PR 開出到首次 review 開始 | Elite < 1 小時、Good 1–4 小時、Fair 5–16 小時 | LinearB 2026（810 萬 PR、4,800 團隊）`[31]` | 2026，一手網頁 |
| Pickup time（2025 版） | PR 開出到首次 review 開始 | Elite < 75 分鐘、Good 75 分鐘–5 小時 | LinearB 2025（610 萬 PR、3,000 團隊）`[31]` | 2025，二手摘要 |
| Review time | 首次 review 到獲得核准 | Elite < 3 小時、Good 3–14 小時 | LinearB 2026 `[31]` | 2026，一手網頁 |
| Cycle time | 整體變更週期 | Elite < 25 小時、Good 25–72 小時 | LinearB 2026 `[31]` | 2026，一手網頁 |
| PR size | 單一 PR 變更行數 | Elite < 100 行、Good 100–155 行 | LinearB 2026 `[31]` | 2026，一手網頁 |
| Rework rate | 重工修改比例 | Elite < 3%、Good 3–5% | LinearB 2026 `[31]` | 2026，一手網頁 |
| PR cycle time | 開出 PR 到完成合併 | Great < 24 小時、Good < 5 天 | Swarmia `[54]` | 日期不明，一手 |
| Time to first human review | 要求審查到首次人類審查（排除 bot） | Great 4 小時內、Good 24 小時內（表內有矛盾，見下述） | Swarmia `[54]` | 日期不明，一手 |
| Batch size | 單一 PR 變更行數 | Great < 200 行、Good < 500 行 | Swarmia `[54]` | 日期不明，一手 |
| Median PR size | 活躍開發者之 PR 行數中位數 | 整體 47 行；經多次 review 的 PR 為 94 行 | Graphite `[55]` | 日期不明，一手 |
| Median time to merge | PR 發布到完成合併中位數 | 全部 PR 3.5 小時；活躍開發者 9 小時（頁內有矛盾） | Graphite `[55]` | 資料自 2023-01 起，一手 |
| First response SLA / 小 CL | 首次回覆上限與合理行數 | 最長 1 個工作日內回覆；約 100 行合理、約 1,000 行太大 | Google Engineering Practices `[13]` | 日期不明（2025-11 封存），一手 |
| 最佳審查效率區間 | 審查效果達高點之行數與時間 | 200–400 行、60 分鐘達高點；另份研究稱 <50 行與 >1,000 行首次回覆中位數差約 9 倍 | SmartBear（2,500 PR）／廠商自述（2,189 PR）`[25]` | 日期不明，二手摘要 |
| Diffs per engineer | 每位工程師每週合併 PR 數 | 具體數值未取得 | DX Core 4 `[56]` | 日期不明，一手（缺數值） |

註：Jellyfish 的主打指標與具體 benchmark 數值於本次素材中未查到 `[56]`。

### 2. 跨來源數字矛盾與使用注意事項

1. **PR 大小門檻各說各話**：Google 與 LinearB 2026（Elite）皆將標準定在約 100 行內 `[13][31]`；Swarmia 的 Great 放寬到 200 行內、Good 500 行內 `[54]`；SmartBear（二手，2,500 個 PR）稱 200 至 400 行效果最佳 `[25]`；Graphite 則報告其平台活躍開發者中位數僅 47 行（多次 review 者 94 行），明顯受其主打 stacked PR 的用戶群特性影響 `[55]`。
2. **首次回覆時間定義與分級不一**：Swarmia 明確在指標定義中「排除 bot 留言」，規定人類首次審查 Great 為 4 小時內、Good 為 24 小時內（與 Google 的 1 個工作日一致）`[13][54]`；但其官方表格出現自相矛盾，將 `Needs attention` 欄位也寫成「小於 24 小時」，與 Good 區間重疊 `[54]`。LinearB 則不論是否為 bot，且 2025 版（Elite < 75 分鐘）與 2026 版（Elite < 1 小時）分級標準已改變，不可跨年直接比較 `[31]`。另有廠商 Augment Code（二手）宣稱「1h／4h／24h」分級源於 DORA，但查無 DORA 一手出處 `[25]`。
3. **Graphite 合併時間頁內自相矛盾**：在 Graphite 的 `Median time to merge` 報告中，針對「僅計算有 review 的 PR」之合併時間中位數，頁面摘要寫 6 小時，內文卻寫 10 小時，且未交代資料集大小與發布日期 `[55]`。

---

## 七、對本團隊與 review plugin 的啟示

基於上述證據，我們在設計團隊內部審查流程與開發 Claude Code 審查 plugin 時，應立即落實以下 5 項可執行決策：

1. **Plugin 預設必須「極度降噪、只抓 P0/P1 correctness 與安全問題，且絕不自動檢查 coding style」**
   - **依據**：Claude Code Review 預設只看 correctness（內部自報誤報率低於 1%）`[2][35]`、OpenAI Codex 預設只標 P0/P1 `[4]`、Gemini 預設門檻為 MEDIUM `[10]`，且 Anthropic 在對照 spec 審查的最佳實踐中明言必須加上 `skip style` 否則模型一定會挑出一堆小毛病。我們應將格式與 lint 完全交給本機 lefthook 與 CI 的 reviewdog `[48][49]`，讓 plugin 專注於語義錯誤、邊界條件與安全漏洞。
2. **實作「寫與審分離（Fresh Subagent）」加「二階段驗證去重」架構**
   - **依據**：Anthropic 的 `/code-review` 採用沒看過開發對話的獨立 subagent 以避免推理偏誤 `[2]`，而其託管版與 Cloudflare 管線（最多 7 個專家 agent 加 coordinator 去重）皆透過「平行找問題 → 驗證步驟濾除誤報 → 嚴重度排序發單一結構化留言」將實質留言率拉升至 54% 並維持低噪音 `[2][35][51]`。我們的 plugin 應拆分為平行專家 subagents（如邏輯、資安、migration）加一個負責驗證與去重的 coordinator subagent。
3. **導入 Cloudflare 式的「變更風險三級分流」以控制成本與延遲**
   - **依據**：Claude 託管版單次成本高達 15 至 25 美元（二手自報）且預設 `After every push` 成本最高 `[2][35]`；反觀 Cloudflare 在 CI 先濾掉 lock 檔與生成檔，再依行數、檔案數與是否觸碰 `auth/`、`crypto/` 分為 `trivial`、`lite`、`full` 3 級，將 131,246 次審查的平均成本壓在 1.19 美元、中位耗時 3 分 39 秒 `[51]`。Plugin 應內建前置過濾器與分級路由，小變更只跑輕量單一 pass，觸及敏感目錄才啟動多代理深度審查。
4. **設定檔讀取雙軌支援 `REVIEW.md` 與 `AGENTS.md`，且安全規則強制從 base branch 讀取**
   - **依據**：業界設定檔已向 `AGENTS.md`（Copilot、Codex、CodeRabbit 共用）與 `REVIEW.md`／`CLAUDE.md` 收斂 `[1][2][4][6]`；但 Copilot 從 head branch 讀規則存在被 PR 提交者篡改審查標準的風險，Claude 則規定只從 base 或 default branch 讀取 `REVIEW.md` `[1][2]`。Plugin 在 CI 執行時應強制讀取 base branch 的審查規則，並支援輸出 Conventional Comments 或 LOGAF 格式標籤 `[24][50]`。
5. **團隊流程綁定「本機 Pre-push 自審 ＋ Stacked PR ＋ Merge Queue」，並設立人工 `break glass` 逃生口**
   - **依據**：Faros 2026 與 LinearB 2026 證明把未整理的龐大 AI PR 直接丟給人類，會導致 review 中位時間暴增 441.5% `[28]`、AI PR 的 30 天合併率僅 32.7% `[31]`。團隊應規定：第一，本機配置 `PreToolUse` hook 禁止 `--no-verify`，並在 `pre-push` 跑 plugin 自審 `[48]`；第二，利用 GitHub 原生 stacked PR 將變更拆至 100 至 200 行內 `[13][14][31][54]`；第三，啟用 GitHub merge queue 並確認所有 Actions workflow 訂閱 `merge_group` 事件 `[16]`；第四，AI 審查永遠不自動 approve，人類保留最終核准與留言 `break glass` 強制放行（記錄於遙測）的權限 `[2][51]`。

---

## 八、未確認與互相矛盾的事項

為確保決策嚴謹，以下誠實列出四份研究素材中標記為「未確認」、僅有二手來源或彼此矛盾的項目：

1. **工具價格與功能未確認項**：
   - **OpenAI Codex 與 Gemini Code Assist 計價**：官方文件頁面均未記載價格（未確認）`[4][10]`；Gemini 是否仍支援 `/gemini review` 指令亦未確認 `[10]`。
   - **Cursor Bugbot 計價**：官方 help 頁面未列價；二手搜尋摘要一處稱 $40／月（上限 200 個 PR），另一處稱每 PR 約 $1.25，兩者均未確認 `[5]`。
   - **Qodo（PR-Agent）計價與治理**：官方頁未列價格與 slash command，第三方二手價格互相矛盾；PR-Agent 改由社群組織維護、Qodo 轉為贊助者一事僅出自二手來源（未確認）`[9]`。
   - **Graphite 現況與收購影響**：官方定價頁未說明觸發方式與覆蓋範圍，亦未出現 Diamond 或 Graphite Agent 字樣（改名一事未確認）`[7]`；2025-12-19 被 Cursor 收購後的產品整合路線圖均屬二手報導與未確認狀態 `[12]`。
   - **GitHub Copilot 計價舊資料衝突**：官方現已改為 AI credits 加 Actions minutes，部分二手文章仍寫 premium requests（應為舊資料）`[1]`。
   - **Claude Code `/security-review` 與 `/simplify`**：`/security-review` 僅讀到 `support.claude.com` 二手摘要而未取得 docs 本文 `[2][47]`；素材四未找到 `/code-review` 與 `/simplify` 對應文件 `[47]`。此外，Claude Code Review 的 check run「永不失敗」在一處為官方文件說明 `[2]`，在素材四則標為二手摘要。
2. **平台與工作流機制未確認項**：
   - **GitHub 原生 Stacked PR 細節**：官方 `About stacked pull requests` 頁面回傳 404，入口頁未標明 preview／GA；公開預覽日期（2026-07-30）、行為細節與 merge queue「逐步支援中」主要依賴二手報導 `[14]`，其方案限制與 Jujutsu（`jj`）相容性文件皆未在 GitHub Docs 確認 `[14][15]`。
   - **SAST 整合與人類審查慣例**：Semgrep、CodeQL 在 GitHub code scanning 的 inline 註解與是否可設為 required check 未確認；「兩段式 review（self-review → peer）」與「reviewer 輪替／負載平衡」均未找到一手文件（未確認）。
   - **企業內部案例缺口**：Stripe（含二手指南稱 Stripe Minions 每週合併逾 1,000 個 PR）、Vercel、Meta 內部 AI review 現況、Python 專案政策，以及 Anthropic「How Anthropic teams use Claude Code」與「65% 產品工程 PR 由系統處理」皆查無一手來源（未確認）。
3. **數據與研究報告矛盾項**：
   - **Faros PR 大小增幅矛盾**：Faros 2025 報告寫高 AI 採用團隊 PR 大小 `+154%` `[27]`，但其另一頁 FAQ 寫 `+51.3%`，2026 報告摘要又寫 `+51%`，統計口徑未對齊 `[28]`。
   - **METR 研究後續狀態矛盾**：有二手來源稱 METR 後續研究被擱置，與 2026-02-24 實際發布的更新矛盾；且更新版細節僅有搜尋摘要 `[32]`。
   - **LinearB 與 Harvard 報告讀取限制**：Harvard 工作論文（Chen & Stratton）僅讀到二手報導，樣本數與確切發布日期未確認 `[30]`；LinearB 2025 與 2026 PDF 報告未直接讀取，且 Agentic PR 指標在二手摘要中出現 `5.3x` 與 `4.6x` 兩種不同口徑，Worklytics 轉述的「Elite cycle time 小於 2.5 天」亦未驗證 `[31]`。
   - **DORA 報告限制**：DORA 2025 完整 PDF 未讀（七種團隊類型僅見二手），且官方 blog 未直接討論 code review `[29]`；「DORA 2026 可能不出新報告」僅見單一搜尋結果，未驗證。
   - **開源政策細節分歧**：Linux kernel 現行文件頁面未見搜尋結果所稱的 `Assisted-by` 標籤 `[38]`；QEMU 2026-05 放寬提案是否合併未確認 `[39]`；NetBSD 一處二手來源說全面禁止，另一處說需 core team 核准 `[40]`；curl「2026-07 停止讀報告」無第二來源，且真實有效報告比例出現「約 1/6」與「低於 5%」兩種矛盾數字 `[42]`。
   - **OpenAI 與 Anthropic 內部數據**：Anthropic 的 `16% → 54%` 與 GA 日期（2026-10-15）僅見於二手報導且屬廠商自報 `[35]`；OpenAI 內部經 Codex 審查比例在二手來源中出現「幾乎每個 PR」與「100%」兩種不同措辭 `[37]`。

---

## 參考來源

- `[1]` GitHub Docs: Copilot code review (`https://docs.github.com/en/copilot/concepts/agents/code-review`) — 日期不明，一手。
- `[2]` Anthropic Claude Code Docs: Code Review & Costs (`https://code.claude.com/docs/en/code-review.md`、`code-review-costs.md`) — 日期不明，一手（註：本機指令可客製為二手來源說明）。
- `[3]` Anthropic Claude Code Docs: GitHub Actions (`https://code.claude.com/docs/en/github-actions`) — 日期不明，一手。
- `[4]` OpenAI ChatGPT Learn Docs: GitHub / Codex (`https://learn.chatgpt.com/docs/third-party/github`) — 日期不明，一手（計價未載，未確認）。
- `[5]` Cursor Help: Bugbot (`https://cursor.com/help/ai-features/bugbot`) — 日期不明，一手（價格官方未列，二手搜尋摘要稱 $40／月上限 200 PR 或每 PR 約 $1.25，未確認）。
- `[6]` CodeRabbit Pricing & Review Instructions (`https://coderabbit.ai/pricing`、`https://docs.coderabbit.ai/guides/review-instructions`) — 日期不明，一手。
- `[7]` Graphite Pricing (`https://graphite.com/pricing`) — 頁尾標示 2026，一手（觸發與覆蓋範圍未確認）。
- `[8]` Greptile Pricing & Custom Context Docs (`https://greptile.com/pricing`、`docs/code-review-bot/custom-context`) — 日期不明，一手。
- `[9]` Qodo (PR-Agent) Code Review Docs (`https://docs.qodo.ai/code-review`) — 日期不明，一手（價格與社群維護現況為二手且互相矛盾，未確認）。
- `[10]` Google Cloud Docs: Gemini Code Assist Customize Repo Review (`https://docs.cloud.google.com/gemini/docs/code-review/customize-repo-review`) — 日期不明，一手（計價未載，未確認）。
- `[11]` GitLab Docs (Duo Code Review Flow, 2026-10-05) & GitLab Official Blog (`https://about.gitlab.com/blog/agentic-code-reviews-with-flat-rate-pricing`, 2026-03-19) — 一手。
- `[12]` SiliconANGLE / TechCrunch / DevOps.com: Cursor 收購 Graphite 報導 (`https://siliconangle.com/2025/12/19/cursor-acquires-ai-code-review-startup-graphite/`、`https://techcrunch.com/2025/12/19/cursor-continues-acquisition-spree-with-graphite-deal`) — 2025-12-19，二手。
- `[13]` Google Engineering Practices Documentation (`https://google.github.io/eng-practices/review/reviewer/standard.html`、`/speed.html`、`/developer/small-cls.html`) 及 GitHub commits (`https://github.com/google/eng-practices/commits/master`) — 頁面日期不明，repo 於 2025-11-21 封存、最後內容更新 2024-05-10，一手。
- `[14]` IT Brief UK: GitHub puts stacked pull requests into public preview (`https://itbrief.co.uk/story/github-puts-stacked-pull-requests-into-public-preview`, 2026-07-31，二手) 與 GitHub Docs (`https://docs.github.com/en/pull-requests/how-tos/stacked-pull-requests`, 日期不明，一手入口頁，About 頁 404)。
- `[15]` Jujutsu 社群工具 `jj-stack` (`https://www.serpentine.com/posts/2026/announcing-jj-stack/`, 2026，二手) 及 Sapling `sl pr`、`jjpr`、`jj-vine` 第三方描述（日期不明，二手）。
- `[16]` GitHub Docs: Managing a merge queue (`https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue`) 及 Troubleshooting required status checks (`https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks`) — 日期不明，一手。
- `[17]` GitLab Docs: Merge trains (`https://docs.gitlab.com/ci/pipelines/merge_trains/`) — 日期不明，一手。
- `[18]` Mergify Changelog: Auto-group queued PRs (`https://docs.mergify.com/changelog/2026-06-02-auto-group-queued-pull-requests-by-changed-files/`, 2026-06-02) 與 Merge GitHub stacked PRs (`https://docs.mergify.com/changelog/2026-08-12-merge-github-stacked-pull-requests-with-the-merge-queue/`, 2026-08-12) — 一手。
- `[19]` Trunk Based Development: Short-Lived Feature Branches (`https://trunkbaseddevelopment.com/short-lived-feature-branches/`) — 版權標示 2017-2020（AI 段落更新日期不明），一手。
- `[20]` GitHub Docs: About code owners (`https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners`) — 日期不明，一手。
- `[21]` GitHub Docs: About rulesets (`https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets`) — 日期不明，一手。
- `[22]` GitLab Docs: Approval rules (`https://docs.gitlab.com/ee/user/project/merge_requests/approvals/rules.html`) — 日期不明，一手。
- `[23]` Rouan Wilsenach: Ship / Show / Ask (`https://martinfowler.com/articles/ship-show-ask.html`) — 2021-09-08，一手。
- `[24]` Paul Slaughter: Conventional Comments (`https://conventionalcomments.org/`) — © 2025（無版本號，日期不明），一手。
- `[25]` 速度與 PR 行數二手研究摘要：Augment Code（宣稱源於 DORA，查無一手出處）、SmartBear（2,500 PR）、廠商自述分析（2,189 PR）— 日期不明，二手（僅讀搜尋摘要）。
- `[26]` Learn Agile Practices (`https://learnagilepractices.substack.com/p/code-review-approaches-for-trunk`, 2025-05-06) 與 Crisp Blog (`https://blog.crisp.se/2025/06/02/michaelgothe/mob-programming-with-ai-inside-a-high-performing-teams-journey`, 2025-06-02) — 二手。
- `[27]` Faros AI Productivity Paradox Report 2025 (`https://www.faros.ai/blog/ai-productivity-paradox-report-2025`) — 2025-07-23（資料至 2025-06），一手（廠商）。
- `[28]` Faros AI Engineering Report 2026 (`https://faros.ai/blog/ai-acceleration-whiplash-takeaways`) — 2026-04-12，一手（廠商）。
- `[29]` Google Cloud Blog: Announcing the 2025 DORA Report (`https://cloud.google.com/blog/products/ai-machine-learning/announcing-the-2025-dora-report`) — 2025-09-24，一手（完整 PDF 未讀）。
- `[30]` ComplexDiscovery: Harvard 工作論文報導（Chen & Stratton，Jellyfish 資料）(`https://complexdiscovery.com/harvard-researchers-find-ai-coding-agents-shifted-the-bottleneck-to-code-review/`) — 2026 年（日期未確認），二手（未讀原文，未經同行審查）。
- `[31]` LinearB Engineering Benchmarks (`https://linearb.io/engineering-benchmarks/`, 2026，一手網頁) 及 LinearB 2026／2025 Benchmark Report PDF (`https://assets.linearb.io/image/upload/v1765300694/resources/LinearB_2026_Software_Engineering_Benchmarks_Report.pdf`、`https://assets.linearb.io/image/upload/v1731970015/resources/LinearB_2025_Benchmark_Report.pdf`，2025-12 發布／2025，二手搜尋摘要，未直接讀 PDF)。
- `[32]` METR Study (`https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/`) — 2025-07-10 為一手；2026-02-24 更新細節為二手搜尋摘要。
- `[33]` Google Research Blog: Resolving code review comments with ML (`https://research.google/blog/resolving-code-review-comments-with-ml/`, 2023-05-23，一手) 與 ICSE 2024 Talk (`https://conf.researchr.org/details/icse-2024/icse-2024-software-engineering-in-practice/35/Resolving-Code-Review-Comments-with-Machine-Learning`, 2024，二手議程頁)。
- `[34]` TechSpot: Google AI generates 75% of new code (`https://www.techspot.com/news/112152-google-ai-now-generates-75-new-code-up.html`) — 2026-04，二手。
- `[35]` Anthropic Blog: Code Review (`https://claude.com/blog/code-review`, 2026-03-09，一手) 與 InfoQ 報導 (`https://www.infoq.com/news/2026/04/claude-code-review/`, 2026-04，二手廠商自報)。
- `[36]` I Programmer: GitClear code quality report (`https://www.i-programmer.info/news/105-artificial-intelligence/17871-gitclear-reveals-ais-negative-impact-on-code-quality.html`) — 2025-02（資料 2020–2024），二手（廠商）。
- `[37]` Analytics India Magazine: OpenAI DevDay Codex (`https://analyticsindiamag.com/ai-news-updates/almost-all-new-code-written-at-openai-today-is-from-codex-users/`) — 2025 DevDay，二手。
- `[38]` Linux Kernel Docs: Coding Assistants (`https://docs.kernel.org/process/coding-assistants.html`) — 2025 年起（RFC 2025-07，頁面日期不明），一手。
- `[39]` QEMU Docs: Code Provenance (`https://www.qemu.org/docs/master/devel/code-provenance.html`) — 2025-06，一手（2026-05 放寬提案來自 Phoronix 二手報導，未確認）。
- `[40]` Linuxiac: NetBSD AI policy (`https://linuxiac.com/netbsd-new-policy-prohibits-usage-of-ai-code/`, 2024-05，二手) 與 Tom's Hardware: Gentoo bans AI code (`https://www.tomshardware.com/software/linux/linux-distros-ban-tainted-ai-generated-code`, 2024-04，二手)。
- `[41]` Ghostty `AI_POLICY.md` (`https://github.com/ghostty-org/ghostty`) — 約 2025-08 起，二手（僅讀鏡像與二手報導）。
- `[42]` The Register: curl ends bug bounty (`https://www.theregister.com/2026/01/21/curl_ends_bug_bounty/`) — 2026-01-21，二手。
- `[43]` EFF Policy on LLM-Assisted Contributions (`https://www.eff.org/deeplinks/2026/02/effs-policy-llm-assisted-contributions-our-open-source-projects`) — 2026-02，未確認（內容未讀）。
- `[44]` GitHub Blog Changelog: Copilot code review can now approve pull requests (`https://github.blog/changelog/2026-09-01-copilot-code-review-can-now-approve-pull-requests`, 2026-09-01，一手) 與 GitHub Docs: Review Copilot PRs (`https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/review-copilot-prs`, 日期未確認，一手)。
- `[45]` arXiv 論文: 開源專案 AI 貢獻政策統計 (`https://arxiv.org/html/2609.07542`) — 2026-09-07，一手。
- `[46]` 新興審查風險二手來源：JetBrains Research（2026-10，僅搜尋摘要，原文 403）、Stack Overflow（2026-05，二手）、Sonar 2026 調查（二手引用）。
- `[47]` Anthropic Support: Automated security reviews in Claude Code (`https://support.claude.com/en/articles/11932705-automated-security-reviews-in-claude-code`) — 日期不明，二手摘要。
- `[48]` Daniel Vaughan: Codex CLI Git Hooks (`https://codex.danielvaughan.com/2026/04/27/codex-cli-git-hooks-pre-commit-review-commit-msg-pre-push-validation/`, 2026-04-27，二手) 與 HackerNoon: Block no-verify hook (`https://hackernoon.com/skills/wshobson-block-no-verify-hook`, 日期不明，二手)。
- `[49]` Danger.js Docs (`https://danger.systems/js/`, 日期不明，一手) 與 reviewdog GitHub (`https://github.com/reviewdog/reviewdog`, 日期不明，一手)。
- `[50]` Sentry Engineering Practices: Code Review (`https://develop.sentry.dev/engineering-practices/code-review/`) — 日期不明，一手（Archgate 對 Sentry 的研究為二手）。
- `[51]` Cloudflare Blog: AI Code Review (`https://blog.cloudflare.com/ai-code-review/`) — 2026-04-20（資料期間 2026-03-10 至 2026-04-09），一手。
- `[52]` Microsoft DevBlogs: Enhancing code quality at scale with AI-powered code reviews (`https://devblogs.microsoft.com/engineering-at-microsoft/enhancing-code-quality-at-scale-with-ai-powered-code-reviews/`) — 2025-07-14，一手（自報）。
- `[53]` Graphite Customer Story: Shopify (`https://graphite.com/customer/shopify`) — 日期不明，二手（廠商行銷頁）。
- `[54]` Swarmia Help: Benchmarks and comparisons (`https://help.swarmia.com/guides/benchmarks-and-comparisons`) — 日期不明，一手。
- `[55]` Graphite Research: Median PR size (`https://graphite.com/research/median-pr_size`, 日期不明，一手) 與 Median time to merge PRs (`https://graphite.com/research/median-time-to-merge-prs`, 資料自 2023-01 起，發布日期不明，一手)。
- `[56]` DX Core 4 Benchmarks (`https://getdx.com/research/benchmarks/`) — 日期不明，一手（具體數值未取得）。

