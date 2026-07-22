# Timothy Liao's Plugin Marketplace

Custom marketplace of Claude Code plugins — organized as topical **toolkits** (工具集) plus focused domain experts and utilities.

## Plugins

### Domain experts

#### animate-dev

Adobe Animate + CreateJS development expert with performance optimization tools.

- **Skills**: `animate-dev`, `animate-performance`
- **Agents**: code-reviewer, component-analyzer, createjs-developer, issue-finder, performance-analyzer
- **Version:** 1.0.0

#### xapi-engineer

xAPI statement generation and validation expert for educational assessment tracking.

- **Skills**: `prompt-engineering`, `xapi-specification`
- **Agents**: xapi-designer
- **Commands**: `/analyze`, `/generate`, `/validate`
- **Version:** 1.0.0

### Toolkits (工具集)

#### pm-toolkit

個人專案管理工具集：需求撰寫 → 追蹤。

- **Skills**: `file-based-issues`（檔案式 issue tracker 方法論）, `spec-writing`（Spec/Story 撰寫，含 INVEST 檢查與反模式掃描）
- **Agents**: codebase-explorer, context-reader, spec-reviewer, story-mapper
- **Version:** 0.2.0

#### review-toolkit

驗證／審查工具集：上線前的品質閘。

- **Skills**: `code-quality-review`（六維度平行程式碼品質審查）, `copy-verify`（文案對術語 SSOT 的驗證與對齊）
- **Agents**: misuse-reviewer, modularity-reviewer, readability-reviewer, reusability-reviewer, surprises-reviewer, testability-reviewer
- **Commands**: `/review-quality`
- **Version:** 0.2.0

#### design-toolkit

設計工具集。

- **Skills**: `figma-read`（透過連結讀取 Figma 設計稿，抽取結構化版面摘要）
- **Agents**: figma-reader
- **Commands**: `/figma-read`
- **Version:** 0.1.0

#### marketing-toolkit

行銷工具集。

- **Skills**: `add-seo-ga`（在 HTML `<head>` 加入 SEO 標籤與 Google Analytics 追蹤碼）
- **Version:** 1.0.0

#### data-converter

資料轉換工具箱，收納各種格式互轉的 skill。

- **Skills**: `md-to-pdf`
- **Version:** 1.5.1

### Utilities

#### tunnelbox-cli

TunnelBox CLI usage guide — manage local static sites, servers, and Cloudflare tunnels.

- **Skills**: `tunnelbox-cli`, `tunnelbox-auth`, `tunnelbox-site`, `tunnelbox-publish`, `tunnelbox-tunnel`, `tunnelbox-domain`, `tunnelbox-env`
- **Version:** 0.1.0

#### k8s-troubleshooter

Diagnose Kubernetes alerts on Tim's OCI cluster — fetches alertmanager details, pulls relevant kubectl context, and proposes fixes.

- **Skills**: `k8s-alert-investigate`
- **Commands**: `/k8s-alert-investigate`
- **Version:** 0.1.0

#### workflow-lab

Park expensive multi-agent Workflow ideas as ready-to-run scripts, then run one later behind a cost gate.

- **Skills**: `workflow-capture`, `workflow-run`
- **Version:** 0.1.0

#### book-study

讀書會學習流程工具 — 從原文產生筆記、比對增補、Q&A 調查、導讀建議、Notion 發布。

- **Skills**: `note-generator`, `notion-publisher`, `qa-investigator`, `reading-guide`
- **Agents**: note-reviewer
- **Commands**: `/study`
- **Version:** 0.1.0

## Installation

This marketplace is automatically loaded from:
```
~/.claude/plugins/marketplaces/user-marketplace/
```

The plugins should appear in Claude Code's plugin list after marketplace discovery.

## Structure

```
user-marketplace/
├── .claude-plugin/
│   └── marketplace.json
├── .claude/skills/          ← symlinks for in-project testing (Claude Code)
│   ├── animate-dev -> ../../plugins/animate-dev/skills/animate-dev
│   ├── spec-writing -> ../../plugins/pm-toolkit/skills/spec-writing
│   └── ...
├── .cursor/skills/          ← symlinks for in-project testing (Cursor)
│   └── ... (mirrors .claude/skills)
├── plugins/                 ← real skill files (source of truth)
│   ├── animate-dev/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── agents/
│   │   └── skills/
│   ├── pm-toolkit/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── agents/          ← spec-writing agents
│   │   ├── scripts/
│   │   └── skills/          ← file-based-issues, spec-writing
│   ├── review-toolkit/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── agents/
│   │   ├── commands/
│   │   └── skills/          ← code-quality-review, copy-verify
│   ├── design-toolkit/
│   ├── marketing-toolkit/
│   └── ...
├── docs/                    ← plans / analyses (date-prefixed)
├── LICENSE
└── README.md
```

### Skill Symlinks

`.claude/skills/` 和 `.cursor/skills/` 內的 symlink 指向 `plugins/` 中的真實 skill 目錄，讓你在此專案內即可直接測試 skill，不需全域安裝。編輯 `plugins/` 下的 skill 檔案會立即反映到兩個工具。真實檔案一律在 `plugins/` 下。

## Author

Timothy Liao (tim80411@gmail.com)

## License

MIT
