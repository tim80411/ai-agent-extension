> **DEPRECATED**: 此檔案已被 `error-index.md` + `errors/` 取代。將在未來版本移除。

# Common Mistakes from Real Project Analysis

This reference documents common mistakes discovered from comparing error vs correct folder implementations in real Adobe Animate + CreateJS projects.

## Critical Error 1: Missing CreateJS Library

### Discovery
**Error folder**: `project/js`
- Contains: `main.js` only

**Correct folder**: `project-fixed/js`
- Contains: `createjs-2015.11.26.min.js` AND `main.js`

### Impact
Adobe Animate exports HTML5 Canvas projects that depend on CreateJS library. Without this library:
- All CreateJS namespace references fail (`createjs.MovieClip`, `createjs.Ticker`, etc.)
- Exported `main.js` code cannot execute
- Runtime errors: "createjs is not defined"

### Prevention
Always verify CreateJS library exists before deploying:

```bash
# Check for CreateJS library
ls js/createjs*.min.js

# Or check in HTML
grep -i "createjs" index.html
```

### Fix
Include CreateJS library from:
1. Adobe Animate export (check "Include CreateJS" in publish settings)
2. CDN: `https://code.createjs.com/1.0.0/createjs.min.js`
3. Local copy from previous export

### Verification
```javascript
// In browser console or init code
if (typeof createjs === 'undefined') {
    console.error('CRITICAL: CreateJS library not loaded!');
    alert('Application failed to load required libraries.');
}
```

## Error Pattern 2: Initialization Order Issues

### Common Anti-Pattern
```javascript
// WRONG - Frame control before adding to stage
var component = new lib.MyComponent();
component.gotoAndStop(0);  // Error: component not on display list yet
parent.addChild(component);
```

### Why This Fails
- MovieClip frame methods require component to be on display list
- Throws: "Cannot read property 'gotoAndStop' of undefined" or similar
- Timing issue causes intermittent failures

### Correct Pattern
```javascript
// RIGHT - Add to stage first
var component = new lib.MyComponent();
parent.addChild(component);  // Add to display list FIRST
component.gotoAndStop(0);    // THEN control frames
```

### Additional Safe Pattern
```javascript
// With existence check
var component = new lib.MyComponent();
parent.addChild(component);

if (component && component.gotoAndStop) {
    component.gotoAndStop(0);
}
```

## Error Pattern 3: Scope Loss in Event Handlers

### Common Anti-Pattern
```javascript
function setupComponent() {
    var component = new lib.Button();
    parent.addChild(component);

    component.addEventListener("click", function(e) {
        this.handleClick(e);  // ERROR: 'this' is wrong context!
    });
}
```

### Why This Fails
- Inside event callback, `this` refers to the event target, not outer scope
- Results in: "this.handleClick is not a function"
- Common mistake when coming from other frameworks

### Correct Pattern
```javascript
function setupComponent() {
    var self = this;  // Preserve scope
    var component = new lib.Button();
    parent.addChild(component);

    component.addEventListener("click", function(e) {
        self.handleClick(e);  // Correct: uses preserved scope
    });
}
```

### Alternative: Use .on() with Scope Parameter
```javascript
component.on("click", this.handleClick, this);  // Cleaner
```

## Error Pattern 4: Memory Leaks - Missing Event Cleanup

### Common Anti-Pattern
```javascript
function removeComponent(component) {
    parent.removeChild(component);  // INCOMPLETE - event listeners still attached
}
```

### Why This Fails
- Event listeners remain in memory
- Component cannot be garbage collected
- Accumulates memory over time in long-running applications

### Correct Pattern
```javascript
function removeComponent(component) {
    if (component) {
        // 1. Remove event listeners FIRST
        component.removeAllEventListeners();

        // 2. Remove from display list
        if (component.parent) {
            component.parent.removeChild(component);
        }

        // 3. Nullify reference
        component = null;
    }
}
```

### Module Pattern with Cleanup
```javascript
var MyModule = (function() {
    var components = [];

    function init() {
        // Create components
        var comp = new lib.Component();
        components.push(comp);
    }

    function cleanup() {
        components.forEach(function(comp) {
            if (comp) {
                comp.removeAllEventListeners();
                if (comp.parent) {
                    comp.parent.removeChild(comp);
                }
            }
        });
        components = [];
    }

    return {init: init, cleanup: cleanup};
})();
```

## Error Pattern 5: Frame States Not Paused

### Common Anti-Pattern
```javascript
// Component with frames representing states (idle, hover, active)
var button = new lib.ButtonComponent();
parent.addChild(button);
// MISSING: button.stop();
// Result: Button plays through all frames as animation
```

### Why This Fails
- MovieClips default to playing through timeline
- Frames intended as states animate continuously
- Unwanted visual glitches
- Performance impact from unnecessary rendering

### Correct Pattern
```javascript
// State-based component
var button = new lib.ButtonComponent();
parent.addChild(button);
button.stop();  // Pause on current state

// Or jump to specific state
button.gotoAndStop(0);  // Frame 0 = "idle" state
button.gotoAndStop("hover");  // Using frame label (preferred)
```

### When NOT to Stop
```javascript
// Animation-based component (frames = motion)
var character = new lib.WalkingCharacter();
parent.addChild(character);
character.gotoAndPlay(0);  // Let it animate
```

## Error Pattern 6: mouseChildren Not Set

### Common Anti-Pattern
```javascript
// Button with child graphics
var button = new lib.ComplexButton();
parent.addChild(button);

button.addEventListener("click", function(e) {
    console.log("Clicked:", e.target.name);
    // Problem: e.target might be child shape, not button itself
});
```

### Why This Fails
- Click events propagate through children
- Child shapes/text intercept clicks
- Event delegation breaks
- Inconsistent click behavior

### Correct Pattern for Buttons
```javascript
var button = new lib.ComplexButton();
parent.addChild(button);
button.mouseChildren = false;  // Treat as single click target

button.addEventListener("click", function(e) {
    console.log("Clicked:", e.target.name);  // Always the button
});
```

### When to Use mouseChildren = true
```javascript
// Container with multiple interactive children
var menu = new lib.MenuContainer();
parent.addChild(menu);
menu.mouseChildren = true;  // Allow child interaction

// Child buttons handle their own clicks
menu.optionButton1.addEventListener("click", handler1);
menu.optionButton2.addEventListener("click", handler2);
```

## Error Pattern 7: Timeline Frame Number Confusion

### Common Anti-Pattern
```javascript
// In Adobe Animate, placed code on "Frame 1" in timeline
// Expects it to run first
// But JavaScript uses 0-based indexing
// Code on Frame 1 might run unexpectedly
```

### Why This Fails
- Adobe Animate displays Frame 1 as first frame
- JavaScript internally uses Frame 0
- Code placement confusion
- Timing issues

### Correct Pattern
```javascript
// Use frame labels instead of numbers
this.gotoAndStop("init");     // Clear intent
this.gotoAndStop("gameStart"); // Descriptive
this.gotoAndStop("results");   // Maintainable

// Avoid magic numbers
// this.gotoAndStop(1);  // What is frame 1?
```

### Best Practice
In Adobe Animate timeline:
1. Add frame labels for key states
2. Reference labels in code, not numbers
3. Keep timeline code minimal
4. Move complex logic to external JS files

## Error Pattern 8: lib vs _lib Confusion

### Common Anti-Pattern
```javascript
// Early in initialization
var ComponentClass = lib.MyComponent;  // undefined!
var instance = new ComponentClass();   // Error
```

### Why This Fails
- `lib` may not be fully initialized yet
- Timing dependency on Adobe Animate export
- Intermittent failures

### Correct Pattern
```javascript
// For early access, use _lib
var ComponentClass = _lib["MyComponent"];
if (typeof ComponentClass !== 'undefined') {
    var instance = new ComponentClass();
}

// Or safe fallback
var ComponentClass = _lib["MyComponent"] || lib.MyComponent;
if (typeof ComponentClass !== 'undefined') {
    var instance = new ComponentClass();
}
```

## Error Pattern 9: Missing Stage Ticker

### Common Anti-Pattern
```javascript
var canvas = document.getElementById("canvas");
var stage = new createjs.Stage(canvas);
var exportRoot = new lib.MainTimeline();
stage.addChild(exportRoot);
// MISSING: Ticker setup
// Result: Nothing animates
```

### Why This Fails
- Stage requires ticker to update
- MovieClips don't advance frames
- Tweens don't play
- Application appears frozen

### Correct Pattern
```javascript
var canvas = document.getElementById("canvas");
var stage = new createjs.Stage(canvas);
var exportRoot = new lib.MainTimeline();
stage.addChild(exportRoot);

// Set up ticker
createjs.Ticker.framerate = 30;
createjs.Ticker.addEventListener("tick", stage);
```

## Error Pattern 10: Null Path References

### Common Anti-Pattern
```javascript
// Assuming nested structure exists
_this.mapView.item_1.gotoAndStop(0);
// Error: Cannot read property 'item_1' of undefined
```

### Why This Fails
- Component might not exist in export
- Path typo
- Component not added yet
- Runtime errors

### Correct Pattern
```javascript
// Validate path exists
if (_this.mapView && _this.mapView.item_1) {
    _this.mapView.item_1.gotoAndStop(0);
} else {
    console.warn("Component path invalid: _this.mapView.item_1");
}

// Or use optional chaining (ES2020+)
_this.mapView?.item_1?.gotoAndStop(0);
```

## Error Pattern 11: Canvas Text 自訂字體在觸屏裝置無法顯示

### Common Anti-Pattern
```javascript
// Adobe Animate 匯出的 index.js 中，Text 物件使用系統字體名稱
this.text_label = new cjs.Text("Hello", "bold 70px 'SystemFontName'", "#333333");
this.text_timer = new cjs.Text("00", "35px 'AnotherSystemFont'", "#FFFFFF");
```

```html
<!-- index.html 中用 @font-face 載入字體檔，但 font-family 名稱與 Animate 匯出的不同 -->
<style>
  @font-face {
    font-family: 'MyCustomFont';
    src: url('../fonts/CustomFont.ttc') format('collection');
  }
</style>
```

### Why This Fails
- Adobe Animate 匯出的 `index.js` 使用的是字體的**系統安裝名稱**（如 `'SystemFontName'`）
- CSS `@font-face` 載入字體檔時使用了**不同的 font-family 名稱**（如 `'MyCustomFont'`）
- **桌面電腦**：如果系統已安裝該字體，用系統名稱也能正常顯示
- **觸屏裝置（平板、手機）**：系統未安裝該字體，Canvas text 使用的系統名稱找不到字體，退回 fallback 字體
- 開發時在電腦上測試正常，部署到觸屏裝置才發現字體顯示錯誤

### Correct Pattern — buildNewFont 函數

在 JS function 中直接覆蓋 Canvas text 的 `.font` 屬性，使用與 `@font-face` 一致的 font-family 名稱。

**Step 1: 在 game.js 定義 buildNewFont 工具函數**
```javascript
function buildNewFont(object, newFontName) {
  var currentFontSize = object.font.match(/\d+px/)[0];
  var newFont = currentFontSize + " " + newFontName;
  return newFont;
}
```

**Step 2: 在場景初始化函數中覆蓋字體**
```javascript
// 取得 text 物件參考後，立即用 buildNewFont 覆蓋字體
// 'MyCustomFont' 必須與 @font-face 的 font-family 名稱一致
if (textLabel) {
  textLabel.font = buildNewFont(textLabel, "MyCustomFont");
}

if (timer.text_minutes) {
  timer.text_minutes.font = buildNewFont(timer.text_minutes, "MyCustomFont");
}
if (timer.text_seconds) {
  timer.text_seconds.font = buildNewFont(timer.text_seconds, "MyCustomFont");
}
```

### Key Points
1. **不要修改 `index.js`**（Animate 匯出檔），因為重新發布會覆蓋修改
2. **在 scene 初始化函數中覆蓋**，確保每次進入場景都套用正確字體
3. `buildNewFont` 會自動保留原本的字體大小（如 `70px`、`35px`），只替換字體名稱
4. `@font-face` 的 `font-family` 名稱與 `buildNewFont` 第二個參數必須完全一致

### Prevention
- 匯出 Animate 專案後，檢查 `index.js` 中所有 `new cjs.Text(...)` 使用的字體名稱
- 確認 `@font-face` 的 `font-family` 名稱是否與 canvas text 的字體名稱一致
- 若不一致，必須在 JS function 中用 `buildNewFont` 覆蓋
- **務必在觸屏裝置上測試字體顯示**

## Summary Checklist

Before deploying Adobe Animate + CreateJS project:

- [ ] CreateJS library file exists in js/ folder
- [ ] HTML includes CreateJS script tag
- [ ] All addChild() calls before gotoAndStop() calls
- [ ] All event handlers use scope preservation (`var self = this`)
- [ ] Cleanup methods remove event listeners before removeChild
- [ ] State-based MovieClips call .stop() after addChild
- [ ] Interactive buttons have mouseChildren = false
- [ ] Frame labels used instead of magic numbers
- [ ] Null checks on all MovieClip path references
- [ ] Stage ticker is set up
- [ ] lib/_lib usage appropriate for timing
- [ ] Canvas text 自訂字體使用 buildNewFont 覆蓋，確保與 @font-face 名稱一致

## Testing Checklist

After fixing issues:

- [ ] Test in browser console: `typeof createjs !== 'undefined'`
- [ ] Test in browser console: `typeof lib !== 'undefined'`
- [ ] Click all interactive elements - verify no errors
- [ ] Navigate through all scenes - check frame control
- [ ] Long-running session - monitor memory usage
- [ ] Mobile/touch devices - verify custom font rendering on canvas text
- [ ] Mobile devices - check performance
- [ ] Different browsers - verify compatibility

## Additional Resources

For more patterns and best practices, see:
- Main SKILL.md for comprehensive guidance
- `references/performance-patterns.md` for optimization
- `references/educational-patterns.md` for e-learning specific patterns
