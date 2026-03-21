# ERR-CANVAS-FONT: Canvas Text Custom Font Issues

## Quick Summary
Custom fonts in Canvas text don't display on touch devices because font-family names mismatch between Animate export and CSS @font-face.

## Symptoms
- 字體不顯示（觸屏裝置）
- Font shows on desktop but not mobile/tablet
- 平板字體錯誤
- Canvas text falls back to default font on touch devices

## Detection
### Grep Patterns
- `new cjs\.Text\(` with font string containing custom font names
- `@font-face` in HTML/CSS with different `font-family` name than JS
- Mismatch between Animate export font name and CSS font-family

### Code Pattern (Wrong)
```javascript
// index.js (Animate export) uses system font name
this.text_label = new cjs.Text("Hello", "bold 70px 'SystemFontName'", "#333333");
```
```html
<!-- CSS uses different font-family name -->
<style>
  @font-face {
    font-family: 'MyCustomFont';
    src: url('../fonts/CustomFont.ttc') format('collection');
  }
</style>
```

## Fix Strategy
### Use buildNewFont to override
**Step 1: Define utility function**
```javascript
function buildNewFont(object, newFontName) {
    var currentFontSize = object.font.match(/\d+px/)[0];
    var newFont = currentFontSize + " " + newFontName;
    return newFont;
}
```

**Step 2: Override in scene initialization**
```javascript
// 'MyCustomFont' must match @font-face font-family exactly
if (textLabel) {
    textLabel.font = buildNewFont(textLabel, "MyCustomFont");
}
```

### Key Points
1. Do NOT modify `index.js` (Animate export) — re-publish will overwrite
2. Override in scene init function
3. `buildNewFont` preserves original font size, replaces font name
4. `@font-face` font-family must exactly match `buildNewFont` second parameter

## iOS 18 CJK @font-face 加粗 Bug (WebKit Bug #283393)

### Symptoms
- iOS 18 上添加 `@font-face` 規則後，CJK（中日韓）字元意外變粗體
- 非 CJK 字元不受影響
- iOS 17 無此問題

### Root Cause
iOS 18 Safari 在存在 `@font-face` 規則時，可能為 CJK 字元選擇了不同的字型變體（如選到較粗的 weight），尤其在未指定 `lang` 屬性時更容易發生。

### Workaround
```html
<!-- ✅ 明確指定語言屬性 -->
<html lang="zh-TW">
```

```css
/* ✅ 明確指定 CJK 字型和 weight */
@font-face {
  font-family: 'MyCustomFont';
  src: url('./font/DFGB5ZY7.TTC') format('truetype');
  font-weight: normal;  /* 明確指定 */
}
```

對 Canvas text 而言，使用 `buildNewFont` 時可明確指定不含 bold 的字體字串：
```javascript
function buildNewFont(object, newFontName) {
    var currentFontSize = object.font.match(/\d+px/)[0];
    // 不帶 bold 前綴，避免 iOS 18 CJK 加粗問題
    var newFont = currentFontSize + " " + newFontName;
    return newFont;
}
```

**參考**: [WebKit Bug #283393](https://bugs.webkit.org/show_bug.cgi?id=283393) — Status: NEW, P2

## @font-face 路徑注意事項

字體檔案路徑不應包含中文字元，否則 iPad Safari 可能因 URL 編碼差異導致載入失敗。詳見 [ERR-CJK-PATH-RESOURCE](./err-cjk-path-resource.md)。

同時確保 CSS 中加上 `@charset "utf-8";` 聲明，因為 Safari 對 CSS 預設可能使用 ISO-8859-1 編碼。

## Verification
- All `new cjs.Text()` font names match `@font-face` font-family
- Test on touch devices (tablet/phone) to verify font rendering
- `buildNewFont` applied in scene init, not in Animate export files
- HTML 有 `lang="zh-TW"` 或適當的語言屬性
- 在 iOS 18 iPad 上確認 CJK 字元未異常加粗
- 字體檔案路徑為 ASCII（無中文字元）
