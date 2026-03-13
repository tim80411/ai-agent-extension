# PERF-MISSING-CACHE: Missing Cache on Static Content

## Quick Summary
Complex vector graphics redrawn every frame instead of being cached as bitmaps.

## Symptoms
- Complex static graphics render slowly
- 複雜圖形卡頓
- Vector redraw every frame
- 每幀重繪靜態內容

## Detection
### Grep Patterns
- Complex `graphics` operations (`beginFill`, `drawRect`, `drawCircle`) without `.cache(`
- `new createjs\.Shape\(\)` with complex drawing but no cache
- Static shapes that never change content

### Code Pattern (Wrong)
```javascript
function createComplexGraphic() {
    var shape = new createjs.Shape();
    var g = shape.graphics;
    g.beginFill("#FF0000");
    for (var i = 0; i < 100; i++) {
        g.drawRect(i * 10, i * 10, 10, 10);
    }
    g.endFill();
    // No caching - redraws all 100 rects every frame
    return shape;
}
```

## Fix Strategy
### Cache as bitmap
```javascript
function createComplexGraphic() {
    var shape = new createjs.Shape();
    var g = shape.graphics;
    g.beginFill("#FF0000");
    for (var i = 0; i < 100; i++) {
        g.drawRect(i * 10, i * 10, 10, 10);
    }
    g.endFill();
    shape.cache(0, 0, 1000, 1000);  // Cache as bitmap
    return shape;
}
```

### Update cache only when content changes
```javascript
function updateBackground(bg, newColor) {
    bg.uncache();
    var g = bg.graphics;
    g.clear();
    g.beginFill(newColor);
    // ... redraw
    g.endFill();
    bg.cache(0, 0, 1000, 1000);  // Re-cache
}
```

## Verification
- Complex static graphics have `.cache()` applied
- Cache updated only when content changes (`.uncache()` then `.cache()`)
- Rendering performance improved for complex shapes
