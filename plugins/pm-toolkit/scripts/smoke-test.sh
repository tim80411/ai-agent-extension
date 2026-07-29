#!/usr/bin/env bash
# pm-toolkit 建單腳本的煙霧測試。零依賴，只需要 node 與 git。
# 用法：bash scripts/smoke-test.sh [工作目錄]
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${1:-$(mktemp -d)}"
PASS=0
FAIL=0

ok()   { printf '  ✓ %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  ✗ %s\n     %s\n' "$1" "${2:-}"; FAIL=$((FAIL+1)); }
head_() { printf '\n== %s ==\n' "$1"; }

export PM_TOOLKIT_CONFIG="$WORK/config.yaml"
NEW="node $HERE/issue-new.mjs"
CFG="node $HERE/pm-config.mjs"
CHK="node $HERE/issue-check.mjs"
REC="node $HERE/issue-reconcile.mjs"

mkdir -p "$WORK"
cat > "$PM_TOOLKIT_CONFIG" <<'YAML'
version: 1
defaults:
  provider: file-based
profiles:
  demo:
    match:
      path: __WORK__/demo
    issues_root: issues
    id_prefix: DEMO
    grouping: milestone
    default_group: uncategorized
    status:
      initial: Backlog
      done: Done
      enum: [Backlog, Todo, In Progress, Done]
    sections: ["背景", "AC", "範圍外"]
  nogit:
    match:
      path: __WORK__/nogit
    issues_root: issues
    id_prefix: NG
    grouping: null
    require_existing_group: false
  hastool:
    match:
      path: __WORK__/hastool
    id_prefix: HT
    grouping: null
    create_cmd: "pnpm issue:new"
  strict:
    match:
      path: __WORK__/strict
    id_prefix: ST
    grouping: milestone
    require_existing_group: true
  jirathing:
    provider: jira
    match:
      path: __WORK__/jirathing
    project_key: ABC
YAML
# BSD/GNU sed 相容寫法
sed -i.bak "s|__WORK__|$WORK|g" "$PM_TOOLKIT_CONFIG" && rm -f "$PM_TOOLKIT_CONFIG.bak"

head_ "設定檔解析"
if $CFG list --json >/dev/null 2>&1; then ok "config 解析 + 4 個 profile 驗證通過"; else bad "config 解析" "$($CFG list 2>&1 | head -3)"; fi

# ── file-based 主流程 ────────────────────────────────────────────────
mkdir -p "$WORK/demo/issues/uncategorized" "$WORK/demo/issues/m1"
git -C "$WORK/demo" init -q 2>/dev/null
git -C "$WORK/demo" checkout -qb feat/smoke 2>/dev/null

head_ "profile 解析"
OUT=$(cd "$WORK/demo" && $CFG show --json 2>&1)
if grep -q '"profile": "demo"' <<<"$OUT"; then ok "路徑前綴命中 demo"; else bad "profile 解析" "$OUT"; fi
if grep -q '"handled_by_this_plugin": true' <<<"$OUT"; then ok "file-based 標為本 plugin 處理"; else bad "provider 標記" "$OUT"; fi

head_ "建單"
OUT=$(cd "$WORK/demo" && $NEW "[Bug] 匯出 CSV 缺欄位" --label P1 --label Bug 2>&1)
ID1=$(head -1 <<<"$OUT"); P1=$(sed -n 2p <<<"$OUT")
[[ "$ID1" == "DEMO-1" ]] && ok "第一號 = DEMO-1" || bad "第一號" "$OUT"
[[ -f "$P1" ]] && ok "index.md 實際產出" || bad "index.md 不存在" "$P1"
[[ "$P1" == *"DEMO-1-匯出-csv-缺欄位/"* ]] && ok "slug 去掉 [Bug] 前綴、CJK 保留、英文轉小寫" || bad "slug" "$P1"

head_ "frontmatter 依 profile"
FM=$(cat "$P1")
grep -q '^status: Backlog$'   <<<"$FM" && ok "status 用 profile 的 initial" || bad "status" "$FM"
grep -q '^milestone: uncategorized$' <<<"$FM" && ok "分組欄位名 = grouping(milestone)" || bad "grouping 欄位" "$FM"
grep -q '^labels: \["P1", "Bug"\]$'  <<<"$FM" && ok "labels 平鋪陣列" || bad "labels" "$FM"
grep -q '^git_branch: feat/smoke$' <<<"$FM" && ok "記錄當前分支（無 commit 的新 repo 也抓得到）" || bad "git_branch" "$FM"
grep -q '^completed:$'        <<<"$FM" && ok "completed 留空到真的 Done" || bad "completed" "$FM"
grep -q '^## 範圍外$'          <<<"$FM" && ok "內文分段照 profile sections" || bad "sections" "$FM"

head_ "連號與分組"
OUT=$(cd "$WORK/demo" && $NEW "第二張" --group m1 2>&1)
[[ "$(head -1 <<<"$OUT")" == "DEMO-2" ]] && ok "連號 DEMO-2" || bad "連號" "$OUT"
[[ "$(sed -n 2p <<<"$OUT")" == *"/issues/m1/DEMO-2-"* ]] && ok "落在指定分組 m1" || bad "分組落地" "$OUT"

OUT=$(cd "$WORK/demo" && $NEW "不存在的分組" --group m9 2>&1)
grep -q '自動建立 milestone 目錄' <<<"$OUT" && ok "分組不存在時自動建立" || bad "自動建分組" "$OUT"
grep -q '既有的：' <<<"$OUT" && ok "同時印出既有兄弟目錄（打錯字看得出來）" || bad "兄弟目錄提示" "$OUT"
[[ -d "$WORK/demo/issues/m9" ]] && ok "目錄真的建出來了" || bad "目錄未建" "$WORK/demo/issues/m9"

mkdir -p "$WORK/strict/issues"
OUT=$(cd "$WORK/strict" && $NEW "嚴格模式" --group nope 2>&1)
grep -q '分組目錄不存在' <<<"$OUT" && ok "require_existing_group: true 仍可擋下" || bad "嚴格模式" "$OUT"

head_ "子單巢狀"
OUT=$(cd "$WORK/demo" && $NEW "子任務" --parent DEMO-2 2>&1)
SUB=$(grep -o '/.*index.md' <<<"$OUT" | tail -1)
[[ "$SUB" == *"DEMO-2-"*"/DEMO-"*"/index.md" ]] && ok "子單巢狀在父單資料夾下" || bad "子單巢狀" "$OUT"
grep -q '^milestone: m1$' "$SUB" && ok "子單分組繼承父單" || bad "子單分組繼承" "$(cat "$SUB")"

head_ "併發不撞號（8 個同時跑）"
cd "$WORK/demo"
for i in $(seq 1 8); do ( $NEW "併發 $i" --group m1 2>/dev/null | head -1 > "$WORK/c$i.txt" ) & done
wait
IDS=$(cat "$WORK"/c*.txt | sort)
N=$(wc -l <<<"$IDS" | tr -d ' '); U=$(sort -u <<<"$IDS" | wc -l | tr -d ' ')
[[ "$N" == "8" && "$U" == "8" ]] && ok "8 個併發全部拿到相異號（$(tr '\n' ' ' <<<"$IDS"))" || bad "併發撞號" "$IDS"

head_ "計數檔遺失也不退號"
COUNTER="$WORK/counters/demo.counter"
BEFORE="$(cat "$COUNTER")"
rm -f "$COUNTER"
OUT="$(cd "$WORK/demo" && $NEW "計數檔被砍之後" --group m1 2>&1)"
GOT="$(head -1 <<<"$OUT" | tr -dc '0-9')"
if [[ -n "$GOT" && "$GOT" -gt "$BEFORE" ]]; then
  # 注意：${GOT} 必須用大括號——後面緊接全形「）」時 bash 會把它吃進變數名
  ok "掃描當地板，號碼仍前進（${BEFORE} → ${GOT}）"
else
  bad "計數檔遺失後退號" "before=$BEFORE out=$OUT"
fi

head_ "無 git 環境"
mkdir -p "$WORK/nogit"
OUT=$(cd "$WORK/nogit" && $NEW "沒有 git 也能建" 2>&1)
[[ "$(head -1 <<<"$OUT")" == "NG-1" ]] && ok "無 git repo 照樣發號（計數器在全域）" || bad "無 git" "$OUT"
grep -q 'git_branch' "$(sed -n 2p <<<"$OUT")" && bad "無 git 不該有 git_branch" "" || ok "無 git 時略過 git_branch"

head_ "provider 閘門"
mkdir -p "$WORK/jirathing"
OUT=$(cd "$WORK/jirathing" && $NEW "應該被擋" 2>&1); RC=$?
[[ $RC -eq 2 ]] && grep -q 'jira-cli' <<<"$OUT" && ok "jira profile 拒絕並指向正確工具（exit 2）" || bad "provider 閘門" "rc=$RC $OUT"

head_ "專案自帶工具時讓位"
mkdir -p "$WORK/hastool"
OUT=$(cd "$WORK/hastool" && $NEW "應該讓位" 2>&1); RC=$?
[[ $RC -eq 3 ]] && grep -q 'pnpm issue:new' <<<"$OUT" && ok "有 create_cmd 時讓位並印出該用的指令（exit 3）" || bad "create_cmd 讓位" "rc=$RC $OUT"
OUT=$(cd "$WORK/hastool" && $NEW "強制建" --force 2>&1)
[[ "$(head -1 <<<"$OUT")" == "HT-1" ]] && ok "--force 可覆寫讓位" || bad "--force" "$OUT"

head_ "找不到 profile 時導向登記 skill"
mkdir -p "$WORK/unknown"
OUT=$(cd "$WORK/unknown" && $NEW "沒設定過的專案" 2>&1); RC=$?
[[ $RC -eq 4 ]] && ok "未登記專案以 exit 4 停下（不猜一個來發號）" || bad "未知專案退出碼" "rc=$RC $OUT"
grep -q 'init-tracker-config' <<<"$OUT" && ok "訊息指向 init-tracker-config skill" || bad "缺少 skill 指引" "$OUT"

head_ "detect：唯讀推斷"
OUT=$(cd "$WORK/demo" && $CFG detect --json 2>&1)
grep -q '"idPrefix": "DEMO"' <<<"$OUT" && ok "從現存資料夾推斷出 id_prefix=DEMO" || bad "推斷 prefix" "$OUT"
grep -q '"issuesRoot": "issues"' <<<"$OUT" && ok "推斷出 issues_root" || bad "推斷 issuesRoot" "$OUT"
grep -q '"grouping": "milestone"' <<<"$OUT" && ok "靠 frontmatter 值對上目錄名推斷出 grouping" || bad "推斷 grouping" "$OUT"
grep -q '"範圍外"' <<<"$OUT" && ok "從現存 index.md 抽出內文分段" || bad "推斷 sections" "$OUT"
grep -q '"Backlog"' <<<"$OUT" && ok "從現存 index.md 統計出 status 值" || bad "推斷 status" "$OUT"

OUT=$(cd "$WORK/unknown" && $CFG detect --json 2>&1); RC=$?
[[ $RC -eq 4 ]] && grep -q '"need": "id_prefix"' <<<"$OUT" && ok "沒有任何現存 issue 時拒絕猜前綴（exit 4）" || bad "空 repo 推斷" "rc=$RC $OUT"

head_ "detect 認出專案自帶的建立工具"
mkdir -p "$WORK/withtool/issues/uncategorized/WT-1-x"
printf -- '---\nid: WT-1\nstatus: Todo\nmilestone: uncategorized\n---\n\n## 背景\n' > "$WORK/withtool/issues/uncategorized/WT-1-x/index.md"
printf '{"scripts":{"issue:new":"ts-node x.ts"}}' > "$WORK/withtool/package.json"
touch "$WORK/withtool/pnpm-lock.yaml"
OUT=$(cd "$WORK/withtool" && $CFG detect --json 2>&1)
grep -q '"createCmd": "pnpm issue:new"' <<<"$OUT" && ok "認出 package.json 的 issue:new 並用對 runner" || bad "createCmd 偵測" "$OUT"

head_ "add：登記後端到端可建單"
mkdir -p "$WORK/newproj/issues/m1/NP-1-seed"
printf -- '---\nid: NP-1\nstatus: Todo\nmilestone: m1\n---\n\n## 背景\n\n## AC\n' > "$WORK/newproj/issues/m1/NP-1-seed/index.md"
DETECTED=$(cd "$WORK/newproj" && $CFG detect --json 2>/dev/null)
OUT=$(cd "$WORK/newproj" && $CFG add --json "$DETECTED" 2>&1)
grep -q '已登記 profile `newproj`' <<<"$OUT" && ok "add 寫入並讀回驗證通過" || bad "add 寫入" "$OUT"
OUT=$(cd "$WORK/newproj" && $CFG show --json 2>&1)
grep -q '"profile": "newproj"' <<<"$OUT" && ok "show 解析得到新登記的 profile" || bad "登記後解析" "$OUT"
OUT=$(cd "$WORK/newproj" && $NEW "登記後第一張" --group m1 2>&1)
[[ "$(head -1 <<<"$OUT")" == "NP-2" ]] && ok "接續現存最大號發 NP-2" || bad "登記後建單" "$OUT"
OUT=$(cd "$WORK/newproj" && $CFG add --json "$DETECTED" 2>&1)
grep -q '已存在' <<<"$OUT" && ok "重複登記同名 profile 被擋下" || bad "重複登記" "$OUT"

head_ "add：非 file-based 的轉介型 profile"
OUT=$($CFG add --json '{"profileName":"somejira","provider":"jira","match":{"path":"'"$WORK"'/somejira"},"settings":{"project_key":"ABC"}}' 2>&1)
grep -q '已登記' <<<"$OUT" && ok "jira 型 profile 可登記" || bad "jira profile 登記" "$OUT"
mkdir -p "$WORK/somejira"
OUT=$(cd "$WORK/somejira" && $NEW "應該被擋" 2>&1); RC=$?
[[ $RC -eq 2 ]] && ok "登記後該 repo 建單被擋（exit 2，不會長出 issues/）" || bad "jira 閘門" "rc=$RC $OUT"
[[ ! -d "$WORK/somejira/issues" ]] && ok "確認沒有誤建 issues/ 目錄" || bad "誤建 issues/" ""

head_ "設定檔既有內容不被洗掉"
grep -q '^# pm-toolkit 設定檔' "$PM_TOOLKIT_CONFIG" 2>/dev/null || head -1 "$PM_TOOLKIT_CONFIG" | grep -q 'version' && ok "append 寫入後原檔頭仍在" || bad "設定檔被重寫" "$(head -3 "$PM_TOOLKIT_CONFIG")"
grep -q 'id_prefix: DEMO' "$PM_TOOLKIT_CONFIG" && ok "既有 profile 未被破壞" || bad "既有 profile 遺失" ""

head_ "YAML parser 拒絕不支援語法"
printf 'profiles:\n\tdemo:\n\t\tid_prefix: X\n' > "$WORK/bad.yaml"
OUT=$(PM_TOOLKIT_CONFIG="$WORK/bad.yaml" $CFG list 2>&1)
grep -q 'tab' <<<"$OUT" && ok "tab 縮排明確報錯而非安靜解析錯" || bad "tab 偵測" "$OUT"
printf 'profiles:\n  demo:\n    id_prefix: X\n    note: |\n      multi\n' > "$WORK/bad2.yaml"
OUT=$(PM_TOOLKIT_CONFIG="$WORK/bad2.yaml" $CFG list 2>&1)
grep -q 'multi-line scalar' <<<"$OUT" && ok "multi-line scalar 明確報錯" || bad "multi-line 偵測" "$OUT"

head_ "status enum 一致性"
printf 'profiles:\n  demo:\n    id_prefix: X\n    status:\n      initial: Nope\n      enum: [Backlog, Done]\n' > "$WORK/bad3.yaml"
OUT=$(PM_TOOLKIT_CONFIG="$WORK/bad3.yaml" $CFG list 2>&1)
grep -q 'status.initial' <<<"$OUT" && ok "initial 不在 enum 內時擋下" || bad "enum 檢查" "$OUT"

head_ "issue-check：乾淨的 tracker 應該通過"
OUT=$(cd "$WORK/demo" && $CHK 2>&1); RC=$?
[[ $RC -eq 0 ]] && ok "issue-new 產出的卡本身就合格（骨架與稽核期待同一組欄位）" || bad "乾淨卻不通過" "$OUT"

head_ "issue-check：每一種漂移都抓得到"
CARD="$WORK/demo/issues/uncategorized/$(ls "$WORK/demo/issues/uncategorized" | head -1)/index.md"
cp "$CARD" "$WORK/card.bak"
mut() { sed -i.bak "$1" "$CARD" && rm -f "$CARD.bak"; }
chk() { (cd "$WORK/demo" && $CHK 2>&1); }

mut 's/^status: Backlog$/status: 亂寫的/'
grep -q '不在 enum' <<<"$(chk)" && ok "status 不在 enum" || bad "status enum 未抓到" "$(chk)"
cp "$WORK/card.bak" "$CARD"

mut 's/^milestone: uncategorized$/milestone: m1/'
grep -q 'layer-1 資料夾' <<<"$(chk)" && ok "grouping 欄與資料夾不符（搬檔沒改欄）" || bad "grouping 漂移未抓到" "$(chk)"
cp "$WORK/card.bak" "$CARD"

mut 's/^status: Backlog$/status: Done/'
grep -q 'completed 空白' <<<"$(chk)" && ok "Done 卻沒有 completed" || bad "done⇔completed 未抓到" "$(chk)"
cp "$WORK/card.bak" "$CARD"

mut '/^labels: /d'
grep -q '缺 frontmatter 欄位' <<<"$(chk)" && ok "frontmatter 缺欄" || bad "缺欄未抓到" "$(chk)"
cp "$WORK/card.bak" "$CARD"

mut 's/^blocks: \[\]$/blocks: [DEMO-2]/'
grep -q 'blocked_by 沒有' <<<"$(chk)" && ok "單向關係欄（A blocks B 但 B 沒回指）" || bad "單向關係未抓到" "$(chk)"
cp "$WORK/card.bak" "$CARD"

mut 's/^blocks: \[\]$/blocks: [DEMO-999]/'
grep -q 'DEMO-999 不存在' <<<"$(chk)" && ok "關係欄指向不存在的 ID" || bad "懸空關係未抓到" "$(chk)"
cp "$WORK/card.bak" "$CARD"

printf '# INDEX\n\nDEMO-1 在這裡，DEMO-404 是幽靈\n' > "$WORK/demo/issues/INDEX.md"
OUT=$(chk)
grep -q 'INDEX.md 提到 DEMO-404' <<<"$OUT" && ok "INDEX 提到不存在的卡" || bad "INDEX 幽靈未抓到" "$OUT"
grep -q '沒有出現在 INDEX.md' <<<"$OUT" && ok "卡沒出現在 INDEX" || bad "INDEX 漏卡未抓到" "$OUT"
rm -f "$WORK/demo/issues/INDEX.md"
(cd "$WORK/demo" && $CHK >/dev/null 2>&1) && ok "還原後回到全綠（前面的檢查沒有副作用）" || bad "還原後仍失敗" "$(chk)"

head_ "issue-reconcile：判準與 --fix"
git -C "$WORK/demo" add -A >/dev/null 2>&1
git -C "$WORK/demo" -c user.email=t@t -c user.name=t commit -q -m "chore: seed" 2>/dev/null
git -C "$WORK/demo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "feat(x): DEMO-1 做完了"
git -C "$WORK/demo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "docs(x): DEMO-2 補說明"
OUT=$(cd "$WORK/demo" && $REC --released HEAD 2>&1); RC=$?
grep -q 'DEMO-1' <<<"$OUT" && ok "feat 開頭且 subject 帶號 → 命中" || bad "應命中卻沒有" "$OUT"
grep -q 'DEMO-2' <<<"$OUT" && bad "docs 不該命中" "$OUT" || ok "docs 開頭 → 不命中（不是實作）"
[[ $RC -eq 1 ]] && ok "有候選未修時 exit 1" || bad "退出碼" "rc=$RC"

(cd "$WORK/demo" && $REC --released HEAD --fix >/dev/null 2>&1)
D1=$(grep -rl '^id: DEMO-1$' "$WORK/demo/issues" | head -1)
grep -q '^status: Done$' "$D1" && ok "--fix 把 status 翻成 profile 的 done 值" || bad "--fix status" "$(cat "$D1")"
grep -qE '^completed: [0-9]{4}-[0-9]{2}-[0-9]{2}$' "$D1" && ok "--fix 補上 completed（用 commit 日期）" || bad "--fix completed" "$(cat "$D1")"
(cd "$WORK/demo" && $CHK >/dev/null 2>&1) && ok "--fix 後 check 仍全綠（沒破壞 done⇔completed）" || bad "--fix 後 check 失敗" "$(chk)"
OUT=$(cd "$WORK/demo" && $REC --released HEAD 2>&1)
grep -q 'DEMO-1' <<<"$OUT" && bad "已修的卡不該再出現" "$OUT" || ok "已修的卡不再是候選"

head_ "issue-reconcile：讓位與 provider 閘門"
$CFG add --json '{"profileName":"hasrecon","idPrefix":"HR","match":{"path":"'"$WORK"'/hasrecon"},"reconcileCmd":"pnpm issue:reconcile","status":{"initial":"Backlog","done":"Done","enum":["Backlog","Done"]},"sections":["背景"]}' >/dev/null 2>&1
mkdir -p "$WORK/hasrecon/issues"
OUT=$(cd "$WORK/hasrecon" && $REC 2>&1); RC=$?
[[ $RC -eq 3 ]] && grep -q 'pnpm issue:reconcile' <<<"$OUT" && ok "有 reconcile_cmd 時讓位（exit 3）" || bad "reconcile_cmd 讓位" "rc=$RC $OUT"
OUT=$(cd "$WORK/jirathing" && $REC 2>&1); RC=$?
[[ $RC -eq 2 ]] && ok "非 file-based provider 被擋（exit 2）" || bad "provider 閘門" "rc=$RC $OUT"

head_ "add 寫得出 schema 文件宣告的所有欄位"
$CFG add --json '{"profileName":"fullopts","idPrefix":"FO","match":{"path":"'"$WORK"'/fullopts"},"requireExistingGroup":true,"recordBranch":false,"frontmatterExtra":{"team":"core"},"reconcileCmd":"make reconcile","status":{"initial":"Backlog","done":"Done","enum":["Backlog","Done"]},"sections":["背景"]}' >/dev/null 2>&1
for k in require_existing_group record_branch frontmatter_extra reconcile_cmd; do
  grep -q "$k" "$PM_TOOLKIT_CONFIG" && ok "add 寫得出 $k" || bad "add 漏寫 $k" ""
done

printf '\n────────────────────────\n通過 %d ／ 失敗 %d\n工作目錄：%s\n' "$PASS" "$FAIL" "$WORK"
[[ $FAIL -eq 0 ]]
