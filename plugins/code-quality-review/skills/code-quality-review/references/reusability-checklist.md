# 可重用性 (RU) 檢查項目

## 檢查項清單

| 編號 | 檢查項 | 說明 |
|------|--------|------|
| RU-1 | 重複邏輯 | 是否有相同或高度相似的邏輯出現在多個地方？設定查詢、錯誤範圍判斷、key 建構、data 物件建構等是否重複？ |
| RU-2 | 重複元件 | 是否有功能相同的裝飾器、工具函式、或服務存在多個版本？例如兩個 `CurrentUser` 裝飾器。 |
| RU-3 | 資料物件建構 | 相同的資料結構（如 `{ path: request.url, method: request.method }`）是否在多處重複建構？ |
| RU-4 | 基礎類別利用 | 基礎類別/抽象類別是否充分利用？子類別中是否有應該被提升到基礎類別的共用模式？ |
| RU-5 | 回傳值臭蟲 | 是否有建構了物件、修改後卻回傳新建構的另一個物件（丟棄第一個的修改）？這是功能性臭蟲。 |
| RU-6 | 集合操作 | 是否有手動展開/遍歷集合而非使用 `Object.values()`、`flatMap()` 等標準方法？新增項目是否需要手動維護列表？ |
| RU-7 | 既有工具忽略 | 專案中已有的工具類別（如 `RedisKeyUtil`、`IdUtil`、`ErrorCodeUtil`）是否被新程式碼忽略，改為手動實作相同功能？ |
| RU-8 | 臨時 ID 產生 | 是否有使用 `Date.now() + Math.random()` 而非專用 ID 產生工具（如 `crypto.randomUUID()`）的情況？ |
| RU-9 | Guard/Interceptor 組合 | 功能相似的 Guard 或 Interceptor 是否可以透過組合/繼承重用，而非重新實作相同的 JWT 處理、Observable 轉換等邏輯？ |
| RU-10 | 領域例外使用 | 是否有繞過專案領域例外系統直接使用 NestJS 原始例外（`ForbiddenException`、`BadRequestException`）的情況？ |

## 指導原則

### 審查心態
以「如果我需要修改這個行為，需要在幾個地方同步修改？遺漏一處會怎樣？」作為核心問題。

### 嚴重度判定指引
- **嚴重**：此視角**不應有嚴重發現**。重複程式碼通常不會直接導致臭蟲或安全性問題。
- **重要**：
  - 丟棄修改後物件的回傳值臭蟲（RU-5，這是功能性問題）
  - 重複元件（兩個相同功能的裝飾器/服務）
  - 手動展開影響正確性（新增領域時遺漏）
  - Guard 重新實作導致功能缺陷（如 `@Public()` 不生效）
- **輕微**：
  - 私有 key 建構器忽略既有工具
  - 臨時 ID 產生方式
  - 原始例外繞過領域系統
  - 錯誤範圍判斷重複

### 重複偵測法

#### 設定查詢重複
```bash
# 找出相同的 configService.get 呼叫
grep -rn "configService.get" src/ --include='*.ts' | sort -t: -k3
```

#### 相同裝飾器檢查
```bash
# 找出可能重複的自訂裝飾器
find src -name '*.decorator.ts' | xargs grep 'createParamDecorator\|SetMetadata'
```

#### 既有工具盤點
```bash
# 列出專案中的工具類別
find src -name '*util*' -o -name '*helper*' | grep -v '.spec.'
```

### 回傳值臭蟲模式

這是最需要注意的模式，因為它是實際的功能性臭蟲：

```typescript
// 臭蟲：建構 → 修改 → 回傳新物件（丟棄修改）
const response = ResponseDto.success(data, token);  // 建構第一個
this.addMetadata(response, request);                  // 修改第一個
return ResponseDto.success(data, token);              // 回傳新的，metadata 丟失

// 正確：回傳被修改的物件
const response = ResponseDto.success(data, token);
this.addMetadata(response, request);
return response;  // 回傳同一個
```

### 組合 vs 重新實作

好的重用（組合）：
```typescript
// AdminAuthGuard 繼承 JwtAuthGuard，自動獲得 @Public() 支援
class AdminAuthGuard extends JwtAuthGuard {
  handleRequest(err, user, info, context) {
    const result = super.handleRequest(err, user, info, context);
    return this.checkAdminRole(result);
  }
}
```

壞的重用（重新實作）：
```typescript
// AdminAuthGuard 從 AuthGuard('jwt') 重新開始，遺漏 @Public() 等功能
class AdminAuthGuard extends AuthGuard('jwt') {
  canActivate(context) {
    // 手動重寫 JWT 驗證 + Observable 處理
    // @Public() 裝飾器在這裡不生效
  }
}
```
