---
name: tunnelbox-publish
description: >-
  Use this skill when the user wants to publish a local folder or project to the
  public internet in one step. Trigger phrases include: "publish this",
  "deploy to public", "make this public", "share this online",
  "發布到公開網路", "把這個發布出去", "公開這個資料夾", "一鍵發布",
  "把 dist 發布", "發布到 test.example.com", "幫我公開這個站".
---

# TunnelBox 一鍵發布

一句話完成「建站 → 公開到網路」的完整流程。全程使用中文回應（除非使用者用英文提問）。

本 Skill 組合了 site、tunnel、domain、env、auth 等操作，提供端到端的發布體驗。

## 發布模式

| 模式 | 觸發條件 | 結果 |
|------|---------|------|
| Quick Tunnel | 使用者只說「發布」、「公開」 | 產生臨時公開 URL（每次不同） |
| 固定網域 | 使用者指定了網域（如 `test.example.com`） | 綁定持久公開 URL |

## 執行步驟

### Quick Tunnel 發布（使用者說「把 ./dist 發布到公開網路」）

1. **檢查環境**：
   ```bash
   tunnelbox env check --json
   ```
   - 若 `installed: false`，自動安裝：
     ```bash
     tunnelbox env install --json
     ```
   - 若安裝失敗，告知使用者原因並停止。

2. **檢查站台是否已存在**：
   ```bash
   tunnelbox site list --json
   ```
   - 解析 `data` 陣列，比對 `folderPath` 是否與使用者指定的資料夾相同。
   - 若找到既有站台，**使用既有站台**，不重複建立。記下站台名稱。

3. **建立站台**（若不存在）：
   ```bash
   tunnelbox site add <name> <folder> --json
   ```
   - 名稱可根據資料夾名稱自動產生。

4. **啟動 Quick Tunnel**：
   ```bash
   tunnelbox tunnel quick <nameOrId> --json
   ```
   - 解析 JSON，取得 `publicUrl`。

5. **回報結果**：向使用者提供公開 URL，說明這是臨時 URL，重啟後會改變。

### 固定網域發布（使用者說「把 ./dist 發布到 test.example.com」）

1. **檢查環境**（同上步驟 1）。

2. **確認登入狀態**：
   ```bash
   tunnelbox auth status --json
   ```
   - 若 `loggedIn: false`，提醒使用者：
     > 請先在瀏覽器中登入 Cloudflare 帳號（https://dash.cloudflare.com），然後執行授權。
   - 引導使用者執行 `tunnelbox auth login`，等待完成。

3. **檢查/建立站台**（同 Quick Tunnel 步驟 2-3）。

4. **綁定固定網域**：
   ```bash
   tunnelbox domain bind <nameOrId> <domain> --json
   ```
   - 解析 JSON，取得 `publicUrl`。

5. **回報結果**：向使用者提供固定網域 URL，說明這是持久 URL，不會因重啟而改變。

## JSON 輸出範例

### env check
```json
{ "success": true, "data": { "installed": true, "status": "available", "version": "2024.1.0" } }
```

### site add
```json
{ "success": true, "data": { "id": "uuid", "name": "my-blog", "serveMode": "static", "folderPath": "/abs/path/dist" } }
```

### tunnel quick
```json
{ "success": true, "data": { "id": "uuid", "name": "my-blog", "publicUrl": "https://xxx.trycloudflare.com" } }
```

### domain bind
```json
{ "success": true, "data": { "id": "uuid", "name": "my-blog", "domain": "test.example.com", "publicUrl": "https://test.example.com" } }
```

## 錯誤處理

所有指令加上 `--json` 以取得結構化輸出。錯誤格式：
```json
{ "success": false, "error": "error message" }
```

| 錯誤訊息 | 階段 | 建議 |
|---------|------|------|
| cloudflared not installed | env check | 自動執行 `tunnelbox env install` |
| TunnelBox app is not running | env install | 提示使用者先啟動 TunnelBox |
| Folder not found | site add | 確認資料夾路徑是否正確 |
| Site name already exists | site add | 使用既有站台或換一個名稱 |
| Not logged in | domain bind | 引導使用者執行 `tunnelbox auth login` |
| Login timed out | auth login | 確認已在瀏覽器登入 Cloudflare 後重試 |

遇到錯誤時，說明當前處於發布流程的哪個階段、錯誤原因、以及如何解決後繼續。
