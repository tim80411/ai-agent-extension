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

OUT=$(cd "$WORK/demo" && $NEW "不存在的分組" --group nope 2>&1)
grep -q '分組目錄不存在' <<<"$OUT" && ok "分組不存在時擋下並列出可用值" || bad "分組檢查" "$OUT"

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

head_ "找不到 profile 時不亂猜"
mkdir -p "$WORK/unknown"
OUT=$(cd "$WORK/unknown" && $NEW "沒設定過的專案" 2>&1); RC=$?
[[ $RC -ne 0 ]] && grep -q '找不到對應的 profile' <<<"$OUT" && ok "未知專案直接報錯而非猜一個來發號" || bad "未知專案" "rc=$RC $OUT"

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

printf '\n────────────────────────\n通過 %d ／ 失敗 %d\n工作目錄：%s\n' "$PASS" "$FAIL" "$WORK"
[[ $FAIL -eq 0 ]]
