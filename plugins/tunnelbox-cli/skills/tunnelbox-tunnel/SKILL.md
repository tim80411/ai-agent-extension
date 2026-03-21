---
name: tunnelbox-tunnel
description: >-
  Use this skill when the user wants to expose a site publicly via Cloudflare
  Quick Tunnel, or stop an existing tunnel. Trigger phrases include:
  "公開站台", "把 site 公開到網路", "start a tunnel", "quick tunnel",
  "expose my site", "get a public URL", "share my site publicly",
  "停止 tunnel", "stop tunnel", "關閉公開連結", "取消公開",
  "我要一個公開網址", "幫我開 tunnel", "把網站分享出去".
---

# TunnelBox Tunnel Operations

透過 Cloudflare Quick Tunnel 將本地站台公開至網際網路。全程使用中文回應（除非使用者用英文提問）。

## 指令參考

### 啟動 Quick Tunnel

```bash
tunnelbox tunnel quick <nameOrId>
```
- 自動檢查 cloudflared 是否已安裝
- 若本地伺服器未啟動，會自動啟動
- 回傳公開 URL

**JSON 輸出範例：**
```json
{ "success": true, "data": { "id": "uuid", "name": "my-site", "publicUrl": "https://xxx.trycloudflare.com" } }
```

若伺服器被自動啟動，額外欄位 `serverAutoStarted: true`。
若 tunnel 已在運行，額外欄位 `alreadyRunning: true`。

### 停止 Tunnel

```bash
tunnelbox tunnel stop <nameOrId>
```

**JSON 輸出範例：**
```json
{ "success": true, "data": { "id": "uuid", "name": "my-site", "stopped": true } }
```

若無 tunnel 在運行：`{ "success": true, "data": { "id": "uuid", "name": "my-site", "noTunnel": true } }`

### 環境檢查

```bash
tunnelbox env check
```

**JSON 輸出範例：**
```json
{ "success": true, "data": { "installed": true, "status": "available", "version": "2024.6.1" } }
```

### 安裝 cloudflared

```bash
tunnelbox env install
```

## 執行步驟

### 公開站台（完整流程）

當使用者說「把 XXX 公開到網路上」或類似請求時，依照以下步驟：

1. **確認站台存在**：用 `tunnelbox site list --json` 找到目標站台。若使用者給的是模糊描述，列出站台讓使用者確認。

2. **檢查環境**：執行 `tunnelbox env check --json`，確認 cloudflared 已安裝。
   - 若未安裝，告知使用者並執行 `tunnelbox env install` 安裝。
   - 若版本過舊（status 為 `outdated`），建議使用者更新。

3. **啟動 Quick Tunnel**：
   ```bash
   tunnelbox tunnel quick <nameOrId> --json
   ```
   - tunnel quick 會自動啟動伺服器（若未運行），不需手動 `server start`。

4. **回報結果**：向使用者提供公開 URL，並說明：
   - 這是一個臨時的 Quick Tunnel URL
   - 每次啟動會產生新的 URL
   - 停止方式：`tunnelbox tunnel stop <name>`

### 停止 Tunnel

1. 確認要停止的站台。若不確定，先用 `tunnelbox site list --json` 查詢。
2. 執行：
   ```bash
   tunnelbox tunnel stop <nameOrId> --json
   ```
3. 回報結果。若回應 `noTunnel: true`，告知使用者該站台目前沒有運行中的 tunnel。

## 錯誤處理

所有指令加上 `--json` 以取得結構化輸出。錯誤格式：
```json
{ "success": false, "error": "error message" }
```

常見錯誤與解決建議：

| 錯誤 | 原因 | 建議 |
|------|------|------|
| `cloudflared not installed` | cloudflared 未安裝 | 執行 `tunnelbox env install` 安裝 |
| `Site not found` | 站台名稱或 ID 不正確 | 用 `tunnelbox site list` 確認正確名稱 |

遇到錯誤時，向使用者說明原因並提供可行的解決建議。
