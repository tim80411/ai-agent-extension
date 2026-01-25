# Animate 元件規則

## 命名規則的目的

**命名規則是幫助 agent 快速理解元件意義**：
- `btn_submit` → 這是一個按鈕，用於提交
- `state_feedback` → 這是狀態元件，會有多個視覺狀態
- `anim_loading` → 這是動畫，可能會循環播放

**當元件沒有遵循命名規則時**：
- 無法從名稱判斷元件類型
- 必須一一確認元件的用途和行為
- 確認後的資訊必須儲存到 Project Memory

---

## 元件命名慣例：`{type}_{name}`

所有 MovieClip 元件建議遵循 `{type}_{name}` 格式。

### Type 1: btn - 按鈕元件

**用途**：觸發互動的可點擊元件

**特性**：
- `mouseChildren = false`（整體接收點擊）
- 可能有多個 frame 表示狀態（normal, hover, pressed）

**範例**：
```javascript
var submitBtn = _this.btn_submit;
submitBtn.mouseChildren = false;
submitBtn.on("click", handleSubmit, this);
```

---

### Type 2: state - 狀態元件

**用途**：用 frame 表示不同視覺狀態，使用 `gotoAndStop()` 切換

**特性**：
- 每個 frame 代表一個離散狀態
- 不會自動播放，必須手動切換
- **優先使用 frame label**
- 狀態命名根據元件用途變化，沒有固定名稱

**CRITICAL**：遇到 state 元件時，必須詢問用戶：
```
「state_{name} 有幾個影格？每個影格代表什麼狀態？」
例如：Frame "idle" = 初始狀態, Frame "correct" = 正確, Frame "wrong" = 錯誤
```

**範例**：
```javascript
// 優先用 label
var feedback = _this.state_feedback;
feedback.gotoAndStop("idle");     // 初始狀態

function showCorrect() {
    feedback.gotoAndStop("correct");  // 切換到正確狀態
}

// 如果沒有 label，用 frame number（需先確認各 frame 意義）
feedback.gotoAndStop(0);  // Frame 0 = idle
feedback.gotoAndStop(1);  // Frame 1 = correct
```

---

### Type 3: area - 區域元件

**用途**：容器區域，用於放置動態內容（圖片、文字、影片）

**特性**：
- 作為 placeholder，內容動態載入
- 通常不需要 frame 切換

**範例**：
```javascript
var imageArea = _this.area_image;
var bitmap = new createjs.Bitmap("path/to/image.jpg");
imageArea.addChild(bitmap);
```

---

### Type 4: anim - 動畫元件

**用途**：連續播放的動畫，使用 `gotoAndPlay()` 播放

**特性**：
- 可能一直循環播放
- 或在特定時機觸發播放
- 通常不需要手動停止（除非有 loop 控制）

**何時使用**：
- 載入動畫、轉場效果
- 角色動作（走路、跳躍）
- 背景動畫效果

**範例**：
```javascript
// 立即播放並循環
var loadingAnim = _this.anim_loading;
loadingAnim.gotoAndPlay("loop");

// 特定時機播放
var transitionAnim = _this.anim_transition;
transitionAnim.stop();  // 初始停止

function playTransition() {
    transitionAnim.gotoAndPlay("enter");
}

// 監聽動畫結束（如果有 label）
transitionAnim.on("animationend", function() {
    transitionAnim.gotoAndStop("idle");
}, this);
```

**循環控制**：
```javascript
// 在 Animate 時間軸最後一格加入：
this.gotoAndPlay("loopStart");  // 跳回循環起點

// 或用程式控制
anim.loop = true;   // 自動循環
anim.loop = false;  // 播放一次
```

---

### Type 5: scene - 場景元件

**用途**：完整的場景頁面，需要 `new` 建立並加入 stage

**特性**：
- 不直接存在於場景，需要動態建立
- 切換場景時需要 cleanup 舊場景

**CRITICAL**：專案開始時必須詢問用戶：
```
1. 「這個專案有幾個場景？」
2. 「每個場景的用途是什麼？」
   例如：scene_1 = 首頁, scene_2 = 主要內容, scene_3 = 測驗
```

**範例**：
```javascript
var currentScene = null;

function switchScene(sceneName) {
    // 1. Cleanup 舊場景
    if (currentScene) {
        currentScene.removeAllEventListeners();
        if (currentScene.parent) {
            currentScene.parent.removeChild(currentScene);
        }
        currentScene = null;
    }

    // 2. 建立新場景（CRITICAL: 必須用 new）
    var SceneClass = lib[sceneName];
    if (typeof SceneClass === 'undefined') {
        console.error("Scene not found: " + sceneName);
        return;
    }

    var newScene = new SceneClass();

    // 3. 加入 stage
    stage.addChild(newScene);
    currentScene = newScene;

    stage.update();
}

// 使用
switchScene("scene_1");
switchScene("scene_2");
```

---

## 元件確認流程

### 情況 1：元件名稱符合規則

```
元件名稱：btn_next
→ 自動識別：這是按鈕元件
→ 套用 btn 的標準處理方式
```

### 情況 2：元件名稱不符合規則

```
元件名稱：menu_1, menu_2, ... menu_14
→ 無法判斷：這是什麼類型的元件？
→ 需要詢問用戶確認
```

**詢問模板**：
```
「我發現元件 {component_name} 的命名沒有遵循 {type}_{name} 規則。
請問這個元件是什麼類型？

A) 按鈕（btn）- 可點擊，觸發動作
B) 狀態（state）- 有多個影格代表不同狀態
C) 動畫（anim）- 播放連續動畫
D) 區域（area）- 容器，放置動態內容
E) 其他 - 請說明用途」
```

**確認後追問（如果是 state）**：
```
「了解，{component_name} 是狀態元件。
請問它有哪些狀態（frame）？每個代表什麼？

例如：
- Frame 0 或 label "___": ___
- Frame 1 或 label "___": ___
...」
```

---

## Frame Label 使用規則

### 優先順序
1. **優先使用 frame label** - 可讀性高、維護性好
2. **沒有 label 時** - 詢問用戶各 frame 的意義，並記錄到 Project Memory

### 詢問模板

當遇到沒有 label 的元件時：
```
「我發現 {component_name} 沒有 frame label。
請問這個元件有幾個影格？每個影格代表什麼？

例如：
- Frame 0: ___
- Frame 1: ___
- Frame 2: ___

這樣我才能正確使用 gotoAndStop()。」
```

---

## Project Memory 儲存

### 什麼要存到 Project Memory？

確認過的專案領域知識，包括：
- 元件類型對照表
- 各 state 元件的 frame 定義
- scene 結構和用途
- 專案特有的命名慣例
- 其他重要的專案規則

### 儲存位置

儲存到專案根目錄的 `CLAUDE.md` 或 `.claude/project-memory.md`：

```markdown
# Project Memory: [專案名稱]

## 元件類型對照

| 元件名稱 | 類型 | 說明 |
|---------|------|------|
| menu_1 ~ menu_14 | btn | 選單按鈕，點擊切換內容 |
| feedback | state | 回饋狀態 |
| character | anim | 角色動畫 |

## State 元件定義

### feedback
| Frame | Label | 意義 |
|-------|-------|------|
| 0 | idle | 初始狀態，無顯示 |
| 1 | correct | 正確回饋，綠色勾勾 |
| 2 | wrong | 錯誤回饋，紅色叉叉 |
| 3 | hint | 提示狀態，顯示提示文字 |

### character
| Frame | Label | 意義 |
|-------|-------|------|
| 0 | idle | 站立不動 |
| 1-10 | walk | 走路動畫（循環） |
| 11-15 | jump | 跳躍動畫 |

## Scene 結構

| Scene | 用途 |
|-------|------|
| scene_1 | 首頁/介紹頁 |
| scene_2 | 主要學習內容 |
| scene_3 | 測驗頁面 |
| scene_4 | 結果頁面 |

## 專案特有規則

- 所有 menu 按鈕使用事件委派模式
- 場景切換時需要播放 anim_transition
- ...
```

### 儲存時機

Agent 在以下時機應該更新 Project Memory：
1. 首次分析專案結構後
2. 確認新元件的類型和定義後
3. 發現專案特有規則後
4. 用戶提供新的專案知識後

### 讀取時機

Agent 在開始工作前應該：
1. 檢查 Project Memory 是否存在
2. 如果存在，先讀取已知的專案知識
3. 避免重複詢問已確認過的資訊

---

## 驗證清單

實作前確認：
- [ ] 元件類型已識別（btn / state / area / anim / scene）
- [ ] 命名遵循 `{type}_{name}` 格式，或已確認非標準命名的用途
- [ ] state 元件的各 frame 意義已確認
- [ ] anim 元件的播放時機已確認（自動 / 觸發 / 循環）
- [ ] scene 元件數量和用途已確認
- [ ] 確認的資訊已儲存到 Project Memory
