# BDD 落地研究：從 GWT 驗收標準到可執行規格

> 本檔是同一份研究素材的另一寫作版本（writing-ab 盲測，兩版並存）。正式版見 `2026-11-09-bdd-adoption.md`。

## Context

本團隊的 user story 已經用 Given-When-Then（GWT）寫驗收標準（AC），但這些 AC 通常沒有經過跨角色的例子對話，也沒有接到會失敗的測試。這份研究整理 BDD 的正統流程、TS／Python／E2E 的工具現況、AI coding agent 帶來的新變數，以及導入失敗的常見原因。資料來自 Cucumber 官方文件、GitHub／npm／PyPI 發版紀錄、論文與社群文章，查證日為 2026-11-09，每條主張都標了一手或二手。適用情境是 PM 加工程師、沒有專職 QA 的小團隊，結論也作為把 spec-writing 產出的 AC 接到可執行測試的 plugin 設計依據。

---

## 一、全景摘要

- 只寫 GWT AC，等於只做到 Formulation 的輸入端，真正缺的是前面的 Discovery 對話與後面的 Automation 綁定[^1]。
- 工具選型已經收斂：NestJS 後端用 @cucumber/cucumber，Python 用 pytest-bdd，E2E 要 Gherkin 只能靠第三方 playwright-bdd，因為 Playwright 官方已明確不做 BDD[^2]。
- LLM 能產出可用的 Gherkin，但品質由輸入決定：只給 user story 時人工評分 3.16 到 3.37，加上需求描述可達 4.17 到 4.63（滿分 5）[^3]。
- agent 時代最大的風險是自己出題自己答：SpecBench 中 Claude Code 可見測試幾乎滿分，隱藏測試卻落差約 43 到 48 點[^4]。
- 導入最常見的死法是工具先行，輕量路線是先做 Example Mapping、只把高價值或高風險的 AC 變 executable，但這條選擇準則只有廠商與顧問層級的依據[^5][^6]。

## 二、BDD 的正統流程，以及 GWT 驗收標準離「可執行」還差什麼

### 2.1 三個階段

Cucumber 官方把 BDD 分成三個階段[^1]。一手來源對順序的主張一致：對話比記錄重要，記錄比自動化重要[^1][^7]。

| 階段 | 回答的問題 | 活動 | 參與者 | 產出 |
|---|---|---|---|---|
| Discovery | 它可以做什麼 | 針對真實例子的結構化對話，例如 Example Mapping | 參與想像與交付的人，至少 PO、開發、測試[^8] | 對規則與範圍的共識、缺口、可延後項目 |
| Formulation | 它應該做什麼 | 把例子寫成人機皆可讀的 Gherkin | 初期全隊；之後開發或自動化負責人與測試配對，PO 須主動審閱[^9] | 可執行規格、共用詞彙 |
| Automation | 它實際做什麼 | 每個例子接到系統，先紅後綠，必要時搭配較低層測試 | 官方頁未明指角色（未確認）[^1] | 自動化測試、活文件、回歸保護 |

Dan North 在 2006 年的〈Introducing BDD〉自述，當時團隊的問題是不知道測什麼、不測什麼[^10]。North 的做法是把測試名稱寫成句子，把 AC 寫成 Given（情境）、When（事件）、Then（結果），再讓這些片段直接對映程式碼執行[^10]。GWT 由 North 與 Chris Matts 發展（Fowler bliki，二手轉述）[^11]。Cucumber 創辦人 Aslak Hellesøy 認為 BDD 與 TDD 都是開發工作流，差別在 BDD 更強調技術與業務的協作（二手訪談，日期不明）[^12]。分層上，官方的 Automation 階段是先寫失敗的驗收層例子，再用單元測試實作[^1]。也就是 BDD 管功能層，TDD 管函式層。

Discovery 最輕量的工具是 Example Mapping。黃卡寫 story，藍卡寫規則（就是 AC），綠卡寫例子，紅卡寫未解問題，一次只處理一張 story[^13]。Matt Wynne 原文的時間盒約 25 分鐘，結束時用 thumb-vote 判斷能不能開發[^13]。現行官方 docs 寫 25 到 30 分鐘、3 到 6 人，並建議在開發前不久才辦[^8]。卡片分布本身就是訊號：紅卡多代表要學的多，藍卡多代表要切 story，單一規則下例子多代表規則太複雜[^13]。代價也很明確：每張 story 要排 25 分鐘以上的跨角色會議，而且 PO 必須到場[^13]。

### 2.2 Gherkin 寫作規範與反模式

一手規範比想像中薄。官方〈Writing better Gherkin〉全頁只有兩節：描述行為而非實作，以及宜用宣告式[^14]。其餘建議散在 Gherkin Reference 頁與 2016 年的反模式文章。

| 規範 | 具體做法 | 來源與強度 |
|---|---|---|
| 描述行為，不描述實作 | 判斷法：實作改了，這句措辭要不要跟著改 | 一手[^14] |
| 宣告式優先 | 寫「Free Frieda 有免費訂閱」，不寫一串 UI 操作 | 一手[^14] |
| Given／When／Then 分工 | Given 設定已知狀態、避免使用者互動；When 描述動作、不含 UI；Then 是可觀察結果，不驗資料庫內部 | 一手[^15] |
| 長度 | 例子約 3 到 5 步 | 一手[^15]；「少於 6 步、可確定、能失敗」僅見搜尋摘要[^16] |
| Background | 約 4 行內，只放重複且非關鍵的 Given；一個 Feature 或 Rule 只能有一個 | 一手[^15] |
| Rule 與 Scenario Outline | Rule（Gherkin 6 起）一個對應一條業務規則；Outline 對每列 Examples 執行一次，濫用會變慢、場景暴增 | Rule 一手[^15]；濫用說法未讀原文[^17] |

常聽到的「一個 scenario 只能有一個 When」不是官方硬規則，Reference 頁沒有寫明[^15]。

Theo England 2016 年在 Cucumber 部落格列出六個反模式[^18]：程式寫完才寫場景、PO 獨自寫場景、多餘細節、一個場景驗多條規則、場景命名差或缺、無意義的「As a user」敘述。文章較舊，但前兩項正是「AC 先行」團隊最容易踩到的。

### 2.3 從 GWT AC 到 executable scenario 的差距

一手來源裡沒有專門談「AC 怎麼補成可執行」的指南。下表是由官方頁面推得的差距，推論處已標註。

| 差距 | 典型 AC 的樣子 | 要補什麼 | 依據 |
|---|---|---|---|
| 來源 | PO 一人寫完 | 改由 Discovery 對話產生 | PO 獨寫是反模式[^18] |
| 規則與例子混寫 | 一條抽象規則 | 藍卡規則配綠卡例子，一個例子只說明一條規則 | [^13] |
| 沒有具體資料 | 「User A」、沒有數值 | 有名字的角色；數值與邊界值在 Discovery 補（推論） | [^15] |
| Given 不完整 | 省略前置資料 | Given 要能把系統放進已知狀態 | [^15] |
| Then 無法失敗 | 結果模糊或驗內部資料 | 可觀察、能失敗的結果 | [^15][^16] |
| 夾帶 UI 步驟 | 「點選按鈕、輸入欄位」 | 改宣告式，細節收進 step definition | [^14] |
| 一條 AC 多條規則 | 一段 GWT 驗好幾件事 | 拆成多個 scenario | [^18] |
| 沒有綁定 | AC 本身不會執行 | 寫 step definition，先紅後綠 | [^1] |
| 缺邊界與錯誤情境 | 只有 happy path | 由測試角色在 Discovery 補（官方未列清單，推論） | [^9] |

九項差距裡，只有「沒有綁定」是工具問題。其餘八項都要靠對話與改寫解決。

## 三、工具鏈：依技術棧的選擇

### 3.1 工具現況

| 工具 | 語言 | 最新版本與日期 | 維護狀態 | 關鍵限制 |
|---|---|---|---|---|
| @cucumber/cucumber | TS/JS | 13.3.0，2026-10-05[^19] | 活躍 | 獨立 runner，不共用 Jest／Vitest 的 fixtures 與 mock；TS 需自行 transpile |
| playwright-bdd | TS | 9.2.1，2026-09-06[^20] | 活躍，支援最新 Playwright 加前 10 版 | 第三方、非官方；多一道 generate 步驟 |
| @amiceli/vitest-cucumber | TS | 8.0.0，2026-09-05[^21] | 活躍 | 需 Vitest ≥2.0.0；CLI 只產 TS 骨架 |
| jest-cucumber | TS/JS | 4.5.0，2024-07-25[^22] | 停滯（依發版日推論） | 步驟預設需與 feature 逐字對齊 |
| pytest-bdd | Python | 9.0.1，2026-10-31[^23] | 活躍，需 Python ≥3.10 | 一個 feature 檔只能有一個 Feature；async 支援未確認 |
| behave | Python | 1.3.3，2025-09-04[^24] | 活躍（最近 commit 2026-11-02，為依賴更新） | 獨立 runner，沒有 pytest fixtures |
| Reqnroll | .NET | 3.3.4，2026-03-23[^25] | 活躍 | SpecFlow fork；無 LivingDoc 直接替代 |
| Cucumber-JVM | Java | 8.0.4，2026-10-02[^26] | 活躍 | 可疊加 Serenity |
| Allure Report | 多語言 | allure-js 3.14.0，2026-10-19[^27] | 活躍 | 屬報告層，不產 feature 文件站 |
| Serenity BDD | JVM | GitHub latest 標籤 4.0.1，2024-01-10，可能非最新[^28] | 未確認 | 完整 feature 文件只支援 Cucumber |

兩件事直接影響選型。第一，Playwright 官方已經關門。issue #11975 在 2026-04-28 由維護者 Pavel Feldman 關閉，原話是「We are not going to be implementing BDD and will prioritize agentic application for test generation and execution」[^2]。第二，工具真的會死。SpecFlow 由 Tricentis 宣告停止，2024-12-31 EOL，2025-01-01 GitHub 專案被刪（時間線以二手來源為主）[^29]。社群 fork Reqnroll 接手，但非開源的 SpecFlow+ LivingDoc 沒有直接替代品[^25]。

living documentation 方面，最成熟的是 JVM 的 Serenity BDD，而且只有搭 Cucumber 才有完整 feature 文件[^28]。TS 與 Python 多半用 Cucumber 的 html／message 報告加 Allure，兩者都是測試報告，不是文件站[^19][^27]。cucumber-js 的 json formatter 已進入 maintenance mode，官方建議改用 message[^19]。

### 3.2 依技術棧的建議

- **TS＋NestJS 後端**：首選 @cucumber/cucumber，步驟內用 @nestjs/testing 建 app，再用 supertest 打 HTTP[^19]。理由是官方維護，message 是標準格式。代價是自成 runner，NestJS app 要自己組。若團隊已全面 Vitest，可評估 @amiceli/vitest-cucumber，換得共用 runner，代價是由個人維護者主導[^21]。NestJS 文件頁摘要寫新專案預設用 Vitest[^30]。若屬實，vitest-cucumber 的吸引力會上升（推論，落地前要核對）。不建議新用 jest-cucumber，最新版已 16 個月沒有更新[^22]。
- **Python**：pytest-bdd。步驟走 pytest 依賴注入，given 可用 target_fixture，tag 會轉成 pytest marker，與既有 fixtures、CI 完全共用[^23]。官方 docs 沒提 async，相關 PR 合併狀態未確認。大量 async 步驟時，先在目標版本做 PoC[^23]。behave 只在已有既存資產時留用[^24]。
- **E2E（Playwright）**：要 Gherkin 就選 playwright-bdd。它把 .feature 轉成原生 Playwright 測試，保留 trace、並行與 sharding[^20]。風險是官方不會接手，且相依單一第三方維護[^2]。不要 Gherkin，就直接寫 Playwright 原生測試，這是官方路線。

### 3.3 Gherkin 以外的替代做法

| 做法 | 代表工具 | 適合情境 | 代價 |
|---|---|---|---|
| 測試框架內寫 GWT 結構的 helper 與註解 | Jest／Vitest／pytest 加自訂 helper；jest-given（現況未查證） | 純工程師讀寫，不需非技術人員審閱 | 無 feature 檔，不能當溝通文件，沒有步驟重用的約束 |
| describe／it 命名成情境句 | Vitest／Jest、pytest 類別命名 | 成本最低，單元與整合測試 | 同上，報告看不出規格 |
| 規格檔式 | Gauge | 要規格檔但不要 Gherkin 語法 | 官方贊助 2021 年結束，核心團隊僅 spare time 維護[^31] |
| 關鍵字驅動 | Robot Framework 7.5.1，2026-11-02[^32] | QA 主導、跨系統自動化（含 RPA） | 自成 DSL；GWT 支援未確認 |
| Gherkin 轉原生測試 | playwright-bdd、vitest-cucumber | 要 feature 檔又要主流 runner | 多一層生成與對齊維護 |

前兩種做法的代價是失去溝通文件。團隊內沒人讀 feature file 時，這是合理選擇（廠商建議，二手）[^33]。

## 四、AI coding agent 時代的 BDD

### 4.1 spec-driven 工具與 BDD

| 工具 | spec 格式 | 可執行？ | 與 Gherkin 的關係 |
|---|---|---|---|
| GitHub spec-kit | spec.md 的 user story（P1/P2/P3）下列 GWT Acceptance Scenarios 與「Independent Test」欄位[^34] | 否，測試由後續步驟產生 | 借用 GWT，模板未提 Gherkin |
| AWS Kiro | requirements.md、design.md、tasks.md 三檔[^35] | 否；另有 property-based testing 的 Correctness 功能（細節未確認） | 官方 docs 稱 EARS；Böckeler 文章稱 GWT（矛盾） |
| Claude Code | interview 後寫 SPEC.md，新 session 實作，subagent 對照審查[^36] | 否；done 靠測試、typecheck、Stop hook、CI | 未規定格式 |
| OpenAI（Sean Grove） | 主張瓶頸移到寫 spec，spec 應持久保存（二手摘要）[^37] | 未確認 | 未確認 |
| 社群 plugin（beat、claude-bdd、bdd-workflow） | 先寫 .feature 再 TDD[^38] | 是（Cucumber／pytest-bdd） | 直接用 Gherkin |

Böckeler 實測三個工具，把 SDD 分成 spec-first、spec-anchored、spec-as-source 三級，所見全是 spec-first[^39]。在這篇評測裡，Kiro 的 GWT 驗收標準被視為最像 BDD 的部分[^39]。但 Kiro 官方 docs 寫的是 EARS（WHEN…THE SYSTEM SHALL…）[^35]。兩者矛盾，可能是產品版本不同，無法判定。

結論是 SDD 的 spec 不取代 Automation 階段。spec-kit 的 GWT 和 Claude Code 的 SPEC.md 都是給 agent 讀的自然語言，還要再轉成測試[^34][^36]。只有社群 plugin 直接以 Gherkin 為源頭[^38]。Cucumber／SmartBear 官方的 AI 生成 Gherkin 功能沒有查到，只有一則 2026-10-20 的 BearQ 標題，內容未確認[^40]。

### 4.2 LLM 生成 scenario 的證據

| 研究 | 日期 | 樣本 | 主要數字 | 注意事項 |
|---|---|---|---|---|
| AutoUAT（GPT-4 Turbo） | 2025-04-09 | 合作公司真實專案，筆數未載明 | scenario 95% 被評有幫助；測試 60% 直接可用、8% 小修、24% 補資訊重生、8% 丟棄[^41] | 「有幫助」是使用者主觀評價 |
| RMIT／IntelligenceBank | 2026-03-05 | 500 則 story；6 位資深 QA 評 600 個 scenario | Claude 3 為 4.06、GPT-4 為 3.79、Gemini 為 3.39；story 加描述 4.17 到 4.63，只給 story 3.16 到 3.37[^3] | 只評 happy path；2024 年舊模型 |
| Epic-Organized 對 per-requirement | 2026-07-02 | 4 份 SRS、107 條需求、4 位評審 | correctness 4.61 對 4.14；負面情境覆蓋 67.0% 對 81.2%，baseline 較好[^42] | Fleiss' κ 約 0；單次執行 |
| AToMIC（BMW MyBMW App） | 2025-10-21 | 13 個真實 issue、170+ 畫面 | Gherkin 語法正確 93.3%；Page Object 免修可跑 78.8%；每 feature 5 分鐘內[^43] | 模型未具名；受訪人數未載明 |

四份研究可以讀出三件事。

- **輸入決定輸出。** RMIT 研究中只給 story 的分數最低[^3]。餵給 agent 的不能只有 story 卡，要連規則與例子一起給。
- **邊界情境是弱點。** RMIT 只評 happy path[^3]。Epic 分組做法的負面情境覆蓋只有 67.0%，輸給 baseline[^42]。邊界與錯誤情境仍要人在 Discovery 補。
- **自動指標不可信。** RMIT 發現自動文字指標與人工評分相關性弱[^3]。Epic 研究的評審一致性 Fleiss' κ 約 0[^42]。scenario 品質目前只能靠人讀。

另外，沒有任何研究量測 scenario 的長期維護成本。研究用的模型多為 GPT-4、Claude 3、gpt-4o-mini，與現行 coding agent 有世代差距，外推要保守[^3][^42]。

### 4.3 三種 agent 工作流與人把關的位置

| 工作流 | 流程 | 人把關的位置 | 代表 |
|---|---|---|---|
| A. 先寫 scenario | AC 或 interview 產 Gherkin 草稿；agent 寫 step definition 先確認紅燈；實作到綠燈；獨立 agent 驗證 scenario 與測試一一對應 | 審 .feature（業務規則、邊界、幻覺 domain 詞）；審 PR，看 .feature 與測試有沒有被改 | beat、claude-bdd[^38] |
| B. SPEC.md 流程 | interview 寫 SPEC.md；開新 session 實作並指定可跑的檢查；subagent 對照 SPEC.md 審 diff，要求 skip style | 確認 SPEC.md；讀 agent 貼出的指令與輸出 | Claude Code best practices[^36] |
| C. 兩階段管線 | story 加需求描述產 Gherkin；再結合 HTML 或程式碼變更產 Cypress／Flutter 測試 | 審或抽審 scenario；看測試結果決定重生或棄用 | AutoUAT、AToMIC[^41][^43] |

A 最貼近 BDD。B 最容易接上現有的 Claude Code 習慣，只要把 GWT AC 放進 SPEC.md，再要求轉成測試。C 偏向 UI 測試量產，用 JSON schema 約束輸出可提高結構有效性[^42]。另有 levi9 的部落格示範用 Claude Sonnet 把測試步驟轉成 Gherkin、再由 Playwright 執行，但沒有數字（二手）[^44]。

防作弊的現況很薄。beat 的 README 沒有硬鎖，只靠 `@covered-by` 標籤加 lint 與獨立驗證 agent[^38]。developertoolkit 的範例只是在 prompt 裡寫「Do NOT edit cart.feature」[^45]。要硬性禁止 agent 改 .feature，得另設 Claude Code 的 permission 或 hook，具體寫法未查證。

### 4.4 風險與反模式

- **自己出題自己答。** SpecBench 用 30 個系統級任務測試，frontier agent 幾乎滿分通過可見測試，Claude Code 的隱藏測試落差約 43 到 48 點[^4]。程式碼量每增加 10 倍，落差約多 27 到 28 點[^4]。極端個案是可見測試 97%、隱藏測試 0%[^4]。對策是保留一組 agent 看不到的 held-out 驗收。
- **改測試與硬編碼。** ImpossibleBench 顯示 GPT-5 在 conflicting 變體的作弊率 66% 到 93%，Anthropic 模型的主要手法是直接改測試檔（二手轉述）[^46]。加上「測試有問題就停」的選項後，GPT-5 從 54% 降到 9%，Claude Opus 4.1 卻幾乎不用這個選項，仍有 46%[^46]。EvilGenie 發現題目越模糊越容易硬編碼，Codex 44.4%、Claude 33.3%，但樣本只有 n=9[^47]。這直接連回 Discovery：AC 越模糊，agent 越傾向取巧。
- **幻覺 step。** agent 會產生沒有對應定義的 undefined step（二手）[^48]。Gherkin 也容易寫得好讀，內容卻滑向實作細節（二手）[^49]。
- **Gherkin 淪為中介格式。** Böckeler 實測 spec-kit 產出大量重複 markdown，原話是「I'd rather review code than all these markdown files」[^39]。Tessl 對同一份 spec 多次生成，結果不同[^39]。Adzic 與 Daniel Terhorst-North 在 GOTO 訪談中表示，one-shot spec-to-product 不可行，應走緊密的迭代回饋[^50]。訪談也主張規則要寫成 CI 自動 lint，不能只放在 markdown 指令裡[^50]。

## 五、導入怎麼不失敗

### 5.1 失敗模式

| 模式 | 徵兆 | 原因 | 解法 | 來源 |
|---|---|---|---|---|
| Gherkin 當自動化腳本 | 一個 scenario 十幾步，滿是 UI 操作與參數 | 把 feature file 當 Selenium 腳本的外衣 | 只寫行為，細節下沉到 step definition；一個 scenario 一個結果 | [^18]；[^51]（二手） |
| 事後補 scenario | 程式寫完才寫 feature file | 失去檢驗共同理解的功能，只剩測試 | 開發前由全隊定案 | [^52] |
| PO 缺席或獨寫 | PO 獨寫，開發為了自動化改寫，與原意脫節，PO 不再讀 | Discovery 被指派給單人 | 協作式 Discovery 與 Gherkin 撰寫 | [^18][^52]；[^51]（二手） |
| scenario 爆量、step 重複 | 數百 scenario 對應數百到上千個 step method | step 綁在單一 feature，沒有 domain 分類 | 依 domain 概念整理 step；不寫連接詞式 step；step 不互叫 | [^53]；[^54]（二手，無實測數字） |
| 共享狀態導致 flaky | 失敗難定位，一步壞整個 scenario 作廢 | 全域 World／`this` 共享可變狀態 | step 保持無狀態，抽出 domain 層 | [^54][^51]（皆二手） |
| 全走 UI | 只能放在測試金字塔頂端 | scenario 只能經由完整介面執行 | scenario 先於實作，才有機會往下層測 | [^17]（全文未確認） |
| 只導入工具 | 框架普及，協作沒跟上 | 「產品黏、流程不黏」 | 重建 Discovery 儀式，補 facilitation 能力 | [^5] |

最常見的死法是工具先行：用了 Cucumber，就當作在做 BDD[^5]。Pawar 觀察到利害關係人到 sprint 2 之後就不再讀 feature file（二手意見）[^51]。

事後補 scenario 算不算 BDD，來源有分歧。Cucumber 官方說事後自動化是合理的測試做法，但不是 BDD[^52]。Knight 則認為把協作與自動化切開是矯枉過正，兩者要並重[^5]。兩種說法都承認事後補 scenario 有測試價值，差別在算不算 BDD。

### 5.2 真實案例：數量很少

公開、可驗證的團隊案例只找到兩個，兩個都沒有量化結果[^55][^54]。2022 到 2026 年具名公司、附團隊規模與量化結果的導入案例，沒有找到。以下案例不能當成功率證據。

- **Corrado Calzoni 的團隊（Example Mapping，2021）**[^55]：成員含開發、需求工程師、測試與 PO，用 SpecFlow，人數未給。業務專家帶 story 與初始範例，與會者追問規則、補 edge case，未決問題寫紅色便利貼，會後補功課。會後由 PO 寫 Gherkin，全隊覆核；規則太多就拆 story。結果是 story 變小、每次迭代可交付、改採 no-estimates，資淺成員更常發言。代價是整隊開會耗時，早期還因過度糾結語法浪費了好幾場。
- **Luis Inge 的大型後端 Cucumber**[^54]：多年用 Cucumber 做整合測試，累積「數百 scenario」。評估 Karate、REST-assured、Playwright 後，自建插件式 step 的 Azertio，不必自寫 step definition。作者自稱仍在早期，沒有報告量化改善，且屬自家工具推廣。
- **排除項**：Scott Logic 的 Xin Chen 只說明三階段，沒有團隊數據，屬意見文章[^56]。搜尋摘要提到的「852 scenario 的 Playwright＋Cucumber 個案」，核對後對到的是一篇無關的 flaky test 論文，不採用[^57]。

### 5.3 輕量路線與「哪些 AC 值得 executable」

輕量路線有一手依據。

- **只做 Discovery**：Example Mapping 產出的例子可以直接當 AC，不一定要接 Cucumber。Calzoni 的原話是「Example Mapping 的目標是對話，不是 test scenario」[^55]。
- **Gherkin 可以不接自動化**：Liz Keogh 2014 年寫過，有些 step 可以沒有程式碼，只用來說明「為什麼重要」[^7]。
- **GWT 不是必要格式**：多篇二手文章轉述 North「story 格式非強制」，原文未讀，未確認[^58]。另有二手摘要稱 North 強調 BDD 的本質是聚焦行為、不是 GWT 記法，原文未驗證[^59]。

哪些 AC 值得變 executable，沒有權威標準。下表前四條是綜合整理，後兩條是由一手規範與 benchmark 推得的補充。

| 準則 | 判斷問題 | 依據強度 |
|---|---|---|
| 先做 Discovery，所有 AC 保留 GWT 文字 | 這張 story 開過 Example Mapping 嗎 | 一手主張的順序[^1][^7] |
| 只挑高業務價值或高風險的 AC | 這條規則壞了會不會出事 | 廠商建議，二手[^6] |
| 先用少量 scenario 做 PoC 再擴張 | 先挑哪幾條 | 書籍預覽，二手[^60] |
| 系統要有乾淨的測試入口 | 不經 UI 能不能把系統放進 Given 的狀態 | 廠商文章，二手；沒有入口時可能一個都不能自動化[^61] |
| 規則描述的是行為（推論） | 實作改了，這條要不要跟著改 | 由一手規範推得[^14] |
| 規則已經明確（推論） | 模糊的 AC 會不會讓 agent 取巧 | 由 benchmark 推得[^47] |

### 5.4 指標與角色分工

沒有任何一手來源給出 scenario 數量、執行時間或 flaky 率的建議值。可用的只有幾條二手意見。

- living doc 報告應顯示新鮮度（commit、build、執行時間），不要只顯示 scenario 數[^62]。
- flaky 率常用「flaky 次數／總執行數」，至少 10 次執行才標記（廠商範例）[^63]。
- Pawar 批評「500 個 scenario、90% Gherkin 覆蓋」這類數字，主張改測「新人 30 秒內看懂一個 scenario」（個人意見）[^51]。

Three Amigos 每場通常不超過 30 分鐘，一場一個 story（二手）[^56]。多久開一次沒有來源，通常綁在每個 story 開工前。

誰寫 scenario，四個來源有四種說法：

| 來源 | 誰寫 | 誰審 |
|---|---|---|
| Cucumber 官方 | 初期全隊，之後開發或自動化負責人與測試配對；反對 PO 單獨寫 | PO 主動審閱[^9][^18] |
| Matt Wynne | PO 必須在場，Gherkin 由其他人事後寫 | 未說明[^13] |
| Calzoni 團隊 | PO 會後寫 | 全隊覆核[^55] |
| Scott Logic | tester 寫 | 業務覆核[^56] |

誰維護 step definition、沒有專職 QA 時怎麼分工，都沒有直接來源。讓開發或 PM 兼任「挑邊界與失敗情境」的測試角色，是推論。

## 六、對本團隊的落地路線

原則是照 Discovery、Formulation、Automation 的順序，一次往下推一層[^1]。每個階段都有可檢查的訊號，訊號不對就不往下走。

### 階段一：先補對話，不動工具

- **做什麼**：每張要開工的 story，在開發前不久跑一次 Example Mapping，時間盒 25 到 30 分鐘[^8]。把現有 GWT AC 當藍卡，逼出綠卡（具體例子）與紅卡（未解問題）[^13]。依據是差距清單九項有八項靠對話與改寫解決（見 2.3）。
- **用什麼**：卡片或白板，不導入框架。spec-writing 的 AC 產出改成「規則、例子、未解問題」三層，為下一階段的 agent 準備輸入，因為只給 story 的 LLM scenario 品質最低[^3]。會前可讓 agent 用 interview 方式補問[^36]。Example Mapping 加 LLM 沒有受控研究，所以只當會前準備，不取代會議。
- **誰把關**：PM 必須在場[^13]。沒有專職 QA，由一位工程師輪值專挑邊界與失敗情境[^9]。這個分工是推論，沒有直接來源。
- **怎麼知道做對了**：thumb-vote 通過才開工，超時或藍卡過多就切 story[^13]。Calzoni 團隊的觀察可作為對照：story 變小，每次迭代可交付[^55]。

### 階段二：挑少量高風險規則變 executable

- **做什麼**：從階段一的例子裡，只挑高業務價值或高風險的規則[^6]，先做小量 PoC[^60]。每個 scenario 只驗一條規則[^18]，寫成 3 到 5 步的宣告式[^15]，先確認紅燈再實作[^1]。
- **用什麼**：NestJS 用 @cucumber/cucumber 13.3.0，搭 @nestjs/testing 與 supertest[^19]。若確認新專案已是 Vitest，再評估 @amiceli/vitest-cucumber[^21][^30]。Python 用 pytest-bdd 9.0.1，async 步驟先實測[^23]。E2E 先不上 Gherkin，維持 Playwright 原生測試，依據是官方拒絕 BDD[^2]，且全走 UI 本身被列為反模式（僅見搜尋摘要）[^17]。agent 走工作流 A，人審過 .feature 才寫 step definition[^38]。
- **誰把關**：PM 審 .feature 的業務語意，對應 Formulation 階段 PO 須主動審閱[^9]。工程師審 step definition 與 PR，重點看 .feature 與測試有沒有被 agent 改[^38]。
- **怎麼知道做對了**：每句 Gherkin 通過「實作改了要不要跟著改」的檢驗[^14]。每個 scenario 都有先紅後綠的紀錄。過了 sprint 2，PM 仍會主動讀 .feature，因為 PO 不再讀是已知的失敗徵兆[^51]。

### 階段三：擴大範圍並加上防作弊

- **做什麼**：把 executable 範圍擴到其他高風險規則。保留一組 agent 看不到的 held-out 驗收 scenario[^4]。把 Gherkin 規範與 scenario 對應檢查寫成 CI lint，不只寫在 agent 指令裡[^50]。beat 的 `@covered-by` 標籤是可參考的對應做法[^38]。
- **用什麼**：Cucumber message 報告加 Allure，當作 living documentation 的替代品，但要記得它是測試報告，不是文件站[^19][^27]。用 Claude Code 的 permission 或 hook 禁止 agent 改 .feature。具體寫法未查證，要先驗證再上線。
- **誰把關**：工程師依 domain 概念整理 step definition，避免近似措辭長出新 step[^53]。這件事沒有一手說法，要由團隊指定負責人。PM 定期抽讀 scenario。
- **怎麼知道做對了**：報告顯示新鮮度，不只是 scenario 數[^62]。flaky 率至少以 10 次執行計算[^63]。新人 30 秒內看得懂一個 scenario[^51]。CI 裡沒有 undefined step[^48]。這些都是二手意見，只能看內部趨勢。

對 plugin 設計的含意是：spec-writing 的下一步不該是直接把 AC 轉成 .feature。更貼近證據的管線是「AC → Example Map（規則、例子、問題）→ .feature 草稿 → 人審 → step definition 紅燈 → 實作」[^3][^38]。審 .feature 與審 PR 這兩道人工關卡，要寫死在流程裡，不能讓 agent 自動略過[^38][^36]。

## 七、未確認與互相矛盾的事項

### 互相矛盾

| 主題 | 說法一 | 說法二 | 現況 |
|---|---|---|---|
| Kiro 的 spec 格式 | 官方 docs：EARS（WHEN…THE SYSTEM SHALL…）[^35] | Böckeler 2025-10 評測：GIVEN/WHEN/THEN[^39] | 可能是產品版本不同，未判定 |
| 誰寫 scenario | Cucumber 官方反對 PO 單獨寫[^18]；Wynne 主張由其他人事後寫[^13] | Calzoni 團隊由 PO 會後寫[^55]；Scott Logic 由 tester 寫[^56] | 無共識 |
| 事後自動化算不算 BDD | Cucumber 官方：不是 BDD[^52] | Knight：切開是矯枉過正，兩者並重[^5] | 並列，未裁決 |
| Example Mapping 時間盒 | 2015 部落格：約 25 分鐘[^13] | 現行 docs 討論頁：25 到 30 分鐘[^8]；Example Mapping 頁本身未寫[^64] | 差異小，來源不同 |
| 隱藏測試的防作弊效果 | ImpossibleBench：幾乎消除作弊，但降低正當表現（二手轉述）[^46] | EvilGenie：只小幅改善，LLM judge 偵測最有效[^47] | 實驗設計不同，未調和 |

### 未確認

- **方法論**：North 2023 到 2026 對 BDD 現況與 AI 的看法未確認[^10]。Farley 訪談頁面未陳述[^65]，Hatoum 的文章只是詮釋[^66]，GOTO 訪談只讀到摘要[^50]。Specification by Example 的一手章節[^67]、Automation 階段的角色、ATDD 與 BDD 的官方界定都未取得。cucumber.io/docs 頁面的原始撰寫日不明[^1]。
- **工具**：SpecFlow 時間線缺 Tricentis 原文[^29]。pytest-bdd 的 async[^23]、Serenity 的版本[^28]、cucumber-js 的 Node 與 ESM／TS 細節、Allure 對 behave 的支援、jest-given、Cucumber Reports 託管服務都未確認。jest-cucumber「停滯」是推論[^22]，NestJS 預設 Vitest 只取自摘要[^30]。Gauge 的規格格式與 Robot Framework 的 GWT 支援未確認[^31][^32]。
- **AI**：Cucumber／SmartBear 官方 AI 功能[^40]、OpenAI 的 spec 格式[^37]、Kiro Correctness 細節[^35]、Claude Code 防改測試的 hook 寫法都未確認。Example Mapping 加 LLM 沒有受控研究，scenario 維護成本與審閱耗時沒有數字。
- **導入**：指標建議值、step definition 由誰維護、無專職 QA 的分工、QA 角色轉變都沒有來源。anti-patterns part 2[^17]、Seb Rose 投影片[^16]、Docler Engineering 文章（抓取 404）與 Gáspár Nagy 的 Formulation 指引都未讀到原文。2022 到 2026 年具名公司的量化案例未找到。

## 參考來源

[^1]: Cucumber 官方文件，BDD 總覽頁，https://cucumber.io/docs/bdd/ ，頁面標示最後更新 2026-11-08，原始撰寫日不明。一手。
[^2]: GitHub microsoft/playwright issue #11975，https://github.com/microsoft/playwright/issues/11975 ，2026-04-28 由維護者 Pavel Feldman 關閉。一手。
[^3]: arXiv 2603.04729（RMIT 與 IntelligenceBank），https://arxiv.org/html/2603.04729v1 ，2026-03-05。一手論文；單一公司資料，模型為 2024 年舊版。
[^4]: SpecBench，arXiv 2605.21384，https://arxiv.org/html/2605.21384v1 ，2026-05-20，30 個系統級任務。一手論文。
[^5]: Andrew Knight，Automation Panda〈Is BDD Dying?〉，2025-03-06。一手意見，無統計。
[^6]: Aziro、Kualitatem 的廠商建議，日期未記錄。二手。
[^7]: Liz Keogh 部落格（deriving-gherkin-from-real-conversations），https://lizkeogh.com/2014/09/01/deriving-gherkin-from-real-conversations/ ，2014-09-01。一手。
[^8]: Cucumber 官方文件，Discovery workshop 頁，https://cucumber.io/docs/bdd/discovery-workshop ，最後更新 2026-11-08。一手。
[^9]: Cucumber 官方文件，Who does what 頁，https://cucumber.io/docs/bdd/who-does-what/ ，最後更新 2026-11-08。一手。
[^10]: Dan North，〈Introducing BDD〉，https://dannorth.net/blog/introducing-bdd/ ，2006-09-20（文末稱 2006-03 首刊於 Better Software）。一手。另查 dannorth.net 2023 到 2025 的文章標題清單（最新一篇 2025-02-03），沒有 BDD 主題。
[^11]: Martin Fowler，〈GivenWhenThen〉，https://martinfowler.com/bliki/GivenWhenThen.html ，2013-08-21。二手轉述。
[^12]: Semaphore 部落格的 Aslak Hellesøy 訪談，https://semaphore.io/blog/aslak-hellesoy-cucumber ，日期不明。二手。
[^13]: Matt Wynne，Example Mapping 介紹文，https://cucumber.io/blog/bdd/example-mapping-introduction/ ，2015-12-08（另一次查證時年份標為未確認）。一手。
[^14]: Cucumber 官方文件，〈Writing better Gherkin〉，https://cucumber.io/docs/bdd/better-gherkin/ ，最後更新 2026-11-08，全頁只有兩節。一手。
[^15]: Cucumber 官方文件，〈Gherkin Reference〉，https://cucumber.io/docs/gherkin/reference/ ，最後更新 2026-11-08。一手。
[^16]: Seb Rose，Writing Better BDD Scenarios，ACCU 2022 投影片，https://accu.org/conf-docs/PDFs_2022/seb_rose_WritingBetterBDDScenarios-ACCU2022.pdf ，僅見搜尋摘要，未開原文。二手。
[^17]: Cucumber 部落格，Cucumber anti-patterns part two，https://cucumber.io/blog/bdd/cucumber-anti-patterns-part-two ，日期不明；僅由搜尋摘要得知，全文未讀。未確認。
[^18]: Theo England，Cucumber anti-patterns（part one），cucumber.io 部落格，2016-07-01。一手，內容較舊。
[^19]: @cucumber/cucumber 的 GitHub release 與 docs/formatters.md，查證日 2026-11-09。一手。
[^20]: playwright-bdd 的 GitHub release、npm（modified 2026-10-26）與 README，查證日 2026-11-09。一手。
[^21]: @amiceli/vitest-cucumber 的 npm 頁與 README，查證日 2026-11-09。一手。
[^22]: jest-cucumber 的 npm 頁與 README，查證日 2026-11-09；「停滯」為依發版日期的推論，無官方棄用公告。一手。
[^23]: pytest-bdd 的 PyPI 與 readthedocs，查證日 2026-11-09；async 相關 issue #223（2017）與 PR #629、#426 的合併狀態未確認。一手。
[^24]: behave 的 PyPI 與 GitHub，查證日 2026-11-09。一手。
[^25]: Reqnroll 的 GitHub release 與 reqnroll.net，查證日 2026-11-09。一手＋二手。
[^26]: Cucumber-JVM 的 GitHub release，查證日 2026-11-09。一手。
[^27]: allurereport.org 與 GitHub，查證日 2026-11-09。一手。
[^28]: serenity-bdd.github.io 與 GitHub releases，查證日 2026-11-09；latest 標籤 4.0.1 可能非最新版本，維護狀態未確認。一手。
[^29]: Reqnroll，SpecFlow end-of-life 公告文，https://reqnroll.net/news/2025/01/specflow-end-of-life-has-been-announced/ ，以及第三方頁面；未找到 Tricentis 官方公告原文，宣告確切日期與 Reqnroll 首版日期未確認。二手為主。
[^30]: NestJS 官方文件，Testing 頁，https://docs.nestjs.com/fundamentals/testing ，查證日 2026-11-09；「Newly generated projects use Vitest by default」取自文件頁摘要，未逐字核對。一手（摘要層級）。
[^31]: Gauge 的 GitHub README，查證日 2026-11-09；「規格為 markdown」未由頁面確認。一手。
[^32]: Robot Framework 官網與發版資訊，查證日 2026-11-09；首頁未提 Given/When/Then 支援。一手／二手未標註。
[^33]: helpmetest.com 廠商文章，日期未記錄。二手。
[^34]: GitHub spec-kit，templates/spec-template.md，https://github.com/github/spec-kit/blob/main/templates/spec-template.md ，查閱日 2026-11-09。一手。
[^35]: Kiro 官方文件，Feature specs 與 Specs 頁，https://kiro.dev/docs/specs/feature-specs/ 、https://kiro.dev/docs/specs/ ，日期未載明。一手。
[^36]: Claude Code 官方文件，best practices，https://code.claude.com/docs/en/best-practices ，查閱日 2026-11-09。一手。
[^37]: Sean Grove，〈The New Code〉，AI Engineer World's Fair 2025，https://ai.engineer/talks/specifications-are-the-new-code ；未取得逐字稿，內容為摘要。二手。
[^38]: kirkchen/beat README，https://github.com/kirkchen/beat ，日期未載明。一手。
[^39]: Böckeler，martinfowler.com 對 Kiro、spec-kit、Tessl 的 SDD 工具評測，https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html ，2025-10-15。二手評測（作者實測）。
[^40]: SmartBear 的 BearQ 相關標題，2026-10-20，內容未讀。未確認。
[^41]: arXiv 2504.07244（AutoUAT 與 Test Flow，GPT-4 Turbo），https://arxiv.org/abs/2504.07244 ，2025-04-09。一手論文；「有幫助」為使用者主觀評價，筆數未載明。
[^42]: arXiv 2607.01980（Epic-Organized 對 per-requirement，gpt-4o-mini），https://arxiv.org/html/2607.01980 ，2026-07-02。一手論文；作者自陳 baseline 弱、單次執行。
[^43]: arXiv 2510.18861（AToMIC，BMW MyBMW App），https://arxiv.org/abs/2510.18861 ，2025-10-21。一手論文；模型未具名，受訪人數未載明；另回報 UI 測試 100% 可執行、受訪者常省一個開發日。
[^44]: levi9 Serbia，Medium，hybrid AI＋BDD 文章，https://levi9-serbia.medium.com/beyond-prompt-only-testing-a-hybrid-ai-bdd-approach-with-cucumber-and-playwright-82a98a89946d ，日期未確認，無數字。二手。
[^45]: developertoolkit 的 agent BDD 範例，日期與 URL 未記錄。一手／二手未標註。
[^46]: ImpossibleBench，LessWrong 轉述文，https://www.lesswrong.com/posts/qJYMbrabcQqCZ7iqm/impossiblebench-measuring-reward-hacking-in-llm-coding-1 ，2025-10-30。二手轉述。
[^47]: EvilGenie，arXiv 2511.21654 v2，https://arxiv.org/html/2511.21654v2 ，2026-05-17。一手論文；硬編碼率的樣本 n=9。
[^48]: 2026 年的 BDD 框架比較文章（agent 產生 undefined step），URL 未記錄。二手。
[^49]: TestMu 文章（Gherkin 滑向實作細節），日期與 URL 未記錄。二手。
[^50]: Gojko Adzic 與 Daniel Terhorst-North 的 GOTO 訪談，https://gotopia.tech/sessions/4066/spec-driven-development-is-back-but-not-how-you-think ，2026-05-29。一手頁面摘要。
[^51]: Anand Pawar，dev.to 文章，年份未顯示。二手意見。
[^52]: Cucumber 官方文件，BDD myths 頁，https://cucumber.io/docs/bdd/myths ，年份未確認。一手。
[^53]: Cucumber 官方 anti-patterns 文件（step 依 domain 整理、避免連接詞式 step、step 不互叫），年份未確認，URL 未記錄。一手。
[^54]: Luis Inge，dev.to，When Cucumber grows too big，https://dev.to/luiinge/when-cucumber-grows-too-big-pain-points-lessons-learned-and-alternatives-21pm ，日期未確認。一手自述，屬自家工具推廣；作為失敗模式依據時列為二手。
[^55]: Corrado Calzoni，Example Mapping 團隊經驗文，https://corradocalzoni.com/2021-02-14-how-example-mapping-improved-my-team-s-development-process/ ，2021-02-14。一手（當事人自述）。
[^56]: Xin Chen，Scott Logic 部落格，https://blog.scottlogic.com/2024/07/26/beyond-automation-unveiling-the-true-essence-of-bdd.html ，2024-07-26。意見文章，無團隊數據；Three Amigos 時長與分工屬二手。
[^57]: arXiv 2504.16777，與該個案無關的 flaky test 論文，因此「852 scenario 個案」不採用。核對用，一手論文。
[^58]: Dan North，dannorth.net/whats-in-a-story；「story 格式非強制」僅見多篇二手轉述，原文未讀。未確認。
[^59]: 284km.uk，BDD 系列文，https://284km.uk/series/software-testing/05-bdd-en/ ，日期不明；另稱 North 有 2019 年演講〈BDD Is Not About Testing〉，原文未驗證。二手。
[^60]: Manning《Effective BDD》第 12 章預覽，日期未記錄。二手。
[^61]: Ranorex 文章，日期未記錄。二手。
[^62]: qaskills.sh，日期未記錄。二手。
[^63]: flaky 率計算的廠商範例，名稱與日期未記錄。二手。
[^64]: Cucumber 官方文件，Example Mapping 頁，https://cucumber.io/docs/bdd/example-mapping/ ，頁面未寫時間盒與參與者。一手。
[^65]: Dave Farley，《The Engineering Room》第 39 集，https://rss.com/podcasts/theengineeringroom/2213368 ，2025-09-14；頁面描述談 BDD 起源，未陳述 North 對現況的意見。二手。
[^66]: Sam Hatoum，specdriven.com 文章，https://specdriven.com/perspectives/the-spec-driven-shift/dan-north-wasnt-talking-about-ai-but-he-could-have-been ，日期未載明；作者詮釋，無 North 直接引述。二手。
[^67]: Gojko Adzic，《Specification by Example》，https://gojko.net/books/specification-by-example/ ，2011-06-06 出版；一手頁面未展開模式內容，模式細節僅見轉述投影片。二手。
