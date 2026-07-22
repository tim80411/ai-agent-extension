# add-seo-ga

Claude Code plugin：在 HTML 文件的 `<head>` 區段加入完整的 SEO 標籤結構和 Google Analytics 追蹤代碼。

## 功能

- 加入完整的 SEO Meta 標籤（title, description, keywords）
- 加入 Open Graph 標籤（og:title, og:image 等社群分享標籤）
- 加入 Schema.org / itemprop 標籤
- 加入作者與版權資訊
- 可選加入 Google Analytics 追蹤代碼（支援 GA ID 或完整 script）
- 自動根據圖片副檔名判斷 `og:image:type`
- 自動格式化關鍵字（支援中英文逗號、頓號）
- 檢測並提醒現有 GA 代碼衝突

## 安裝

將此 plugin 目錄加入 Claude Code：

```bash
claude plugin add /path/to/add-seo-ga-plugin
```

## 使用方式

在 Claude Code 中使用以下觸發語句：

- 「幫我加入 SEO 標籤」
- 「加 meta tags」
- 「加 og tags / Open Graph」
- 「加 Google Analytics / GA 追蹤」
- 「加 gtag」

Claude 會引導你提供必要資訊，並自動在 HTML 文件中插入標籤。

## 目錄結構

```
add-seo-ga-plugin/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── add-seo-ga/
│       ├── SKILL.md
│       └── references/
│           └── examples.md
└── README.md
```
