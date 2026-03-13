# ERR-FRAME-NUMBER-CONFUSION: Frame Number Confusion

## Quick Summary
Confusion between Animate's 1-based frame display and JavaScript's 0-based frame index.

## Symptoms
- Wrong frame showing
- 幀號錯誤、off-by-one
- Code on "Frame 1" runs unexpectedly
- 時間軸混亂

## Detection
### Grep Patterns
- `gotoAndStop\(\d+\)` — magic frame numbers without comments
- `gotoAndPlay\(\d+\)` — same issue
- Hard-coded frame numbers instead of labels

### Code Pattern (Wrong)
```javascript
// Adobe Animate shows Frame 1 as first frame
// JavaScript uses Frame 0 internally
this.gotoAndStop(1);  // What is frame 1? Confusing.
```

## Fix Strategy
### Use frame labels instead of numbers
```javascript
// Clear, maintainable, no confusion
this.gotoAndStop("init");
this.gotoAndStop("gameStart");
this.gotoAndStop("results");
```

### Best Practice
In Adobe Animate timeline:
1. Add frame labels for key states
2. Reference labels in code, not numbers
3. Keep timeline code minimal
4. Move complex logic to external JS files

## Verification
- No magic frame numbers in code (all use labels)
- Frame labels defined in Animate timeline match code references
- No off-by-one display issues
