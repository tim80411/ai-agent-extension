---
name: site-seo
description: 把一個靜態網站備妥到「可交付、可被搜尋」的完整 SEO 狀態：每頁 head（title／description／canonical／Open Graph／Twitter Card／lang）、JSON-LD 結構化資料、站台級的 robots.txt 與 sitemap.xml、多頁站的 canonical 與 breadcrumb，以及交付前的逐項稽核。內建「預覽站 vs 正式站」分流——預覽站一律 noindex，交付前必須把 noindex 的 robots.txt 換掉，否則客戶的站會被整站擋出搜尋結果。當要「幫這個站加 SEO」「做 SEO 優化」「加 sitemap／robots／canonical／結構化資料」「交付前檢查 SEO」「網站搜尋不到」時使用。單一 HTML 檔、已知全部資訊、只想快速塞 meta 與 GA 追蹤碼，用 add-seo-ga 就好，不必開這支。
version: 1.0.0
---

# site-seo：把站台備妥到可交付、可被搜尋

這支 skill 的產出不是「塞幾個 meta 標籤」，是**讓一個靜態站在交出去之後，能被搜尋引擎正確
收錄、被社群正確預覽，而且不帶任何開發期的殘留設定**。

順序有意義，別跳：先判斷站別 → 收齊輸入 → 每頁 head → 結構化資料 → 站台級檔案 → 稽核。

---

## 步驟 0：先判斷這一份是「預覽站」還是「交付站」

**這是本 skill 最重要的一步，做錯後面全錯。** 兩種站的 SEO 目標是相反的。

| | 預覽站（QA／內部審閱） | 交付站（客戶要上線的） |
| --- | --- | --- |
| 怎麼認 | 跑在你自己部署的臨時網域上（`*.pages.dev`、`*.netlify.app`、隨機碼站名…） | 要打包交給客戶、跑在**客戶自己的網域** |
| `robots.txt` | `Disallow: /`（**全站擋**） | `Allow` + 指向 sitemap |
| `<link rel="canonical">` | **不要放** | 必放，指向客戶正式網域 |
| `og:url` | **不要放預覽網址** | 客戶正式網址 |
| sitemap.xml | 不需要 | 需要，URL 全用客戶網域 |
| `<meta name="robots">` | `noindex, nofollow` | 不放（預設就是可收錄），或 `index, follow` |

> **為什麼要當成兩種站處理**：預覽站是公開無認證的，只是網址猜不到。它一旦被收錄，
> 「這家公司正在做哪些案子」就進了搜尋結果——隨機站名擋得住猜測，擋不住爬蟲跟著任何一個
> 外連進來。所以預覽站一律 noindex。
>
> 但真正會出事的是反方向：**開發期為預覽站建的 `Disallow: /` robots.txt，會原封不動被打進
> 交付包**。客戶把包上傳到自己的網域，整站被擋出搜尋結果，而且沒有任何錯誤訊息——
> 站是好的、頁面是好的、就是永遠搜不到。等客戶發現通常已經過了幾週。
> **交付前把 robots.txt 換掉，是這支 skill 的硬性關卡（見步驟 5）。**

### 兩種站共用同一個 repo 的處理方式

一個案子通常先做預覽、後做交付，同一份程式碼。**不要維護兩份 robots.txt 分支**，會漏。
做法是：開發期照你的預覽部署流程放 `Disallow: /`；進入交付流程時，把 robots.txt 的
替換列進交付前檢查（步驟 5 的清單第 1 條），由清單擋住，不靠記性。

canonical 與 `og:url` 則相反——**它們從一開始就寫客戶正式網域**，不隨站別改。
預覽站上這兩個標籤指向一個還沒上線的網址是無害的（沒人會收錄預覽站），
而把預覽網址寫進去才是災難：交付包會把你的內部預覽位址一起交到客戶手上。

---

## 步驟 1：收齊輸入（跟 PM／客戶要，不要自己編）

下面這些**編不出來**，缺了就去問。尤其是正式網域——你手上只有預覽網址，那不是答案。

| # | 輸入 | 缺了會怎樣 | 可不可以自己決定 |
| --- | --- | --- | --- |
| 1 | **正式網域與各頁路徑** | canonical／og:url／sitemap 全部做不了 | ❌ 必問 |
| 2 | **每頁的頁面標題**（給搜尋結果看） | 只能拿 `<h1>` 或檔名硬湊 | ⚠️ 可先擬草稿請客戶確認 |
| 3 | **每頁的描述文**（150–160 字元內） | 搜尋結果摘要會由 Google 隨機截取 | ⚠️ 同上 |
| 4 | **分享預覽圖**（1200×630，絕對網址） | 社群分享出來是空白卡片 | ❌ 必問（客戶得提供圖或授權你做） |
| 5 | **網站／品牌名稱** | `og:site_name`、JSON-LD 的 Organization 填不了 | ❌ 必問 |
| 6 | **語言**（多半 `zh-Hant-TW`） | `<html lang>` 錯會影響搜尋引擎判讀 | ✅ 依內容判定 |
| 7 | **GA／GTM 追蹤 ID**（選配） | 沒有就不裝，不要塞自己的 | ❌ 必問，不可代填 |

> **分享預覽圖的尺寸別再用 300×300。** 那是很舊的建議。現在 Facebook／LINE／X 的大圖卡
> 都以 **1200×630（1.91:1）** 為準，低於 600×315 會退化成小圖卡或不顯示。
> 圖片網址**必須是絕對路徑**（`https://…`），相對路徑在社群爬蟲那邊解不開。

**沒收到就開工的止損做法**：先把所有 head 標籤用明確佔位符寫進去（例如
`__CANONICAL_ORIGIN__`），並在交付前稽核清單裡把「佔位符歸零」列為必檢項——
`grep -rn '__[A-Z_]*__' <發佈根>` 要是空的。**不要用看起來像真的假網址**（`https://example.com`），
那種東西會活著被交出去。

---

## 步驟 2：每頁的 `<head>`

放在 `<meta charset>` 與 `viewport` 之後。**每一頁都要有自己的一份**，不要全站複製同一組——
複製會造成所有頁面標題／描述／canonical 相同，搜尋引擎只會留一頁。

```html
<!DOCTYPE html>
<html lang="zh-Hant-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <!-- ── 基本 ── -->
  <title>本頁標題｜品牌名</title>
  <meta name="description" content="這一頁在講什麼，150–160 字元內，寫給人看不是塞關鍵字。">
  <link rel="canonical" href="https://客戶網域/本頁路徑">

  <!-- ── Open Graph（FB / LINE / Threads 等吃這組）── -->
  <meta property="og:type"        content="website">
  <meta property="og:site_name"   content="品牌名">
  <meta property="og:locale"      content="zh_TW">
  <meta property="og:title"       content="分享時顯示的標題">
  <meta property="og:description" content="分享時顯示的描述">
  <meta property="og:url"         content="https://客戶網域/本頁路徑">
  <meta property="og:image"       content="https://客戶網域/og-cover.png">
  <meta property="og:image:width"  content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt"   content="預覽圖在畫什麼">

  <!-- ── Twitter / X ── -->
  <meta name="twitter:card" content="summary_large_image">
</head>
```

### 幾條有理由的規定

**`canonical` 要絕對網址、要含通訊協定、要跟實際可存取的網址一字不差。**
`https://a.example.com/page` 與 `https://a.example.com/page/` 是兩個網址。挑一個、全站一致、
確認伺服器上那個真的打得開。canonical 指向一個 404 比不放還糟。

**`title` 的格式用「本頁標題｜品牌名」**，控制在 60 字元內（中文約 28–30 字），
超過會被搜尋結果截斷。每頁不同。

**`description` 不是排名因素，是點擊率因素。** 它決定搜尋結果那兩行寫什麼。
寫成關鍵字堆疊，Google 會直接無視它、自己從內文截一段。

**`twitter:title` / `twitter:description` / `twitter:image` 通常不必寫。**
X 找不到 `twitter:*` 時會自動退回讀 `og:*`。只有 `twitter:card` 需要明寫，
因為它決定卡片型態（大圖／小圖），OG 沒有對應欄位。要蓋掉 OG 的內容時才補寫其他 `twitter:*`。

**`<meta name="keywords">` 是死的。** Google 2009 年就公開宣布不採用。
放著無害但也無用；客戶指名要才放，不要拿它充數當「做了 SEO」的證據。

**已停用、不要再寫的標籤**：`<link rel="author">`、`<link rel="publisher">`
（Google+ 時代的 authorship markup，2019 年隨 Google+ 一起停用），
以及 `<meta name="revisit-after">`、`<meta name="robots" content="all">`（從未被支援）。

**多語言站才需要 `hreflang`。** 單一中文站放了只會增加出錯面。真要放：每個語言版本
互指、且每一版都要包含指向自己的 `hreflang`，缺一邊 Google 會整組忽略。

---

## 步驟 3：JSON-LD 結構化資料

放一個 `<script type="application/ld+json">` 在 `</head>` 前。**用 JSON-LD，不要用 microdata／RDFa**——
Google 官方明確偏好 JSON-LD，而且它不必和 HTML 結構糾纏，改版不會壞。

最小可用組合（首頁）：

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://客戶網域/#org",
      "name": "品牌名",
      "url": "https://客戶網域/",
      "logo": "https://客戶網域/logo.png"
    },
    {
      "@type": "WebSite",
      "@id": "https://客戶網域/#site",
      "url": "https://客戶網域/",
      "name": "品牌名",
      "publisher": { "@id": "https://客戶網域/#org" },
      "inLanguage": "zh-Hant-TW"
    }
  ]
}
</script>
```

內頁再加 `WebPage`，多層站再加 `BreadcrumbList`。完整可貼的樣板見
`references/templates.md`，選型別的判斷表也在那裡。

> **結構化資料的鐵律：標記的內容必須真的出現在頁面上。** 標了頁面上沒有的評分、價格、
> 作者，是 Google 明文列出的違規（structured data spam），會被取消所有複合式搜尋結果資格。
> 拿不準就少標——只標 `Organization` + `WebSite` 是安全且有效的。

---

## 步驟 4：站台級檔案

兩個檔案，放在**發佈輸出的根目錄**（有 `index.html` 的那層），不是 repo 根。

### `robots.txt`

交付站版本：

```
User-agent: *
Allow: /

Sitemap: https://客戶網域/sitemap.xml
```

預覽站版本（開發期維持不動）：

```
User-agent: *
Disallow: /
```

> `robots.txt` 的 `Disallow` 擋的是「爬取」，不是「收錄」。已經被收錄的網址就算之後補上
> `Disallow` 也不會消失，只會變成沒有摘要的裸連結。要讓一頁確實不出現在搜尋結果，
> 得用頁面上的 `<meta name="robots" content="noindex">`，而且**不能同時 Disallow 它**——
> 爬蟲被擋在門外就讀不到那個 noindex。這條反直覺，是實務上最常搞錯的一點。

### `sitemap.xml`

小型靜態站手寫即可，逐頁列出：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://客戶網域/</loc>
    <lastmod>2026-08-05</lastmod>
  </url>
  <url>
    <loc>https://客戶網域/about.html</loc>
    <lastmod>2026-08-05</lastmod>
  </url>
</urlset>
```

規則：
- `<loc>` **必須是絕對網址，且與該頁 canonical 完全一致**。sitemap 說 A、canonical 說 B，
  是明確的矛盾訊號，Google 兩邊都會打折。
- 只列**要被收錄**的頁面。noindex 的頁、重複頁、後台頁不要列。
- `<changefreq>` 與 `<priority>` 可以不寫。Google 公開說明已表示不使用這兩個欄位。
- 單一 sitemap 上限 50,000 筆 / 50MB，靜態案子不會碰到。

---

## 步驟 5：交付前稽核（硬性關卡，逐項打勾）

**做完不等於做對。** 這份清單要在**打包交付之前**跑完。
每一條都要有實際看過的證據，不能靠印象。

| # | 檢查項 | 怎麼驗 | 失敗代表 |
| --- | --- | --- | --- |
| 1 | **robots.txt 不是 `Disallow: /`** | `cat <發佈根>/robots.txt` | ⛔ 交付包會讓客戶整站搜不到。**最高優先** |
| 2 | **沒有殘留 `noindex`** | `grep -rn 'noindex' <發佈根>` | ⛔ 同上，單頁級 |
| 3 | **沒有預覽網址外洩** | `grep -rn 'pages\.dev' <發佈根>` | ⛔ 把內部預覽站位址交到客戶手上 |
| 4 | **沒有佔位符殘留** | `grep -rn '__[A-Z_]*__\|example\.com\|TODO\|待補' <發佈根>` | ⛔ 假網址會活著上線 |
| 5 | **每頁都有 title 且互不相同** | `grep -h '<title>' <發佈根>/*.html \| sort \| uniq -d` | 有輸出＝有重複 |
| 6 | **每頁都有 canonical 且指向自己** | 逐頁核對路徑 | canonical 指錯＝該頁不會被收錄 |
| 7 | **og:image 是絕對網址且圖檔真的存在** | `curl -sI <og:image 網址>` 回 200 | 分享出來是空白卡 |
| 8 | **sitemap 的每個 `<loc>` 都打得開** | 逐一 `curl -sI` 回 200 | 死連結會拉低整份 sitemap 的信任 |
| 9 | **JSON-LD 語法正確** | 貼進 Google Rich Results Test | 語法錯＝整段被忽略 |
| 10 | **`<html lang>` 有設且正確** | `grep -n '<html' <發佈根>/*.html` | 影響搜尋引擎語言判讀 |

第 1～4 條是**紅線**：任何一條沒過就不准打包。第 5～10 條沒過要回報，由 PM 判斷是修還是接受。

稽核完在你的收尾回報裡寫清楚：跑了哪幾條、各自的實際輸出是什麼。
**寫「已完成 SEO 檢查」而不附輸出，等於沒檢查。**

---

## 邊界

**這支不管 GA／GTM 追蹤碼。** 加追蹤碼用 `add-seo-ga`。追蹤 ID 一律跟客戶要，
不可以用自己的——那會把客戶的流量灌進你的帳號，是嚴重問題。

**這支不管 canvas 內文字的可搜尋性。** Animate→Canvas 的站，畫布內的文字對搜尋引擎
與螢幕閱讀器都是不存在的。要讓那些內容可被搜尋需要另外設計 HTML 語意層（`<noscript>`
或視覺隱藏的文字層），那是內容結構問題不是標籤問題，超出本 skill 範圍——
**但發現案子屬於這種狀況時要主動回報**，因為「加了完整 SEO 標籤但站上沒有任何可讀文字」
是個真實的期待落差，客戶會以為買到了搜尋排名。

**這支不管效能。** 首屏速度（Core Web Vitals）確實影響排名，但那是效能分析工具的守備範圍，
不是標籤問題。

**這支不保證排名。** 它保證的是「技術面沒有擋住收錄、社群分享正確、交付包乾淨」。
排名取決於內容與外部連結，不是標籤。跟客戶溝通時別把兩件事混為一談。

---

## 參考檔

- **`references/templates.md`** — 可直接貼用的完整樣板：各站型的 head 整段、
  JSON-LD 各型別（Organization／WebSite／WebPage／BreadcrumbList／Article／Course／
  LocalBusiness／FAQPage）與選型判斷表、robots.txt 兩版、sitemap 骨架。
- **`references/audit.md`** — 稽核清單的可執行版（一段 shell 跑完紅線四項）、
  常見錯誤與其症狀對照表、交付前後的驗證工具清單。
