# Timothy Liao's Plugin Marketplace

Custom marketplace for Adobe Animate and CreateJS development tools.

## Plugins

### animate-dev

Adobe Animate + CreateJS development expert with comprehensive performance optimization capabilities.

**Features:**
- Auto-fix debugging for common CreateJS issues
- MovieClip lifecycle management
- Event handling patterns
- Performance optimization tools
- Memory leak detection and prevention
- Automatic performance analysis

**Components:**
- **Main Skill**: `animate-dev` - Complete Adobe Animate + CreateJS development guide
- **Performance Skill**: `animate-performance` - Dedicated performance optimization guidance
- **Performance Analyzer Agent**: Automated performance issue detection and fixing

**Version:** 1.0.0

**Author:** Timothy Liao (tim80411@gmail.com)

## Installation

This marketplace is automatically loaded from:
```
~/.claude/plugins/marketplaces/timothy-liao-marketplace/
```

The plugin should appear in Claude Code's plugin list after marketplace discovery.

## Usage

### Trigger Main Skill
```
"I'm working with Adobe Animate and CreateJS"
"Help me debug this MovieClip issue"
"gotoAndStop is undefined"
```

### Trigger Performance Analysis
```
"Check this project for performance issues"
"Optimize the performance"
"檢查效能問題"
```

### Trigger Performance Optimization Skill
```
"How to optimize Adobe Animate performance?"
"Check for memory leaks in CreateJS"
"效能優化的最佳實踐"
```

## Structure

```
timothy-liao-marketplace/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace manifest
├── plugins/
│   └── animate-dev/
│       ├── .claude-plugin/
│       │   └── plugin.json       # Plugin manifest
│       ├── agents/
│       │   └── performance-analyzer.md
│       ├── skills/
│       │   ├── animate-dev/
│       │   │   ├── SKILL.md
│       │   │   └── references/
│       │   └── animate-performance/
│       │       ├── SKILL.md
│       │       └── references/
│       │           ├── common-patterns.md
│       │           └── fix-strategies.md
│       └── README.md
└── README.md                     # This file
```

## Maintenance

To update the plugin:
1. Make changes to the plugin files
2. Increment version in `marketplace.json` and `plugin.json`
3. Restart Claude Code to reload plugins

## License

Custom plugin for personal use.
