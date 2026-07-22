---
name: figma-read
description: Read a Figma design link and extract structured layout summary
argument-hint: "<figma-url> [focus area]"
allowed-tools:
  - Task
---

Extract structured layout information from a Figma design URL using the figma-reader agent.

Parse the user's input:
- First argument: Figma URL (required)
- Remaining text: optional focus area (e.g., "form fields", "navigation", "data tables")

Launch the `figma-reader` agent via the Task tool with:
- The Figma URL
- Any focus area specified by the user
- Request for concise hierarchical summary

Present the agent's summary to the user.
