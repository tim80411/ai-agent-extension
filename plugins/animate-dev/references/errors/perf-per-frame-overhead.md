# PERF-PER-FRAME-OVERHEAD: Per-Frame Execution Overhead

## Quick Summary
Heavy loops or unnecessary logic running inside ticker/tick handlers at 60 FPS.

## Symptoms
- High CPU usage during idle
- CPU 過高、卡頓
- Janky animations
- Battery drain on mobile
- 每幀運算過多

## Detection
### Grep Patterns
- `Ticker\.addEventListener\("tick"` with loops inside handler
- `setInterval\(` with intervals < 500ms
- `for\s*\(` inside tick handler functions
- `setChildIndex` inside tick handlers

### Code Pattern (Wrong)
```javascript
createjs.Ticker.addEventListener("tick", function() {
    for (var i = 1; i <= 14; i++) {
        var menu = _this["menu_" + i];
        if (menu && _this.contains(menu)) {
            _this.setChildIndex(menu, _this.numChildren - 1);
        }
    }
    // 60 FPS x 14 iterations = 840 operations/second
});
```

## Fix Strategy
### Replace polling with event-driven approach
```javascript
// Only run when state actually changes
function bringMenuToTop(menuId) {
    var menu = _this["menu_" + menuId];
    if (menu && _this.contains(menu) && menu.visible) {
        _this.setChildIndex(menu, _this.numChildren - 1);
    }
}

// Call only on user interaction
function handleMenuBtn(id) {
    // ... show/hide logic ...
    if (_this["menu_" + id]) {
        _this["menu_" + id].visible = true;
        bringMenuToTop(id);  // Only when menu shown
    }
}

// Remove ticker handler entirely if no longer needed
```

**Performance calculation:**
```
Before: 840 operations/second (continuous)
After: 2-3 operations per user interaction
Reduction: 99.6%
```

## Verification
- No heavy loops inside tick handlers
- Operations per second calculated and justified
- Event-driven alternatives used where possible
- CPU idle usage is low
