# CreateJS Patterns for Web Interactive Applications

Research summary from web sources on Adobe Animate + CreateJS usage in production interactive and educational applications.

## CreateJS Library Architecture

### Four Independent Libraries

CreateJS is modular - use only what you need:

#### 1. EaselJS - Display List Management
Core library for working with HTML5 Canvas:

**Display Objects:**
- `Stage`: Root container, manages canvas
- `Container`: Groups display objects, manages hierarchy
- `MovieClip`: Timeline-based animations (integrates with TweenJS)
- `Sprite`: Sprite sheet animations
- `Bitmap`: Images
- `Shape`: Vector graphics
- `Text`: Text rendering

**Key Features:**
- Hierarchical display list (like Flash/ActionScript)
- Mouse interaction handling
- Filters and caching
- Hit detection

#### 2. TweenJS - Animation Engine
Property tweening for smooth animations:

**Features:**
- Tween any JavaScript property
- Chainable tween sequences
- Easing functions
- Timeline synchronization with MovieClip

**Usage:**
```javascript
// Simple tween
createjs.Tween.get(target)
    .to({x: 100, alpha: 1}, 1000, createjs.Ease.quartOut);

// Chained sequence
createjs.Tween.get(target)
    .to({x: 100}, 500)
    .wait(200)
    .to({alpha: 0}, 300)
    .call(onComplete);
```

#### 3. SoundJS - Audio Management
Cross-browser audio handling:

**Features:**
- Automatic fallback for browser compatibility
- Sprite sheet support for sound effects
- Volume/pan control
- Preloading coordination

**Usage:**
```javascript
createjs.Sound.registerSound("audio/bgm.mp3", "bgm");
createjs.Sound.play("bgm", {loop: -1, volume: 0.5});
```

#### 4. PreloadJS - Asset Loading
Robust asset management with progress:

**Features:**
- XHR-based loading with progress
- Multiple concurrent connections
- Error handling
- Queue management
- Tag-based fallback

**Usage:**
```javascript
var queue = new createjs.LoadQueue();
queue.on("complete", handleComplete);
queue.on("progress", handleProgress);
queue.loadManifest(manifestArray);
```

## Container Architecture Pattern

### Hierarchical Organization

Use Containers to organize display list by function and Z-order:

```javascript
// Define named containers at program start
var backgroundContainer = new createjs.Container();
var gameContainer = new createjs.Container();
var uiContainer = new createjs.Container();
var overlayContainer = new createjs.Container();

// Add in Z-order (bottom to top)
stage.addChild(backgroundContainer);
stage.addChild(gameContainer);
stage.addChild(uiContainer);
stage.addChild(overlayContainer);

// Add content to appropriate container
backgroundContainer.addChild(bgImage);
gameContainer.addChild(player);
uiContainer.addChild(scoreDisplay);
overlayContainer.addChild(pauseMenu);
```

**Benefits:**
- Clear separation of concerns
- Easy Z-order management
- Bulk operations (show/hide layer)
- Performance optimization (cache containers)

### Modular Component Pattern

```javascript
// Create reusable components as Containers
function createButton(label, callback) {
    var button = new createjs.Container();

    // Background
    var bg = new createjs.Shape();
    bg.graphics.beginFill("#4CAF50").drawRoundRect(0, 0, 120, 40, 5);
    button.addChild(bg);

    // Label
    var text = new createjs.Text(label, "16px Arial", "#FFF");
    text.textAlign = "center";
    text.x = 60;
    text.y = 12;
    button.addChild(text);

    // Interaction
    button.mouseChildren = false;
    button.cursor = "pointer";
    button.on("click", callback);

    // Hover effect
    button.on("mouseover", function() {
        bg.graphics.clear().beginFill("#66BB6A").drawRoundRect(0, 0, 120, 40, 5);
        stage.update();
    });

    button.on("mouseout", function() {
        bg.graphics.clear().beginFill("#4CAF50").drawRoundRect(0, 0, 120, 40, 5);
        stage.update();
    });

    return button;
}

// Usage
var playButton = createButton("Play", startGame);
uiContainer.addChild(playButton);
```

## MovieClip Advanced Patterns

### Mode Management

MovieClip has three playback modes:

```javascript
// INDEPENDENT (default): Plays independently of parent
movieClip.mode = createjs.MovieClip.INDEPENDENT;

// SINGLE_FRAME: Shows single frame only (no animation)
movieClip.mode = createjs.MovieClip.SINGLE_FRAME;
movieClip.startPosition = 5;  // Which frame to show

// SYNCHED: Synchronized with parent timeline
movieClip.mode = createjs.MovieClip.SYNCHED;
```

**Use Cases:**
- **INDEPENDENT**: Autonomous animations (character cycles, effects)
- **SINGLE_FRAME**: Static exports from Animate (for layout only)
- **SYNCHED**: Tightly coupled parent-child animation sequences

### Label-Based State Management

Use labels for maintainable state control:

```javascript
// Define states in Adobe Animate timeline with labels
// "idle", "walk", "jump", "attack"

// Navigate by label (preferred)
character.gotoAndPlay("walk");
character.gotoAndStop("idle");

// Respond to reaching labels
character.on("change", function(evt) {
    if (evt.currentLabel === "attack") {
        playAttackSound();
    }
});
```

**Benefits:**
- Self-documenting code
- Easy to modify in Animate without code changes
- Supports complex state machines

### Hybrid Timeline + Code Animation

Combine frame-based and programmatic animation:

```javascript
// Use timeline for UI state changes
menu.gotoAndStop("open");

// Use TweenJS for smooth transition
createjs.Tween.get(menu)
    .to({x: 0}, 400, createjs.Ease.cubicOut);

// Result: Frame defines visual state, tween animates position
```

## Event System Patterns

### EventDispatcher Integration

Two ways to add event capabilities:

**1. Extend EventDispatcher:**
```javascript
class GameManager extends createjs.EventDispatcher {
    constructor() {
        super();
        this.score = 0;
    }

    addPoints(points) {
        this.score += points;
        var evt = new createjs.Event("scoreChange");
        evt.score = this.score;
        this.dispatchEvent(evt);
    }
}
```

**2. Mix in EventDispatcher:**
```javascript
function GameManager() {
    this.score = 0;
}

// Add EventDispatcher methods
createjs.EventDispatcher.initialize(GameManager.prototype);

GameManager.prototype.addPoints = function(points) {
    this.score += points;
    var evt = new createjs.Event("scoreChange");
    evt.score = this.score;
    this.dispatchEvent(evt);
};
```

### Scoped Listeners with .on()

```javascript
// Preserve scope with third parameter
component.on("click", this.handleClick, this);

// One-time listener (fourth parameter)
component.on("complete", this.onComplete, this, true);

// Multiple events
component.on("click mouseover", this.handleInteraction, this);
```

### Custom Event Data

```javascript
// Create custom event with data
var evt = new createjs.Event("levelComplete");
evt.levelId = currentLevel;
evt.score = totalScore;
evt.timeElapsed = elapsedTime;

gameManager.dispatchEvent(evt);

// Listen
gameManager.on("levelComplete", function(evt) {
    console.log("Level", evt.levelId, "Score:", evt.score);
    saveProgress(evt);
});
```

## Asset Management Strategies

### Scene-Based Loading

Load assets per scene instead of all upfront:

```javascript
var assetManifest = {
    menu: [
        {id: "menuBg", src: "images/menu_bg.png"},
        {id: "menuMusic", src: "audio/menu.mp3"}
    ],
    level1: [
        {id: "level1Bg", src: "images/level1_bg.png"},
        {id: "level1Data", src: "data/level1.json"},
        {id: "enemies", src: "images/enemies.png"}
    ],
    level2: [
        {id: "level2Bg", src: "images/level2_bg.png"},
        {id: "level2Data", src: "data/level2.json"}
    ]
};

function loadScene(sceneId, callback) {
    var queue = new createjs.LoadQueue();
    queue.on("complete", callback);
    queue.loadManifest(assetManifest[sceneId]);
}

// Usage
loadScene("menu", showMenu);
```

### Progress Tracking

```javascript
var queue = new createjs.LoadQueue();

// Track overall progress
queue.on("progress", function(evt) {
    var percent = Math.round(evt.progress * 100);
    updateLoadingBar(percent);
});

// Track individual files
queue.on("fileload", function(evt) {
    console.log("Loaded:", evt.item.id);

    // Immediate use for critical assets
    if (evt.item.id === "logo") {
        showLogo(evt.result);
    }
});

// Handle errors
queue.on("error", function(evt) {
    console.error("Failed to load:", evt.data.id);
    showErrorMessage(evt.data.id);
});

queue.loadManifest(manifest);
```

### Connection Optimization

```javascript
// Adjust concurrent connections
queue.setMaxConnections(6);  // Default is 1

// Higher number = faster parallel loading
// Lower number = more stable on slow connections
// Recommended: 4-8 for most cases
```

## Performance Optimization Patterns

### Caching Strategy

```javascript
// Cache complex vector graphics
function optimizeVectorArt(displayObject) {
    var bounds = displayObject.getBounds();
    if (bounds) {
        displayObject.cache(
            bounds.x,
            bounds.y,
            bounds.width,
            bounds.height
        );
    }
}

// Cache static backgrounds
backgroundContainer.cache(0, 0, stage.canvas.width, stage.canvas.height);

// Update cache when content changes
function updateBackground() {
    backgroundContainer.uncache();
    // Modify background
    backgroundContainer.cache(0, 0, stage.canvas.width, stage.canvas.height);
}
```

### Sprite Sheet Optimization

```javascript
// Define sprite sheet
var spriteSheet = new createjs.SpriteSheet({
    images: ["character_sheet.png"],
    frames: {width: 64, height: 64, count: 20},
    animations: {
        idle: [0, 3, "idle", 0.5],     // frames 0-3, loops, 0.5 speed
        walk: [4, 11, "walk", 1],      // frames 4-11
        jump: [12, 15, "idle"],        // frames 12-15, goes to idle
        attack: [16, 19, "idle", 1.5]  // frames 16-19, 1.5 speed
    }
});

// Create sprite
var character = new createjs.Sprite(spriteSheet, "idle");

// Change animation
character.gotoAndPlay("walk");

// Listen for animation complete
character.on("animationend", function(evt) {
    if (evt.name === "attack") {
        console.log("Attack complete");
    }
});
```

### Efficient Stage Updates

```javascript
// Flag-based update pattern
var needsUpdate = false;

createjs.Ticker.framerate = 30;
createjs.Ticker.on("tick", function(evt) {
    // Game logic (always runs)
    updateGameLogic(evt.delta);

    // Render only when needed
    if (needsUpdate) {
        stage.update();
        needsUpdate = false;
    }
});

// Set flag when visuals change
function movePlayer(x, y) {
    player.x = x;
    player.y = y;
    needsUpdate = true;
}

// For continuous animation, always update
createjs.Ticker.on("tick", stage);  // Simple but less optimized
```

### Mouse Event Optimization

Disable mouse on non-interactive objects:

```javascript
// Disable mouse for decorative elements
backgroundImage.mouseEnabled = false;
decorativeShape.mouseEnabled = false;

// Disable for entire layers
backgroundContainer.mouseChildren = false;
backgroundContainer.mouseEnabled = false;

// Performance impact:
// - Reduces hit testing overhead
// - Especially important on mobile
// - Critical in iframes
```

## Separation of Concerns Pattern

### HTML/CSS for Layout, Canvas for Dynamic Content

```html
<!-- HTML for static UI -->
<div id="gameContainer">
    <div id="header">
        <h1>Game Title</h1>
        <button id="settingsBtn">Settings</button>
    </div>

    <!-- Canvas for dynamic game content -->
    <canvas id="gameCanvas"></canvas>

    <div id="footer">
        <p>Score: <span id="score">0</span></p>
    </div>
</div>
```

```javascript
// Canvas handles only dynamic, animated content
var canvas = document.getElementById("gameCanvas");
var stage = new createjs.Stage(canvas);

// Game objects
var player = new createjs.Sprite(playerSheet);
var enemies = new createjs.Container();
stage.addChild(player, enemies);

// HTML handles score display
function updateScore(points) {
    score += points;
    document.getElementById("score").textContent = score;
    // No need to update canvas for UI changes
}
```

**Benefits:**
- Better performance (DOM for UI, Canvas for animation)
- Easier styling (CSS for UI)
- Accessibility (HTML for text/buttons)
- SEO friendly (HTML content)

## Educational Application Patterns

### Learning Module Structure

```javascript
var LearningApp = (function() {
    var currentModule = null;
    var modules = {};

    function defineModule(id, config) {
        modules[id] = {
            title: config.title,
            assets: config.assets,
            setup: config.setup,
            teardown: config.teardown,
            onComplete: config.onComplete
        };
    }

    function loadModule(id) {
        if (currentModule) {
            modules[currentModule].teardown();
        }

        var module = modules[id];

        // Load module assets
        loadScene(id, function() {
            module.setup();
            currentModule = id;
        });
    }

    function completeModule() {
        if (currentModule && modules[currentModule].onComplete) {
            modules[currentModule].onComplete();
        }
    }

    return {
        defineModule: defineModule,
        loadModule: loadModule,
        completeModule: completeModule
    };
})();

// Define learning modules
LearningApp.defineModule("intro", {
    title: "Introduction",
    assets: introAssets,
    setup: function() {
        showIntroScene();
    },
    teardown: function() {
        cleanupIntroScene();
    },
    onComplete: function() {
        LearningApp.loadModule("lesson1");
    }
});

LearningApp.defineModule("lesson1", {
    title: "Lesson 1: Basic Concepts",
    assets: lesson1Assets,
    setup: function() {
        showLesson1();
    },
    teardown: function() {
        cleanupLesson1();
    },
    onComplete: function() {
        LearningApp.loadModule("quiz1");
    }
});
```

### Feedback and Analytics

```javascript
var AnalyticsTracker = (function() {
    var sessionData = {
        startTime: Date.now(),
        interactions: [],
        completedModules: []
    };

    function trackInteraction(type, data) {
        var interaction = {
            timestamp: Date.now(),
            type: type,
            data: data
        };

        sessionData.interactions.push(interaction);

        // Send to analytics service
        sendToAnalytics(interaction);
    }

    function trackModuleComplete(moduleId, score) {
        sessionData.completedModules.push({
            moduleId: moduleId,
            score: score,
            timestamp: Date.now()
        });

        // Visual feedback
        showCompletionAnimation(moduleId, score);
    }

    function getSessionReport() {
        return {
            duration: Date.now() - sessionData.startTime,
            interactions: sessionData.interactions.length,
            completed: sessionData.completedModules.length,
            averageScore: calculateAverageScore()
        };
    }

    return {
        trackInteraction: trackInteraction,
        trackModuleComplete: trackModuleComplete,
        getSessionReport: getSessionReport
    };
})();

// Usage
button.on("click", function() {
    AnalyticsTracker.trackInteraction("button_click", {
        buttonId: "startLesson",
        moduleId: currentModule
    });
});
```

### Adaptive Difficulty

```javascript
var DifficultyManager = (function() {
    var performanceHistory = [];
    var currentDifficulty = "medium";

    function recordPerformance(score, timeElapsed) {
        performanceHistory.push({
            score: score,
            time: timeElapsed,
            difficulty: currentDifficulty
        });

        // Keep last 5 attempts
        if (performanceHistory.length > 5) {
            performanceHistory.shift();
        }

        adjustDifficulty();
    }

    function adjustDifficulty() {
        var recentAverage = calculateAverage(performanceHistory);

        if (recentAverage > 0.9) {
            // User doing very well, increase difficulty
            if (currentDifficulty === "easy") currentDifficulty = "medium";
            else if (currentDifficulty === "medium") currentDifficulty = "hard";
        } else if (recentAverage < 0.5) {
            // User struggling, decrease difficulty
            if (currentDifficulty === "hard") currentDifficulty = "medium";
            else if (currentDifficulty === "medium") currentDifficulty = "easy";
        }
    }

    function getDifficulty() {
        return currentDifficulty;
    }

    return {
        recordPerformance: recordPerformance,
        getDifficulty: getDifficulty
    };
})();
```

## Responsive Canvas Pattern

```javascript
function setupResponsiveCanvas() {
    var canvas = document.getElementById("canvas");
    var stage = new createjs.Stage(canvas);

    // Original design dimensions
    var designWidth = 1024;
    var designHeight = 768;

    function resizeCanvas() {
        var container = canvas.parentElement;
        var containerWidth = container.offsetWidth;
        var containerHeight = container.offsetHeight;

        // Calculate scale to fit
        var scaleX = containerWidth / designWidth;
        var scaleY = containerHeight / designHeight;
        var scale = Math.min(scaleX, scaleY);

        // Apply scale
        canvas.width = designWidth;
        canvas.height = designHeight;
        stage.scaleX = stage.scaleY = scale;

        // Center if needed
        var scaledWidth = designWidth * scale;
        var scaledHeight = designHeight * scale;
        canvas.style.marginLeft = ((containerWidth - scaledWidth) / 2) + "px";
        canvas.style.marginTop = ((containerHeight - scaledHeight) / 2) + "px";

        stage.update();
    }

    // Initial resize
    resizeCanvas();

    // Resize on window resize
    window.addEventListener("resize", resizeCanvas);

    return stage;
}
```

## Best Practices Summary

### Architecture
- Use modular Container hierarchy for organization
- Separate static UI (HTML/CSS) from dynamic content (Canvas)
- Implement scene-based asset loading
- Use EventDispatcher for custom application events

### MovieClip Usage
- Set appropriate mode (INDEPENDENT, SINGLE_FRAME, SYNCHED)
- Use labels instead of frame numbers
- Combine timeline states with TweenJS transitions
- Call .stop() for state-based MovieClips

### Performance
- Cache complex vector graphics
- Use sprite sheets for animations
- Disable mouse on non-interactive objects
- Implement flag-based stage updates
- Optimize concurrent asset loading connections

### Events
- Use .on() with scope parameter for proper this context
- Attach custom data to events
- Remove listeners in cleanup to prevent leaks
- Set mouseChildren = false for button-like components

### Educational Content
- Structure by learning modules
- Implement progress tracking and analytics
- Provide immediate visual feedback
- Consider adaptive difficulty
- Test on target devices and browsers

## Additional Considerations

### Browser Compatibility
- CreateJS handles most cross-browser issues
- Test on target browsers (especially mobile)
- Provide fallbacks for older browsers
- Consider using polyfills for modern JS features

### Accessibility
- Use HTML for text content when possible
- Provide keyboard navigation alternatives
- Include ARIA labels for canvas elements
- Ensure sufficient color contrast

### Maintenance Status
**Important**: CreateJS development has slowed significantly. The team has shifted focus to other technologies like Flutter. While CreateJS remains stable and functional, consider this for long-term projects:

- Active maintenance unlikely
- Security updates may be delayed
- New features not expected
- Community support still available

For new projects, evaluate if CreateJS + Animate workflow meets needs or if modern alternatives (Canvas libraries like PixiJS, or HTML5 frameworks) are better suited.
