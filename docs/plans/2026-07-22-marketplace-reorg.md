# Marketplace 整理計畫 — 合併散落的單一 skill plugin

**日期**：2026-07-22
**目標**：把散落、多為「單一 skill」的 plugin 依主題收斂成 toolbox，刪除不再需要的 `deploy-gdrive`。
**方向**：主題工具箱（延續既有 `pm-toolkit` / `data-converter` 模式）。

---

## 決策摘要（已與使用者確認）

| 決策 | 結果 |
|---|---|
| deploy-gdrive | **刪除** |
| spec-writer | **併入 pm-toolkit**（spec-writing skill + 4 agents + scripts） |
| copy-verify | **併入 code-quality-review**，且該 plugin **改名 review-toolkit** |
| add-seo-ga | **改名 marketing-toolkit**（行銷工具集，未來成長容器） |
| figma-reader | **改名 design-toolkit**（設計工具集，未來成長容器） |

## 最終結構（14 → 11 plugins）

| # | Plugin | 變更 | 內容 |
|---|---|---|---|
| 1–7 | animate-dev, xapi-engineer, book-study, tunnelbox-cli, workflow-lab, k8s-troubleshooter, data-converter | 不變 | — |
| 8 | **pm-toolkit** | ⬅ 併入 spec-writer | file-based-issues + spec-writing (+4 agents +script) |
| 9 | **review-toolkit** | ⬅ code-quality-review 改名 + 併入 copy-verify | code-quality-review skill + copy-verify skill (+6 agents +cmd) |
| 10 | **marketing-toolkit** 🆕 | ⬅ add-seo-ga 改名 | add-seo-ga skill |
| 11 | **design-toolkit** 🆕 | ⬅ figma-reader 改名 | figma-read skill + figma agent + figma cmd |
| — | ~~deploy-gdrive~~ ~~spec-writer~~ ~~copy-verify~~ ~~add-seo-ga~~ ~~figma-reader~~ ~~code-quality-review~~ | dir 移除/改名 | — |

---

## 機制約束（必須遵守）

1. **Symlinks**：每個掛了 symlink 的 skill 在 `.claude/skills/` 與 `.cursor/skills/` 各有一條，指向 `plugins/<plugin>/skills/<skill>`。移動/改名 → 重新指向 target。
2. **version-bump hook**（`.claude/scripts/bump-plugin-version.sh`，PreToolUse on `git commit`）：偵測到 plugin.json 已被 stage 時 **會跳過** 該 plugin。→ 手動設好版本並一起 stage，避免 bump dance。
3. **marketplace.json** 與 **README.md** 要與 plugin 目錄同步（README 有 plugin 清單 + 目錄樹，含 deploy-gdrive）。
4. 受影響 plugin 內 **無** `CLAUDE_PLUGIN_ROOT` 或硬編路徑引用 → 移動安全。

---

## 逐步執行計畫

### Step 1 — 刪除 deploy-gdrive
- [ ] `git rm -r plugins/deploy-gdrive`
- [ ] 移除 symlink：`.claude/skills/deploy-gdrive`、`.cursor/skills/deploy-gdrive`
- [ ] marketplace.json 移除 deploy-gdrive 條目
- [ ] README：從清單與目錄樹移除

### Step 2 — spec-writer → pm-toolkit
- [ ] `git mv plugins/spec-writer/skills/spec-writing plugins/pm-toolkit/skills/spec-writing`
- [ ] `mkdir -p plugins/pm-toolkit/agents` → `git mv plugins/spec-writer/agents/*.md plugins/pm-toolkit/agents/`
- [ ] `mkdir -p plugins/pm-toolkit/scripts` → `git mv plugins/spec-writer/scripts/spec-frontmatter.sh plugins/pm-toolkit/scripts/`
- [ ] `git rm -r plugins/spec-writer`
- [ ] 重指 symlink：`.claude/skills/spec-writing`、`.cursor/skills/spec-writing` → `../../plugins/pm-toolkit/skills/spec-writing`
- [ ] pm-toolkit plugin.json：version `0.1.0 → 0.2.0`，description 補 spec-writing
- [ ] marketplace.json：移除 spec-writer；更新 pm-toolkit（version + description + keywords）

### Step 3 — copy-verify + code-quality-review → review-toolkit
- [ ] `git mv plugins/code-quality-review plugins/review-toolkit`
- [ ] `git mv plugins/copy-verify/skills/copy-verify plugins/review-toolkit/skills/copy-verify`
- [ ] `git rm plugins/copy-verify/README.md`（plugin 級 README，內容已在 SKILL.md）
- [ ] `git rm -r plugins/copy-verify`
- [ ] review-toolkit plugin.json：name `code-quality-review → review-toolkit`，version `0.1.0 → 0.2.0`，description 反映 code+copy 雙驗證
- [ ] 重指 symlink：`.claude/skills/code-quality-review`、`.cursor/skills/code-quality-review` → `../../plugins/review-toolkit/skills/code-quality-review`
- [ ] 新增 symlink（原本無）：`.claude/skills/copy-verify`、`.cursor/skills/copy-verify` → `../../plugins/review-toolkit/skills/copy-verify`
- [ ] marketplace.json：移除 copy-verify；code-quality-review 條目改名 review-toolkit（name + source + description + version + keywords）

### Step 4 — add-seo-ga → marketing-toolkit
- [ ] `git mv plugins/add-seo-ga plugins/marketing-toolkit`
- [ ] `git rm -r plugins/marketing-toolkit/.claude-plugin/.claude-plugin`（清除巢狀重複 plugin.json cruft）
- [ ] marketing-toolkit plugin.json：name `add-seo-ga → marketing-toolkit`，version 維持 `1.0.0`，description 改為行銷工具集
- [ ] 新增 symlink（原本無）：`.claude/skills/add-seo-ga`、`.cursor/skills/add-seo-ga` → `../../plugins/marketing-toolkit/skills/add-seo-ga`
- [ ] marketplace.json：add-seo-ga 條目改名 marketing-toolkit（name + source + description）

### Step 5 — figma-reader → design-toolkit
- [ ] `git mv plugins/figma-reader plugins/design-toolkit`（agent + command 隨目錄一起搬）
- [ ] design-toolkit plugin.json：name `figma-reader → design-toolkit`，version 維持 `0.1.0`，description 改為設計工具集
- [ ] 重指 symlink：`.claude/skills/figma-read`、`.cursor/skills/figma-read` → `../../plugins/design-toolkit/skills/figma-read`
- [ ] marketplace.json：figma-reader 條目改名 design-toolkit（name + source + description）

### Step 6 — README.md 全面同步
- [ ] Plugins 清單：反映刪除、併入、改名
- [ ] 目錄樹圖：移除 deploy-gdrive，更新改名

### Step 7 — 驗證（read-back，不宣稱先驗證）
- [ ] `find plugins -name plugin.json` → 11 個，name 欄與目錄名一致
- [ ] `jq` 檢查 marketplace.json plugins 陣列 = 11、每個 source 目錄存在、version 與 plugin.json 相符
- [ ] `ls -la .claude/skills .cursor/skills` → 無斷掉 symlink（`find -L . -type l` 檢查 dangling）
- [ ] `grep -rn deploy-gdrive` 全 repo → 僅剩本計畫文件
- [ ] 每個改名 plugin 的 skill/agent/command 檔案齊全

---

## 版本與 commit 策略

- 所有變更以 **單一 atomic commit** 完成（marketplace.json 必須與 plugin 目錄隨時同步）。
- **手動設定** 上述 plugin.json 版本並 `git add`，讓 bump hook 對這些 plugin 跳過（不觸發 deny）。
- 已刪除的 plugin dir 無 plugin.json 殘留 → hook 無可 bump。
- commit message：`refactor(marketplace): 收斂散落單一 skill plugin 為主題 toolbox` 類（非 feat!，避免訊息訊號誤判；但因所有 plugin.json 已 stage，hook 一律跳過）。
- **依 harness 規則：commit 只在使用者要求時執行。** 本計畫先完成檔案變更 + 驗證，再詢問是否 commit。
- **版本漂移修正**：已發現 marketplace.json 與 plugin.json 版本不同步（如 deploy-gdrive marketplace 0.1.1 vs plugin.json 0.3.1）。凡本次 **有觸碰** 的 plugin，marketplace 版本一律對齊 plugin.json 實際值；未觸碰的 plugin 維持現狀（超出本次範圍，僅提醒使用者）。

## Rollback
- 執行前於乾淨工作區進行；若中途出錯 `git checkout -- . && git clean -fd`（注意 untracked 新 symlink / 新目錄）。

## 進度（Progress / 斷點續做）
- [x] Step 1 deploy-gdrive 刪除
- [x] Step 2 spec-writer → pm-toolkit
- [x] Step 3 copy-verify + code-quality-review → review-toolkit
- [x] Step 4 add-seo-ga → marketing-toolkit
- [x] Step 5 figma-reader → design-toolkit
- [x] Step 6 README 同步
- [x] Step 7 驗證（11 plugins 全 name==dir、marketplace↔plugin.json 版本同步、symlink 無斷、無 deploy-gdrive 殘留）
- [x] 額外：修正 3 個 plugin.json author 格式（review-toolkit、marketing-toolkit、k8s-troubleshooter）＋ 2 筆 marketplace 版本漂移（animate-dev、book-study）
- [x] commit（使用者授權，單一 atomic commit）
