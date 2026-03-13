# ERR-MOUSE-CHILDREN: mouseChildren Not Set

## Quick Summary
Button-like components don't set `mouseChildren = false`, causing child shapes to intercept clicks.

## Symptoms
- Click not responding on button
- 點擊沒反應、點到子元素
- `e.target` returns child shape instead of button
- Inconsistent click behavior

## Detection
### Grep Patterns
- `addEventListener\("click"` or `\.on\("click"` on compound components without `mouseChildren\s*=\s*false`
- Button components (btn_, button) missing mouseChildren setting

### Code Pattern (Wrong)
```javascript
var button = new lib.ComplexButton();
parent.addChild(button);
button.addEventListener("click", function(e) {
    console.log("Clicked:", e.target.name);
    // e.target might be child shape, not button itself
});
```

## Fix Strategy
### For buttons (single click target)
```javascript
var button = new lib.ComplexButton();
parent.addChild(button);
button.mouseChildren = false;  // Treat as single click target
button.addEventListener("click", function(e) {
    console.log("Clicked:", e.target.name);  // Always the button
});
```

### For containers with clickable children
```javascript
var menu = new lib.MenuContainer();
parent.addChild(menu);
menu.mouseChildren = true;  // Allow child interaction
menu.optionButton1.addEventListener("click", handler1);
menu.optionButton2.addEventListener("click", handler2);
```

## Verification
- All button-like components have `mouseChildren = false`
- Container components with multiple clickable children have `mouseChildren = true`
- Click events consistently target the expected element
