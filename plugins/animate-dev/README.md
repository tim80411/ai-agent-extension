# Adobe Animate + CreateJS Development Assistant

專為 Adobe Animate + CreateJS 互動專案設計的開發助手，能自動修復常見陷阱並執行最佳實踐。

## 安裝

此 skill 已安裝於：
```
~/.claude/plugins/custom/animate-dev/
```

Claude Code 會自動偵測並載入此 plugin。

## 使用方式

### 建立新元件
```bash
/animate-dev build [元件描述]
```

**範例**：
- `/animate-dev build quiz result display with icon`
- `/animate-dev build menu button with hover state`
- `/animate-dev build scene transition`

**行為**：
- 讀取 index.js 了解元件結構
- 建立遵循專案模式的元件代碼
- 自動處理 lib 初始化、影格暫停、scope 綁定
- 整合到 AppState（如需要）
- 自動驗證初始化順序和清理邏輯

### 整合元件到專案
```bash
/animate-dev integrate [整合描述]
```

**範例**：
- `/animate-dev integrate new analysis button`
- `/animate-dev integrate option selector for scene 15`
- `/animate-dev integrate quiz answer feedback`

**行為**：
- 找到整合點（main.js 或模組檔案）
- 遵循命名規範添加事件處理器（{type}_{id}）
- 更新 AppState（如需要）
- 確保清理邏輯完整
- 自動驗證 scope 保存和事件委派

### 除錯問題
```bash
/animate-dev debug [可選：特定問題描述]
```

**範例**：
- `/animate-dev debug`（掃描所有問題）
- `/animate-dev debug gotoAndStop error`
- `/animate-dev debug memory leak`

**行為**：
- **自動修復所有發現的問題，不詢問**
- 掃描 scope 問題、時序問題、記憶體洩漏
- 驗證 MovieClip 路徑和影格控制
- 檢查效能問題（過多子元件、sprite sheet 建議）
- 提供修復前後的代碼對比

## 功能特色

### 🔧 自動修復
自動更正常見的 CreateJS 陷阱，無需確認：
- Scope 問題：添加 `var self = this` 模式
- 時序問題：重新排序 addChild/gotoAndStop 呼叫
- 記憶體洩漏：添加 removeEventListener 清理
- 路徑錯誤：根據 index.js 驗證
- 影格控制：暫停代表狀態的 MovieClip
- 互動元素：設定 mouseChildren = false

### 📋 主動驗證
操作前總是檢查 index.js：
- 驗證元件類別存在
- 了解元件階層和影格結構
- 確認影格數量（totalFrames）
- 檢查嵌套子元件

### 🎯 Scope 管理
確保所有事件處理器正確綁定 `this`：
```javascript
var self = this;
component.addEventListener("click", function(e) {
  self.handleClick(e);  // 正確的 scope
});
```

### 🧹 記憶體洩漏偵測
識別缺少清理的問題：
```javascript
// 自動修復
if (component) {
  component.removeAllEventListeners();
  parent.removeChild(component);
  component = null;
}
```

### ⚡ 效能分析
建議優化：
- 偵測過多的 display list 子元件（>100 警告）
- 建議使用 sprite sheets
- 識別迴圈中過度的 gotoAndStop 呼叫
- 建議靜態內容使用 cache()

## 專案特定知識

此 skill 了解你的專案結構：

### 全域物件
```javascript
lib          // 從 index.js 匯出的類別定義
_lib         // 早期存取的 lib 參照（用於初始化時機）
_this        // exportRoot 的參照（主時間軸）
stage        // CreateJS Stage 實例
exportRoot   // 主時間軸根元素
AppState     // 全域狀態管理物件
```

### 狀態管理
- 遵循 state.js 的模組模式
- 適當時更新 AppState
- 重置功能中包含清理

### 事件處理
- 使用 game.onclick 的 switch/case 模式
- 命名規範：`{type}_{id}`（例如："menuBtn_1", "itemBtn_3"）
- 事件委派使用 `split("_")` 解析 ID

### 元件生命週期
```javascript
// 標準順序
1. 建立實例：var component = new _lib.ComponentClass();
2. 加到父元件：parent.addChild(component);
3. 控制影格：component.stop(); // 如果影格代表狀態
4. 設定屬性：component.mouseChildren = false; // 互動元素
5. 綁定事件：使用 scope 保存模式
```

## 自動套用的常見修復

### 1. Scope 保存
```javascript
// 修復前
scene.addEventListener("click", function(e) {
  this.handleClick(e);  // 錯誤的 scope!
});

// 修復後
var self = this;
scene.addEventListener("click", function(e) {
  self.handleClick(e);  // 正確的 scope
});
```

### 2. 初始化順序
```javascript
// 修復前
component.gotoAndStop(0);
parent.addChild(component);

// 修復後
parent.addChild(component);
component.gotoAndStop(0);
```

### 3. 記憶體清理
```javascript
// 修復前
parent.removeChild(component);

// 修復後
component.removeAllEventListeners();
parent.removeChild(component);
component = null;
```

### 4. Null 檢查
```javascript
// 修復前
_this.mapView.item_1.gotoAndStop(0);

// 修復後
if (_this.mapView && _this.mapView.item_1) {
  _this.mapView.item_1.gotoAndStop(0);
}
```

### 5. 影格狀態控制
```javascript
// 修復前
var component = new _lib.MenuComponent();
parent.addChild(component);
// 元件會自動播放所有影格

// 修復後
var component = new _lib.MenuComponent();
parent.addChild(component);
component.stop();  // 暫停在當前狀態
```

### 6. 互動元素設定
```javascript
// 修復前
var button = new _lib.ButtonComponent();
parent.addChild(button);
// 子元件可能會阻擋點擊事件

// 修復後
var button = new _lib.ButtonComponent();
parent.addChild(button);
button.mouseChildren = false;  // 防止事件穿透
```

## 執行的最佳實踐

基於研究和代碼分析，此 skill 強制執行：

1. **影格控制在舞台加入後** - 防止 undefined 錯誤
2. **事件監聽器清理** - 防止記憶體洩漏
3. **正確使用 lib/_lib** - 處理初始化時機
4. **命名規範** - 維持一致性（{type}_{id}）
5. **Null 檢查** - 防止運行時錯誤
6. **mouseChildren = false** - 防止事件穿透
7. **Scope 保存** - 確保回調函式中的 `this` 上下文
8. **狀態 vs 動畫區分** - 在需要時暫停影格

## 參考實作

**主要參考**：`js/sceneManager.js`（702 行）

此檔案展示了所有最佳實踐：
- 模組模式
- 初始化順序
- Scope 保存
- 事件委派
- mouseChildren 設定
- 影格暫停（pauseListedMovieClips 函式）
- 清理邏輯
- 元件生命週期管理

有疑問時，參考此檔案。

## 重要檔案參考

操作前會檢查：

1. **index.js**：元件類別定義、階層、影格數
2. **js/utils.js**：輔助函式（getComponent, updateButtonFrame, setComponentVisible）
3. **js/state.js**：AppState 結構
4. **js/config.js**：配置常數
5. **js/main.js**：事件處理模式、初始化

## 輸出格式

完成工作後，skill 會提供：

### 1. 摘要
- 建立/整合/除錯的內容
- 套用的自動修復數量
- 主要變更

### 2. 修改的檔案
列出每個檔案及簡短描述

### 3. 套用的自動修復
每個修復顯示修復前後的代碼片段

### 4. 警告（如有）
- 需要手動審查的效能問題
- 使用者應確認的架構決策

### 5. 後續步驟
- 測試建議
- 相關元件檢查
- 建議的改進

## 驗證清單

每個任務完成前自動檢查：

- ✅ index.js 中存在所有參照的元件
- ✅ addChild 在 gotoAndStop 之前
- ✅ 所有事件處理器使用 `var self = this`
- ✅ 影格編號有效（0-based）
- ✅ AppState 已更新（如需要）
- ✅ removeEventListener 在 removeChild 之前
- ✅ 遵循命名規範（{type}_{id}）
- ✅ 操作前驗證存在性
- ✅ 互動元素設定 mouseChildren = false
- ✅ 代表狀態的 MovieClip 呼叫 .stop()

## 測試範例

### 測試案例 1：建立元件
```bash
/animate-dev build quiz result display with icon
```

**預期**：
- 讀取 index.js 尋找 quiz 相關元件
- 建立包含 scope 保存的元件
- 暫停 MovieClip 影格
- 設定 mouseChildren = false
- 驗證初始化順序

### 測試案例 2：除錯時序問題
引入 bug：
```javascript
component.gotoAndStop(0);
parent.addChild(component);
```
執行：`/animate-dev debug`

**預期**：自動修復為 addChild 優先

### 測試案例 3：整合
```bash
/animate-dev integrate new analysis button
```

**預期**：
- 在 switch 語句中添加事件處理器
- 遵循命名規範
- 包含 scope 保存
- 更新 AppState（如需要）

## 常見問題

### Q: Skill 會自動提交變更嗎？
A: 不會。Skill 會修改檔案但不會自動提交。你需要手動檢查變更並提交。

### Q: 如何知道套用了哪些修復？
A: Skill 會輸出完整的修復前後代碼對比，清楚顯示每個變更。

### Q: 可以針對特定檔案除錯嗎？
A: 可以。使用 `/animate-dev debug [檔案描述]`，skill 會專注於相關檔案。

### Q: Skill 會修改 index.js 嗎？
A: 不會。index.js 是 Adobe Animate 匯出的，skill 只讀取不修改。

### Q: 如何停用某個自動修復？
A: Skill 設計為全自動修復。如果特定修復不適用，可以在修復後手動還原該變更。

## 資源

實作基於以下資源：
- [Adobe Animate HTML5 Canvas 文件](https://adobe.com)
- [CreateJS MovieClip API](https://createjs.com)
- [StackOverflow 常見 CreateJS 陷阱](https://stackoverflow.com)
- 當前代碼庫模式（特別是 sceneManager.js）

## 支援

如有問題或建議：
1. 檢查此 README
2. 參考 `js/sceneManager.js` 的實作範例
3. 執行 `/animate-dev debug` 獲取詳細診斷

## 版本

- **1.0.0**: 初始版本
  - 建立元件功能
  - 整合元件功能
  - 除錯功能與自動修復
  - 支援專案特定模式
