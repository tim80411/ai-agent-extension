# site-seo 交付前稽核

**打包交付前跑完，把實際輸出貼進工作結果卡。** 沒有輸出＝沒有檢查。

---

## 1. 紅線四項（一段跑完，任一條沒過就不准打包）

把 `ROOT` 換成發佈輸出根目錄（有 `index.html` 的那層）：

```bash
ROOT="<發佈根>"

echo "=== [1] robots.txt 是否仍為預覽站的全站封鎖 ==="
if [ -f "$ROOT/robots.txt" ]; then
  cat "$ROOT/robots.txt"
  grep -qE '^\s*Disallow:\s*/\s*$' "$ROOT/robots.txt" \
    && echo ">>> 紅線 1 失敗：robots.txt 仍在擋整站，交付出去客戶會完全搜不到" \
    || echo ">>> 紅線 1 通過"
else
  echo ">>> 紅線 1 注意：沒有 robots.txt。交付站建議補一份（含 Sitemap: 指向）"
fi

echo; echo "=== [2] 殘留 noindex ==="
grep -rn 'noindex' "$ROOT" --include='*.html' --include='*.txt' \
  && echo ">>> 紅線 2 失敗：上面這些位置還帶 noindex" \
  || echo ">>> 紅線 2 通過"

echo; echo "=== [3] 預覽站網址外洩 ==="
grep -rniI 'pages\.dev\|workers\.dev\|localhost\|127\.0\.0\.1\|ngrok' "$ROOT" \
  && echo ">>> 紅線 3 失敗：交付包含有內部／開發環境位址" \
  || echo ">>> 紅線 3 通過"

echo; echo "=== [4] 佔位符與假網址殘留 ==="
grep -rnI '__[A-Z_]\{2,\}__\|example\.com\|yourdomain\|TODO\|FIXME\|待補\|客戶網域' "$ROOT" \
  && echo ">>> 紅線 4 失敗：上面是沒填完的佔位符" \
  || echo ">>> 紅線 4 通過"
```

> **為什麼紅線 3 連 `workers.dev` 一起抓**：預覽部署常伴隨一些自架的輔助服務
> （部署註冊、表單接收、預覽用 API…），位址多半落在同一批共用網域上。開發期若把某段
> 呼叫指令或回應貼進了任何檔案的註解，交付包就帶著一個內部服務位址出去。
> 這條清單依你實際用的部署平台增修——重點是「開發期才有的位址一個都不能留」。

---

## 2. 品質六項

```bash
ROOT="<發佈根>"

echo "=== [5] title 重複 ==="
grep -ho '<title>[^<]*</title>' "$ROOT"/*.html | sort | uniq -d \
  && echo ">>> 有重複標題（上面列出的）" || echo ">>> 每頁標題皆不同"

echo; echo "=== [6] 缺 canonical 的頁 ==="
for f in "$ROOT"/*.html; do
  grep -q 'rel="canonical"' "$f" || echo "缺 canonical：$f"
done

echo; echo "=== [10] html lang ==="
grep -h '<html' "$ROOT"/*.html | sort -u
```

**[7] og:image 可存取**（每個不同的 og:image 各驗一次）：

```bash
grep -rho 'property="og:image"[^>]*content="[^"]*"' "$ROOT"/*.html \
  | grep -o 'https\?://[^"]*' | sort -u | while read -r u; do
    printf '%s -> %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' "$u")"
  done
```

期望全部 `200`。出現 `000` 代表網域還沒上線——那是正常的（客戶還沒部署），
但要在卡上寫明「og:image 待客戶網域上線後複驗」，不能當作通過。

**[8] sitemap 每個 loc 可存取**：

```bash
grep -o '<loc>[^<]*</loc>' "$ROOT/sitemap.xml" | sed 's/<[^>]*>//g' | while read -r u; do
  printf '%s -> %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' "$u")"
done
```

**[9] JSON-LD 語法**：先本機驗 JSON 合法性，再用官方工具驗 schema。

```bash
# 抽出每段 JSON-LD 丟給 python 驗語法
python3 - "$ROOT" <<'PY'
import sys, re, json, pathlib
root = pathlib.Path(sys.argv[1])
bad = 0
for f in root.rglob("*.html"):
    for i, m in enumerate(re.findall(
            r'<script[^>]*type=["\']application/ld\+json["\'][^>]*>(.*?)</script>',
            f.read_text(encoding="utf-8", errors="ignore"), re.S)):
        try:
            json.loads(m)
        except Exception as e:
            bad += 1
            print(f"JSON-LD 語法錯誤 {f}#{i}: {e}")
print("JSON-LD 全部合法" if not bad else f">>> {bad} 段有語法錯誤")
PY
```

語法過了之後，schema 正確性用 Google Rich Results Test 驗
（<https://search.google.com/test/rich-results>，貼原始碼即可，不必網站上線）。

---

## 3. 常見錯誤 → 症狀對照

拿到「客戶說 SEO 沒效」的回報時，從症狀反查：

| 症狀 | 最可能的原因 | 怎麼確認 |
| --- | --- | --- |
| 整站完全搜不到，連 `site:網域` 都空 | robots.txt `Disallow: /` 被交付出去 | 直接開 `網域/robots.txt` |
| `site:` 查得到但關鍵字搜不到 | 正常。收錄 ≠ 排名，需要內容與時間 | 說明期待落差，不是 bug |
| 只有首頁被收錄，內頁都沒有 | 內頁 canonical 全指向首頁（複製 head 沒改） | 逐頁看 canonical |
| 搜尋結果標題不是我寫的 title | title 過長被截斷，或 Google 認為內文更相關 | 縮到 60 字元內、與 h1 一致 |
| 搜尋結果摘要不是我寫的 description | description 是關鍵字堆疊或與內文不符 | 改寫成自然語句 |
| LINE／FB 分享出來是空白卡 | og:image 是相對路徑、或圖檔 404、或尺寸過小 | `curl -sI` 該圖；確認 ≥600×315 |
| 分享卡片一直是舊的 | 社群平台快取 | 用各平台的 debugger 強制重抓 |
| 結構化資料完全沒作用 | JSON 語法錯（整段被靜默忽略） | 本節 [9] 的 python 驗證 |
| 明明設了 noindex 卻還在搜尋結果 | 同時 `Disallow` 了該頁，爬蟲讀不到 noindex | 拿掉 Disallow，留 noindex |

---

## 4. 交付後客戶端可做的事（寫進交付說明，不是你做）

這些需要網域擁有者的權限，**開發方做不了也不該做**。列進交付文件讓客戶自己完成：

1. 到 Google Search Console 驗證網域擁有權
2. 提交 `https://網域/sitemap.xml`
3. 用「網址審查」對首頁要求編入索引
4. （若要追蹤）在 GA 建立資源、取得評估 ID，回頭請開發方植入（見 `add-seo-ga`）

> 收錄不是即時的。提交 sitemap 後首次收錄通常數天到數週。
> **在交付說明裡先講清楚這個時間尺度**，可以省掉一輪「怎麼還搜不到」的往返。
