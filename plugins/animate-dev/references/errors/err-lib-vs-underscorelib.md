# ERR-LIB-VS-UNDERSCORELIB: lib vs _lib Confusion

## Quick Summary
Using `lib.Component` before it's fully initialized; `_lib` should be used for early access.

## Symptoms
- `lib.MyComponent` is undefined
- 元件找不到
- Intermittent failures during initialization
- 載入時機問題

## Detection
### Grep Patterns
- `var\s+\w+\s*=\s*lib\.` early in initialization code
- `new lib\.` without checking if defined
- Missing `_lib` usage in early-stage code

### Code Pattern (Wrong)
```javascript
// Early in initialization
var ComponentClass = lib.MyComponent;  // undefined!
var instance = new ComponentClass();   // Error
```

## Fix Strategy
### Option A: Use _lib for early access
```javascript
var ComponentClass = _lib["MyComponent"];
if (typeof ComponentClass !== 'undefined') {
    var instance = new ComponentClass();
}
```

### Option B: Safe fallback
```javascript
var ComponentClass = _lib["MyComponent"] || lib.MyComponent;
if (typeof ComponentClass !== 'undefined') {
    var instance = new ComponentClass();
}
```

## Verification
- Early initialization code uses `_lib` instead of `lib`
- All component class access has undefined check
- No intermittent "undefined" errors on startup
