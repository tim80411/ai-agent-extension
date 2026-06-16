---
name: workflow-run
description: >-
  Pull a parked Workflow idea out of ~/workflow-lab/ and run it behind a cost
  gate. Use when the user wants to "跑一個囤好的 workflow", "運行 workflow 想法",
  "拿一個 workflow 出來跑", "從 workflow-lab 挑一個跑", "早上跑 workflow",
  "run a parked workflow", "execute a workflow idea", or asks to list what is in
  the workflow lab. Lists ideas with status + cost, fills the script's CONFIG by
  editing it (never args), confirms cost, launches Workflow({scriptPath}), and
  writes results + cost back into the idea's runs/. To create a new idea instead,
  use workflow-capture.
---

# workflow-run

Run an already-parked idea from `~/workflow-lab/` (= `$HOME/workflow-lab/`) with a cost/safety gate, and record the outcome.

## Phase 1 — List & pick

**Goal:** Let the user choose an idea fast.
**Actions:**
- List `~/workflow-lab/*/README.md`; for each show `slug`, `status`, `goal`, `cost_estimate`, `output.kind/execution`, and whether `runs/` is non-empty.
- Sort `ready` first, then `skeleton`, then `run-before`; `draft` last.
- If the user named an idea, skip to it. If a chosen idea is `draft`/`skeleton`, warn it is not fully runnable and offer to hand off to `workflow-capture` to finish it.

## Phase 2 — Fill CONFIG

**Goal:** Put run parameters into the script (never via args).
**Actions:**
- Read the idea's `README.md` `config` list and `workflow.js` `CONFIG` block.
- Ask the user for each unset `CONFIG` value, then **edit `workflow.js`** so the `CONFIG` const holds the concrete values. Do not pass `args` to the Workflow tool.

## Phase 3 — Pre-flight cost gate

**Goal:** No expensive run without explicit confirmation.
**Actions:** Using `AskUserQuestion`, show `cost_estimate` and confirm launch. If `output.kind` includes `action` AND `output.execution == in-workflow`, require an **extra** explicit confirmation stating "this will perform external actions directly" and (if known) how many.

## Phase 4 — Launch

**Goal:** Execute the workflow.
**Actions:**
- Compute the absolute path `ABS="$HOME/workflow-lab/<slug>/workflow.js"`.
- Call the Workflow tool with `{ scriptPath: ABS }`. Do not set `args`.
- If it fails midway, you may edit the persisted script and relaunch with `resumeFromRunId` (same session only); completed agents are cached.

## Phase 5 — Save results & handle action

**Goal:** Persist the outcome and run any post-run action safely.
**Actions:**
- Write `~/workflow-lab/<slug>/runs/<YYYY-MM-DD-HHMM>.md` with: the returned `result` (summary), cost stats (`totalTokens`, `agentCount`, `durationMs`, `status`), and the filled CONFIG used.
- If `output.execution == post-run` and the result contains an action-plan: present the plan, get explicit confirmation via `AskUserQuestion`, then perform the external actions in this foreground session. Record what was actually executed into the same run file.
- Update the idea's `README.md` `status` to `run-before`.

## Verification before done

- A new file exists in `~/workflow-lab/<slug>/runs/`.
- The README `status` is `run-before`.
- Any external action was confirmed before execution and logged in the run file.
