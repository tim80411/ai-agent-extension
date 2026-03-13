# ERR-SCOPE-LOSS: Scope Loss in Event Handlers

## Quick Summary
`this` keyword inside event callbacks refers to wrong context, causing undefined errors.

## Symptoms
- "this.handleClick is not a function"
- Wrong `this` context in callbacks
- Variables not accessible inside event handler
- 回調函數中 this 指向錯誤

## Detection
### Grep Patterns
- `addEventListener.*function\s*\(` with `this\.` inside callback body
- `\.on\(.*function\s*\(` with `this\.` inside callback body
- Missing `var self = this` before event binding

### Code Pattern (Wrong)
```javascript
component.addEventListener("click", function(e) {
    this.handleClick(e);  // 'this' is event target, not outer scope!
});
```

## Fix Strategy
### Option A: Preserve scope with variable
```javascript
var self = this;
component.addEventListener("click", function(e) {
    self.handleClick(e);  // Correct: uses preserved scope
});
```

### Option B: Use .on() with scope parameter
```javascript
component.on("click", this.handleClick, this);  // Cleaner CreateJS pattern
```

## Verification
- All event handlers use `var self = this` or `.on(event, handler, scope)`
- No "is not a function" errors in console during interactions
