---
name: tunnelbox-auth
description: >-
  Use this skill when the user wants to manage Cloudflare authentication —
  login, check status, or logout. Trigger phrases include: "login cloudflare",
  "登入 cloudflare", "我有登入嗎", "auth status", "登出 cloudflare",
  "logout cloudflare", "認證狀態", "cloudflare 帳號".
---

# TunnelBox 認證操作

管理 Cloudflare 認證（login / status / logout）。全程使用中文回應（除非使用者用英文提問）。

## 指令參考

### 登入 Cloudflare

```bash
tunnelbox auth login --json
```

**JSON 輸出範例（成功）：**
```json
{ "success": true, "data": { "status": "success", "message": "Login successful" } }
```

**JSON 輸出範例（已登入）：**
```json
{ "success": true, "data": { "status": "already_logged_in", "message": "Already logged in" } }
```

### 查看認證狀態

```bash
tunnelbox auth status --json
```

**JSON 輸出範例（已登入）：**
```json
{ "success": true, "data": { "loggedIn": true, "status": "logged_in" } }
```

**JSON 輸出範例（未登入）：**
```json
{ "success": true, "data": { "loggedIn": false, "status": "logged_out" } }
```

### 登出 Cloudflare

```bash
tunnelbox auth logout --json
```

**JSON 輸出範例：**
```json
{ "success": true, "data": { "message": "Logged out successfully" } }
```

## 執行步驟

### 登入

1. 先執行 `tunnelbox auth status --json` 確認是否已登入。
2. 若已登入，告知使用者不需要重複登入。
3. 若未登入，**提醒使用者**：
   > 請先在瀏覽器中登入你的 Cloudflare 帳號（https://dash.cloudflare.com），否則授權流程可能無法正常完成。
4. 使用者確認後，執行：
   ```bash
   tunnelbox auth login --json
   ```
5. 告知使用者瀏覽器將開啟 Cloudflare 授權頁面，需要選擇要授權的網域（zone）。
6. 等待指令完成（最多 2 分鐘），解析 JSON 回報結果。

### 查看認證狀態

1. 執行指令：
   ```bash
   tunnelbox auth status --json
   ```
2. 解析 JSON 輸出，向使用者回報：
   - `loggedIn: true` → 已登入 Cloudflare
   - `loggedIn: false` → 未登入，需要執行 `tunnelbox auth login`

### 登出

1. 執行指令：
   ```bash
   tunnelbox auth logout --json
   ```
2. 回報登出結果。若原本就未登入，告知使用者。

## 錯誤處理

所有指令加上 `--json` 以取得結構化輸出。錯誤格式：
```json
{ "success": false, "error": "error message" }
```

| 錯誤訊息 | 原因 | 建議 |
|---------|------|------|
| Login timed out | 使用者未在 2 分鐘內完成授權 | 確認已在瀏覽器登入 Cloudflare 後重試 |
| Login failed: 認證已取消 | 使用者取消了授權 | 重新執行登入 |
| cloudflared 尚未安裝 | cloudflared 未安裝 | 執行 `tunnelbox env install` |

遇到錯誤時，向使用者說明原因並提供可行的解決建議。
