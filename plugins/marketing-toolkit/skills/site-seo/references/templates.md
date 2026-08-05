# site-seo 樣板集

可直接複製修改。所有 `https://客戶網域` 都要換成真實正式網域，**不是預覽網址**。

---

## 1. 完整 head（單頁站／首頁）

```html
<!DOCTYPE html>
<html lang="zh-Hant-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <!-- ── 基本 SEO ── -->
  <title>頁面標題｜品牌名</title>
  <meta name="description" content="150–160 字元內的頁面描述，寫給人看。">
  <link rel="canonical" href="https://客戶網域/">

  <!-- ── Open Graph ── -->
  <meta property="og:type"         content="website">
  <meta property="og:site_name"    content="品牌名">
  <meta property="og:locale"       content="zh_TW">
  <meta property="og:title"        content="分享標題">
  <meta property="og:description"  content="分享描述">
  <meta property="og:url"          content="https://客戶網域/">
  <meta property="og:image"        content="https://客戶網域/og-cover.png">
  <meta property="og:image:width"  content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt"    content="預覽圖描述">

  <!-- ── X / Twitter ── -->
  <meta name="twitter:card" content="summary_large_image">

  <!-- ── favicon ── -->
  <link rel="icon" href="/favicon.ico" sizes="any">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
</head>
```

`og:image:type` 依副檔名補（可選）：`.png` → `image/png`、`.jpg`/`.jpeg` → `image/jpeg`、
`.webp` → `image/webp`。

---

## 2. 內頁 head（與首頁的差異處）

只列要改的四項，其餘沿用：

```html
  <title>內頁標題｜品牌名</title>
  <meta name="description" content="這一頁自己的描述。">
  <link rel="canonical" href="https://客戶網域/about.html">
  <meta property="og:url" content="https://客戶網域/about.html">
```

`og:title` / `og:description` 若與 `title` / `description` 內容相同，仍要各自寫一份——
它們是不同的消費端，社群爬蟲不會去讀 `<title>`。

---

## 3. JSON-LD 型別選擇

| 站的性質 | 用哪些型別 |
| --- | --- |
| 任何站（打底，一定要） | `Organization` + `WebSite` |
| 有多層路徑的內頁 | 再加 `WebPage` + `BreadcrumbList` |
| 文章／衛教／新聞內容頁 | 再加 `Article` |
| 課程／教材／教學單元 | 再加 `Course` |
| 有實體店面／診所／門市 | 用 `LocalBusiness` 取代 `Organization` |
| 有問答區塊（頁面上真的看得到） | 再加 `FAQPage` |
| 活動頁 | 再加 `Event` |

拿不準就只放打底那兩個。**標了頁面上沒有的東西是違規**，不是「多做一點」。

### 3.1 打底：Organization + WebSite

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

> `@id` 用「網址 + `#錨點`」的形式，是為了讓後面的型別能用 `{"@id": "…"}` 互相引用，
> 而不必把同一份 Organization 資料在每頁重複寫一遍。這是 schema.org 的標準做法。

### 3.2 內頁：WebPage + BreadcrumbList

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "WebPage",
      "@id": "https://客戶網域/about.html#page",
      "url": "https://客戶網域/about.html",
      "name": "關於我們",
      "description": "與該頁 meta description 一致",
      "isPartOf": { "@id": "https://客戶網域/#site" },
      "inLanguage": "zh-Hant-TW"
    },
    {
      "@type": "BreadcrumbList",
      "itemListElement": [
        { "@type": "ListItem", "position": 1, "name": "首頁",   "item": "https://客戶網域/" },
        { "@type": "ListItem", "position": 2, "name": "關於我們", "item": "https://客戶網域/about.html" }
      ]
    }
  ]
}
</script>
```

BreadcrumbList 的**最後一項也要寫 `item`**（指向自己）。麵包屑要與頁面上實際看得到的
導覽層級一致。

### 3.3 Article

```json
{
  "@type": "Article",
  "headline": "標題（≤110 字元）",
  "description": "摘要",
  "image": ["https://客戶網域/article-cover.png"],
  "datePublished": "2026-08-05",
  "dateModified": "2026-08-05",
  "author":    { "@type": "Person", "name": "作者姓名" },
  "publisher": { "@id": "https://客戶網域/#org" },
  "mainEntityOfPage": { "@id": "https://客戶網域/article.html#page" }
}
```

`author` 必填且不能是空殼。日期用 ISO 8601。`headline` 超過 110 字元 Google 會忽略整則。

### 3.4 Course

```json
{
  "@type": "Course",
  "name": "課程名稱",
  "description": "課程描述",
  "provider": { "@id": "https://客戶網域/#org" },
  "hasCourseInstance": {
    "@type": "CourseInstance",
    "courseMode": "online",
    "courseWorkload": "PT2H"
  }
}
```

`courseWorkload` 用 ISO 8601 duration（`PT2H` = 2 小時）。

### 3.5 LocalBusiness

```json
{
  "@type": "LocalBusiness",
  "@id": "https://客戶網域/#org",
  "name": "店名",
  "url": "https://客戶網域/",
  "telephone": "+886-2-1234-5678",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "中正路 1 號",
    "addressLocality": "台北市",
    "addressRegion": "TW-TPE",
    "postalCode": "100",
    "addressCountry": "TW"
  },
  "openingHoursSpecification": [{
    "@type": "OpeningHoursSpecification",
    "dayOfWeek": ["Monday","Tuesday","Wednesday","Thursday","Friday"],
    "opens": "09:00",
    "closes": "18:00"
  }]
}
```

電話用 E.164 格式（`+886-…`）。地址每個欄位都要是真的，這會進 Google 商家資訊比對。

### 3.6 FAQPage

```json
{
  "@type": "FAQPage",
  "mainEntity": [{
    "@type": "Question",
    "name": "問題文字",
    "acceptedAnswer": { "@type": "Answer", "text": "答案文字" }
  }]
}
```

⚠️ 問答**必須在頁面上直接可見**（不能藏在只有點擊才展開又不存在 DOM 的地方，
摺疊面板但 DOM 內存在是可以的）。標了看不到的問答是違規。

---

## 4. robots.txt

### 交付站

```
User-agent: *
Allow: /

Sitemap: https://客戶網域/sitemap.xml
```

### 預覽站（開發期）

```
User-agent: *
Disallow: /
```

### 要擋特定路徑

```
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /*.json$

Sitemap: https://客戶網域/sitemap.xml
```

`Sitemap:` 那行**用絕對網址**，且不受 `User-agent` 區塊影響，放檔案任何位置都可以，
慣例放最後。

---

## 5. sitemap.xml

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
  <url>
    <loc>https://客戶網域/contact.html</loc>
    <lastmod>2026-08-05</lastmod>
  </url>
</urlset>
```

從發佈目錄自動生出骨架（人工核對後再用）：

```bash
cd <發佈根>
ORIGIN="https://客戶網域"
{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
  find . -name '*.html' -not -path './node_modules/*' | sed 's|^\./||' | sort | while read -r f; do
    url="$ORIGIN/${f%index.html}"
    printf '  <url>\n    <loc>%s</loc>\n    <lastmod>%s</lastmod>\n  </url>\n' \
      "$url" "$(date -r "$f" +%F)"
  done
  echo '</urlset>'
} > sitemap.xml
```

> 這段是**草稿產生器不是最終答案**。它會把所有 `.html` 都列進去，包含你不想收錄的頁。
> 產生後一定要逐行看過並刪掉不該列的，再核對每個 `<loc>` 與該頁 canonical 一字不差。
