# PERF-RESOURCE-MANAGEMENT: Resource Management Issues

## Quick Summary
All assets loaded upfront instead of lazily, and audio instances not tracked or cleaned up.

## Symptoms
- Slow startup / long initial load
- 啟動慢、記憶體過高
- Audio overlapping across scenes
- 音效重疊
- High memory from unused assets

## Detection
### Grep Patterns
- Preload loops: `for.*new Image\(\)` loading all assets at once
- `Sound\.play\(` without storing return value
- `loop:\s*-1` without corresponding stop
- Missing audio cleanup on scene change

### Code Pattern (Wrong)
```javascript
// All assets loaded on startup
function init() {
    for (var i = 1; i <= 100; i++) {
        var img = new Image();
        img.src = "images/content_" + i + ".png";
        imageCache[i] = img;
    }
}

// Audio not tracked
function playBGM() {
    createjs.Sound.play("bgm", {loop: -1});  // No reference stored
}
```

## Fix Strategy
### Lazy loading
```javascript
var imageCache = {};

function loadImage(id) {
    if (!imageCache[id]) {
        var img = new Image();
        img.src = "images/content_" + id + ".png";
        imageCache[id] = img;
    }
    return imageCache[id];
}

function showContent(id) {
    var img = loadImage(id);  // Load only when needed
    var bitmap = new createjs.Bitmap(img);
    stage.addChild(bitmap);
}
```

### Audio cleanup
```javascript
var bgmInstance = null;

function playBGM() {
    if (bgmInstance) bgmInstance.stop();
    bgmInstance = createjs.Sound.play("bgm", {loop: -1});
}

function stopBGM() {
    if (bgmInstance) {
        bgmInstance.stop();
        bgmInstance = null;
    }
}

function changeScene() {
    stopBGM();  // Clean up audio before switching
}
```

## Verification
- Assets loaded on demand, not all at startup
- Sound instances stored and stopped on scene change
- No audio overlap across scenes
- Initial load time reasonable
