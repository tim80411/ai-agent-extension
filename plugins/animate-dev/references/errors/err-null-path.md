# ERR-NULL-PATH: Null Path References

## Quick Summary
Accessing nested component properties without null checks, causing runtime errors.

## Symptoms
- "Cannot read property 'item_1' of undefined"
- 路徑錯誤、元件路徑無效
- Nested component not found
- Runtime errors on deep property access

## Detection
### Grep Patterns
- Deep property chains: `_this\.\w+\.\w+\.\w+` without null checks
- `\.\w+\.gotoAndStop` without preceding if check
- Missing optional chaining or guard clauses

### Code Pattern (Wrong)
```javascript
_this.mapView.item_1.gotoAndStop(0);
// Error if mapView or item_1 doesn't exist
```

## Fix Strategy
### Option A: Guard clauses
```javascript
if (_this.mapView && _this.mapView.item_1) {
    _this.mapView.item_1.gotoAndStop(0);
} else {
    console.warn("Component path invalid: _this.mapView.item_1");
}
```

### Option B: Optional chaining (ES2020+)
```javascript
_this.mapView?.item_1?.gotoAndStop(0);
```

## Verification
- All deep property chains have null/undefined checks
- No "Cannot read property of undefined" errors in console
- Graceful handling when components don't exist
