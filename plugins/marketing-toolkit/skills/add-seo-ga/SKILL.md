---
name: add-seo-ga
description: 在**單一 HTML 檔**的 `<head>` 快速插入 SEO meta／Open Graph 標籤與 Google Analytics 追蹤碼。適用於資訊已知、只差把標籤貼進去的情況。當使用者說「加入 SEO」「加 meta tags」「加 og tags」「加 Open Graph」「加 Google Analytics」「GA 追蹤」「GA ID」「gtag」「SEO 標籤」「社群分享標籤」時使用。**邊界**：若是整個站要交付、需要 canonical／robots.txt／sitemap.xml／JSON-LD 結構化資料／多頁處理／交付前稽核，改用 `site-seo`——那支才處理「預覽站的 noindex robots.txt 不能被交付出去」這類會讓客戶整站搜不到的關卡。
version: 1.1.0
---

# add-seo-ga

在 HTML 文件的 `<head>` 區段加入完整的 SEO 標籤結構和 Google Analytics 追蹤代碼。

## 需要的資訊

### SEO 必要資訊（6項）
1. **頁籤標題** - 瀏覽器分頁上顯示的標題
2. **分享預覽標題** - 在社群媒體分享時顯示的標題
3. **搜尋關鍵字** - SEO 關鍵字，用逗號或頓號分隔
4. **網址** - 網頁的完整 URL
5. **預覽圖網址** - 社群分享時顯示的圖片完整 URL
6. **分享描述文** - 社群媒體分享時顯示的描述文字

### SEO 進階資訊（5項，建議提供）
7. **作者名稱** - 內容作者或機構名稱
8. **版權所有者** - 版權歸屬者名稱
9. **網站名稱** - 網站品牌名稱
10. **預覽圖寬度** - 圖片寬度（像素，預設 **1200**）
11. **預覽圖高度** - 圖片高度（像素，預設 **630**）

> **尺寸預設值已從 300×300 改為 1200×630（2026-08-05）。** Facebook／LINE／X 的大圖卡
> 以 1.91:1 為準，低於 600×315 會退化成小圖卡甚至不顯示。300×300 是舊建議，
> 照著填會讓分享效果比不填還差。實際尺寸要以圖檔真實尺寸為準，別填一個和圖不符的數字。

### Google Analytics 資訊（2項，可選）
12. **GA 追蹤 ID** - Google Analytics 追蹤代碼 ID（例如：G-XXXXXXXXXX）
13. **完整 GA Script** - 或者提供完整的 Google Analytics script 代碼

> **注意**：GA 資訊為可選項，如果使用者未提供則僅加入 SEO 標籤。

## 標籤結構

### Part 1: SEO Meta 標籤

#### 1. 基本 SEO 標籤
```html
<!-- SEO Meta Tags -->
<title>{頁籤標題}</title>
<meta name="keywords" content="{搜尋關鍵字}">
<meta name="description" content="{分享描述文}">
```

> **`keywords` 對 Google 沒有作用**——2009 年就公開宣布不採用。保留是因為部分客戶
> 會逐項檢查、部分內部系統仍在讀它。放著無害，但**不要拿它當「已做 SEO」的交付證據**，
> 真正有影響的是 `title` 與 `description`。

#### 2. Open Graph 標籤（基本）
```html
<meta property="og:title" content="{分享預覽標題}" />
<meta property="og:description" content="{分享描述文}" />
<meta property="og:url" content="{網址}" />
<meta property="og:image" content="{預覽圖網址}" />
<meta property="og:locale" content="zh_TW" />
<meta property="og:type" content="website" />
<meta property="og:site_name" content="{網站名稱}" />
```

#### 3. 作者與版權資訊
```html
<meta name="author" content="{作者名稱}">
<meta name="copyright" content="{版權所有者}">
```

#### 4. X / Twitter 卡片
```html
<meta name="twitter:card" content="summary_large_image">
```

只需要這一行。X 找不到 `twitter:*` 時會自動退回讀 `og:*`，標題／描述／圖片都不必重寫；
`twitter:card` 沒有 OG 對應欄位，所以必須明寫，它決定卡片是大圖還是小圖。

> **已移除的標籤（2026-08-05）**：本節原本教人加 `<link rel="author">` 與
> `<link rel="publisher">`。那是 Google+ 時代的 authorship markup，隨 Google+ 於 2019 年
> 一併停用，現在只是無效字元。原本的 `itemprop` microdata 也移除了——同樣的資訊用
> JSON-LD 表達更穩且是 Google 明示偏好的格式，需要結構化資料請用 `site-seo`。

#### 5. Open Graph 圖片詳細資訊
```html
<meta property="og:image:secure_url" content="{預覽圖網址}" />
<meta property="og:image:type" content="image/png" />
<meta property="og:image:width" content="{預覽圖寬度}" />
<meta property="og:image:height" content="{預覽圖高度}" />
```

### Part 2: Google Analytics 追蹤代碼

GA 代碼應加在 `</head>` 標籤之前，在所有其他 `<script>` 標籤之後。

#### 方式 1：使用 GA 追蹤 ID（推薦）
如果使用者提供 GA ID（例如：`G-ABCD123456`），使用以下格式：

```html
<!-- write your code here -->
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id={GA_ID}"></script>
<script>
	window.dataLayer = window.dataLayer || [];
	function gtag() { dataLayer.push(arguments); }
	gtag('js', new Date());

	gtag('config', '{GA_ID}');
</script>
</head>
```

#### 方式 2：使用完整 GA Script
如果使用者提供完整的 GA script 代碼，直接插入：

```html
<!-- write your code here -->
{使用者提供的完整 GA Script}
</head>
```

## 標籤放置位置

### SEO Meta 標籤位置
放在 `<head>` 區段的最前面，緊接在基本 meta 標籤（charset, viewport）之後：

```html
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<!-- ↓ SEO 標籤從這裡開始 ↓ -->
	<title>...</title>
	<meta property="og:title" content="..." />
	...
```

### GA 追蹤代碼位置
放在 `</head>` 結束標籤之前，在所有其他內容之後：

```html
	</script>
	<!-- write your code here -->
	<!-- ↓ GA 代碼放這裡 ↓ -->
	<!-- Google tag (gtag.js) -->
	<script async src="..."></script>
	<script>...</script>
</head>
```

## GA 代碼識別與處理

### 自動識別 GA ID 格式
- **GA4 格式**：`G-XXXXXXXXXX`（10 個字符）
- **Universal Analytics**：`UA-XXXXXXXX-X`
- **Google Tag Manager**：`GTM-XXXXXXX`

如果使用者只提供 ID（沒有完整 script），自動套用標準 gtag.js 格式。

### 檢查現有 GA 代碼
在加入 GA 代碼前，檢查 HTML 文件中是否已存在：
- 如果已有 GA 代碼，詢問是否要替換
- 搜尋關鍵字：`gtag.js`、`analytics.js`、`ga(`、`dataLayer`

## 執行流程

1. **檢查 SEO 資訊完整性** - 檢查必要資訊（1-6）是否完整，若缺漏主動詢問
2. **詢問進階資訊** - 詢問是否需要作者、版權等進階資訊（7-11），提供預設值建議
3. **處理 GA 資訊** - 檢查是否提供 GA ID 或完整 GA script，驗證格式並生成代碼
4. **讀取目標 HTML 文件** - 檢查是否已存在 GA 代碼，確認插入位置
5. **加入 SEO 標籤** - 在 `<head>` 區段適當位置加入，使用 `<!-- SEO Meta Tags -->` 標記
6. **加入 GA 代碼（如果有）** - 在 `</head>` 之前加入，使用 `<!-- Google tag (gtag.js) -->` 標記
7. **驗證與儲存** - 根據圖片副檔名自動設定 `og:image:type`，確認格式正確
8. **完成報告** - 列出已加入的 SEO 標籤項目、GA 代碼資訊，提供測試建議

## 注意事項

1. **SEO 資訊缺漏提醒** - 如果缺少必要資訊（1-6 項），主動詢問：「請提供以下 SEO 資訊：頁籤標題、分享預覽標題、搜尋關鍵字、網址、預覽圖網址、分享描述文」
2. **進階資訊詢問** - 如果未提供進階資訊（7-11 項），詢問：「是否需要加入作者與版權資訊？預覽圖尺寸為何？（建議 1200x630）」
3. **GA 資訊處理** - GA 為可選項；提供 GA ID 時自動產生標準 gtag.js 格式；提供完整 script 時先檢查格式正確性
4. **圖片格式自動判斷** - 根據副檔名設定 `og:image:type`：`.png` → `image/png`、`.jpg`/`.jpeg` → `image/jpeg`、`.webp` → `image/webp`、`.gif` → `image/gif`
5. **關鍵字格式化** - 接受逗號、頓號或中文頓號分隔，自動轉換為英文逗號分隔格式
6. **GA ID 驗證** - 檢查 GA ID 格式是否正確（G-、UA-、GTM- 開頭），格式不正確時警告並詢問是否繼續
7. **現有 GA 代碼處理** - 如果文件中已有 GA 代碼，詢問：「檢測到文件中已有 Google Analytics 代碼（ID: XXX），是否要替換為新的代碼（ID: YYY）？」

## Additional Resources

### Reference Files

For detailed input/output examples, consult:
- **`references/examples.md`** - 包含教育類網站、純 SEO（無 GA）、完整 GA Script 等完整範例
