# copy-verify

驗證並對齊 app 的 user-facing 文案，對照一份**受版控的、專案專屬的詞彙定本（glossary SSOT）**。
核心是 **guard 優先的增量迴圈**：機械性違規（他地用語、已決議翻譯的行話、違反文案框架的字）交給
自動測試回歸；自動抓不到的判斷（跨頁多名、工程術語外洩、錯誤直吐後端）用 5 維 rubric 補。

## 兩種模式
- **增量模式** — 專案已有 glossary + guard：只驗改動的字串。
- **bootstrap 模式** — 專案還沒有 glossary：先用 `references/` 的範本把 SSOT + guard 立起來，再驗。

## 內容
- `skills/copy-verify/SKILL.md` — 方法論（與專案、語系無關）。
- `skills/copy-verify/references/glossary-template.ts` — TERMS + BANNED_TERMS 骨架。
- `skills/copy-verify/references/guard-test-template.ts` — 掃描 guard 骨架（vitest 風格，可改任何 runner）。

## 觸發
「改文案 / 驗文案 / 文案對齊 / 文案一致 / glossary / 禁用詞 / 術語統一 / UI copy review /
microcopy audit / copy consistency」。

## 設計原則
可重用的是**判斷框架**（rubric / 主線 / gotchas），不可重用的是**判斷結果**（實際 TERMS /
路徑 / 工單）——後者屬各專案自己，且常含產品內部細節，不放進通用 skill。
