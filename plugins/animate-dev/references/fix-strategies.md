# Fix Strategies and Code Examples

This reference provides complete before/after code examples for fixing each performance issue, with step-by-step implementation guides.

## 1. Event Listener Memory Leak Fixes

### Fix Strategy: Store and Clean Up Listener References

**Implementation Steps:**

1. Add listener storage to state object
2. Store listener reference when adding
3. Remove listener using stored reference
4. Clean up before removing display object

**Complete Example:**

**Before (Memory Leak):**
```javascript
// state.js
var AppState = {
  scene: {
    currentSceneId: null,
    instance: null
    // ❌ No listener tracking
  }
};

// climateDisplay.js
bindSceneEventListeners: function(scene) {
  var self = this;
  // ❌ Anonymous function - can't remove
  scene.addEventListener("click", function(e) {
    self.handleSceneClick(e, scene);
  });
},

// main.js
function handleClimateBtn(e, id) {
  // Remove old scene
  if (AppState.scene.instance) {
    _this.removeChild(AppState.scene.instance); // ❌ Listener still attached!
    AppState.scene.instance = null;
  }

  // Create new scene
  var newScene = new _lib["scene_" + id]();
  _this.addChild(newScene);
  AppState.scene.instance = newScene;

  ClimateDisplay.initScene(newScene);
}
```

**After (Fixed):**
```javascript
// state.js
var AppState = {
  scene: {
    currentSceneId: null,
    instance: null,
    clickListener: null  // ✅ Added: Store listener reference
  }
};

// climateDisplay.js
bindSceneEventListeners: function(scene) {
  if (!scene) return;

  var self = this;
  // ✅ Named function stored in variable
  var clickListener = function(e) {
    self.handleSceneClick(e, scene);
  };

  // ✅ Store reference for later cleanup
  AppState.scene.clickListener = clickListener;
  scene.addEventListener("click", clickListener);

  console.log("場景事件監聽器已綁定");
},

// ✅ New: Cleanup function
unbindSceneEventListeners: function(scene) {
  if (!scene || !AppState.scene.clickListener) return;

  scene.removeEventListener("click", AppState.scene.clickListener);
  AppState.scene.clickListener = null;
  console.log("場景事件監聽器已移除");
},

// main.js
function handleClimateBtn(e, id) {
  // Remove old scene
  if (AppState.scene.instance) {
    // ✅ Clean up listeners first
    if (typeof ClimateDisplay !== 'undefined') {
      ClimateDisplay.unbindSceneEventListeners(AppState.scene.instance);
    }

    _this.removeChild(AppState.scene.instance);
    AppState.scene.instance = null;
  }

  // Create new scene
  var newScene = new _lib["scene_" + id]();
  _this.addChild(newScene);
  AppState.scene.instance = newScene;

  ClimateDisplay.initScene(newScene);
}
```

**Impact:** Prevents memory leak of ~50KB-500KB per scene switch (depends on scene complexity)

---

## 2. Redundant Event Binding Fixes

### Fix Strategy: Guard Registration with Existence Check

**Implementation Steps:**

1. Store handler reference as object property
2. Check if handler exists before registering
3. Return early if already registered
4. Provide cleanup method

**Complete Example:**

**Before (Duplicate Registration):**
```javascript
// worldMap.js
var WorldMap = {
  container: null,
  mapContent: null,
  // ❌ No handler reference

  registerWheelEvent: function() {
    var canvas = document.getElementById("canvas");
    if (!canvas) return;

    var self = this;
    // ❌ Creates new handler every time
    canvas.addEventListener("wheel", function(e) {
      self.handleWheel(e);
    }, { passive: false });
  },

  handleWheel: function(e) {
    // Zoom logic
  }
};

// Called multiple times during scene switches
WorldMap.init(container1); // First registration
WorldMap.init(container2); // Second registration - now fires twice!
```

**After (Protected):**
```javascript
// worldMap.js
var WorldMap = {
  container: null,
  mapContent: null,
  wheelHandler: null, // ✅ Store handler reference

  registerWheelEvent: function() {
    // ✅ Guard: Check if already registered
    if (this.wheelHandler) {
      console.log("WorldMap: 滾輪事件已存在，跳過重複註冊");
      return;
    }

    var canvas = document.getElementById("canvas");
    if (!canvas) return;

    var self = this;
    // ✅ Store handler for later removal
    this.wheelHandler = function(e) {
      self.handleWheel(e);
    };

    canvas.addEventListener("wheel", this.wheelHandler, { passive: false });
    console.log("WorldMap: 滾輪事件已註冊");
  },

  // ✅ Cleanup method
  removeWheelEvent: function() {
    var canvas = document.getElementById("canvas");
    if (canvas && this.wheelHandler) {
      canvas.removeEventListener("wheel", this.wheelHandler);
      this.wheelHandler = null;
      console.log("WorldMap: 滾輪事件已移除");
    }
  },

  handleWheel: function(e) {
    // Zoom logic
  }
};

// Now safe to call multiple times
WorldMap.init(container1); // Registers
WorldMap.init(container2); // Skips (already registered)
```

**Call cleanup on scene change:**
```javascript
// climateDisplay.js - handlePreviousBtn
handlePreviousBtn: function(scene) {
  // Clean up event listeners
  this.unbindSceneEventListeners(AppState.scene.instance);

  // ✅ Clean up WorldMap wheel event
  if (typeof WorldMap !== 'undefined') {
    WorldMap.removeWheelEvent();
  }

  // Remove scene
  _this.removeChild(AppState.scene.instance);
  // ... rest of cleanup
}
```

**Impact:** Prevents duplicate handlers, fixes event firing multiple times

---

## 3. Per-Frame Execution Fixes

### Fix Strategy: Event-Driven Instead of Polling

**Implementation Steps:**

1. Identify what's being checked every frame
2. Determine when state actually changes
3. Move logic to state change events
4. Remove or reduce tick handler

**Complete Example:**

**Before (60 FPS Overhead):**
```javascript
// main.js
game.onTick = function() {
  // ❌ Runs 60 times per second
  for (var i = 1; i <= 14; i++) {
    var menu = _this["menu_" + i];
    if (menu && _this.contains(menu)) {
      // Forces display list reordering every frame
      _this.setChildIndex(menu, _this.numChildren - 1);
    }
  }
  // 60 FPS × 14 iterations = 840 operations/second
  // 99% of these do nothing (menu state unchanged)
};

game.main = function() {
  // ...
  createjs.Ticker.addEventListener("tick", game.onTick); // ❌ Every frame
  // ...
};
```

**After (Event-Driven):**
```javascript
// main.js

// ✅ New: Only runs when menu visibility changes
game.bringMenuToTop = function(menuId) {
  if (!_this) return;

  var menu = _this["menu_" + menuId];
  if (menu && _this.contains(menu) && menu.visible) {
    _this.setChildIndex(menu, _this.numChildren - 1);
    console.log("Menu " + menuId + " brought to top");
  }
};

function handleMenuBtn(id) {
  if (typeof AppState === 'undefined') return;

  if (AppState.menu.currentMenuId === id) {
    // Close current menu
    AppState.menu.currentMenuId = null;
    if (_this["menu_" + id]) {
      _this["menu_" + id].visible = false;
    }
  } else {
    // Close all menus
    for (var i = 1; i <= 14; i++) {
      if (_this["menu_" + i]) {
        _this["menu_" + i].visible = false;
      }
    }

    // Open new menu
    AppState.menu.currentMenuId = id;
    if (_this["menu_" + id]) {
      _this["menu_" + id].visible = true;
      // ✅ Only when menu shown (2-3 times per user interaction)
      game.bringMenuToTop(id);
    }
  }
}

game.main = function() {
  // ...
  // ✅ Removed: No longer needed
  // createjs.Ticker.addEventListener("tick", game.onTick);
  // ...
};
```

**Performance Calculation:**
```
Before: 840 operations/second (continuous)
After: 2-3 operations per menu interaction
Reduction: 99.6% (when user not actively using menus)
```

**Impact:** Significant CPU reduction, better battery life, smoother animations

---

## 4. MovieClip Lifecycle Fixes

### Fix Strategy: Systematic Pause on Creation

**Implementation Steps:**

1. Create comprehensive pause list
2. Pause all listed MovieClips after scene creation
3. Control animations explicitly via gotoAndStop
4. Update pause list when adding new MovieClips

**Complete Example:**

**Before (Auto-Playing MovieClips):**
```javascript
// climateDisplay.js
initScene: function(scene) {
  if (!scene) return;

  // ❌ MovieClips start auto-playing
  // scene.climateBigWindow animates in background (hidden)
  // scene.analyseWindow animates (not visible)
  // scene.question.resultIcon animates (before quiz starts)

  this.bindSceneEventListeners(scene);
  console.log("ClimateDisplay 場景元件初始化完成");
}
```

**After (Controlled Animation):**
```javascript
// climateDisplay.js

// ✅ Comprehensive pause list
pauseTargets: {
  direct: [
    "climateSmall_1",
    "climateSmall_2",
    "climateSmall_3",
    "climateBigWindow",
    "analyseWindow",
    "worldMapContainer",
    "question",
    "quizBtn",
    "confirmBtn",
    "previousBtn",
    "downloadBtn",
    "analyseBtn"
  ],
  numbered: [
    { prefix: "locationBtn_", max: 10 },
    { prefix: "optionBtn_", max: 4 }
  ],
  worldMapChildren: [
    { prefix: "location_", max: 20 }
  ],
  questionChildren: {
    direct: [
      "questionText",
      "questionTitle",
      "resultText",
      "resultIcon",
      "analyseBtn",
      "confirmBtn"
    ],
    numbered: [
      { prefix: "optionBtn_", max: 4 },
      { prefix: "option_", max: 4 }
    ]
  }
},

// ✅ Systematic pause function
pauseListedMovieClips: function(scene) {
  if (!scene) return;

  var pausedCount = 0;
  var self = this;

  function pauseTarget(target) {
    if (target && target.stop && typeof target.stop === 'function') {
      target.stop();
      return true;
    }
    return false;
  }

  // Pause direct children
  this.pauseTargets.direct.forEach(function(name) {
    if (pauseTarget(scene[name])) {
      pausedCount++;
    }
  });

  // Pause numbered children
  this.pauseTargets.numbered.forEach(function(item) {
    for (var i = 1; i <= item.max; i++) {
      if (pauseTarget(scene[item.prefix + i])) {
        pausedCount++;
      }
    }
  });

  // Pause worldMap children
  var worldMap = scene.worldMapContainer ? scene.worldMapContainer.worldMap : null;
  if (worldMap) {
    pauseTarget(worldMap);
    pausedCount++;

    this.pauseTargets.worldMapChildren.forEach(function(item) {
      for (var i = 1; i <= item.max; i++) {
        if (pauseTarget(worldMap[item.prefix + i])) {
          pausedCount++;
        }
      }
    });
  }

  // Pause question children
  if (scene.question) {
    var qConfig = this.pauseTargets.questionChildren;

    if (qConfig.direct) {
      qConfig.direct.forEach(function(name) {
        if (pauseTarget(scene.question[name])) {
          pausedCount++;
        }
      });
    }

    if (qConfig.numbered) {
      qConfig.numbered.forEach(function(item) {
        for (var i = 1; i <= item.max; i++) {
          if (pauseTarget(scene.question[item.prefix + i])) {
            pausedCount++;
          }
        }
      });
    }
  }

  console.log("已暫停 " + pausedCount + " 個列舉的 MovieClip 元件");
},

initScene: function(scene) {
  if (!scene) return;

  // ✅ Pause all MovieClips first
  this.pauseListedMovieClips(scene);
  this.setInteractiveElements(scene);

  // ✅ Control explicitly when needed
  // (e.g., in quiz: scene.question.resultIcon.gotoAndStop(0))

  this.bindSceneEventListeners(scene);
  console.log("ClimateDisplay 場景元件初始化完成");
}
```

**Impact:** Prevents unnecessary timeline updates, reduces CPU usage for complex scenes

---

## 5. Batch stage.update() Calls

### Fix Strategy: Group Changes, Update Once

**Before:**
```javascript
function updateMenuPositions() {
  for (var i = 1; i <= 14; i++) {
    var menu = _this["menu_" + i];
    menu.x = calculateX(i);
    stage.update(); // ❌ 14 redraws!
  }
}
```

**After:**
```javascript
function updateMenuPositions() {
  // Make all changes first
  for (var i = 1; i <= 14; i++) {
    var menu = _this["menu_" + i];
    menu.x = calculateX(i);
  }
  // ✅ Update once after all changes
  stage.update();
}
```

---

## 6. Add Cache for Static Content

### Fix Strategy: Cache Complex Graphics

**Before:**
```javascript
function createBackground() {
  var bg = new createjs.Shape();
  var g = bg.graphics;

  // Complex drawing
  g.beginFill("#FF0000");
  for (var i = 0; i < 100; i++) {
    g.drawRect(i * 10, i * 10, 10, 10);
  }
  g.endFill();

  // ❌ Redraws all 100 rects every frame
  return bg;
}
```

**After:**
```javascript
function createBackground() {
  var bg = new createjs.Shape();
  var g = bg.graphics;

  g.beginFill("#FF0000");
  for (var i = 0; i < 100; i++) {
    g.drawRect(i * 10, i * 10, 10, 10);
  }
  g.endFill();

  // ✅ Cache as bitmap - fast rendering
  bg.cache(0, 0, 1000, 1000);

  return bg;
}
```

**When to update cache:**
```javascript
// Only when content changes
function updateBackground(bg, newColor) {
  bg.uncache();

  var g = bg.graphics;
  g.clear();
  g.beginFill(newColor);
  // ... redraw
  g.endFill();

  bg.cache(0, 0, 1000, 1000); // Re-cache
}
```

---

## 7. Resource Management Fixes

### Lazy Loading Strategy

**Before:**
```javascript
function init() {
  // ❌ Load all 100 images on startup
  for (var i = 1; i <= 100; i++) {
    var img = new Image();
    img.src = "images/climate_" + i + ".png";
    imageCache[i] = img;
  }
}
```

**After:**
```javascript
var imageCache = {};

function loadImage(id) {
  // ✅ Load only when needed
  if (!imageCache[id]) {
    var img = new Image();
    img.src = "images/climate_" + id + ".png";
    imageCache[id] = img;
  }
  return imageCache[id];
}

function showClimate(id) {
  var img = loadImage(id); // Lazy load
  var bitmap = new createjs.Bitmap(img);
  stage.addChild(bitmap);
}
```

### Audio Cleanup

**Before:**
```javascript
function playBGM() {
  // ❌ No reference, can't stop
  createjs.Sound.play("bgm", {loop: -1});
}
```

**After:**
```javascript
var bgmInstance = null;

function playBGM() {
  // Stop previous if exists
  if (bgmInstance) {
    bgmInstance.stop();
  }

  // ✅ Store reference
  bgmInstance = createjs.Sound.play("bgm", {loop: -1});
}

function stopBGM() {
  if (bgmInstance) {
    bgmInstance.stop();
    bgmInstance = null;
  }
}

// Call on scene change
function changeScene() {
  stopBGM(); // ✅ Clean up audio
  // ... create new scene
}
```

---

## Testing Checklist

After applying fixes:

**Memory Leaks:**
- [ ] Open DevTools Memory profiler
- [ ] Create scene, remove scene, repeat 10 times
- [ ] Take heap snapshot
- [ ] Verify detached DOM nodes don't accumulate
- [ ] Check event listener count stays constant

**Event Handlers:**
- [ ] Open DevTools > Elements > Event Listeners
- [ ] Check addEventListener count
- [ ] Switch scenes, verify count doesn't grow

**Per-Frame Performance:**
- [ ] Open DevTools Performance tab
- [ ] Record during idle state
- [ ] Verify no heavy operations in every frame
- [ ] Check FPS stays at 60

**MovieClips:**
- [ ] Inspect scene after creation
- [ ] Verify hidden MovieClips are stopped
- [ ] Check CPU usage (should be low when idle)

**stage.update():**
- [ ] Search code for `stage.update()`
- [ ] Verify none in loops
- [ ] Check frequency is appropriate

---

## Common Mistakes When Fixing

**❌ Mistake 1: Removing listener with different function**
```javascript
// Won't work - different function references
scene.addEventListener("click", function(e) { ... });
scene.removeEventListener("click", function(e) { ... }); // Different!
```

**✅ Fix: Use same reference**
```javascript
var listener = function(e) { ... };
scene.addEventListener("click", listener);
scene.removeEventListener("click", listener); // Same reference
```

**❌ Mistake 2: Forgetting to null references**
```javascript
scene.removeEventListener("click", this.clickHandler);
// ❌ this.clickHandler still holds reference
```

**✅ Fix: Clear reference**
```javascript
scene.removeEventListener("click", this.clickHandler);
this.clickHandler = null; // ✅ Release reference
```

**❌ Mistake 3: Caching dynamic content**
```javascript
sprite.cache(0, 0, 100, 100);
// Later...
sprite.graphics.clear();
sprite.graphics.beginFill("#FF0000");
// ❌ Still shows old cached version!
```

**✅ Fix: Update cache after changes**
```javascript
sprite.uncache();
sprite.graphics.clear();
sprite.graphics.beginFill("#FF0000");
sprite.cache(0, 0, 100, 100); // ✅ Re-cache
```

---

## Performance Impact Summary

| Fix Type | CPU Reduction | Memory Savings | Priority |
|----------|---------------|----------------|----------|
| Event listener cleanup | 0% | 50KB-500KB per scene | **P0** |
| Prevent duplicate bindings | 5-10% | Varies | **P1** |
| Remove per-frame loops | 30-50% | Minimal | **P1** |
| Pause MovieClips | 10-20% | Minimal | **P2** |
| Batch stage.update() | 20-40% | Minimal | **P1** |
| Add cache | 15-30% | More RAM but faster | **P3** |
| Lazy load assets | 0% | 50-80% initial | **P3** |

Focus on P0 and P1 fixes first for maximum impact.
