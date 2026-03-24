# add-seo-ga 完整範例

## 範例 1：咖啡廳網站 + GA ID

### 輸入資訊
```
頁籤標題: 森日咖啡 Mori Coffee
分享預覽標題: 森日咖啡—手沖精品咖啡專門店
搜尋關鍵字: 精品咖啡、手沖咖啡、咖啡廳、輕食、甜點
網址: https://mori-coffee.example.com
預覽圖網址: https://mori-coffee.example.com/assets/preview.png
分享描述文: 隱身巷弄的手沖精品咖啡專門店，嚴選世界各地莊園豆，搭配自製甜點與輕食，提供舒適的閱讀與工作空間。
作者名稱: 森日咖啡
版權所有者: 森日咖啡有限公司
網站名稱: 森日咖啡 Mori Coffee
預覽圖寬度: 300
預覽圖高度: 300
GA 追蹤 ID: G-ABC123XYZ
```

### 預期輸出（在 `<head>` 中加入）

```html
<!-- SEO Meta Tags -->
<title>森日咖啡 Mori Coffee</title>
<meta name="keywords" content="精品咖啡, 手沖咖啡, 咖啡廳, 輕食, 甜點">
<meta name="description" content="隱身巷弄的手沖精品咖啡專門店，嚴選世界各地莊園豆，搭配自製甜點與輕食，提供舒適的閱讀與工作空間。">
<meta property="og:title" content="森日咖啡—手沖精品咖啡專門店" />
<meta property="og:description" content="隱身巷弄的手沖精品咖啡專門店，嚴選世界各地莊園豆，搭配自製甜點與輕食，提供舒適的閱讀與工作空間。" />
<meta property="og:url" content="https://mori-coffee.example.com" />
<meta property="og:image" content="https://mori-coffee.example.com/assets/preview.png" />
<meta property="og:locale" content="zh_TW" />
<meta property="og:type" content="website" />
<meta property="og:site_name" content="森日咖啡 Mori Coffee" />
<meta name="author" content="森日咖啡">
<meta name="copyright" content="森日咖啡有限公司">
<link rel="author" href="森日咖啡">
<link rel="publisher" href="森日咖啡">
<meta itemprop="name" content="森日咖啡—手沖精品咖啡專門店">
<meta itemprop="image" content="https://mori-coffee.example.com/assets/preview.png">
<meta itemprop="description" content="隱身巷弄的手沖精品咖啡專門店，嚴選世界各地莊園豆，搭配自製甜點與輕食，提供舒適的閱讀與工作空間。">
<meta property="og:image:secure_url" content="https://mori-coffee.example.com/assets/preview.png" />
<meta property="og:image:type" content="image/png" />
<meta property="og:image:width" content="300" />
<meta property="og:image:height" content="300" />

<!-- ... 其他既有的 script 標籤 ... -->

<!-- write your code here -->
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-ABC123XYZ"></script>
<script>
	window.dataLayer = window.dataLayer || [];
	function gtag() { dataLayer.push(arguments); }
	gtag('js', new Date());

	gtag('config', 'G-ABC123XYZ');
</script>
</head>
```

## 範例 2：只加入 SEO，不加 GA

### 輸入資訊
```
頁籤標題: 光旅攝影 Hikari Photo
分享預覽標題: 光旅攝影—用鏡頭記錄旅途中的光影
搜尋關鍵字: 旅行攝影、風景攝影、攝影作品集、攝影師
網址: https://hikari-photo.example.com
預覽圖網址: https://hikari-photo.example.com/images/cover.jpg
分享描述文: 走過世界各地，用鏡頭捕捉旅途中的光影與故事。從城市街景到自然風光，每張照片都是一段旅程的記憶。
作者名稱: 光旅攝影工作室
版權所有者: 光旅攝影工作室
網站名稱: 光旅攝影
（未提供 GA 資訊）
```

### 預期輸出（在 `<head>` 中加入）

```html
<!-- SEO Meta Tags -->
<title>光旅攝影 Hikari Photo</title>
<meta name="keywords" content="旅行攝影, 風景攝影, 攝影作品集, 攝影師">
<meta name="description" content="走過世界各地，用鏡頭捕捉旅途中的光影與故事。從城市街景到自然風光，每張照片都是一段旅程的記憶。">
<meta property="og:title" content="光旅攝影—用鏡頭記錄旅途中的光影" />
<meta property="og:description" content="走過世界各地，用鏡頭捕捉旅途中的光影與故事。從城市街景到自然風光，每張照片都是一段旅程的記憶。" />
<meta property="og:url" content="https://hikari-photo.example.com" />
<meta property="og:image" content="https://hikari-photo.example.com/images/cover.jpg" />
<meta property="og:locale" content="zh_TW" />
<meta property="og:type" content="website" />
<meta property="og:site_name" content="光旅攝影" />
<meta name="author" content="光旅攝影工作室">
<meta name="copyright" content="光旅攝影工作室">
<link rel="author" href="光旅攝影工作室">
<link rel="publisher" href="光旅攝影工作室">
<meta itemprop="name" content="光旅攝影—用鏡頭記錄旅途中的光影">
<meta itemprop="image" content="https://hikari-photo.example.com/images/cover.jpg">
<meta itemprop="description" content="走過世界各地，用鏡頭捕捉旅途中的光影與故事。從城市街景到自然風光，每張照片都是一段旅程的記憶。">
<meta property="og:image:secure_url" content="https://hikari-photo.example.com/images/cover.jpg" />
<meta property="og:image:type" content="image/jpeg" />
<meta property="og:image:width" content="300" />
<meta property="og:image:height" content="300" />
</head>
```

> **注意**：此範例不包含 GA 代碼，僅加入 SEO 標籤。圖片副檔名為 `.jpg`，`og:image:type` 自動設為 `image/jpeg`。

## 範例 3：使用完整 GA Script

### 輸入資訊
```
頁籤標題: 企業解決方案
分享預覽標題: 創新企業解決方案平台
搜尋關鍵字: 企業管理、解決方案、數位轉型、商業工具
網址: https://business-solution.com
預覽圖網址: https://business-solution.com/og-image.png
分享描述文: 提供完整的企業數位解決方案，協助企業提升效率，達成數位轉型目標。
作者名稱: XX科技股份有限公司
版權所有者: XX科技股份有限公司
網站名稱: XX科技
預覽圖寬度: 1200
預覽圖高度: 630
完整 GA Script:
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-CUSTOM123"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-CUSTOM123');
  gtag('config', 'AW-123456789'); // 額外的轉換追蹤
</script>
```

### 預期輸出（在 `<head>` 中加入）

```html
<!-- SEO Meta Tags -->
<title>企業解決方案</title>
<meta name="keywords" content="企業管理, 解決方案, 數位轉型, 商業工具">
<meta name="description" content="提供完整的企業數位解決方案，協助企業提升效率，達成數位轉型目標。">
<meta property="og:title" content="創新企業解決方案平台" />
<meta property="og:description" content="提供完整的企業數位解決方案，協助企業提升效率，達成數位轉型目標。" />
<meta property="og:url" content="https://business-solution.com" />
<meta property="og:image" content="https://business-solution.com/og-image.png" />
<meta property="og:locale" content="zh_TW" />
<meta property="og:type" content="website" />
<meta property="og:site_name" content="XX科技" />
<meta name="author" content="XX科技股份有限公司">
<meta name="copyright" content="XX科技股份有限公司">
<link rel="author" href="XX科技股份有限公司">
<link rel="publisher" href="XX科技股份有限公司">
<meta itemprop="name" content="創新企業解決方案平台">
<meta itemprop="image" content="https://business-solution.com/og-image.png">
<meta itemprop="description" content="提供完整的企業數位解決方案，協助企業提升效率，達成數位轉型目標。">
<meta property="og:image:secure_url" content="https://business-solution.com/og-image.png" />
<meta property="og:image:type" content="image/png" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />

<!-- ... 其他既有的 script 標籤 ... -->

<!-- write your code here -->
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-CUSTOM123"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-CUSTOM123');
  gtag('config', 'AW-123456789'); // 額外的轉換追蹤
</script>
</head>
```

> **注意**：此範例使用者提供了完整的 GA Script（包含額外的轉換追蹤 `AW-123456789`），直接使用而非自動產生。預覽圖尺寸使用非預設值 1200x630（適合 Facebook 分享）。
