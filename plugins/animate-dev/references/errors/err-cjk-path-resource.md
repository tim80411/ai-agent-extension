# ERR-CJK-PATH-RESOURCE: CJK/中文路徑導致 iPad Safari 資源載入失敗

## Quick Summary
資源檔案（音效、圖片、字體）的路徑或檔名包含中文/CJK 字元時，在 iPad Safari 上可能因 URL 編碼差異導致載入失敗（404），而在 Chrome/桌面瀏覽器上正常。

## Symptoms
- 音效在 iPad Safari 無法播放，但桌面 Chrome 正常
- 圖片在 iPad Safari 顯示不出來
- 字體在 iPad Safari 無法載入
- Console 出現 404 錯誤，路徑含中文字元
- `createjs.Sound.registerSound` 載入失敗
- `createjs.LoadQueue` manifest 載入部分資源失敗
- 開發電腦上完全正常，部署到 iPad 才發現問題

## Root Cause

### 1. Safari URL 百分號編碼行為差異
Safari 的 URL 解析器對路徑中的非 ASCII 字元（包括中文）的百分號編碼（percent-encoding）行為，歷史上與 Chrome/Firefox 不一致。Chrome/Firefox 會自動將路徑中的中文字元轉換為 `%E4%B8%AD` 等形式，Safari 的處理可能不同，導致伺服器無法匹配到正確的檔案。

**參考**: [WebKit URL Parsing Blog](https://webkit.org/blog/7086/url-parsing-in-webkit/)

### 2. Safari CSS 字元編碼預設為 ISO-8859-1
Safari 對 CSS 檔案的預設字元編碼可能使用 ISO-8859-1（而非 UTF-8），導致 CSS 中 `url()` 引用含中文路徑的資源時被錯誤解析。

**參考**: [W3C - Declaring character encodings in CSS](https://www.w3.org/International/questions/qa-css-charset)

### 3. iOS WKWebView 中文 Bundle 路徑 Bug
若 App 的 Bundle 路徑包含中文字元，WKWebView 無法正確載入本地資源（iOS 14+ 已確認）。

**參考**: [WebKit Bug #291833](https://bugs.webkit.org/show_bug.cgi?id=291833)

### 4. 雙重百分號編碼（Double Percent-Encoding）
若程式碼中已對 URL 做過 `encodeURI()`，iOS Safari 可能再次編碼，導致 `%E4` 變成 `%25E4`，伺服器完全無法解析。

**參考**: [Zulip Mobile Issue #4136](https://github.com/zulip/zulip-mobile/issues/4136)

## Detection

### Grep Patterns
```
# 音效路徑含中文
src:.*sounds/[\x{4e00}-\x{9fff}]
registerSound.*[\x{4e00}-\x{9fff}]

# 圖片路徑含中文
src:.*images/[\x{4e00}-\x{9fff}]
manifest.*[\x{4e00}-\x{9fff}]

# CSS @font-face 路徑含中文
url\(.*[\x{4e00}-\x{9fff}]
```

### Code Pattern (Wrong)
```javascript
// ❌ 音效檔名使用中文
const MUSIC_TO_LOAD = [
  { src: "./sounds/收集成功.mp3", id: "collect" },
  { src: "./sounds/蓋印章.mp3", id: "stamp" },
  { src: "./sounds/電子鎖_按鍵聲.mp3", id: "lock" },
  { src: "./sounds/滑鼠點擊.mp3", id: "click" },
];
```

```javascript
// ❌ Animate 匯出的 manifest 中圖片檔名使用中文
manifest: [
  {src: "images/欄杆_.png", id: "欄杆"},
]
```

```css
/* ❌ CSS @font-face 未指定 charset，且路徑可能含中文 */
@font-face {
  font-family: 'MyCustomFont';
  src: url('./font/華康字體.TTC') format('truetype')
}
```

## Fix Strategy

### 方法一：將所有資源檔名改為 ASCII（推薦）

**這是最安全、最徹底的做法。**

1. 將所有含中文的檔案重新命名為英文：

```
sounds/收集成功.mp3      → sounds/collect-success.mp3
sounds/蓋印章.mp3        → sounds/stamp.mp3
sounds/電子鎖_按鍵聲.mp3 → sounds/electronic-lock-key.mp3
sounds/滑鼠點擊.mp3      → sounds/mouse-click.mp3
sounds/櫃子解鎖.mp3      → sounds/cabinet-unlock.mp3
sounds/鎖住.mp3          → sounds/locked.mp3
sounds/吃東西.mp3        → sounds/eat.mp3
sounds/switch鍵.mp3      → sounds/switch-key.mp3
images/欄杆_.png         → images/railing.png
```

2. 更新程式碼中的引用：

```javascript
// ✅ 所有路徑使用 ASCII
const MUSIC_TO_LOAD = [
  { src: "./sounds/BGM.mp3", id: "BGM" },
  { src: "./sounds/collect-success.mp3", id: "collect" },
  { src: "./sounds/stamp.mp3", id: "stamp" },
  { src: "./sounds/electronic-lock-key.mp3", id: "lock" },
  { src: "./sounds/mouse-click.mp3", id: "click" },
  { src: "./sounds/switch-key.mp3", id: "switch" },
  { src: "./sounds/cabinet-unlock.mp3", id: "unlock" },
  { src: "./sounds/locked.mp3", id: "locked" },
  { src: "./sounds/eat.mp3", id: "eat" },
];
```

3. **注意 Animate 匯出的 index.js**：若 manifest 中包含中文檔名（如 `欄杆_.png`），需在 Adobe Animate 中修改素材名稱後重新發布，或手動修改 `index.js` 中的 manifest（但重新發布會覆蓋）。

### 方法二：對中文路徑做百分號編碼

若無法修改檔名，可在程式碼中手動編碼：

```javascript
// ✅ 對含中文的路徑做 encodeURI
const MUSIC_TO_LOAD = [
  { src: encodeURI("./sounds/收集成功.mp3"), id: "collect" },
  { src: encodeURI("./sounds/蓋印章.mp3"), id: "stamp" },
];
```

**注意**：使用 `encodeURI()` 而非 `encodeURIComponent()`，前者不會編碼 `/` 和 `.`。且確保不要對已編碼的 URL 再次編碼（避免雙重編碼）。

### 方法三：CSS @font-face 加上 charset 聲明

```html
<style>
  /* ✅ 明確指定 UTF-8 */
  @charset "utf-8";

  @font-face {
    font-family: 'MyCustomFont';
    src: url('./font/DFGB5ZY7.TTC') format('truetype');
  }
</style>
```

或透過 HTTP 標頭：
```
Content-Type: text/css; charset=utf-8
```

## Animate 專案特殊注意事項

### Manifest 中的中文檔名
Adobe Animate 匯出的 `index.js` 會自動產生 `manifest` 陣列。如果 Animate 專案中的素材使用中文命名，匯出的 manifest 也會包含中文路徑：

```javascript
// index.js（自動產生，不應手動修改）
manifest: [
  {src: "images/欄杆_.png", id: "欄杆"},
]
```

**最佳做法**：在 Adobe Animate 的「庫」面板中，將素材名稱改為英文，然後重新發布。這樣 manifest 中的路徑和 id 都會是 ASCII。

### CreateJS LoadQueue 的 URI 處理
`createjs.LoadQueue` 內部會對路徑做處理，但不保證在所有瀏覽器上對中文路徑的處理一致。使用 ASCII 路徑可完全避免此問題。

### CreateJS Sound.registerSound 的路徑
`createjs.Sound.registerSound(src, id)` 的 `src` 參數如果包含中文，iPad Safari 的 WebAudioPlugin 或 HTMLAudioPlugin 可能無法正確解析路徑。

## Verification
- [ ] 所有音效檔名為 ASCII
- [ ] 所有圖片檔名為 ASCII
- [ ] 所有字體檔名為 ASCII
- [ ] CSS 中有 `@charset "utf-8"` 或 HTTP 標頭指定 charset
- [ ] 程式碼中無對已編碼 URL 的重複 `encodeURI()` 呼叫
- [ ] **在 iPad Safari 上實際測試所有資源載入**
- [ ] Animate 匯出的 manifest 中無中文路徑
- [ ] Console 無 404 錯誤

## Related
- [ERR-CANVAS-FONT](./err-canvas-font.md) — 字體名稱不匹配導致觸屏裝置字體不顯示
- [PERF-RESOURCE-MANAGEMENT](./perf-resource-management.md) — 資源管理最佳實踐
