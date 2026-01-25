# Reference 索引

## 快速對照表

| Reference | 類型 | 一句話描述 |
|-----------|------|-----------|
| `component-rules.md` | 規範型 | 元件命名規則與類型定義 |
| `best-practices.md` | 規範型 | 程式碼組織與狀態管理規範 |
| `common-mistakes.md` | 診斷型 | 功能性錯誤診斷（10 種錯誤模式） |
| `common-patterns.md` | 診斷型 | 效能反模式識別（7 大類問題） |
| `fix-strategies.md` | 修復型 | Before/After 程式碼範例 |
| `createjs-web-patterns.md` | 教學型 | CreateJS API 與架構模式 |

---

## 關鍵字 → Reference

| 關鍵字 | 載入 |
|-------|------|
| `btn_`, `state_`, `area_`, `anim_`, `scene_`, 命名規則, 元件類型 | `component-rules.md` |
| AppState, 狀態管理, 初始化順序, cleanup, 審查清單 | `best-practices.md` |
| TypeError, undefined, scope, this 錯誤, mouseChildren | `common-mistakes.md` |
| memory leak, 效能, Ticker, polling, stage.update, cache | `common-patterns.md` |
| 修復, fix, before/after, 怎麼改 | `fix-strategies.md` |
| Container, MovieClip, Tween, LoadQueue, EaselJS | `createjs-web-patterns.md` |

---

## Reference 關係

```
識別問題: common-mistakes.md / common-patterns.md
    ↓
修復問題: fix-strategies.md
```

```
理解結構: component-rules.md
    ↓
開發實作: best-practices.md + createjs-web-patterns.md
```
