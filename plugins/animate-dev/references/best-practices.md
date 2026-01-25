# Animate 專案最佳實踐

## 程式碼組織

### 1. JS 與 HTML 分離

**不要這樣做**
```html
<!-- index.html -->
<script>
var canvas = document.getElementById("canvas");
var stage = new createjs.Stage(canvas);
// ... 所有程式碼都在這裡
</script>
```

**應該這樣做**
```html
<!-- index.html -->
<script src="js/lib/createjs.min.js"></script>
<script src="js/main.js"></script>
```

```javascript
// js/main.js
(function() {
    var canvas = document.getElementById("canvas");
    var stage = new createjs.Stage(canvas);
    init();
})();
```

### 2. 模組化結構

```
js/
├── lib/
│   └── createjs.min.js
├── modules/
│   ├── SceneManager.js
│   ├── AudioManager.js
│   └── StateManager.js
├── scenes/
│   ├── MenuScene.js
│   └── GameScene.js
├── main.js              # 入口點
└── config.js            # 配置常數
```

---

## 狀態管理

### 中心化 AppState

```javascript
var AppState = {
    // 當前狀態
    currentScene: null,
    currentFrame: 0,
    isPlaying: false,

    // 用戶數據
    userData: {
        progress: 0,
        settings: {}
    },

    // 元件參照（用於 cleanup）
    refs: {
        stage: null,
        scenes: {},
        activeListeners: []
    },

    // 狀態變更方法
    setScene: function(sceneName) {
        if (this.currentScene) {
            this.cleanupScene(this.currentScene);
        }
        this.currentScene = sceneName;
        this.dispatchEvent("sceneChange", sceneName);
    },

    // Cleanup 追蹤
    registerListener: function(target, event, handler, scene) {
        target.on(event, handler);
        this.refs.activeListeners.push({target: target, event: event, handler: handler, scene: scene});
    },

    cleanupScene: function(sceneName) {
        // 移除該場景的所有 listeners
        var self = this;
        this.refs.activeListeners = this.refs.activeListeners.filter(function(item) {
            if (item.scene === sceneName) {
                item.target.off(item.event, item.handler);
                return false;
            }
            return true;
        });
    }
};
```

### 為何需要中心化狀態？

1. **Debug 容易**：所有狀態在一個地方，console.log(AppState) 即可查看
2. **避免 scope 問題**：不需要 `var self = this`，直接用 `AppState.currentScene`
3. **Cleanup 追蹤**：統一管理 listener，避免 memory leak
4. **跨元件通信**：透過 AppState 事件，元件間解耦

---

## 初始化順序

### 標準初始化流程

```javascript
function initApp() {
    // 1. 設置 Stage
    AppState.refs.stage = new createjs.Stage("canvas");

    // 2. 設置 Ticker
    createjs.Ticker.framerate = 30;
    createjs.Ticker.on("tick", AppState.refs.stage);

    // 3. 建立 Container 層級（如果需要）
    setupContainers();

    // 4. 載入資源
    loadAssets(function() {
        // 5. 初始化場景
        initFirstScene();
    });
}
```

### 元件初始化順序（CRITICAL）

```javascript
// ALWAYS follow this order
// 1. Instantiate
var component = new lib.ComponentName();

// 2. Add to parent FIRST
parent.addChild(component);

// 3. THEN control frames (if state-based)
component.stop();  // or component.gotoAndStop(frameNumber);

// 4. Set interaction properties
component.mouseChildren = false;  // For buttons/single-target interaction

// 5. Bind events with scope preservation
var self = this;
component.on("click", function(e) {
    self.handleClick(e);
}, this);
```

**Why this order matters**:
- `addChild` first ensures component is on display list
- Frame control AFTER addChild prevents "undefined" errors
- Event binding last ensures component is fully initialized

---

## 事件管理最佳實踐

### 1. 使用 .on() 的 scope 參數

```javascript
// 需要 var self = this
var self = this;
button.on("click", function() {
    self.handleClick();
});

// 更好：使用 scope 參數
button.on("click", this.handleClick, this);
```

### 2. 儲存 listener 參照

```javascript
// 無法移除
button.on("click", function() { doSomething(); });

// 可以移除
var clickHandler = function() { doSomething(); };
button.on("click", clickHandler);
// 之後：button.off("click", clickHandler);
```

### 3. 使用 AppState 追蹤

```javascript
// 註冊時追蹤
AppState.registerListener(button, "click", clickHandler, "menuScene");

// 離開場景時自動清理
AppState.cleanupScene("menuScene");
```

### 4. 事件委派模式

```javascript
// 命名格式：{type}_{id}
// Examples: "menuBtn_1", "locationBtn_3", "quizOption_2"

var self = this;
container.on("click", function(e) {
    var arr = e.target.name.split("_");
    var prefix = arr[0];    // e.g., "menuBtn"
    var id = parseInt(arr[1]);  // e.g., 1, 2, 3

    switch(prefix) {
        case "menuBtn":
            self.handleMenu(id);
            break;
        case "locationBtn":
            self.handleLocation(id);
            break;
    }
}, this);
```

---

## Cleanup 模式

### 標準 Cleanup 流程

```javascript
function cleanup(component) {
    // 1. Remove event listeners FIRST
    if (component) {
        component.removeAllEventListeners();
    }

    // 2. Remove from parent
    if (component && component.parent) {
        component.parent.removeChild(component);
    }

    // 3. Nullify reference
    component = null;
}
```

### 場景 Cleanup

```javascript
function cleanupScene(scene) {
    if (!scene) return;

    // 1. 停止所有動畫
    createjs.Tween.removeTweens(scene);

    // 2. 遞迴清理子元件
    while (scene.numChildren > 0) {
        var child = scene.getChildAt(0);
        cleanup(child);
    }

    // 3. 清理場景本身
    cleanup(scene);
}
```

---

## 效能考量

### 1. mouseEnabled 設定

```javascript
// 純展示元件：完全禁用滑鼠
background.mouseEnabled = false;
background.mouseChildren = false;

// 按鈕元件：自己接收，不傳給子元件
button.mouseEnabled = true;
button.mouseChildren = false;

// 容器：傳遞給子元件
container.mouseEnabled = true;
container.mouseChildren = true;
```

### 2. 避免不必要的 stage.update()

```javascript
// 不好：每次都更新
function changeState(state) {
    component.gotoAndStop(state);
    stage.update();  // 每次都呼叫
}

// 好：批次更新或依賴 Ticker
function changeState(state) {
    component.gotoAndStop(state);
    needsUpdate = true;  // 標記需要更新
}

// Ticker 中統一更新
createjs.Ticker.on("tick", function() {
    if (needsUpdate) {
        stage.update();
        needsUpdate = false;
    }
});
```

### 3. 快取複雜圖形

```javascript
// 快取靜態複雜圖形
var bounds = complexShape.getBounds();
if (bounds) {
    complexShape.cache(bounds.x, bounds.y, bounds.width, bounds.height);
}

// 內容變更時更新快取
complexShape.updateCache();

// 不需要時清除快取
complexShape.uncache();
```

---

## 審查清單

程式碼審查時檢查：

### 程式碼組織
- [ ] JavaScript 是否從 index.html 分離？
- [ ] 是否有清晰的模組結構？
- [ ] 關注點是否分離（場景、元件、工具）？

### 狀態管理
- [ ] 是否有中心化的 AppState 或類似模式？
- [ ] 元件狀態是否一致追蹤？
- [ ] 狀態變更是否可預測？

### CreateJS 慣例
- [ ] 初始化順序是否正確？（addChild → gotoAndStop → events）
- [ ] 所有 callback 是否有 scope 保留？
- [ ] 元件移除時是否有正確 cleanup？
- [ ] 是否使用 frame label 而非數字？

### 命名慣例
- [ ] 是否使用事件委派模式 `{type}_{id}`？
- [ ] 元件命名是否一致？
- [ ] 函數命名是否清楚反映用途？

### 效能
- [ ] 非互動元件是否設定 mouseEnabled=false？
- [ ] 複雜圖形是否使用快取？
- [ ] 是否避免不必要的 stage.update() 呼叫？
