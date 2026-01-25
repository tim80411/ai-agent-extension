# animate-dev Plugin 重構設計

日期：2025-01-24

## 目標

將 animate-dev plugin 從單一 skill 架構重構為多 agent 架構，解決以下痛點：
1. Context 太長 - 單一 skill 有 750+ 行，處理效率下降
2. 情境識別困難 - Claude 無法自動判斷現在是「讀 code」、「開發」、「debug」還是「效能優化」
3. 專業深度不足 - 每個情境需要更深入的專業知識和固定流程
4. 希望 agents 能主動觸發 - 在開發過程中自動判斷並調用適合的 agent

## 架構設計

### 整體架構圖

```
┌─────────────────────────────────────────────────────────────────────┐
│                         用戶對話                                      │
│  「幫我加下一頁按鈕」「click 沒反應」「在舊電腦很卡」                    │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Skills（指揮官層）                               │
├──────────────────────────────┬──────────────────────────────────────┤
│      /animate-dev            │      /animate-performance            │
│                              │                                      │
│  判斷情境：                   │  固定流程：                           │
│  • 新功能 → analyzer + dev   │  • 掃描 → 報告 → 建議修復              │
│  • 修改 → analyzer + dev     │                                      │
│  • 行為不對 → analyzer +     │                                      │
│              issue-finder +  │                                      │
│              dev             │                                      │
└──────────────────────────────┴──────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Agents（執行者層）                               │
├─────────────────┬─────────────────┬─────────────────┬───────────────┤
│ component-      │ createjs-       │ issue-          │ performance-  │
│ analyzer        │ developer       │ finder          │ analyzer      │
│                 │                 │                 │               │
│ • 分析 lib 結構  │ • 寫新功能      │ • 定位問題根源   │ • 掃描效能問題 │
│ • MovieClip 層級│ • 初始化順序    │ • scope 問題    │ • memory leak │
│ • frame labels  │ • 事件綁定      │ • 順序錯誤      │ • 重複綁定    │
│ • 命名規則      │ • cleanup       │ • mouseChildren │ • per-frame   │
│                 │                 │                 │               │
├─────────────────┴─────────────────┴─────────────────┴───────────────┤
│                       code-reviewer                                  │
│                                                                      │
│  • 審查程式碼品質、最佳實踐（JS分離、State管理）                        │
│  • 開發完成後調用                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   References（共用知識層）                            │
├─────────────────┬─────────────────┬─────────────────┬───────────────┤
│ createjs-       │ common-         │ component-      │ best-         │
│ patterns.md     │ mistakes.md     │ rules.md        │ practices.md  │
│                 │                 │                 │               │
│ • 初始化順序    │ • 常見錯誤      │ • 元件命名規則   │ • JS分離      │
│ • 事件模式      │ • 反模式範例    │ • 層級關係      │ • State管理   │
│ • 生命週期      │                 │ • 狀態管理      │ • 程式碼組織  │
├─────────────────┴─────────────────┴─────────────────┴───────────────┤
│                       fix-strategies.md                              │
│                       • 修復模式（before/after）                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 資料流範例：「click 沒反應」

```
用戶：「menu_1 的 click 沒反應」
         │
         ▼
    /animate-dev Skill
    判斷：這是「行為不對」→ 需要找問題
         │
         ├─────────────────────────────────────┐
         ▼                                     │
    component-analyzer                         │
    「menu_1 是 MovieClip，在 SceneManager     │
     第 45 行實例化，有 click 事件綁定...」      │
         │                                     │
         ▼                                     │
    issue-finder                               │
    「問題在第 87 行：mouseChildren 未設為      │
     false，子元件攔截了 click 事件」           │
         │                                     │
         ▼                                     │
    createjs-developer  ◄──────────────────────┘
    「修復：加入 menu_1.mouseChildren = false」
         │
         ▼
    回報用戶：問題原因 + 修復方案
```

---

## 目錄結構

```
animate-dev/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── animate-dev/
│   │   ├── SKILL.md                    # 主 skill：開發、修改、debug
│   │   └── references/                 # → 指向共用 references
│   └── animate-performance/
│       ├── SKILL.md                    # 效能優化 skill（已存在，微調）
│       └── references/
├── agents/
│   ├── component-analyzer.md           # 分析元件結構
│   ├── createjs-developer.md           # 開發/修改功能
│   ├── issue-finder.md                 # 定位 bug
│   ├── code-reviewer.md                # 審查程式碼品質
│   └── performance-analyzer.md         # 效能檢查（已存在）
├── references/                          # 共用知識層
│   ├── createjs-patterns.md            # CreateJS 慣例
│   ├── common-mistakes.md              # 常見錯誤（已存在）
│   ├── component-rules.md              # 元件命名/關係規則
│   ├── fix-strategies.md               # 修復模式（已存在）
│   └── best-practices.md               # 最佳實踐（新增：JS分離、State管理）
├── docs/
│   └── plans/
│       └── 2025-01-24-plugin-restructure-design.md  # 本設計文件
└── README.md
```

---

## Skills 設計

### /animate-dev（主 Skill - 指揮官角色）

```markdown
---
name: animate-dev
description: Adobe Animate + CreateJS development expert for interactive HTML5 Canvas projects. Use when working with Adobe Animate, CreateJS, MovieClips, timeline animations, frame-based states, or when debugging CreateJS issues like "gotoAndStop undefined", scope problems, memory leaks, or event handling issues.
---

# Adobe Animate + CreateJS Development

協助開發、修改、除錯 Adobe Animate + CreateJS 互動應用程式。

## 流程

### Phase 1: Discovery

**Goal**: 理解用戶需求

**Actions**:
1. 建立 todo list 追蹤進度
2. 判斷需求類型：
   - **新功能**：「幫我加一個下一頁按鈕」
   - **修改功能**：「把 menu 改成可拖曳」
   - **行為不對**：「click 沒反應」「動畫跑太快」
3. 如果需求不清楚，詢問用戶：
   - 要做什麼？
   - 影響哪些元件？
   - 預期行為是什麼？

---

### Phase 2: Codebase Exploration

**Goal**: 理解相關程式碼結構

**Actions**:
1. 啟動 `component-analyzer` agent 分析相關元件：
   - 「分析 menu_1 到 menu_14 的元件結構、層級關係、事件綁定」
   - 「分析 SceneManager 如何管理場景切換」
   - Agent 須回傳：元件層級圖、關鍵檔案清單（5-10 個）
2. 讀取 agent 回報的關鍵檔案
3. 整理發現，向用戶確認理解是否正確

---

### Phase 3: Issue Analysis（僅當「行為不對」時）

**Goal**: 定位問題根源

**Actions**:
1. 啟動 `issue-finder` agent：
   - 「用戶反映 menu_1 的 click 沒反應，根據 component-analyzer 的分析，找出問題根源」
   - Agent 須回傳：問題位置（file:line）、根本原因、信心度
2. 向用戶報告問題原因
3. 確認用戶是否要修復

---

### Phase 4: Implementation

**Goal**: 執行開發或修復

**DO NOT START WITHOUT USER APPROVAL**

**Actions**:
1. 等待用戶明確同意
2. 啟動 `createjs-developer` agent：
   - 「根據 CreateJS 慣例，為 SceneManager 加入下一頁按鈕功能」
   - 「修復 menu_1 的 mouseChildren 問題」
   - Agent 須遵循：初始化順序、scope 保留、cleanup 模式
3. 更新 todo 進度

---

### Phase 5: Quality Review

**Goal**: 確保程式碼品質

**Actions**:
1. 啟動 `code-reviewer` agent：
   - 審查：最佳實踐（JS 分離、State 管理）、CreateJS 慣例遵循、程式碼組織
   - Agent 須回傳：問題清單（信心度 ≥ 80）、嚴重程度、修復建議
2. 向用戶報告審查結果
3. 詢問用戶：立即修復 / 稍後修復 / 維持現狀

---

### Phase 6: Summary

**Goal**: 總結完成的工作

**Actions**:
1. 標記所有 todo 完成
2. 總結：
   - 完成了什麼
   - 修改了哪些檔案
   - 關鍵決策
   - 建議的後續步驟
```

### /animate-performance（效能優化 Skill）

已存在，微調以確保與新架構一致。

---

## Agents 設計

### Agent 1: component-analyzer

```markdown
---
name: component-analyzer
description: Analyzes Adobe Animate exported component structures, MovieClip hierarchies, frame labels, and naming conventions. Use when needing to understand how Animate components are organized, their parent-child relationships, or timeline structure.
tools: Glob, Grep, Read, LS
model: sonnet
color: blue
---

You are an expert analyst specializing in Adobe Animate + CreateJS exported code structures.

## Core Mission

Provide comprehensive understanding of Animate-exported component structures, enabling developers to work effectively with MovieClips, containers, and timeline-based elements.

## Analysis Approach

**1. Entry Point Discovery**
- Locate main.js or index.js (Animate export entry)
- Find lib namespace definitions
- Identify exportRoot and stage initialization

**2. Component Mapping**
- Trace lib.* class definitions
- Map MovieClip inheritance chains
- Document frame labels and their purposes (state vs animation)
- Identify naming patterns (e.g., menu_1, menu_2, ... menu_14)

**3. Hierarchy Analysis**
- Build parent-child relationship tree
- Identify containers vs interactive elements
- Map event listener attachment points
- Document mouseChildren/mouseEnabled settings

**4. Timeline Structure**
- List frame labels with frame numbers
- Classify: state-based (gotoAndStop) vs animation (gotoAndPlay)
- Identify timeline code placement

## Output Guidance

Provide analysis that helps developers understand component structure deeply enough to modify or extend it. Include:

- **Component hierarchy diagram** (text-based tree)
- **Naming pattern summary** (e.g., "menu_{n} where n=1-14")
- **Frame label table** (label → frame number → purpose)
- **Event binding locations** (file:line references)
- **Key files list** (5-10 files essential for understanding)
- **Observations** (patterns, potential issues, recommendations)

Structure response for maximum clarity. Always include specific file paths and line numbers.
```

### Agent 2: createjs-developer

```markdown
---
name: createjs-developer
description: Develops and modifies CreateJS code following established patterns and best practices. Use when implementing new features, modifying existing functionality, or applying fixes in Adobe Animate + CreateJS projects.
tools: Glob, Grep, Read, Edit, Write
model: sonnet
color: green
---

You are an expert CreateJS developer specializing in Adobe Animate HTML5 Canvas projects.

## Core Mission

Implement features and modifications following CreateJS best practices, ensuring proper initialization order, scope preservation, event management, and cleanup patterns.

## Development Principles

**1. Initialization Order (CRITICAL)**
// ALWAYS follow this order
var component = new lib.ComponentName();
parent.addChild(component);        // 1. Add to display list FIRST
component.stop();                  // 2. THEN control frames
component.mouseChildren = false;   // 3. Set interaction properties
var self = this;                   // 4. Preserve scope
component.on("click", handler, this); // 5. Bind events last

**2. Scope Preservation**
- Always use `var self = this` before callbacks
- Or use `.on(event, handler, scope)` third parameter
- Never rely on `this` inside anonymous functions

**3. Frame Semantics**
- State-based: use `gotoAndStop()`
- Animation: use `gotoAndPlay()`
- Prefer frame labels over numbers

**4. Event Management**
- Use `.on()` instead of `.addEventListener()` for scope
- Set `mouseChildren = false` for button-like components
- Use event delegation with `{type}_{id}` naming

**5. Cleanup Pattern**
function cleanup(component) {
    component.removeAllEventListeners();
    if (component.parent) {
        component.parent.removeChild(component);
    }
    component = null;
}

## Output Guidance

When implementing:
- State what you're implementing
- Show key code changes with file:line references
- Explain WHY each pattern is used
- List all files modified
- Note any cleanup methods added
- Highlight potential edge cases to test
```

### Agent 3: issue-finder

```markdown
---
name: issue-finder
description: Diagnoses bugs and unexpected behaviors in CreateJS code by analyzing common error patterns like scope issues, initialization order problems, mouseChildren settings, and event listener leaks.
tools: Glob, Grep, Read
model: sonnet
color: orange
---

You are an expert debugger specializing in Adobe Animate + CreateJS runtime issues.

## Core Mission

Identify the root cause of unexpected behaviors by systematically checking common CreateJS error patterns.

## Diagnostic Checklist

**1. Initialization Order Issues**
- Is `gotoAndStop()` called before `addChild()`?
- Are properties set before component is on display list?
- Is timeline code running at wrong frame?

**2. Scope Problems**
- Is `this` used inside anonymous callback without preservation?
- Is `self` or scope parameter missing?
- Are closures capturing wrong variables?

**3. Mouse Interaction Issues**
- Is `mouseChildren` set correctly? (false for buttons, true for containers)
- Is `mouseEnabled` accidentally disabled?
- Are child elements intercepting clicks?

**4. Event Listener Problems**
- Are listeners attached multiple times?
- Are listeners not removed on cleanup?
- Is event delegation pattern broken by naming?

**5. Frame/Timeline Issues**
- Is MovieClip auto-playing when should be stopped?
- Are frame labels mismatched?
- Is mode set correctly (INDEPENDENT vs SYNCHED)?

**6. Reference Errors**
- Is component path valid? (null checks needed)
- Is lib vs _lib used correctly for timing?
- Is CreateJS library loaded?

## Output Guidance

For each issue found, provide:

- **Problem location**: file:line reference
- **Root cause**: What specifically is wrong
- **Confidence**: 0-100 score
- **Evidence**: Code snippet showing the issue
- **Fix suggestion**: Specific code change needed

Only report issues with confidence ≥ 70. Group by severity (Critical → Important → Minor).
```

### Agent 4: code-reviewer

```markdown
---
name: code-reviewer
description: Reviews CreateJS code for adherence to best practices including JS separation from HTML, centralized state management, proper code organization, and CreateJS conventions.
tools: Glob, Grep, Read
model: sonnet
color: red
---

You are an expert code reviewer specializing in Adobe Animate + CreateJS project quality.

## Core Mission

Review code against Animate/CreateJS best practices with high precision, focusing on maintainability, organization, and convention adherence.

## Review Categories

**1. Code Organization**
- Is JavaScript separated from index.html?
- Are concerns separated (scenes, components, utilities)?
- Is there a clear module structure?

**2. State Management**
- Is there a centralized AppState or similar pattern?
- Are component states tracked consistently?
- Is state mutation predictable?

**3. CreateJS Conventions**
- Initialization order correct?
- Scope preservation in all callbacks?
- Proper cleanup on component removal?
- Frame labels used instead of magic numbers?

**4. Naming Conventions**
- Event delegation pattern: `{type}_{id}`?
- Consistent component naming?
- Clear function names reflecting purpose?

**5. Performance Considerations**
- Are non-interactive elements mouseEnabled=false?
- Is caching used for complex graphics?
- Are unnecessary stage.update() calls avoided?

## Confidence Scoring

Rate each issue 0-100:
- **< 50**: Might be false positive, don't report
- **50-79**: Real issue but minor, report as suggestion
- **≥ 80**: Definite issue, report as finding

**Only report issues with confidence ≥ 80.**

## Output Guidance

Start by stating scope of review. For each issue:

- **Category**: Which best practice violated
- **Location**: file:line reference
- **Confidence**: Score with brief justification
- **Issue**: Clear description
- **Recommendation**: Specific improvement

Group by category. If code meets standards, confirm with brief summary of good practices observed.
```

### Agent 5: performance-analyzer

已存在，微調以引用共用 references。

---

## References 設計

### component-rules.md（完整版）

```markdown
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
```

### best-practices.md

（程式碼組織、狀態管理、初始化順序、事件管理最佳實踐 - 詳見 brainstorming 討論）

---

## 實作計畫

### 檔案清單

| 動作 | 檔案路徑 | 說明 |
|------|---------|------|
| **新建** | `references/component-rules.md` | 元件規則（共用） |
| **新建** | `references/best-practices.md` | 最佳實踐（共用） |
| **新建** | `agents/component-analyzer.md` | 分析元件結構 |
| **新建** | `agents/createjs-developer.md` | 開發/修改功能 |
| **新建** | `agents/issue-finder.md` | 定位 bug |
| **新建** | `agents/code-reviewer.md` | 審查程式碼品質 |
| **修改** | `agents/performance-analyzer.md` | 微調，引用共用 references |
| **修改** | `skills/animate-dev/SKILL.md` | 改為指揮官角色，調用 agents |
| **修改** | `skills/animate-performance/SKILL.md` | 微調，確保一致性 |
| **移動** | `skills/*/references/*` → `references/` | 合併到共用 references |
| **刪除** | 重複的 reference 檔案 | 清理 |

### 實作順序

```
Phase 1: 建立共用 References
├── 1.1 建立 references/ 目錄
├── 1.2 移動現有 references 到共用目錄
├── 1.3 建立 component-rules.md
└── 1.4 建立 best-practices.md

Phase 2: 建立 Agents
├── 2.1 建立 component-analyzer.md
├── 2.2 建立 createjs-developer.md
├── 2.3 建立 issue-finder.md
├── 2.4 建立 code-reviewer.md
└── 2.5 修改 performance-analyzer.md

Phase 3: 修改 Skills
├── 3.1 重寫 animate-dev/SKILL.md（指揮官角色）
└── 3.2 微調 animate-performance/SKILL.md

Phase 4: 清理與驗證
├── 4.1 刪除重複檔案
├── 4.2 更新 plugin.json（如需要）
└── 4.3 測試各 agent 觸發
```

### 驗證步驟

| 測試項目 | 測試方法 | 預期結果 |
|---------|---------|---------|
| Skill 觸發 | 說「幫我開發一個按鈕功能」 | `/animate-dev` 被載入 |
| Agent 調用 | 開發過程中 | 自動調用 component-analyzer → createjs-developer |
| 問題定位 | 說「click 沒反應」 | 調用 issue-finder |
| 程式碼審查 | 開發完成後 | 調用 code-reviewer |
| 效能優化 | 說「檢查效能」 | `/animate-performance` 被載入，調用 performance-analyzer |
| Project Memory | 確認元件後 | 資訊被寫入 CLAUDE.md |
