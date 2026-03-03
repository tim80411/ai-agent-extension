# 可測試性 (TB) 檢查項目

## 檢查項清單

| 編號 | 檢查項 | 說明 |
|------|--------|------|
| TB-1 | 依賴注入 | 是否所有外部依賴都透過建構子注入？是否有直接 `new` 實例或靜態呼叫？ |
| TB-2 | 環境變數存取 | 是否有直接讀取 `process.env` 而非透過 ConfigService 注入？測試中是否能輕鬆替換設定？ |
| TB-3 | 外部資源隔離 | Redis、資料庫、檔案系統等外部資源的存取是否可透過 mock/stub 隔離？是否有繞過服務抽象層直接存取底層 client（如 `getClient()`）的情況？ |
| TB-4 | 介面可替換性 | 是否使用介面或抽象類別讓實作可替換？直接依賴具體類別是否影響可測試性？ |
| TB-5 | 測試覆蓋率 | 核心服務和安全關鍵路徑是否有單元測試？是否有完全沒有測試的重要 service？ |
| TB-6 | 測試品質 | 現有測試是否修改全域狀態（如 `process.env`）？是否有重複的測試案例？setup/teardown 是否正確清理？ |
| TB-7 | 檔案系統依賴 | 是否有直接使用 `fs` 模組而非注入可替換的檔案存取服務？ |
| TB-8 | 模組初始化 | `onModuleInit` 中的邏輯是否可在測試中控制？初始化是否有外部依賴？ |
| TB-9 | E2E 測試基礎設施 | E2E 測試目錄和設定是否存在且可執行？`package.json` 中的測試腳本是否指向有效路徑？ |
| TB-10 | 測試涵蓋完整性 | 現有測試是否只測試包裝器（wrapper）而遺漏核心邏輯？是否有「看起來有測試但實際覆蓋不足」的情況？ |

## 指導原則

### 審查心態
以「如果我需要為這段程式碼寫單元測試，會遇到什麼困難？」作為核心問題。

### 嚴重度判定指引
- **嚴重**：核心服務（認證、JWT、Token 管理、密碼處理）完全沒有單元測試；E2E 測試基礎設施不存在
- **重要**：一般服務沒有測試、直接 `process.env` 存取、繞過服務抽象層
- **輕微**：測試品質問題（全域狀態修改、重複案例）、包裝器測試

### 檢測方法

#### 找出無測試的 service
```bash
# 列出所有 service 檔案
find src -name '*.service.ts' -not -name '*.spec.ts'

# 檢查對應的 .spec.ts 是否存在
for f in $(find src -name '*.service.ts' -not -name '*.spec.ts'); do
  spec="${f%.ts}.spec.ts"
  if [ ! -f "$spec" ]; then echo "NO TEST: $f"; fi
done
```

#### 檢查 process.env 直接存取
```bash
grep -rn 'process\.env\.' src/ --include='*.ts' | grep -v '.spec.ts' | grep -v 'node_modules'
```

#### 檢查 E2E 測試
```bash
ls -la test/ 2>/dev/null || echo "test/ directory does not exist"
cat package.json | grep 'test:e2e'
```

### 特別關注
- 安全相關 service（JWT、Token、認證）的測試覆蓋是最高優先
- `onModuleInit` 中的阻塞操作（輪詢、等待）影響測試啟動速度
- 依賴數量超過 10 個的 service 通常是可測試性的紅旗
