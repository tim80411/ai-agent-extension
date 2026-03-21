---
name: tunnelbox-site
description: >-
  Use this skill when the user wants to manage TunnelBox sites — add, list,
  or remove sites. Trigger phrases include: "add a site", "create a site",
  "register a site", "list sites", "show my sites", "remove a site",
  "delete a site", "建立 site", "新增站台", "列出 site", "刪除 site",
  "移除站台", "幫我建一個 site", "我的站台有哪些".
---

# TunnelBox Site Management

管理 TunnelBox 靜態站台（add / list / remove）。全程使用中文回應（除非使用者用英文提問）。

## 指令參考

### 新增站台

**靜態模式：**
```bash
tunnelbox site add <name> <folder>
```
- `<name>` — 站台名稱（不可重複）
- `<folder>` — 本地資料夾路徑（會自動轉為絕對路徑）

**Proxy 模式：**
```bash
tunnelbox site add <name> --proxy <url>
```
- `--proxy <url>` — 代理目標 URL（如 `http://localhost:3000`）

**JSON 輸出範例：**
```json
{ "success": true, "data": { "id": "uuid", "name": "my-blog", "serveMode": "static", "folderPath": "/abs/path/dist" } }
```

### 列出所有站台

```bash
tunnelbox site list
tunnelbox site list --json
```

- 無站台時輸出 `No items found.`
- 有站台時輸出表格，欄位：name, mode, folder/target, id

### 移除站台

```bash
tunnelbox site remove <nameOrId>
```
- 可用站台名稱或 UUID

## 執行步驟

當使用者要求管理站台時，依照以下步驟：

### 新增站台

1. 確認使用者提供了資料夾路徑（靜態模式）或 proxy URL。
2. 若使用者未指定名稱，根據資料夾名稱建議一個。
3. 執行指令：
   ```bash
   tunnelbox site add <name> <folder> --json
   ```
   或 proxy 模式：
   ```bash
   tunnelbox site add <name> --proxy <url> --json
   ```
4. 解析 JSON 輸出，向使用者回報站台名稱、ID、資料夾路徑（或 proxy 目標）。
5. 若失敗，根據錯誤訊息說明原因：
   - `Folder not found` — 資料夾不存在，確認路徑是否正確
   - `Site name already exists` — 名稱重複，建議換一個名稱
   - `Invalid proxy URL` — proxy URL 格式不正確

### 列出站台

1. 執行指令：
   ```bash
   tunnelbox site list --json
   ```
2. 解析 JSON 輸出，以清晰格式呈現站台清單。
3. 若無站台，告知使用者目前沒有已註冊的站台，並提示可用 `tunnelbox site add` 新增。

### 移除站台

1. 確認使用者要移除的站台名稱或 ID。
2. 若使用者只說了模糊描述，先用 `tunnelbox site list --json` 查詢，再讓使用者確認。
3. 執行指令：
   ```bash
   tunnelbox site remove <nameOrId> --json
   ```
4. 回報移除結果。
5. 若失敗（`Site not found`），告知使用者站台不存在，並列出現有站台供參考。

## 錯誤處理

所有指令加上 `--json` 以取得結構化輸出。錯誤格式：
```json
{ "success": false, "error": "error message" }
```

- Exit code 1：使用者輸入問題（資料夾不存在、名稱重複、站台找不到）
- Exit code 2：系統層級錯誤

遇到錯誤時，向使用者說明原因並提供可行的解決建議。
