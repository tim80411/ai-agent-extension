# ERR-MISSING-TICKER: Missing Stage Ticker

## Quick Summary
Stage ticker not set up, causing nothing to animate or update on canvas.

## Symptoms
- Nothing animates
- 畫面凍結
- Stage not updating
- 動畫不播放
- Application appears frozen
- Tweens don't play

## Detection
### Grep Patterns
- `new createjs\.Stage\(` without `Ticker\.addEventListener\("tick"` nearby
- Missing `createjs\.Ticker\.framerate`
- Stage creation without ticker setup

### Code Pattern (Wrong)
```javascript
var canvas = document.getElementById("canvas");
var stage = new createjs.Stage(canvas);
var exportRoot = new lib.MainTimeline();
stage.addChild(exportRoot);
// MISSING: Ticker setup - nothing will animate
```

## Fix Strategy
### Add ticker after stage setup
```javascript
var canvas = document.getElementById("canvas");
var stage = new createjs.Stage(canvas);
var exportRoot = new lib.MainTimeline();
stage.addChild(exportRoot);

// Set up ticker
createjs.Ticker.framerate = 30;
createjs.Ticker.addEventListener("tick", stage);
```

## Verification
- `createjs.Ticker.addEventListener("tick", stage)` exists after stage creation
- `createjs.Ticker.framerate` is set
- Animations play correctly
