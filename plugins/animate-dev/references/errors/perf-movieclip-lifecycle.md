# PERF-MOVIECLIP-LIFECYCLE: MovieClip Lifecycle Issues

## Quick Summary
MovieClips auto-play in background even when hidden or not visible, wasting CPU.

## Symptoms
- Hidden animations still consuming CPU
- 隱藏動畫仍在播放
- High CPU when application is idle
- 待機 CPU 高

## Detection
### Grep Patterns
- `new lib\.` followed by `addChild` without `.stop()` on same component
- `visible\s*=\s*false` without corresponding `.stop()`
- Missing `pauseListedMovieClips` or similar systematic pause function

### Code Pattern (Wrong)
```javascript
function createScene(id) {
    var scene = new lib.scene_1();
    parent.addChild(scene);
    // MovieClips start auto-playing immediately
    // scene.detailWindow, scene.question, etc. all animating
    return scene;
}
```

## Fix Strategy
### Systematic pause on creation
```javascript
// Define pause targets
var pauseTargets = [
    "detailWindow", "infoWindow", "question",
    "actionBtn", "confirmBtn", "previousBtn"
];

function pauseListedMovieClips(scene) {
    if (!scene) return;
    var count = 0;

    pauseTargets.forEach(function(name) {
        if (scene[name] && typeof scene[name].stop === 'function') {
            scene[name].stop();
            count++;
        }
    });

    // Handle numbered children
    for (var i = 1; i <= 10; i++) {
        var child = scene["itemBtn_" + i];
        if (child && typeof child.stop === 'function') {
            child.stop();
            count++;
        }
    }

    console.log("Paused " + count + " MovieClips");
}

function initScene(scene) {
    pauseListedMovieClips(scene);  // Pause all first
    // Control explicitly when needed:
    // scene.question.resultIcon.gotoAndStop(0);
}
```

## Verification
- Count MovieClips in scene vs `.stop()` calls — should match
- CPU usage low when application is idle
- Hidden MovieClips are confirmed stopped
