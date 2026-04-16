---
name: md-to-pdf
description: >-
  Convert Markdown files to PDF with Mermaid diagram support.
  Use when the user mentions "轉成 PDF", "產生 PDF", "markdown 轉檔",
  "md to pdf", "md-to-pdf", "Markdown 轉 PDF", "把 md 轉成 pdf",
  "convert markdown to pdf", "markdown to pdf", or wants to produce
  a PDF from one or more .md files.
---

# Markdown to PDF

Convert one or more Markdown files to PDF. Supports Mermaid diagrams and Markdown tables.

## Prerequisites

- Node.js v18+

## Workflow

### Phase 1: Parse Input

**Goal:** Identify which .md files to convert.

**Actions:**
1. Extract .md file paths from the user's message
2. Resolve each path to absolute path
3. Verify each file exists using the Read tool
4. If no paths provided, use AskUserQuestion to ask the user which files to convert

### Phase 2-5: Convert

**Goal:** Run the conversion pipeline and report results.

**Actions:**
1. Resolve the script directory relative to this SKILL.md:
   ```
   SKILL_DIR="<directory containing this SKILL.md>"
   ```
2. Execute the pipeline:
   ```bash
   bash "$SKILL_DIR/scripts/convert.sh" <file1.md> [file2.md] ...
   ```
3. Parse stdout for results:
   - Lines starting with `OK:` → successful conversions
   - Lines starting with `FAIL:` → failures (also on stderr)
4. Report results to the user:
   - List each successfully generated PDF path
   - For failures, show the error message and suggest checking
     `references/01-troubleshooting.md` for common fixes (especially Mermaid syntax issues)

## Troubleshooting

If Mermaid rendering fails, common causes are documented in
[references/01-troubleshooting.md](references/01-troubleshooting.md).
The most frequent issue: edge labels containing parentheses must be wrapped in double quotes.
