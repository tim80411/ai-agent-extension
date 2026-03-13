# ERR-MISSING-CREATEJS: CreateJS Library Missing

## Quick Summary
Adobe Animate HTML5 Canvas project fails because CreateJS library file is not included.

## Symptoms
- Runtime error: "createjs is not defined"
- Nothing renders on canvas
- All CreateJS namespace references fail (`createjs.MovieClip`, `createjs.Ticker`)
- 什麼都沒顯示、載入失敗

## Detection
### Grep Patterns
- `createjs` in HTML files (check if script tag exists)
- `createjs*.min.js` in js/ folder (check if file exists)

### Code Pattern (Wrong)
```html
<!-- Missing CreateJS script tag -->
<script src="js/main.js"></script>
<!-- No createjs library loaded -->
```

## Fix Strategy
### Option A: Re-export from Animate
Check "Include CreateJS" in Adobe Animate publish settings and re-export.

### Option B: Add script tag manually
```html
<script src="js/createjs-2015.11.26.min.js"></script>
<script src="js/main.js"></script>
```

### Option C: CDN
```html
<script src="https://code.createjs.com/1.0.0/createjs.min.js"></script>
```

## Verification
```javascript
if (typeof createjs === 'undefined') {
    console.error('CRITICAL: CreateJS library not loaded!');
}
```
- Check js/ folder contains `createjs*.min.js`
- Check HTML includes CreateJS script tag before main.js
