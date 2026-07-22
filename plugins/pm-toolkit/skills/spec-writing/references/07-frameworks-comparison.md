# 方法論比較

## 總覽

| 方法論 | 核心理念 | 最適合 | 產出物 |
|--------|---------|--------|--------|
| INVEST | 單個 Story 的品質檢查 | 日常 Story 撰寫後的驗證 | 檢查結果（pass/fail） |
| JTBD | 理解使用者動機 | 探索階段、定義產品方向 | Job Statement |
| Shape Up | 固定時間框架內解決問題 | 中大型功能的範圍界定 | Pitch 文件 |
| Working Backwards | 從客戶體驗反推 | 新產品/新功能的立項 | PR/FAQ 文件 |

---

## INVEST

**來源：** Bill Wake, 2003

**用途：** 撰寫完 Story 後的品質檢查工具。不是撰寫方法，而是驗證方法。

**六項標準：**
- **I**ndependent — 可獨立開發
- **N**egotiable — 實作細節可協商
- **V**aluable — 有明確價值
- **E**stimable — 可估算工作量
- **S**mall — 一個 Sprint 可完成
- **T**estable — 可明確判斷是否完成

**何時用：** 每個 Story 寫完後過一次。

---

## Jobs-to-be-Done (JTBD)

**來源：** Clayton Christensen / Tony Ulwick

**核心格式：**
```
當 [情境] 時，
我想要 [動機]，
以便 [期望成果]。
```

**與 User Story 的差異：**

| | User Story | JTBD |
|---|-----------|------|
| 焦點 | 功能（What） | 動機（Why） |
| 粒度 | 可實作的單位 | 較抽象的目標 |
| 適用階段 | 開發中 | 探索/策略 |

**範例：**
- **JTBD：** 當我準備明天的課堂時，我想要快速產出適合學生程度的練習題，以便不需要花整個晚上出題。
- **User Story：** 身為國小老師，我需要上傳教材後自動生成練習題，以便節省備課時間。

**何時用：** 產品方向不明確時，先用 JTBD 理解使用者動機，再轉化為 User Story。

---

## Shape Up

**來源：** Basecamp / Ryan Singer

**核心概念：**

1. **Appetite（胃口）：** 先決定願意花多少時間，而非估算要花多少時間
2. **Pitch（提案）：** 包含 Problem、Appetite、Solution、Rabbit Holes、No-gos
3. **Breadboard：** 用文字描述流程（Places → Affordances → Connections），刻意不做 UI 設計
4. **Hill Chart：** 用上坡（探索中）和下坡（執行中）表達進度

**Pitch 結構：**
```
Problem:  老師的 AI 工具散落在各平台，沒有統一入口
Appetite: 2 週
Solution: 統一部署到 subdomain，建立標準流程
Rabbit Holes:
  - Streaming API 的 proxy 轉發可能複雜
  - 20 個專案的程式碼差異可能比預期大
No-gos:
  - 不做使用者認證
  - 不做自動擴展
```

**何時用：** 中大型功能需要界定範圍時。特別適合「我們知道要做什麼，但不確定要做多大」的情境。

---

## Working Backwards (PR/FAQ)

**來源：** Amazon

**核心做法：** 假設產品已完成，寫一篇面向客戶的新聞稿（Press Release），再附上常見問答（FAQ）。

**PR 結構：**
1. 標題（最大的客戶利益）
2. 副標題（目標客群 + 核心價值）
3. 問題段落（客戶現在的痛點）
4. 解決方案段落（產品如何解決）
5. 引述（假想的客戶推薦語）
6. 行動呼籲

**FAQ 結構：**
- 外部 FAQ：客戶會問的問題（價格？相容性？隱私？）
- 內部 FAQ：團隊會問的問題（成本？時程？依賴？）

**何時用：** 新產品立項時。強迫團隊從客戶視角思考，避免「技術很酷但沒人需要」的陷阱。

---

## 實際建議：組合使用

```
1. 產品探索階段 → JTBD（理解動機）
2. 範圍界定階段 → Shape Up Pitch（定義邊界和 appetite）
3. Sprint 規劃階段 → User Story + Enabler Story（可執行的單位）
4. 品質檢查階段 → INVEST（逐條驗證）
```

不需要每個階段都完整走過。根據專案的不確定性程度，選擇需要的階段：
- 不確定性高（新產品）→ 從 JTBD 開始
- 不確定性中（新功能）→ 從 Shape Up Pitch 開始
- 不確定性低（明確需求）→ 直接寫 Story + INVEST 檢查
