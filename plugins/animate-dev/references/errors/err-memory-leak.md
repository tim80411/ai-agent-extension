# ERR-MEMORY-LEAK: Event Listener Memory Leak

## Quick Summary
Event listeners not removed before removing components, preventing garbage collection.

## Symptoms
- Memory usage grows over time
- Detached DOM nodes accumulating
- 記憶體持續增加
- Application slows down after extended use

## Detection
### Grep Patterns
- `removeChild\(` without preceding `removeAllEventListeners\(\)` or `removeEventListener\(`
- `addEventListener` without matching `removeEventListener`
- Missing cleanup/destroy functions

### Code Pattern (Wrong)
```javascript
function removeComponent(component) {
    parent.removeChild(component);  // Listeners still attached!
}
```

## Fix Strategy
### Option A: Full cleanup
```javascript
function removeComponent(component) {
    if (component) {
        component.removeAllEventListeners();  // Remove listeners FIRST
        if (component.parent) {
            component.parent.removeChild(component);
        }
        component = null;  // Nullify reference
    }
}
```

### Option B: Module pattern with tracked cleanup
```javascript
var MyModule = (function() {
    var components = [];

    function init() {
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

    return { init: init, cleanup: cleanup };
})();
```

## Verification
- DevTools Memory profiler: create/remove scene 10 times, heap should not grow
- Event listener count stays constant across scene switches
- No detached DOM nodes in heap snapshot
