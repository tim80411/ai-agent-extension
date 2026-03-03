# 模組化 (MD) 檢查項目

## 檢查項清單

| 編號 | 檢查項 | 說明 |
|------|--------|------|
| MD-1 | 單一職責 | 模組是否包含過多不相關的關注點？是否有模組同時負責 4+ 個不相關的領域（例如 JWT 簽章 + JWKS + 快取監控 + 金鑰輪換）？ |
| MD-2 | 提供者所有權 | 模組是否直接匯入並重新提供（re-provide）其他模組的 service 類別？這會產生重複實例，在 ORM 場景中導致不同的 EntityManager。 |
| MD-3 | 控制器職責 | 控制器是否僅負責 HTTP 層委派？是否有商業邏輯、資料轉換、驗證邏輯、分頁計算、實體轉 DTO 轉換方法？ |
| MD-4 | Repository 模式 | Service 是否繞過 Repository 直接使用 EntityManager（`em.findOne`、`em.find`、`em.persist`）？無過濾條件的 `em.find(Entity, {})` 是否全表載入？ |
| MD-5 | 重複匯入 | 同一模組是否被匯入兩次（裸匯入 + `forwardRef`）？NestJS 會將它們作為兩個模組參照處理。 |
| MD-6 | 模組封裝 | 是否有模組重新宣告其他模組的提供者（如 `providers: [ExternalRepository]`）而非透過匯入模組使用匯出？ |
| MD-7 | 循環依賴 | `forwardRef` 的使用是否合理？是否有潛在的循環依賴路徑？子模組之間的交叉匯入是否有記錄？ |
| MD-8 | 模組放置 | 功能模組是否放在正確的位置？基礎設施元件（如 schema 維護控制器）是否放在資料庫啟動模組內？ |
| MD-9 | 依賴方向 | 依賴箭頭是否從 feature → common 流動？common 模組是否反向匯入了 feature 模組的類別（`import { XService } from '../../modules/...'`）？ |

## 指導原則

### 審查心態
以「如果我需要將其中一個模組抽取為獨立的微服務或 npm 套件，需要修改多少地方？」作為衡量模組化程度的心理實驗。

### 嚴重度判定指引
- **嚴重**：
  - common 模組匯入 feature 模組的類別（依賴方向反轉，MD-9）
  - 重複匯入同一模組（可能產生雙重提供者，MD-5）
  - 直接重新提供其他模組的 service（MikroORM EntityManager 不同實例，MD-2）
- **重要**：
  - 控制器包含商業邏輯（MD-3）
  - 繞過 Repository 直接使用 EntityManager（MD-4）
  - 模組承擔過多職責（MD-1）
  - 循環依賴風險（MD-7）
- **輕微**：
  - 模組放置不當（MD-8）
  - 重新宣告外部提供者（MD-6）

### NestJS 模組分析法

#### 依賴方向檢查
```bash
# 找出 common 模組匯入 feature 模組的情況
grep -rn "from '.*modules/" src/common/ --include='*.ts'
```

#### 重複匯入檢查
```bash
# 在模組檔案中找出同一模組出現兩次的情況
grep -A 20 'imports:' src/**/*.module.ts | grep -E 'forwardRef|Module'
```

#### 提供者所有權檢查
```bash
# 找出模組 providers 中引用其他模組目錄的 service
grep -B 5 -A 30 'providers:' src/**/*.module.ts
```

### 模組邊界評估

健康的模組邊界：
```
AuthModule
  imports: [JwtAuthModule, AccountsModule]  ← 匯入模組
  providers: [AuthService]                   ← 只有自己的 service
  exports: [AuthService]                     ← 明確匯出
```

不健康的模組邊界：
```
JwtAuthModule
  imports: [SMSVerificationModule]           ← common 匯入 feature
  providers: [                               ← 重新提供其他模組的類別
    AccountFacadeService,                    ← 應屬於 AccountsModule
    AccountRepository,                       ← 應屬於 AccountsModule
    PasswordRepository,                      ← 應屬於 PasswordModule
  ]
```
