# md-to-pdf Troubleshooting

## Mermaid edge label 含括號導致 mmdc 報錯

**症狀：** mmdc 解析失敗，錯誤訊息指向 edge label 語法

**原因：** Mermaid parser 將 `(` 視為 shape 定義的開頭。例如：

```
B -.->|decrypt API (cache miss 時)| KMS
```

**解法：** 將 label 用雙引號包裹：

```
B -.->|"decrypt API (cache miss 時)"| KMS
```

---

## md-to-pdf 直接轉含 Mermaid 的 Markdown → 圖變純文字

**症狀：** PDF 中 Mermaid code block 以程式碼形式顯示，沒有渲染成圖

**原因：** `md-to-pdf` 底層用 puppeteer 將 Markdown → HTML → PDF，但不會執行 Mermaid JS 渲染

**解法：** 使用 `preprocess.cjs` 預處理，將 Mermaid block 抽出並用 `mmdc` 渲染為 PNG，再以圖片引用替換原本的 code block

---

## 預處理為 SVG 後 PDF 中圖片空白

**症狀：** PDF 產出了，但 Mermaid 圖的位置是空白

**原因：** puppeteer 的 `file://` 載入 SVG 有 cross-origin 限制，SVG 圖片被忽略

**解法：** 改用 PNG 格式（`mmdc -o output.png`）而非 SVG

---

## PNG 引用使用絕對路徑導致 PDF 中圖片不顯示

**症狀：** 預處理後的 Markdown 用絕對路徑引用 PNG，但 PDF 中圖片沒有出現

**原因：** md-to-pdf / puppeteer 路徑解析問題

**解法：** 使用相對路徑引用（`![](imgs/xxx.png)`），並確保在暫存目錄下執行 md-to-pdf，讓相對路徑能正確對應到 PNG 檔案位置
