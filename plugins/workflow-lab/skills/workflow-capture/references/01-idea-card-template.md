# Idea Card Template (`README.md`)

Every parked idea folder `~/workflow-lab/<slug>/` contains a `README.md` written from this template.

## Frontmatter (YAML)

```yaml
---
slug: <kebab-case-slug>
status: draft            # draft | skeleton | ready | run-before
goal: <one line — what this workflow validates or produces>
output:
  kind: artifact         # artifact | action | both
  execution: post-run    # post-run (default) | in-workflow
  description: <what it produces, or what action it drives>
cost_estimate: "~N agents / ~Nk tokens"
config:                  # values to fill into workflow.js CONFIG before running
  - name: <CONFIG key>
    description: <what to put here>
created: <YYYY-MM-DD>
---
```

## Body sections

```markdown
## 想法
<free-text: the idea in detail, why it is worth running, prior art>

## 預期產出 / 動作
<what the run should produce or trigger; if output.kind includes "action",
 spell out the exact downstream action and whether it runs in-workflow or post-run>

## 跑之前要填什麼
<bullet list mirroring `config:` — what each CONFIG value should be>

## 注意事項
<gotchas, required MCP servers (e.g. Atlassian for Jira), cost caveats>
```

## Field rules

- `status` lifecycle: `draft` (idea only, maybe no script) → `skeleton` (script outline, agent prompts stubbed) → `ready` (complete runnable script) → `run-before` (has at least one entry in `runs/`).
- `output.execution` defaults to `post-run`: the workflow stays side-effect-free and only returns a structured action-plan; the user's foreground session executes the action after confirmation. Use `in-workflow` ONLY when the action volume is the work itself (e.g. create 50 subtasks) and parallel side effects are acceptable.
- `cost_estimate` is a rough ceiling for morning triage — agents count and a token magnitude.
- `config` lists every value the runner must fill into the script's `CONFIG` const (never via `args`).
