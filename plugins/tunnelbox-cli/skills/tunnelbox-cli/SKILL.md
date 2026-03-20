---
name: tunnelbox-cli
description: >-
  This skill should be used when the user asks about "tunnelbox CLI",
  "tunnelbox 指令", "tunnelbox command", "how to use tunnelbox",
  "tunnelbox site", "tunnelbox server", "tunnelbox tunnel",
  "tunnelbox env", "管理靜態站", "啟動本地伺服器",
  "Cloudflare tunnel 怎麼用", "tunnelbox 怎麼用",
  "tunnelbox 使用說明", "tunnelbox help",
  "停止伺服器", "移除站台",
  "tunnelbox 錯誤", "tunnelbox error", "tunnelbox --json",
  or needs guidance on using TunnelBox CLI to manage static sites,
  local servers, or Cloudflare tunnels, including troubleshooting errors.
---

# TunnelBox CLI 使用指南

協助使用者透過 TunnelBox CLI 管理本地靜態網站、伺服器與 Cloudflare Tunnel。

全程使用中文與使用者互動（除非使用者用英文提問）。

## 觸發後行為

1. 讀取本 skill 目錄下的 `references/cli-reference.md` 取得完整指令參考。

2. 根據使用者的問題類型回應：

   - **具體指令問題**（如「怎麼新增 site？」）：直接給出指令語法、參數說明與範例。
   - **工作流程問題**（如「怎麼把本地站台公開到網路？」）：引導完整的端到端步驟。
   - **錯誤排除**（如「為什麼 tunnel 失敗？」）：根據 reference 中的錯誤處理說明診斷。
   - **概覽問題**（如「tunnelbox 能做什麼？」）：簡要介紹功能全貌，再問使用者想深入哪部分。

3. 回應時：
   - 指令用 code block 呈現
   - 複雜流程用編號步驟
   - 提到 `--json` 模式時說明其輸出格式
   - 若使用者的問題超出 CLI 目前支援範圍（如 CLI 模式尚不支援 Quick Tunnel），主動告知限制
