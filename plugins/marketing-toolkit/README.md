# marketing-toolkit

行銷相關的 skill 集合。目前兩支，都在做 SEO，但**守備範圍刻意不同**。

## 選哪一支

| 你的情況 | 用 |
| --- | --- |
| 整個站要交出去給客戶上線 | **`site-seo`** |
| 需要 canonical／sitemap.xml／robots.txt／JSON-LD | **`site-seo`** |
| 多頁站，每頁標題描述都要不一樣 | **`site-seo`** |
| 交付前要稽核「有沒有哪裡做錯」 | **`site-seo`** |
| 就一個 HTML 檔，資訊都有了，只差把標籤貼進去 | `add-seo-ga` |
| 只是要植入 GA／GTM 追蹤碼 | `add-seo-ga` |

拿不準就用 `site-seo`——它涵蓋較廣，且會擋掉幾個 `add-seo-ga` 看不到的交付級錯誤。

---

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

## `add-seo-ga`

單一 HTML 檔的低摩擦版本：在 `<head>` 插入 SEO meta／Open Graph 標籤，
並可選植入 Google Analytics（支援 GA ID 或完整 script，會偵測既有 GA 代碼衝突）。

## 觸發語

- **site-seo**：「幫這個站加 SEO」「做 SEO 優化」「加 sitemap／robots／canonical／結構化資料」
  「交付前檢查 SEO」「網站搜尋不到」
- **add-seo-ga**：「加 meta tags」「加 og tags」「加 Google Analytics」「加 gtag」

## 目錄結構

```
marketing-toolkit/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── site-seo/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── templates.md   # 可貼用樣板：head／JSON-LD 各型別／robots／sitemap
│   │       └── audit.md       # 可執行稽核腳本＋症狀對照表
│   └── add-seo-ga/
│       ├── SKILL.md
│       └── references/
│           └── examples.md
└── README.md
```
