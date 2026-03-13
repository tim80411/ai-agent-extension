# PERF-EXCESSIVE-STAGE-UPDATE: Excessive stage.update() Calls

## Quick Summary
`stage.update()` called inside loops or multiple times in sequence, forcing redundant full canvas redraws.

## Symptoms
- Slow rendering
- 渲染慢、畫面閃爍
- Canvas redraws excessively
- stage.update 被呼叫過多次

## Detection
### Grep Patterns
- `stage\.update\(\)` inside `for\s*\(` loops
- Multiple `stage\.update\(\)` in same function
- `stage\.update\(\)` in frequently-called functions

### Code Pattern (Wrong)
```javascript
function updateAllMenus() {
    for (var i = 1; i <= 14; i++) {
        var menu = _this["menu_" + i];
        menu.x = calculatePosition(i);
        stage.update();  // Called 14 times! Full canvas redraw each time.
    }
}
```

## Fix Strategy
### Batch changes, update once
```javascript
function updateAllMenus() {
    for (var i = 1; i <= 14; i++) {
        var menu = _this["menu_" + i];
        menu.x = calculatePosition(i);
    }
    stage.update();  // Once after all changes
}
```

### For animations, use Ticker instead
```javascript
// Let Ticker handle regular updates
createjs.Ticker.addEventListener("tick", stage);
// Don't manually call stage.update() — Ticker does it
```

## Verification
- No `stage.update()` inside loops
- Changes batched before single update call
- Count `stage.update()` calls — should be minimal
