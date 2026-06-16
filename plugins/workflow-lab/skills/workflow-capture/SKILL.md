---
name: workflow-capture
description: >-
  Record / park a multi-agent Workflow idea WITHOUT running it. Use when the
  user wants to "記錄 workflow 想法", "囤 workflow", "把這個 workflow 想法存起來",
  "新增 workflow 點子", "建一個 workflow 框架先不要跑", "capture workflow idea",
  "park a workflow", or describes a workflow they want to build/validate later
  but not execute now. Writes an idea folder under ~/workflow-lab/<slug>/ (README
  card + runnable workflow.js with a CONFIG const block + runs/). Does NOT call
  the Workflow tool. To actually run a parked idea, use workflow-run instead.
---

# workflow-capture

Turn a Workflow idea into a parked, ready-to-run folder under `~/workflow-lab/` — **without executing it**. Running expensive workflows is the job of `workflow-run`; this skill only records.

`~/workflow-lab/` means `$HOME/workflow-lab/`.

## References

- `references/01-idea-card-template.md` — the `README.md` card to write.
- `references/02-workflow-script-guide.md` — how to author `workflow.js` (CONFIG-not-args rule + Workflow API). Read this before writing any script.

## Phase 0 — Locate the lab

**Goal:** Ensure the idea database exists.
**Actions:**
- `mkdir -p "$HOME/workflow-lab"` if missing.
- If the user gave no idea content, ask what the idea is.

## Phase 1 — Gather the idea

**Goal:** Collect everything the card needs.
**Actions:** Using `AskUserQuestion`, confirm:
- `goal` — one line, what it validates or produces.
- `output.kind` (artifact / action / both) and `output.description`.
- `output.execution` — default `post-run`; only `in-workflow` if the action volume IS the work. If `kind` includes `action`, restate the safety default (post-run = workflow returns an action-plan, you execute after confirm).
- `cost_estimate` — rough agents + token magnitude (help estimate from the planned fan-out).
- `config` — which parameters/static inputs the runner must fill before running.
- Target completeness: `ready` (fully runnable, default) or `skeleton` (outline with stubbed agent prompts).

## Phase 2 — Create the folder + card

**Goal:** Write the idea folder skeleton.
**Actions:**
- Derive a kebab-case `<slug>` from the goal. If `~/workflow-lab/<slug>/` exists, append `-2`, `-3`, … or ask.
- `mkdir -p "$HOME/workflow-lab/<slug>/runs"`.
- Write `README.md` from `references/01-idea-card-template.md`, filling all frontmatter + body sections. Set `created` to today's date.

## Phase 3 — Write workflow.js

**Goal:** Produce the script to the chosen completeness.
**Actions:**
- Read `references/02-workflow-script-guide.md`.
- Write `~/workflow-lab/<slug>/workflow.js`: `meta` literal (with `phases`), a top `CONFIG` const holding every `config` value (left blank/with sensible default for the runner to fill) and all static data, and the body. **Never reference `args`.**
- For `ready`: complete, runnable logic. For `skeleton`: structure + phases present, agent prompts may be `// TODO` stubs — set `status: skeleton`.
- For `post-run` action ideas, the script must return a structured action-plan and perform no external side effects.

## Phase 4 — Finalize

**Goal:** Record status and report.
**Actions:**
- Set `status` in the README (`ready` or `skeleton`).
- Summarize to the user: folder path, status, what to fill before running, and that running is done via `workflow-run`. **Do not run the workflow.**

## Verification before done

- The folder has `README.md`, `workflow.js`, and `runs/`.
- `workflow.js` contains a `CONFIG` const and no `args` reference.
- `README.md` frontmatter has `status`, `goal`, `output`, `cost_estimate`, `config`.
