# Error Index - CreateJS Issue Diagnosis

Use this index to match user symptoms to specific error detail files. Read only the matching `errors/*.md` files.

## Functional Errors

| ID | Error Type | Symptoms Keywords | File |
|----|-----------|-------------------|------|
| ERR-MISSING-CREATEJS | CreateJS Library Missing | `createjs is not defined`, library not loaded, 什麼都沒顯示, nothing renders, 載入失敗 | `errors/err-missing-createjs.md` |
| ERR-INIT-ORDER | Initialization Order | `Cannot read property 'gotoAndStop'`, undefined error on frame control, 元件沒反應, component not responding, 初始化順序 | `errors/err-init-order.md` |
| ERR-SCOPE-LOSS | Scope Loss in Callbacks | `this.handleClick is not a function`, wrong `this` context, callback undefined, 回調函數錯誤, scope 問題 | `errors/err-scope-loss.md` |
| ERR-MEMORY-LEAK | Event Listener Memory Leak | memory growing, 記憶體持續增加, detached DOM nodes, listener not removed, 記憶體洩漏 | `errors/err-memory-leak.md` |
| ERR-FRAME-NOT-PAUSED | Frame States Not Paused | auto-playing, 自動播放, animation won't stop, 按鈕閃爍, MovieClip keeps animating, 狀態元件動畫 | `errors/err-frame-not-paused.md` |
| ERR-MOUSE-CHILDREN | mouseChildren Not Set | click not responding, 點擊沒反應, wrong target, 點到子元素, click passes through, 按鈕點擊問題 | `errors/err-mouse-children.md` |
| ERR-FRAME-NUMBER-CONFUSION | Frame Number Confusion | wrong frame, 幀號錯誤, off-by-one, Frame 1 vs Frame 0, 時間軸混亂 | `errors/err-frame-number-confusion.md` |
| ERR-LIB-VS-UNDERSCORELIB | lib vs _lib Confusion | `lib.MyComponent` undefined, 元件找不到, timing issue, 載入時機, intermittent undefined | `errors/err-lib-vs-underscorelib.md` |
| ERR-MISSING-TICKER | Missing Stage Ticker | nothing animates, 畫面凍結, stage not updating, 動畫不播放, application frozen, Ticker 沒設定 | `errors/err-missing-ticker.md` |
| ERR-NULL-PATH | Null Path References | `Cannot read property of undefined`, 路徑錯誤, nested component not found, 元件路徑無效 | `errors/err-null-path.md` |
| ERR-CANVAS-FONT | Canvas Text Font Issues | 字體不顯示, font not showing on mobile, 觸屏字體問題, custom font fallback, 平板字體錯誤 | `errors/err-canvas-font.md` |

## Performance Anti-Patterns

| ID | Anti-Pattern | Symptoms Keywords | Priority | File |
|----|-------------|-------------------|----------|------|
| PERF-LISTENER-LEAK | Event Listener Leak | memory leak, 記憶體洩漏, listener accumulation, 事件監聽器累積, scene switch leak | P0 | `errors/perf-listener-leak.md` |
| PERF-REDUNDANT-BINDINGS | Redundant Event Bindings | event fires multiple times, 事件觸發多次, duplicate handler, 重複註冊, init called twice | P1 | `errors/perf-redundant-bindings.md` |
| PERF-PER-FRAME-OVERHEAD | Per-Frame Overhead | high CPU, CPU 過高, janky animation, 卡頓, ticker loop heavy, 每幀運算過多 | P1 | `errors/perf-per-frame-overhead.md` |
| PERF-MOVIECLIP-LIFECYCLE | MovieClip Lifecycle | hidden animation running, 隱藏動畫仍在播放, CPU idle high, 待機 CPU 高, auto-play background | P2 | `errors/perf-movieclip-lifecycle.md` |
| PERF-EXCESSIVE-STAGE-UPDATE | Excessive stage.update() | slow rendering, 渲染慢, canvas redraws, 畫面閃爍, update in loop, stage.update 過多 | P1 | `errors/perf-excessive-stage-update.md` |
| PERF-MISSING-CACHE | Missing Cache | complex graphics slow, 複雜圖形卡頓, vector redraw, 每幀重繪, static content slow | P3 | `errors/perf-missing-cache.md` |
| PERF-RESOURCE-MANAGEMENT | Resource Management | slow startup, 啟動慢, high memory, 記憶體過高, audio overlap, 音效重疊, lazy load | P3 | `errors/perf-resource-management.md` |
