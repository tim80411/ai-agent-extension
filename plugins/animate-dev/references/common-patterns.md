# Common Performance Anti-Patterns in Adobe Animate + CreateJS

This reference provides a comprehensive catalog of performance anti-patterns found in Adobe Animate and CreateJS projects, with detection strategies and impact assessment.

## 1. Event Listener Memory Leaks

### Pattern: Anonymous Function Listeners

**Anti-pattern:**
```javascript
function createScene(id) {
  var scene = new lib.scene_1();

  // ❌ Anonymous function - can't be removed later
  scene.addEventListener("click", function(e) {
    handleSceneClick(e, scene);
  });

  parent.addChild(scene);
  return scene;
}

function destroyScene(scene) {
  parent.removeChild(scene); // Listener still attached!
}
```

**Why it's bad:**
- Anonymous function has no reference for `removeEventListener`
- Scene object can't be garbage collected
- Closure holds references to `handleSceneClick` and potentially large scope
- Accumulates memory on repeated scene creation/removal

**Detection:**
- Search for `addEventListener` with `function(`
- Check if corresponding `removeEventListener` exists
- Look for dynamic object creation without cleanup

**Impact:** High - Memory grows linearly with scene switches

---

### Pattern: Missing Cleanup on Dynamic Objects

**Anti-pattern:**
```javascript
var AppState = {
  scene: {
    instance: null,
    currentId: null
    // ❌ No listener reference storage
  }
};

function bindSceneEvents(scene) {
  scene.addEventListener("click", handleClick);
  scene.addEventListener("mousemove", handleMove);
  // Multiple listeners, no tracking
}

function removeScene() {
  _this.removeChild(AppState.scene.instance);
  AppState.scene.instance = null;
  // ❌ Listeners not removed
}
```

**Why it's bad:**
- Multiple listeners compound the leak
- State object doesn't track what needs cleanup
- No systematic cleanup approach

**Detection:**
- Look for state objects managing dynamic instances
- Check if they store listener references
- Verify cleanup functions exist and are called

**Impact:** Critical - Multiple leaks per scene

---

## 2. Redundant Event Bindings

### Pattern: Initialization Without Guards

**Anti-pattern:**
```javascript
var WorldMap = {
  init: function(container) {
    var canvas = document.getElementById("canvas");

    // ❌ No check if already registered
    canvas.addEventListener("wheel", this.handleWheel);

    console.log("WorldMap initialized");
  },

  handleWheel: function(e) {
    // Zoom logic
  }
};

// User code
WorldMap.init(container1);  // First registration
// ... later, scene changes
WorldMap.init(container2);  // Second registration! Now fires twice
```

**Why it's bad:**
- Each `init()` call adds another listener
- Events fire multiple times
- Memory accumulates with duplicate handlers
- Debugging becomes confusing (why does zoom happen 3x?)

**Detection:**
- Search for `addEventListener` in init/register functions
- Check if function can be called multiple times
- Look for guard conditions (`if (this.handler) return`)

**Impact:** Medium-High - Event behavior becomes unpredictable

---

### Pattern: Scene Re-initialization

**Anti-pattern:**
```javascript
function initScene(scene) {
  scene.worldMapContainer.addEventListener("mousedown", startDrag);
  scene.worldMapContainer.addEventListener("pressmove", handleDrag);
  scene.worldMapContainer.addEventListener("pressup", stopDrag);
  // ❌ No cleanup when scene switches
}

// When switching between scenes
removeScene(oldScene);  // Listeners still registered
createScene(newScene);  // New listeners added
initScene(newScene);    // More listeners added
```

**Why it's bad:**
- Event handlers accumulate across scene switches
- Old scenes' handlers may still fire on new scenes
- Mouse events become sluggish with duplicate handlers

**Detection:**
- Check scene initialization called in creation
- Verify scene removal includes event cleanup
- Look for addEventListener without removeEventListener

**Impact:** High - Compounds with each scene switch

---

## 3. Excessive Per-Frame Execution

### Pattern: Ticker with Heavy Loops

**Anti-pattern:**
```javascript
createjs.Ticker.addEventListener("tick", function() {
  // ❌ Runs 60 times per second
  for (var i = 1; i <= 14; i++) {
    var menu = _this["menu_" + i];
    if (menu && _this.contains(menu)) {
      _this.setChildIndex(menu, _this.numChildren - 1);
      // Additional work...
    }
  }
  // 60 FPS × 14 iterations = 840 operations/second
});
```

**Why it's bad:**
- Most frames, menu state hasn't changed
- setChildIndex forces display list reordering
- CPU cycles wasted on unnecessary checks
- Battery drain on mobile devices

**Detection:**
- Search for `Ticker.addEventListener("tick"`
- Look for loops inside tick handlers
- Calculate operations per second (iterations × 60)

**Impact:** High - Constant CPU overhead

**Calculation:**
```
Operations per second = Loop iterations × Frame rate
840 ops/sec = 14 iterations × 60 FPS
```

---

### Pattern: Polling Instead of Events

**Anti-pattern:**
```javascript
var checkInterval;

function startMonitoring() {
  // ❌ Poll every 100ms instead of using events
  checkInterval = setInterval(function() {
    if (AppState.menu.currentMenuId) {
      updateMenuPosition();
    }
    if (AppState.scene.instance) {
      updateSceneState();
    }
  }, 100);
}

// 10 checks per second, most doing nothing
```

**Why it's bad:**
- Wastes CPU checking conditions that rarely change
- Less responsive than event-driven approach
- Harder to coordinate timing

**Detection:**
- Search for `setInterval` and `setTimeout` in loops
- Check if polling could be replaced with events
- Look for frequent interval values (<500ms)

**Impact:** Medium - Background CPU usage

---

## 4. MovieClip Lifecycle Issues

### Pattern: Auto-Playing MovieClips

**Anti-pattern:**
```javascript
function createScene(id) {
  var scene = new lib.scene_1();
  parent.addChild(scene);

  // ❌ MovieClips start auto-playing immediately
  // scene.climateBigWindow animating in background
  // scene.question animating when not visible
  // scene.analyseWindow animating when hidden

  return scene;
}
```

**Why it's bad:**
- Adobe Animate exports MovieClips as auto-playing by default
- Hidden/invisible MovieClips still consume CPU
- Timeline updates every frame even when not visible
- Complex nested animations compound the problem

**Detection:**
- Look for MovieClip creation without `.stop()` calls
- Check if pauseListedMovieClips or similar exists
- Search for visible=false without corresponding stop()

**Impact:** Medium-High - Depends on MovieClip complexity

---

### Pattern: Missing Pause Lists

**Anti-pattern:**
```javascript
function initScene(scene) {
  // ❌ No systematic pausing

  // Some MovieClips might be manually paused
  if (scene.climateBigWindow) {
    scene.climateBigWindow.stop();
  }

  // But many are forgotten:
  // - scene.question (still animating)
  // - scene.analyseWindow (still animating)
  // - scene.worldMapContainer.worldMap (still animating)
  // - All location_ MovieClips inside worldMap (still animating)
}
```

**Why it's bad:**
- Easy to forget MovieClips, especially nested ones
- No systematic approach to ensure all are paused
- Adding new MovieClips requires remembering to pause them

**Detection:**
- Count MovieClips in scene (use stage explorer)
- Count `.stop()` calls in initialization
- If mismatch, some MovieClips not paused

**Impact:** Medium - Depends on forgotten MovieClip count

---

## 5. Excessive stage.update() Calls

### Pattern: Update in Loops

**Anti-pattern:**
```javascript
function updateAllMenus() {
  for (var i = 1; i <= 14; i++) {
    var menu = _this["menu_" + i];
    menu.x = calculatePosition(i);
    stage.update(); // ❌ Called 14 times!
  }
}

function animateTransition() {
  for (var frame = 0; frame < 60; frame++) {
    element.alpha = frame / 60;
    stage.update(); // ❌ Called 60 times!
  }
}
```

**Why it's bad:**
- `stage.update()` redraws entire canvas
- Each call forces complete re-render
- Should batch changes and update once

**Detection:**
- Search for `stage.update()` inside loops
- Check if called multiple times in sequence
- Look for update() in frequently-called functions

**Impact:** High - Forces excessive redraws

**Fix:**
```javascript
function updateAllMenus() {
  for (var i = 1; i <= 14; i++) {
    var menu = _this["menu_" + i];
    menu.x = calculatePosition(i);
  }
  stage.update(); // ✅ Once after all changes
}
```

---

## 6. Cache Management Issues

### Pattern: Missing Cache on Static Content

**Anti-pattern:**
```javascript
function createComplexGraphic() {
  var shape = new createjs.Shape();
  var g = shape.graphics;

  // Complex drawing operations
  g.beginFill("#FF0000");
  for (var i = 0; i < 100; i++) {
    g.drawRect(i * 10, i * 10, 10, 10);
  }
  g.endFill();

  // ❌ No caching - redraws all 100 rects every frame
  return shape;
}
```

**Why it's bad:**
- Complex vector drawing recalculated every frame
- CreateJS must iterate through all draw commands
- Huge performance hit for static content

**Detection:**
- Search for complex drawing operations (beginFill, drawRect)
- Check if `.cache()` is used afterwards
- Look for shapes that don't change

**Impact:** Medium - Depends on drawing complexity

**Fix:**
```javascript
function createComplexGraphic() {
  var shape = new createjs.Shape();
  var g = shape.graphics;

  g.beginFill("#FF0000");
  for (var i = 0; i < 100; i++) {
    g.drawRect(i * 10, i * 10, 10, 10);
  }
  g.endFill();

  // ✅ Cache as bitmap - drawn once, then fast bitmap render
  shape.cache(0, 0, 1000, 1000);

  return shape;
}
```

---

## 7. Resource Management Issues

### Pattern: No Lazy Loading

**Anti-pattern:**
```javascript
function preloadAllAssets() {
  // ❌ Load all 100+ images on startup
  for (var i = 1; i <= 100; i++) {
    var img = new Image();
    img.src = "images/climate_" + i + ".png";
    assetCache[i] = img;
  }
  // Long initial load time, high memory usage
}

function showScene(id) {
  // Only uses 1-2 images from the 100 loaded
  display.addChild(new createjs.Bitmap(assetCache[id]));
}
```

**Why it's bad:**
- Loads assets user may never see
- Increases initial load time
- Wastes memory on unused images

**Detection:**
- Search for preload/load functions that load all assets
- Check if assets loaded before they're needed
- Look for large asset arrays

**Impact:** Medium - Affects startup time and memory

---

### Pattern: No Audio Cleanup

**Anti-pattern:**
```javascript
function playSound(soundId) {
  // ❌ No reference tracking
  createjs.Sound.play(soundId, {loop: -1}); // Infinite loop
}

// Later, user navigates away
function changeScene() {
  // ❌ Sound still playing in background
  createScene(newId);
}
```

**Why it's bad:**
- Sounds accumulate in background
- Memory leak from sound instances
- Audio confusion (multiple sounds overlapping)

**Detection:**
- Search for `Sound.play()` without storing instance
- Check if sounds stopped on scene change
- Look for loop:-1 without corresponding stop

**Impact:** Medium - Compounds over time

---

## Detection Checklist

Use this checklist to systematically find anti-patterns:

**Event Listeners:**
- [ ] Search for `addEventListener` - all have matching `removeEventListener`?
- [ ] All dynamic objects have cleanup functions?
- [ ] Listener references stored in state/object?

**Redundant Bindings:**
- [ ] Init functions have duplicate registration guards?
- [ ] Event handlers stored and checked before adding?

**Per-Frame:**
- [ ] Ticker handlers reviewed for unnecessary loops?
- [ ] Operations per second calculated and justified?
- [ ] Event-driven alternatives considered?

**MovieClips:**
- [ ] All MovieClips paused after creation?
- [ ] Pause list comprehensive and maintained?
- [ ] Nested MovieClips included?

**stage.update():**
- [ ] No update() calls in loops?
- [ ] Changes batched before updating?

**Cache:**
- [ ] Complex static graphics cached?
- [ ] Cache updated only when content changes?

**Resources:**
- [ ] Assets lazy-loaded when needed?
- [ ] Unused assets cleaned up?
- [ ] Audio instances tracked and stopped?

---

## Priority Matrix

| Issue Type | Frequency | Impact | Priority |
|------------|-----------|--------|----------|
| Event listener leaks | High | Critical | **P0 - Fix immediately** |
| Redundant bindings | Medium | High | **P1 - Fix soon** |
| Per-frame loops | Low | High | **P1 - Fix soon** |
| MovieClip lifecycle | High | Medium | **P2 - Plan fix** |
| Excessive updates | Low | High | **P1 - Fix soon** |
| Missing cache | Medium | Medium | **P3 - Optimize** |
| Resource loading | Low | Medium | **P3 - Optimize** |

Focus on P0 and P1 issues first - they have the highest impact on user experience.
