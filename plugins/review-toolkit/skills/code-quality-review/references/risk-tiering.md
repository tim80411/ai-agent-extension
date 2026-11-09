# 風險分級規則

依變更規模與是否碰到敏感路徑，決定 Phase 2 啟動幾個 reviewer agent，而不是固定六個。

## 1. 規模計算

### 分支／diff 模式
適用：使用者指定 branch、PR，或說「審這次改動」。

- 指令：`git diff --stat <base>`（base 對工作樹，涵蓋已 commit 與未 commit 的改動）
- 未追蹤的新檔：用 `git ls-files --others --exclude-standard` 列出，排除「不計入規模的檔案」後，以 `wc -l` 把行數與檔案數加進來。
- 變更行數 = 新增行數 + 刪除行數（含未追蹤新檔的行數）
- 檔案數 = 有變更的檔案數（含未追蹤新檔）
- 若算出來變更為 0 行、0 檔：**不要判 trivial**，改為告訴使用者「分支模式找不到任何變更」，並請使用者改指定檔案或分支。
- base = `git merge-base HEAD origin/main`；沒有 `origin/main` 時依序試 `main`、`master`；使用者可自行指定。

### 檔案／模組模式
適用：使用者指定檔案或模組。

- 以 `wc -l` 計算清單內檔案的總行數與檔案數。
- 此模式審的是整個檔案，所以用整檔行數計算，分級自然偏高；若只想審某檔的改動，改用分支／diff 模式。

### 不計入規模的檔案
- lock 檔：`package-lock.json`、`yarn.lock`、`pnpm-lock.yaml`、`Cargo.lock` 等
- 生成檔：`*.generated.*`、`dist/`、`build/`
- minified 檔
- vendor 目錄
- snapshot 檔

migration 檔**要計入**規模，且視為敏感路徑。

## 2. 敏感路徑

路徑或檔名（不分大小寫）命中下列任一關鍵字，即算碰到敏感路徑：

`auth`、`oauth`、`session`、`jwt`、`token`、`password`、`secret`、`crypto`、`cipher`、`payment`、`billing`、`permission`、`rbac`、`acl`、`migration`、`schema`

**比對方式**：
- 比對對象是從 repo 根目錄算起的完整相對路徑。
- 先把路徑以 `/`、`.`、`-`、`_` 切成 token，全部轉小寫，再與關鍵字做**整個 token 相等**的比對；關鍵字結尾多一個 `s` 也算相等（migrations、permissions、tokens、secrets、sessions、schemas）。
- 不做子字串比對。

| 路徑 | 是否敏感 | 原因 |
|------|----------|------|
| `author.ts` | 否 | token 是 `author`，不等於 `auth` |
| `tokenizer.ts` | 否 | token 是 `tokenizer`，不等於 `token` |
| `schematic/` | 否 | token 是 `schematic`，不等於 `schema` |
| `src/auth/login.ts` | 是 | 有 token `auth` |
| `user_token.ts` | 是 | 以 `_` 切出 token `token` |
| `db/migrations/001.sql` | 是 | 有 token `migrations`（`migration` 加 `s`） |

使用者可在 Phase 0 補充專案自己的敏感路徑。

## 3. 分級表

| 分級 | 條件（全部符合） | 啟動的 agent |
|------|------------------|--------------|
| trivial | 變更 ≤ 50 行、≤ 3 個檔案、未碰敏感路徑 | AS、HM |
| lite | 變更 ≤ 300 行、≤ 10 個檔案、未碰敏感路徑 | AS、HM、TB、MD |
| full | 其餘情況；碰到任一敏感路徑；使用者要求 `--full` 或「全跑」 | 全部 6 個（RD、TB、AS、HM、MD、RU） |

由上往下判定，先符合者即採用（trivial 的條件是 lite 的子集合，所以同時符合時取 trivial）。

## 4. 告知使用者

分級結果在 Phase 0 第 4 步算出時就用一行告訴使用者（也就是 Phase 2 啟動前），格式：

```
分級：lite（變更 120 行、4 檔、無敏感路徑）→ 啟動 4 個 agent：AS、HM、TB、MD
```

## 設計依據

2026-11 的研究（見 `docs/analyses/2026-11-09-code-review-workflows.md` 第七節）顯示：

- 主流 AI reviewer 預設只報高嚴重度問題，以降低噪音。
- Cloudflare 以 trivial／lite／full 三級分流控制成本。

本規則據此：小改動只跑最可能出事的視角（避免意外、難以誤用），敏感路徑一律全跑。
