---
name: tunnelbox-env
description: >-
  Use this skill when the user wants to check or install cloudflared for
  TunnelBox. Trigger phrases include: "check cloudflared", "is cloudflared
  installed", "install cloudflared", "檢查 cloudflared", "安裝 cloudflared",
  "tunnelbox 環境", "環境檢查", "cloudflared 狀態".
---

# TunnelBox 環境檢查與安裝

檢查並安裝 cloudflared 環境。全程使用中文回應（除非使用者用英文提問）。

## 指令參考

### 環境檢查

```bash
tunnelbox env check --json
```

**JSON 輸出範例（已安裝）：**
```json
{ "success": true, "data": { "installed": true, "status": "available", "version": "2024.1.0" } }
```

**JSON 輸出範例（未安裝）：**
```json
{ "success": true, "data": { "installed": false, "status": "not_found" } }
```

**JSON 輸出範例（版本過舊）：**
```json
{ "success": true, "data": { "installed": true, "status": "outdated", "version": "2023.1.0", "errorMessage": "..." } }
```

### 安裝 cloudflared

```bash
tunnelbox env install --json
```

**JSON 輸出範例（成功安裝）：**
```json
{ "success": true, "data": { "installed": true, "version": "2024.1.0" } }
```

**JSON 輸出範例（已安裝）：**
```json
{ "success": true, "data": { "installed": true, "alreadyInstalled": true, "version": "2024.1.0" } }
```

## 執行步驟

### 檢查環境

1. 執行指令：
   ```bash
   tunnelbox env check --json
   ```
2. 解析 JSON 輸出，向使用者回報：
   - `installed: true` + `status: "available"` → cloudflared 已安裝，版本為 X
   - `installed: true` + `status: "outdated"` → cloudflared 已安裝但版本過舊，建議更新
   - `installed: false` → cloudflared 未安裝，建議執行 `tunnelbox env install`

### 安裝 cloudflared

1. 先執行 `tunnelbox env check --json` 確認是否需要安裝。
2. 若已安裝且版本正常，告知使用者不需要重複安裝。
3. 若未安裝，執行：
   ```bash
   tunnelbox env install --json
   ```
4. 解析 JSON 輸出，回報安裝結果。
5. 若失敗，說明可能原因（網路問題、權限不足）。

**注意**：`env install` 需要 TunnelBox app 正在運行。若 app 未開啟，會收到錯誤訊息 `TunnelBox app is not running`，請提示使用者先啟動 TunnelBox。

## 錯誤處理

所有指令加上 `--json` 以取得結構化輸出。錯誤格式：
```json
{ "success": false, "error": "error message" }
```

| 錯誤訊息 | 原因 | 建議 |
|---------|------|------|
| TunnelBox app is not running | App 未啟動 | 請先開啟 TunnelBox |
| 網路/下載相關錯誤 | 網路連線問題 | 檢查網路連線後重試 |

遇到錯誤時，向使用者說明原因並提供可行的解決建議。
