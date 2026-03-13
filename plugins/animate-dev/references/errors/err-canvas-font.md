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

## Verification
- All `new cjs.Text()` font names match `@font-face` font-family
- Test on touch devices (tablet/phone) to verify font rendering
- `buildNewFont` applied in scene init, not in Animate export files
