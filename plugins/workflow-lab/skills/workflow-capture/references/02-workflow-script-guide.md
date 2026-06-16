# Workflow Script Authoring Guide (`workflow.js`)

A parked idea's `workflow.js` is a self-contained script for the Claude Code `Workflow` tool. Author it to the completeness the user chose (default: fully runnable).

## Non-negotiable rule: CONFIG const, never `args`

On this machine the `Workflow` tool's `args` global arrives as `undefined` (verified 2026-06-11). **Do not read `args`.** Put every parameter and all static data in a single `CONFIG` const block at the top. The runner fills these by editing the file before launch.

```js
export const meta = {
  name: 'example-idea',                 // kebab-case, matches the folder slug
  description: 'One line — what this workflow does.',
  phases: [                             // PURE LITERAL: no variables/calls/spreads
    { title: 'Find',   detail: 'fan out N readers' },
    { title: 'Verify', detail: 'adversarially check each finding' },
  ],
}

// ── CONFIG: fill these before running (NOT via args) ───────────────
const CONFIG = {
  target: '',            // e.g. absolute path / question / list — fill before run
  fanout: 5,
}
// ───────────────────────────────────────────────────────────────────

phase('Find')
const found = await parallel(
  Array.from({ length: CONFIG.fanout }, (_, i) => () =>
    agent(`Reader ${i + 1}: examine ${CONFIG.target}`, { schema: FINDINGS_SCHEMA }))
).then(rs => rs.filter(Boolean).flatMap(r => r.findings))

phase('Verify')
const verified = await parallel(found.map(f => () =>
  agent(`Adversarially verify: ${f.title}. Default to refuted if uncertain.`, { schema: VERDICT_SCHEMA })
    .then(v => ({ ...f, verdict: v }))))

return { findings: verified.filter(Boolean) }
```

## Condensed Workflow API (what the script may use)

- `agent(prompt, opts?)` — spawn a subagent. With `{schema}` (JSON Schema) it returns the validated object; without, returns text. Returns `null` if it dies — `.filter(Boolean)`. Other opts: `label`, `phase`, `model`, `effort`, `isolation:'worktree'` (only for parallel file mutation), `agentType`.
- `pipeline(items, stage1, stage2, ...)` — **default for multi-stage work.** No barrier between stages; each item flows independently. A throwing stage drops that item to `null`.
- `parallel(thunks)` — run concurrently, **barrier** (awaits all). A throwing thunk → `null`. Use only when stage N needs ALL of stage N-1 (dedup/merge/early-exit).
- `phase(title)`, `log(message)` — progress display.
- `budget` — `{ total, spent(), remaining() }`; guard loops with `while (budget.total && budget.remaining() > 50_000) {...}`.

## Constraints to respect when authoring

- `meta` must be a pure literal (no variables/calls/spreads/interpolation); required keys `name`, `description`.
- Plain JS only (no TypeScript types). No `Date.now()` / `Math.random()` / argless `new Date()` (they throw — vary by index instead; stamp timestamps after the run).
- Concurrency is capped (~10–16) automatically; you may still pass up to 4096 items to one `parallel`/`pipeline`.
- Prefer `pipeline` over a `parallel`→transform→`parallel` barrier chain.

## Action-type outputs

- Default `post-run`: the script must **not** perform external side effects. Return a structured action-plan (e.g. `{ actions: [...] }`) describing what to do; the runner executes it after user confirmation.
- `in-workflow` (opt-in only): the script performs the action directly via MCP tools. Note interactively-authenticated MCP servers may be absent in background runs — document required servers in the idea's README.

## Resume

Same-session only: if a run fails midway, edit the persisted script and relaunch `Workflow({scriptPath, resumeFromRunId})` — completed `agent()` calls are cached. Cross-day reruns are fresh executions (different session), so side-effecting scripts would repeat actions — another reason `post-run` is the default.
