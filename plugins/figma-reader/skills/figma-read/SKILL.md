---
name: figma-read
description: This skill should be used when the user provides a "Figma link", "Figma URL", "figma.com/design" URL, or asks to "read Figma", "analyze Figma design", "extract Figma layout", or wants to understand a Figma design for development context.
version: 0.1.0
---

# Figma Design Reading

## Overview

Extract structured page layout summaries from Figma design links with minimal context window usage. Designed for developers who need to understand UI layouts to inform development.

## When to Use

- User provides a Figma URL (matching `figma.com/design/...`)
- User wants to understand page structure, form fields, or data flow from a design
- User needs design context before building APIs or data models

## How to Use

### Automatic (Agent)

When a Figma URL is detected, delegate to the `figma-reader` agent via the Task tool. The agent runs in an isolated context and returns only a concise summary, keeping the main conversation context clean.

### Manual (Command)

Use `/figma-read <url> [focus]` to explicitly trigger extraction.

## URL Parsing

Figma URLs follow this pattern:
```
https://figma.com/design/:fileKey/:fileName?node-id=:int1-:int2
```

Extract:
- `fileKey`: the segment after `/design/`
- `nodeId`: convert `node-id` query param from `1-2` to `1:2` format

## Workflow

1. Parse the Figma URL for fileKey and nodeId
2. Use the Task tool to launch the `figma-reader` agent (subagent_type: `figma-reader`)
3. The agent calls `get_metadata` first (lightweight), then `get_screenshot` if needed
4. Agent returns a hierarchical summary under 500 words
5. Present the summary to the user

## Key Principle

Always delegate Figma data fetching to the agent. Never call Figma MCP tools directly in the main conversation - this defeats the purpose of context isolation.
