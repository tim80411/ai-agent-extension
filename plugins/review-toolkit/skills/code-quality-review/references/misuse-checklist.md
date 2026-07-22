# 難以誤用 (HM) 檢查項目

## 檢查項清單

| 編號 | 檢查項 | 說明 |
|------|--------|------|
| HM-1 | 函式簽名清晰度 | 函式參數是否容易混淆？多個同型別參數（如 3 個 string）是否可能被錯位傳入？應使用型別化參數物件。 |
| HM-2 | DTO 驗證完整性 | DTO 的驗證規則是否完整？是否缺少 `@IsNotEmpty`、`@MinLength`？跨欄位驗證（如 password = confirmPassword）是否存在？同一概念的不同 DTO 驗證規則是否一致？ |
| HM-3 | 參數順序一致性 | 同一操作在不同層級（controller → service → repository）的參數順序是否一致？是否有「第一個參數從 account 切換為 uid」的風險？ |
| HM-4 | 回傳型別安全性 | 是否有回傳 `any`、`Promise<any>`、`Record<string, any>` 或大型匿名物件字面值？TypeScript 的型別檢查是否被繞過？ |
| HM-5 | 權限檢查安全性 | 權限檢查是否使用魔術數字（如 `identity & 8`）？是否有多個 fallback 路徑增加攻擊面？ |
| HM-6 | 危險操作防護 | 硬刪除（物理刪除）操作是否有確認機制或軟刪除替代方案？不可復原的操作是否有安全網？ |
| HM-7 | 列舉與常數使用 | 核心欄位（如狀態、角色、性別）是否使用普通 `number`/`string` 而非列舉型別？`user.gender = 99` 是否能在編譯期被捕捉？ |
| HM-8 | 密碼與機敏資料處理 | 是否有明文密碼被儲存？函式介面是否讓「明文密碼」的傳入看起來像正常操作？ |
| HM-9 | 匿名物件回傳 | 大型匿名物件字面值（30+ 欄位）是否應被型別化的 DTO 取代？欄位新增/重新命名/錯誤賦值是否會在靜默中發生？ |

## 指導原則

### 審查心態
以「一個合理但不夠仔細的開發者使用這個 API 時，最可能犯什麼錯？」作為核心問題。好的 API 應該讓「正確使用比錯誤使用更容易」。

### 嚴重度判定指引
- **嚴重**：`Promise<any>` 在認證流程中（完全打敗 TypeScript 分析）、缺少跨欄位驗證（如 confirmPassword）在註冊流程中
- **重要**：核心欄位使用 `number` 而非列舉、參數順序不一致、硬刪除無防護、明文密碼儲存、權限檢查有多個 fallback
- **輕微**：內部函式回傳 `number` 而非列舉、`Record<string, any>` 累加器

### 跨層參數追蹤法

對於涉及多層呼叫的操作，追蹤參數在每一層的簽名：

```
Controller: method(account, password)
    ↓
Service:    method(account, newPassword, passwordPlain)
    ↓
Repository: method(uid, newPassword, plainPassword)
```

問題：
- 第一個參數從 `account` 變成 `uid`，呼叫者是否正確轉換？
- 三個字串參數是否可能被錯位？
- 建議使用型別化參數物件消除歧義。

### DTO 驗證一致性檢查

同一概念的不同 DTO 應有一致的驗證規則：

```
RegisterDto.account:      @IsString @IsNotEmpty @MinLength(8) @Matches(...)
CheckAccountDto.account:  @IsString  ← 缺少 @IsNotEmpty @MinLength
```

若驗證寬鬆的 DTO 用於相同的資料路徑，則可能繞過嚴格 DTO 的驗證。

### 權限檢查分析

好的權限檢查：
```typescript
// 單一權威路徑
return (user.identity & Identity.ADMIN) !== 0;
```

危險的權限檢查：
```typescript
// 多個 fallback 路徑 = 多個攻擊向量
if (user.identity !== undefined) return (user.identity & 8) !== 0;
if (user.isAdmin) return true;                    // token 可注入
if (user.identities?.includes('admin')) return true; // token 可注入
```
