# 驗收標準撰寫原則

## 核心規則

驗收標準描述 **「What — 要達成什麼」**，不描述 **「How — 怎麼達成」**。

---

## Outcome-Focused vs. Implementation-Focused

### 好（Outcome-Focused）

```
- 使用者可透過 HTTPS 安全存取所有工具
- 頁面載入時間 < 3 秒
- 分享連結時顯示正確的預覽標題與描述
- 前端原始碼中不可見任何 API Key
```

### 壞（Implementation-Focused）

```
- 設定 GCP managed SSL 憑證
- 使用 Cloud CDN 加速靜態資源
- 設定 og:title 和 og:description meta tags
- API Key 存放於 GCP Secret Manager
```

壞的版本規定了具體的技術方案。如果團隊發現更好的方案（例如用 Cloudflare 而非 Cloud CDN），這些驗收標準就會變成阻礙。

---

## Given-When-Then 格式

適合描述互動行為的驗收標準。

```
GIVEN 我是一位老師
WHEN 我輸入 LessonHelp.nani.com.tw
THEN 我看到「教案分析與設計」工具的首頁
AND 所有 AI 功能正常運作
```

```
GIVEN 我是管理者
WHEN 我查看費用報表
THEN 我能看到每個專案的 AI API 累計費用
```

---

## 撰寫檢查清單

- [ ] 每條標準是否可被獨立測試（pass/fail）？
- [ ] 非技術人員是否能讀懂？
- [ ] 是否描述結果而非手段？
- [ ] 是否涵蓋錯誤/邊界情境（不只是 happy path）？
- [ ] 是否可量化（有明確的數字或可觀測的行為）？

---

## 常見錯誤

| 錯誤 | 問題 | 修正 |
|------|------|------|
| 「使用 Redis 快取」 | 規定實作技術 | 「回應時間 < 200ms」 |
| 「按鈕應為藍色」 | 規定視覺設計 | 「使用者能清楚辨識主要操作」 |
| 「呼叫 /api/v2/users」 | 規定 API 設計 | 「系統能取得使用者資訊」 |
| 「程式碼覆蓋率 > 80%」 | 衡量手段而非結果 | 「核心流程有自動化測試保護」 |
