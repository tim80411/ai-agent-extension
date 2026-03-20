# TunnelBox CLI Reference

TunnelBox 是一個本地靜態網站管理工具，同時提供 Electron 桌面應用與獨立 CLI。
CLI 二進位名稱為 `tunnelbox`，透過 `npm` 安裝後可直接在終端使用。

## 安裝

> 目前 CLI 尚未發布至 npm registry，僅支援從原始碼安裝。

```bash
# 從專案目錄安裝（開發模式）
pnpm cli:build
npm link

# 或直接執行（開發模式）
pnpm cli:dev
node out/cli/index.js <command>
```

## 全域選項

| 選項 | 說明 |
|------|------|
| `--json` | 所有輸出改為 JSON 格式：`{ "success": true, "data": ... }` 或 `{ "success": false, "error": "..." }` |
| `--version` | 顯示版本號 |
| `--help` | 顯示幫助訊息 |

---

## 指令樹

```
tunnelbox [--json]
  site
    add <name> <folder>       # 註冊一個靜態資料夾為 site
    list                      # 列出所有已註冊的 site
    remove <nameOrId>         # 移除 site（用名稱或 UUID）
  server
    start <nameOrId>          # 啟動 HTTP 伺服器（自動選 port 3000-9000）
    stop <nameOrId>           # 停止 HTTP 伺服器
  env
    check                     # 偵測 cloudflared 安裝狀態與版本
  tunnel
    quick <nameOrId>          # 啟動 Cloudflare Quick Tunnel（CLI 模式尚不支援）
    stop <nameOrId>           # 停止 tunnel
```

---

## site — 管理靜態站台

### `tunnelbox site add <name> <folder>`

註冊一個本地資料夾為靜態站台。

- `<name>`：站台名稱（不可重複）
- `<folder>`：資料夾路徑（會自動轉為絕對路徑）

```bash
# 範例
tunnelbox site add my-blog ./dist
tunnelbox site add portfolio /Users/tim/projects/portfolio/build
```

**行為**：
- 檢查資料夾是否存在，不存在則報錯
- 檢查名稱是否已被使用
- 產生 UUID 作為 site ID
- 寫入本地資料儲存

**JSON 模式輸出**：
```json
{ "success": true, "data": { "id": "uuid", "name": "my-blog", "folderPath": "/abs/path/dist" } }
```

### `tunnelbox site list`

列出所有已註冊的站台。

```bash
tunnelbox site list
# 輸出表格：name, folder, id

tunnelbox site list --json
# 輸出 JSON 陣列
```

### `tunnelbox site remove <nameOrId>`

移除一個站台。可用名稱或 UUID。

```bash
tunnelbox site remove my-blog
tunnelbox site remove 550e8400-e29b-41d4-a716-446655440000
```

---

## server — 管理本地伺服器

### `tunnelbox server start <nameOrId>`

為指定站台啟動 HTTP 伺服器。

- 自動在 3000-9000 範圍內選擇可用 port
- 提供靜態檔案服務（含目錄列表）
- 自動注入 WebSocket hot-reload 腳本到 HTML 頁面
- 監聽檔案變更，自動通知瀏覽器重新載入

```bash
tunnelbox server start my-blog
# 輸出：Server started at http://localhost:3001

tunnelbox server start my-blog --json
# { "success": true, "data": { "id": "uuid", "name": "my-blog", "port": 3001, "url": "http://localhost:3001" } }
```

**注意**：若伺服器已在運行，會回傳現有資訊並標記 `alreadyRunning: true`。

### `tunnelbox server stop <nameOrId>`

停止指定站台的伺服器。

```bash
tunnelbox server stop my-blog
# 輸出：Server stopped for "my-blog"
```

**注意**：若伺服器未在運行，會提示 `Server is not running`。

---

## env — 環境檢查

### `tunnelbox env check`

偵測 `cloudflared` 是否已安裝及其版本。

```bash
tunnelbox env check
# 輸出：cloudflared: installed (version 2024.6.1)
# 或：cloudflared: not installed

tunnelbox env check --json
# { "success": true, "data": { "installed": true, "status": "available", "version": "2024.6.1" } }
```

**偵測路徑**：
1. 先檢查 TunnelBox 本地安裝路徑（`~/Library/Application Support/tunnelbox/` 等）
2. 再檢查系統 PATH（`which cloudflared`）

**最低版本要求**：`2024.1.0`（低於此版本會顯示 `outdated` 警告）

---

## tunnel — 管理 Cloudflare Tunnel

### `tunnelbox tunnel quick <nameOrId>`

為站台啟動 Cloudflare Quick Tunnel，取得公開 URL。

**CLI 模式限制**：此指令目前在 CLI 模式下**尚不支援**，因為 Quick Tunnel 依賴 Electron 的 ProcessManager。執行時會拋出錯誤：
```
Error: Quick tunnel is not yet supported in CLI mode
```

若需要 tunnel 功能，請使用 TunnelBox 桌面應用。

### `tunnelbox tunnel stop <nameOrId>`

停止指定站台的 tunnel。

```bash
tunnelbox tunnel stop my-blog
```

---

## 資料儲存

TunnelBox 使用單一 JSON 檔案儲存所有資料，路徑依平台而異：

| 平台 | 路徑 |
|------|------|
| macOS | `~/Library/Application Support/tunnelbox/tunnelbox-data.json` |
| Windows | `%APPDATA%/tunnelbox/tunnelbox-data.json` |
| Linux | `~/.config/tunnelbox/tunnelbox-data.json` |

此檔案由 CLI 和 Electron 桌面應用共用。

---

## 錯誤處理

TunnelBox CLI 區分兩種錯誤：

| 類型 | Exit Code | 說明 | 範例 |
|------|-----------|------|------|
| 輸入錯誤 | 1 | 使用者輸入有問題 | 資料夾不存在、站台名稱重複、找不到站台 |
| 系統錯誤 | 2 | 環境或系統問題 | cloudflared 未安裝、未預期的錯誤 |

**JSON 模式錯誤輸出**：
```json
{ "success": false, "error": "Site not found: my-blog" }
```

---

## 常見工作流程

### 1. 從零開始啟動一個本地靜態站

```bash
# 1. 註冊站台
tunnelbox site add my-site ./dist

# 2. 啟動伺服器
tunnelbox server start my-site
# → Server started at http://localhost:3001

# 3. 在瀏覽器開啟 http://localhost:3001
# 修改 ./dist 中的檔案會自動 hot-reload
```

### 2. 管理多個站台

```bash
# 註冊多個站台
tunnelbox site add blog ./blog/dist
tunnelbox site add docs ./docs/build
tunnelbox site add demo ./demo/public

# 查看所有站台
tunnelbox site list

# 啟動特定站台
tunnelbox server start blog
tunnelbox server start docs

# 停止並移除
tunnelbox server stop blog
tunnelbox site remove blog
```

### 3. 使用 JSON 模式整合腳本

```bash
# 在 shell script 中取得 server URL
URL=$(tunnelbox server start my-site --json | jq -r '.data.url')
echo "Server running at $URL"

# 檢查指令是否成功
if tunnelbox site add test ./test --json | jq -e '.success' > /dev/null; then
  echo "Site added"
else
  echo "Failed"
fi
```

### 4. 檢查環境是否就緒

```bash
# 確認 cloudflared 是否安裝（tunnel 功能需要）
tunnelbox env check

# 若未安裝，可透過 Homebrew 安裝
brew install cloudflared
```
