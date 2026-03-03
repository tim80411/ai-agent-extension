# 避免意外 (AS) 檢查項目

## 檢查項清單

| 編號 | 檢查項 | 說明 |
|------|--------|------|
| AS-1 | 隱藏副作用 | 函式名稱暗示無副作用（如 `generate`、`get`、`find`、`validate`），但實際包含資料庫寫入、快取操作、外部 API 呼叫等副作用？ |
| AS-2 | 錯誤碼語意矛盾 | 錯誤回應中使用的錯誤碼是否與其語意一致？成功碼是否被用於錯誤情境？ |
| AS-3 | 交易完整性 | `@Transactional` 區塊中是否有顯式的 `em.flush()`？是否有修改實體但沒有交易包裹的情況？部分提交的風險？ |
| AS-4 | 靜默失敗與錯誤吞噬 | `catch` 區塊是否僅記錄日誌而不重新拋出或產生警報？安全關鍵操作（黑名單、token 作廢）失敗是否被靜默吞掉？ |
| AS-5 | 批次操作原子性 | 批次處理中的錯誤是否可能導致部分成功/部分失敗的不一致狀態？共用 EntityManager 是否累積髒實體？ |
| AS-6 | Null 回傳語意 | 在不應該回傳 null 的場景中（如資料一致性錯誤）是否回傳 null 而非拋出例外？ |
| AS-7 | 安全性 Fallback | 驗證失敗時是否有不安全的 fallback 路徑？（例如簽名驗證失敗後解碼未驗證的 token） |
| AS-8 | 環境判斷 | 環境判斷是否寫死了環境名稱？非正式環境是否暴露了不應暴露的資料（OTP、密碼、內部錯誤）？ |
| AS-9 | 啟動行為 | 模組初始化是否有阻塞行為（長時間輪詢、等待）？超時設定是否可調整？是否影響 K8s 健康檢查？ |

## 指導原則

### 審查心態
以「如果我是第一次接觸這段程式碼的維護者，哪些行為會讓我感到意外？」作為核心問題。目標是找出「看起來做 A，實際做 B」的程式碼。

### 嚴重度判定指引
- **嚴重**：安全相關的意外行為 — token 驗證 fallback 回傳未驗證 payload、安全操作失敗被靜默吞掉
- **重要**：交易完整性問題、操作順序不當導致不一致風險、隱藏副作用、環境敏感資料暴露
- **輕微**：null 回傳語意問題、錯誤碼語意矛盾（非安全場景）、資料庫約束違規被行級吞噬

### 操作順序分析法

對於包含多步驟的操作，使用以下分析框架：

```
步驟 1: 操作 A
步驟 2: 操作 B
步驟 3: 操作 C

問題：
- 若步驟 2 失敗，步驟 1 的效果是否需要回滾？
- 若步驟 3 失敗，步驟 1+2 是否留下不一致狀態？
- 操作順序是否可以調整以降低風險？（例如先清除 token 再更新密碼）
```

### 特別關注模式

#### Fire-and-forget async 呼叫
```typescript
// 危險：沒有 await、沒有 catch
someCallback(() => { this.asyncOperation(); });
```

#### 靜默吞噬安全操作失敗
```typescript
// 危險：黑名單失敗只記錄日誌
try {
  await this.blacklistToken(token);
} catch (error) {
  this.logger.error('Failed', error); // 攻擊者的 token 仍然有效
}
```

#### 簽名驗證 Fallback
```typescript
// 嚴重：驗證失敗後解碼未驗證的 token
try {
  return jwt.verify(token, secret);
} catch {
  return JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString());
}
```

#### 密碼重設操作順序
```typescript
// 危險順序：先改密碼、再清 token（清 token 失敗 = token 可重用）
await updatePassword(user, newPassword);
await clearVerificationToken(token); // 失敗時 token 仍可重複使用

// 安全順序：先清 token、再改密碼
await clearVerificationToken(token);
await updatePassword(user, newPassword);
```
