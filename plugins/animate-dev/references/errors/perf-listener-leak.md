# PERF-LISTENER-LEAK: Event Listener Memory Leak

## Quick Summary
Anonymous or untracked event listeners prevent garbage collection when components are removed.

## Symptoms
- Memory grows linearly with scene switches
- 記憶體洩漏、事件監聽器累積
- Application slows down over time
- Detached nodes in heap snapshot

## Detection
### Grep Patterns
- `addEventListener.*function\s*\(` — anonymous listeners (can't be removed)
- `removeChild\(` without `removeEventListener` or `removeAllEventListeners`
- State objects without listener reference storage

### Code Pattern (Wrong)
```javascript
scene.addEventListener("click", function(e) {
    handleSceneClick(e, scene);  // Anonymous - can't remove
});

function removeScene() {
    _this.removeChild(AppState.scene.instance);  // Listener still attached!
    AppState.scene.instance = null;
}
```

## Fix Strategy
### Store and clean up listener references
```javascript
// State: add listener storage
var AppState = {
    scene: {
        instance: null,
        clickListener: null  // Store reference
    }
};

// Bind: store reference
var clickListener = function(e) {
    self.handleSceneClick(e, scene);
};
AppState.scene.clickListener = clickListener;
scene.addEventListener("click", clickListener);

// Cleanup: remove before destroying
function removeScene() {
    if (AppState.scene.instance && AppState.scene.clickListener) {
        AppState.scene.instance.removeEventListener("click", AppState.scene.clickListener);
        AppState.scene.clickListener = null;
    }
    _this.removeChild(AppState.scene.instance);
    AppState.scene.instance = null;
}
```

## Verification
- DevTools Memory: heap doesn't grow after repeated scene switches
- Event listener count stays constant
- No detached DOM nodes accumulating
