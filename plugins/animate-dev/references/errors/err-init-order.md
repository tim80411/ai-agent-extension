# ERR-INIT-ORDER: Initialization Order Issues

## Quick Summary
Frame control methods called before component is added to display list.

## Symptoms
- "Cannot read property 'gotoAndStop' of undefined"
- Component not responding after creation
- 元件沒反應、初始化順序錯誤
- Intermittent failures on component setup

## Detection
### Grep Patterns
- `gotoAndStop\(` followed by `addChild\(` (wrong order)
- `new lib\.` followed immediately by `.gotoAndStop` without `addChild` in between

### Code Pattern (Wrong)
```javascript
var component = new lib.MyComponent();
component.gotoAndStop(0);  // ERROR: not on display list yet
parent.addChild(component);
```

## Fix Strategy
### Option A: Reorder calls
```javascript
var component = new lib.MyComponent();
parent.addChild(component);  // Add to display list FIRST
component.gotoAndStop(0);    // THEN control frames
```

### Option B: With existence check
```javascript
var component = new lib.MyComponent();
parent.addChild(component);
if (component && component.gotoAndStop) {
    component.gotoAndStop(0);
}
```

## Verification
- Ensure all `addChild()` calls appear before `gotoAndStop()` calls
- No errors in console on component creation
- Component displays correct initial state
