# marketing-toolkit

行銷相關的 skill 集合。目前一支。

## `site-seo`

把一個靜態網站備妥到「可交付、可被搜尋」的完整狀態。

- 每頁 `<head>`：title／description／canonical／Open Graph／Twitter Card／`<html lang>`
- JSON-LD 結構化資料：Organization／WebSite／WebPage／BreadcrumbList／Article／Course／
  LocalBusiness／FAQPage，附型別選擇判斷表
- 站台級檔案：`robots.txt`、`sitemap.xml`（含從發佈目錄產生骨架的腳本）
- **預覽站 vs 交付站分流**——兩種站的 SEO 目標相反，做錯後面全錯
- **交付前紅線稽核**：四條硬性關卡 + 六項品質檢查，全部附可直接跑的指令

### 為什麼需要「分流」這件事

開發期為 QA 預覽站放的 `robots.txt`（`Disallow: /`）如果原封不動被打進交付包，
客戶上傳到自己的網域後**整站不會出現在搜尋結果**——站是好的、頁面是好的，
就是永遠搜不到，而且沒有任何錯誤訊息。等發現通常已經過了幾週。

`site-seo` 把這件事列為交付前的第一條紅線，由清單擋住，不靠記性。

## 觸發語

「幫這個站加 SEO」「做 SEO 優化」「加 sitemap／robots／canonical／結構化資料」
「交付前檢查 SEO」「網站搜尋不到」

## 目錄結構

```
marketing-toolkit/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── site-seo/
│       ├── SKILL.md
│       └── references/
│           ├── templates.md   # 可貼用樣板：head／JSON-LD 各型別／robots／sitemap
│           └── audit.md       # 可執行稽核腳本＋症狀對照表
└── README.md
```
