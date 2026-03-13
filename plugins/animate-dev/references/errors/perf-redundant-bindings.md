# PERF-REDUNDANT-BINDINGS: Redundant Event Bindings

## Quick Summary
Event handlers registered multiple times because init functions lack duplicate-registration guards.

## Symptoms
- Event fires multiple times per interaction
- 事件觸發多次、重複註冊
- Zoom/scroll behavior multiplied
- Debugging confusion (why does action happen 3x?)

## Detection
### Grep Patterns
- `addEventListener` inside init/setup/register functions without guard check
- Missing `if (this.handler) return` patterns
- `addEventListener` without stored handler reference

### Code Pattern (Wrong)
```javascript
var MapView = {
    registerWheelEvent: function() {
        var canvas = document.getElementById("canvas");
        canvas.addEventListener("wheel", function(e) {
            self.handleWheel(e);  // New handler each call
        }, { passive: false });
    }
};
// MapView.init() called multiple times = duplicate handlers
```

## Fix Strategy
### Guard registration with existence check
```javascript
var MapView = {
    wheelHandler: null,  // Store handler reference

    registerWheelEvent: function() {
        if (this.wheelHandler) {
            return;  // Already registered
        }
        var canvas = document.getElementById("canvas");
        if (!canvas) return;

        var self = this;
        this.wheelHandler = function(e) {
            self.handleWheel(e);
        };
        canvas.addEventListener("wheel", this.wheelHandler, { passive: false });
    },

    removeWheelEvent: function() {
        var canvas = document.getElementById("canvas");
        if (canvas && this.wheelHandler) {
            canvas.removeEventListener("wheel", this.wheelHandler);
            this.wheelHandler = null;
        }
    }
};
```

## Verification
- Init functions have guard conditions preventing duplicate registration
- Handler references stored for later removal
- Events fire exactly once per interaction
