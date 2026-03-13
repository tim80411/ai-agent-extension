# Reference 索引

## 快速對照表

| Reference | 類型 | 一句話描述 |
|-----------|------|-----------|
| `component-rules.md` | 規範型 | 元件命名規則與類型定義 |
| `best-practices.md` | 規範型 | 程式碼組織與狀態管理規範 |
| `error-index.md` | 索引型 | 兩層錯誤索引（Tier 1：症狀匹配表） |
| `errors/*.md` | 診斷+修復型 | 個別錯誤詳情檔（Tier 2：18 個檔案） |
| `createjs-web-patterns.md` | 教學型 | CreateJS API 與架構模式 |
| ~~`common-mistakes.md`~~ | DEPRECATED | 已被 `error-index.md` + `errors/` 取代 |
| ~~`common-patterns.md`~~ | DEPRECATED | 已被 `error-index.md` + `errors/` 取代 |
| ~~`fix-strategies.md`~~ | DEPRECATED | 已被 `error-index.md` + `errors/` 取代 |

---

## 關鍵字 → Reference

| 關鍵字 | 載入 |
|-------|------|
| `btn_`, `state_`, `area_`, `anim_`, `scene_`, 命名規則, 元件類型 | `component-rules.md` |
| AppState, 狀態管理, 初始化順序, cleanup, 審查清單 | `best-practices.md` |
| 診斷, 錯誤, bug, issue, 症狀匹配 | `error-index.md` → `errors/*.md`（兩層索引） |
| TypeError, undefined, scope, this 錯誤, mouseChildren | ~~`common-mistakes.md`~~ → `error-index.md` |
| memory leak, 效能, Ticker, polling, stage.update, cache | ~~`common-patterns.md`~~ → `error-index.md` |
| 修復, fix, before/after, 怎麼改 | ~~`fix-strategies.md`~~ → `errors/*.md` 內含修復 |
| Container, MovieClip, Tween, LoadQueue, EaselJS | `createjs-web-patterns.md` |

---

## Reference 關係

```
識別問題: error-index.md（Tier 1 症狀匹配）
    ↓
載入詳情: errors/*.md（Tier 2 只讀匹配的檔案）
    ↓
內含修復: 每個 errors/*.md 都有 Detection + Fix Strategy
```

```
理解結構: component-rules.md
    ↓
開發實作: best-practices.md + createjs-web-patterns.md
```
