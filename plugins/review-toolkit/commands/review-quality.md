---
name: review-quality
description: 啟動六維度程式碼品質審查
user_invocable: true
arguments:
  - name: target
    description: 審查目標（模組名稱、檔案路徑、或 "all"）
    required: false
---

啟動六維度程式碼品質審查流程。使用 `code-quality-review` skill 引導整個審查過程。

若使用者提供了 `$ARGUMENTS`，將其作為審查目標傳入 Phase 0。
若未提供，進入 Phase 0 的互動式確認流程。
