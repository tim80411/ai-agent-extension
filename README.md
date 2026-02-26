# Timothy Liao's Plugin Marketplace

Custom marketplace for development tools including Adobe Animate/CreateJS, xAPI learning analytics, Figma design reading, and spec writing methodology.

## Plugins

### animate-dev

Adobe Animate + CreateJS development expert with performance optimization tools.

- **Skills**: `animate-dev`, `animate-performance`
- **Agents**: code-reviewer, component-analyzer, createjs-developer, issue-finder, performance-analyzer
- **Version:** 1.0.0

### xapi-engineer

xAPI statement generation and validation expert for educational assessment tracking.

- **Skills**: `xapi-specification`, `prompt-engineering`
- **Agents**: xapi-designer
- **Commands**: `/analyze`, `/generate`, `/validate`
- **Version:** 1.0.0

### figma-reader

Read Figma designs via link, extract structured page layout summaries with minimal context window usage.

- **Skills**: `figma-read`
- **Agents**: figma-reader
- **Commands**: `/figma-read`
- **Version:** 0.1.0

### spec-writer

Spec/Story 撰寫方法論 — 引導撰寫高品質 User Story 與 Enabler Story，含 INVEST 檢查與反模式掃描。

- **Skills**: `spec-writing`
- **Agents**: codebase-explorer, context-reader, spec-reviewer
- **Version:** 0.1.0

## Installation

This marketplace is automatically loaded from:
```
~/.claude/plugins/marketplaces/timothy-liao-marketplace/
```

The plugins should appear in Claude Code's plugin list after marketplace discovery.

## Structure

```
timothy-liao-marketplace/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── animate-dev/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── agents/
│   │   ├── references/
│   │   └── skills/
│   ├── xapi-engineer/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── agents/
│   │   ├── commands/
│   │   └── skills/
│   ├── figma-reader/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── agents/
│   │   ├── commands/
│   │   └── skills/
│   └── spec-writer/
│       ├── .claude-plugin/plugin.json
│       ├── agents/
│       └── skills/
├── LICENSE
└── README.md
```

## Author

Timothy Liao (tim80411@gmail.com)

## License

MIT
