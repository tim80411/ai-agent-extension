# ERR-FRAME-NOT-PAUSED: Frame States Not Paused

## Quick Summary
MovieClips intended as state containers auto-play through all frames instead of stopping.

## Symptoms
- Button flickers through all states
- 按鈕閃爍、自動播放
- Component plays as animation instead of showing one state
- Unwanted visual glitches on state-based components

## Detection
### Grep Patterns
- `new lib\..*\(\)` followed by `addChild` without `.stop()` or `.gotoAndStop(`
- State-based component names (btn_, state_) without `.stop()` after creation

### Code Pattern (Wrong)
```javascript
var button = new lib.ButtonComponent();
parent.addChild(button);
// MISSING: button.stop();
// Result: Button plays through all frames as animation
```

## Fix Strategy
### Option A: Stop on creation
```javascript
var button = new lib.ButtonComponent();
parent.addChild(button);
button.stop();  // Pause on current state
```

### Option B: Jump to specific state
```javascript
var button = new lib.ButtonComponent();
parent.addChild(button);
button.gotoAndStop("idle");  // Using frame label (preferred)
```

### When NOT to stop
```javascript
// Animation-based components (frames = motion) should play
var character = new lib.WalkingCharacter();
parent.addChild(character);
character.gotoAndPlay(0);  // Let it animate
```

## Verification
- All state-based MovieClips (buttons, UI states) call `.stop()` after `addChild`
- No unwanted auto-playing animations
- Components display correct initial state
