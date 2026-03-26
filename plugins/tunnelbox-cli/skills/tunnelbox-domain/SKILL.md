---
name: tunnelbox-domain
description: >-
  Use this skill when the user wants to bind or unbind a fixed domain for a
  TunnelBox site. Trigger phrases include: "bind domain", "綁定網域",
  "固定網域", "unbind domain", "解除綁定", "domain bind", "domain unbind",
  "把站台綁到", "自訂網域", "custom domain".
---

# TunnelBox Domain 綁定操作

管理 TunnelBox 站台的固定網域綁定（bind / unbind）。全程使用中文回應（除非使用者用英文提問）。

## 指令參考

### 綁定固定網域

```bash
tunnelbox domain bind <nameOrId> <domain> --json
```

**JSON 輸出範例（成功）：**
```json
{ "success": true, "data": { "id": "uuid", "name": "my-site", "domain": "test.example.com", "publicUrl": "https://test.example.com" } }
```

### 解除固定網域

```bash
tunnelbox domain unbind <nameOrId> --json
```

**JSON 輸出範例（成功）：**
```json
{ "success": true, "data": { "id": "uuid", "name": "my-site", "message": "Domain unbound successfully" } }
```

**JSON 輸出範例（無綁定）：**
```json
{ "success": true, "data": { "id": "uuid", "name": "my-site", "message": "No domain binding found" } }
```

## 執行步驟

### 綁定固定網域

1. 先確認使用者已登入 Cloudflare：
   ```bash
   tunnelbox auth status --json
   ```
   若未登入，提示使用者先執行 `tunnelbox auth login`。

2. 確認使用者提供了站台名稱（或 ID）和目標網域。
3. 若使用者不確定站台名稱，先用 `tunnelbox site list --json` 查詢。
4. 執行指令：
   ```bash
   tunnelbox domain bind <nameOrId> <domain> --json
   ```
5. 解析 JSON 輸出，向使用者回報：
   - 綁定成功的網域和公開 URL
   - Named Tunnel 已建立

### 解除固定網域

1. 確認使用者已登入 Cloudflare（同上）。
2. 確認使用者要解除的站台名稱或 ID。
3. 若使用者描述模糊，先用 `tunnelbox site list --json` 查詢。
4. 執行指令：
   ```bash
   tunnelbox domain unbind <nameOrId> --json
   ```
5. 回報解除結果。若站台原本沒有綁定，告知使用者。

## 錯誤處理

所有指令加上 `--json` 以取得結構化輸出。錯誤格式：
```json
{ "success": false, "error": "error message" }
```

| 錯誤訊息 | 原因 | 建議 |
|---------|------|------|
| Not logged in | 未登入 Cloudflare | 執行 `tunnelbox auth login` |
| Site not found | 站台名稱或 ID 不存在 | 用 `tunnelbox site list` 確認 |
| No domain binding found | 該站台沒有綁定網域 | 無需操作 |

遇到錯誤時，向使用者說明原因並提供可行的解決建議。
