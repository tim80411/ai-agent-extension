# workflow-lab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `workflow-lab` plugin (two skills: `workflow-capture`, `workflow-run`) that lets the user park expensive multi-agent Workflow ideas as ready-to-run scripts in a repo-external `~/workflow-lab/` folder, then pull one out and run it later behind a cost gate.

**Architecture:** Skill code lives in this marketplace repo at `plugins/workflow-lab/`. The idea database lives outside the repo at `~/workflow-lab/<slug>/` (each idea = `README.md` card + `workflow.js` with a top-of-file `CONFIG` const block + `runs/` history). `workflow-capture` writes idea folders without executing; `workflow-run` lists them, fills CONFIG by editing the script, gates on cost, launches `Workflow({scriptPath})`, and writes results back.

**Tech Stack:** Claude Code plugin (markdown SKILL.md + JSON manifest), the built-in `Workflow` tool, `git` with the repo's PreToolUse version-bump hook, `jq`/`python3` for JSON validation, `node --check` for script syntax validation.

**Testing note (adaptation):** This deliverable is markdown + JSON config, not code with a unit-test framework. "Tests" here are **structural validations**: valid JSON, required frontmatter/sections present, symlinks resolve, plugin/marketplace versions in sync, and `node --check` on generated workflow scripts. The final acceptance task also dispatches the `plugin-dev:plugin-validator` agent and does a manual capture smoke test.

**Commit strategy (hook-aware):** The repo's `bump-plugin-version.sh` PreToolUse hook **skips bumping any plugin whose `plugin.json` is staged in the commit**. Therefore all `plugins/workflow-lab/` files (manifest + both skills + references) plus the `marketplace.json` registration are committed **together in one commit** (Task 6) so `plugin.json` is a staged add and the version stays `0.1.0`, matching `marketplace.json`. Symlinks are committed separately (Task 7) and touch no `plugins/*` file, so they never trigger a bump. Work happens on the existing `feat/workflow-lab` branch.

**Path convention:** In skill instructions, `~/workflow-lab/` means `$HOME/workflow-lab/`. When passing a path to the `Workflow` tool's `scriptPath`, always use the **absolute** path (`$HOME/workflow-lab/<slug>/workflow.js`) — do not rely on `~` expansion inside the tool.

---

## File Structure

```
plugins/workflow-lab/
├── .claude-plugin/plugin.json                         # manifest (name/version/description/author)
├── skills/
│   ├── workflow-capture/
│   │   ├── SKILL.md                                   # capture flow orchestration
│   │   └── references/
│   │       ├── 01-idea-card-template.md               # README.md card template + field meanings
│   │       └── 02-workflow-script-guide.md            # workflow.js skeleton + CONFIG/args rule + Workflow API cheat-sheet
│   └── workflow-run/
│       └── SKILL.md                                   # run flow: list → fill CONFIG → cost gate → launch → save results
.claude-plugin/marketplace.json                        # MODIFY: register workflow-lab
.claude/skills/workflow-capture  -> ../../plugins/workflow-lab/skills/workflow-capture    # symlink
.claude/skills/workflow-run      -> ../../plugins/workflow-lab/skills/workflow-run        # symlink
.cursor/skills/workflow-capture  -> ../../plugins/workflow-lab/skills/workflow-capture    # symlink
.cursor/skills/workflow-run      -> ../../plugins/workflow-lab/skills/workflow-run        # symlink
```

Responsibilities:
- **plugin.json** — minimal manifest, four required fields, version `0.1.0`.
- **workflow-capture/SKILL.md** — turns an idea into a parked folder; never executes anything.
- **01-idea-card-template.md** — the exact `README.md` frontmatter + body the capture skill writes.
- **02-workflow-script-guide.md** — how to author a runnable `workflow.js` (CONFIG-const-not-args rule + condensed Workflow API), referenced by capture (and by run when reading scripts).
- **workflow-run/SKILL.md** — operational runner with the cost/safety gate and result write-back.

---

## Task 1: Plugin manifest

**Files:**
- Create: `plugins/workflow-lab/.claude-plugin/plugin.json`

- [ ] **Step 1: Write the manifest**

Create `plugins/workflow-lab/.claude-plugin/plugin.json`:

```json
{
  "name": "workflow-lab",
  "version": "0.1.0",
  "description": "Park expensive multi-agent Workflow ideas as ready-to-run scripts, then pull one out and run it later behind a cost gate. Two skills: workflow-capture (record) and workflow-run (run).",
  "author": {
    "name": "Timothy Liao",
    "email": "tim80411@gmail.com"
  }
}
```

- [ ] **Step 2: Validate JSON + required fields**

Run:
```bash
python3 -c "import json; d=json.load(open('plugins/workflow-lab/.claude-plugin/plugin.json')); assert all(k in d for k in ('name','version','description','author')), 'missing field'; assert d['author']=={'name':'Timothy Liao','email':'tim80411@gmail.com'}, 'bad author'; assert d['version']=='0.1.0'; print('plugin.json OK')"
```
Expected: `plugin.json OK`

---

## Task 2: Idea-card template reference

**Files:**
- Create: `plugins/workflow-lab/skills/workflow-capture/references/01-idea-card-template.md`

- [ ] **Step 1: Write the reference**

Create the file with this exact content:

````markdown
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
````

- [ ] **Step 2: Validate it is non-empty and mentions the key contract**

Run:
```bash
grep -q "status: draft" plugins/workflow-lab/skills/workflow-capture/references/01-idea-card-template.md && grep -q "execution: post-run" plugins/workflow-lab/skills/workflow-capture/references/01-idea-card-template.md && echo "template OK"
```
Expected: `template OK`

---

## Task 3: Workflow-script authoring guide reference

**Files:**
- Create: `plugins/workflow-lab/skills/workflow-capture/references/02-workflow-script-guide.md`

- [ ] **Step 1: Write the reference**

Create the file with this exact content:

````markdown
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
````

- [ ] **Step 2: Validate the guide encodes the args rule and API**

Run:
```bash
F=plugins/workflow-lab/skills/workflow-capture/references/02-workflow-script-guide.md
grep -q "never \`args\`" "$F" && grep -q "const CONFIG" "$F" && grep -q "pipeline(items" "$F" && echo "guide OK"
```
Expected: `guide OK`

---

## Task 4: workflow-capture SKILL.md

**Files:**
- Create: `plugins/workflow-lab/skills/workflow-capture/SKILL.md`

- [ ] **Step 1: Write the skill**

Create the file with this exact content:

````markdown
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
````

- [ ] **Step 2: Validate frontmatter + phases + no-run contract**

Run:
```bash
F=plugins/workflow-lab/skills/workflow-capture/SKILL.md
head -1 "$F" | grep -q '^---$' && grep -q "^name: workflow-capture" "$F" && grep -q "^description:" "$F" && grep -q "Phase 0" "$F" && grep -q "Does NOT call" "$F" && echo "capture SKILL OK"
```
Expected: `capture SKILL OK`

---

## Task 5: workflow-run SKILL.md

**Files:**
- Create: `plugins/workflow-lab/skills/workflow-run/SKILL.md`

- [ ] **Step 1: Write the skill**

Create the file with this exact content:

````markdown
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
````

- [ ] **Step 2: Validate frontmatter + cost-gate + phases**

Run:
```bash
F=plugins/workflow-lab/skills/workflow-run/SKILL.md
head -1 "$F" | grep -q '^---$' && grep -q "^name: workflow-run" "$F" && grep -q "Pre-flight cost gate" "$F" && grep -q "scriptPath" "$F" && grep -q "resumeFromRunId" "$F" && echo "run SKILL OK"
```
Expected: `run SKILL OK`

---

## Task 6: Register in marketplace + single hook-clean commit

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Add the plugin entry**

In `.claude-plugin/marketplace.json`, append to the `plugins` array (after the last entry):

```json
{
  "name": "workflow-lab",
  "source": "./plugins/workflow-lab",
  "description": "Park expensive multi-agent Workflow ideas as ready-to-run scripts, then pull one out and run it later behind a cost gate.",
  "version": "0.1.0",
  "author": {
    "name": "Timothy Liao",
    "email": "tim80411@gmail.com"
  },
  "repository": "https://github.com/tim80411/ai-agent-extension",
  "license": "MIT",
  "category": "productivity",
  "keywords": [
    "workflow",
    "multi-agent",
    "orchestration",
    "idea-park",
    "automation"
  ],
  "strict": false
}
```

- [ ] **Step 2: Validate marketplace JSON + version sync**

Run:
```bash
python3 -c "
import json
m=json.load(open('.claude-plugin/marketplace.json'))
p=json.load(open('plugins/workflow-lab/.claude-plugin/plugin.json'))
e=[x for x in m['plugins'] if x['name']=='workflow-lab']
assert len(e)==1, 'workflow-lab not registered exactly once'
assert e[0]['version']==p['version']=='0.1.0', 'version desync'
assert e[0]['source']=='./plugins/workflow-lab'
print('marketplace OK, versions synced at', p['version'])
"
```
Expected: `marketplace OK, versions synced at 0.1.0`

- [ ] **Step 3: Stage the whole plugin + marketplace together and commit**

The `plugin.json` MUST be staged in this commit so the bump hook skips it (keeps `0.1.0`).

Run:
```bash
git add plugins/workflow-lab .claude-plugin/marketplace.json
git status --short
git commit -m "feat(workflow-lab): add plugin with workflow-capture and workflow-run skills

Park expensive multi-agent Workflow ideas as ready-to-run scripts under
~/workflow-lab/<slug>/ (README card + workflow.js with CONFIG const, no args)
without executing; run them later behind a cost gate and write results back.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
Expected: commit succeeds (hook output `{}` — no bump — because `plugin.json` is staged).

- [ ] **Step 4: Confirm version stayed 0.1.0 after commit**

Run:
```bash
python3 -c "import json; print('post-commit version:', json.load(open('plugins/workflow-lab/.claude-plugin/plugin.json'))['version'])"
git log --oneline -1
```
Expected: `post-commit version: 0.1.0`

- [ ] **Step 5 (only if Step 3 was denied by the hook):** If the hook denied and bumped `plugin.json`, sync `marketplace.json` to the new version, re-stage both, and re-commit:
```bash
NEW=$(python3 -c "import json;print(json.load(open('plugins/workflow-lab/.claude-plugin/plugin.json'))['version'])")
python3 -c "
import json
m=json.load(open('.claude-plugin/marketplace.json'))
for x in m['plugins']:
    if x['name']=='workflow-lab': x['version']='$NEW'
json.dump(m,open('.claude-plugin/marketplace.json','w'),ensure_ascii=False,indent=2)
open('.claude-plugin/marketplace.json','a').write('\n')
"
git add plugins/workflow-lab .claude-plugin/marketplace.json
git commit -m "feat(workflow-lab): add plugin with workflow-capture and workflow-run skills

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
Expected: commit succeeds and versions match again.

---

## Task 7: Symlinks for local testing + commit

**Files:**
- Create: `.claude/skills/workflow-capture`, `.claude/skills/workflow-run` (symlinks)
- Create: `.cursor/skills/workflow-capture`, `.cursor/skills/workflow-run` (symlinks)

- [ ] **Step 1: Create the four relative symlinks**

Run:
```bash
ln -s ../../plugins/workflow-lab/skills/workflow-capture .claude/skills/workflow-capture
ln -s ../../plugins/workflow-lab/skills/workflow-run     .claude/skills/workflow-run
ln -s ../../plugins/workflow-lab/skills/workflow-capture .cursor/skills/workflow-capture
ln -s ../../plugins/workflow-lab/skills/workflow-run     .cursor/skills/workflow-run
```

- [ ] **Step 2: Verify the symlinks resolve to real SKILL.md files**

Run:
```bash
for p in .claude/skills/workflow-capture .claude/skills/workflow-run .cursor/skills/workflow-capture .cursor/skills/workflow-run; do
  test -f "$p/SKILL.md" && echo "OK $p" || { echo "BROKEN $p"; exit 1; }
done
```
Expected: four `OK` lines.

- [ ] **Step 3: Commit the symlinks**

Run:
```bash
git add .claude/skills/workflow-capture .claude/skills/workflow-run .cursor/skills/workflow-capture .cursor/skills/workflow-run
git commit -m "chore(workflow-lab): add skill symlinks for local testing

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
Expected: commit succeeds, no version bump (no `plugins/*` file touched).

---

## Task 8: Acceptance — validator + capture smoke test

**Files:** none created (verification only); the smoke test creates a throwaway folder under `~/workflow-lab/` that is then removed.

- [ ] **Step 1: Run the plugin validator**

Dispatch the `plugin-dev:plugin-validator` agent on `plugins/workflow-lab`. Ask it to confirm: manifest has the four required fields, both skills have valid frontmatter (`name` + `description`), and structure follows conventions.
Expected: no blocking issues.

- [ ] **Step 2: Manual capture smoke test (no workflow execution)**

Following `workflow-capture/SKILL.md` by hand, create a throwaway idea to prove the structure works:
```bash
mkdir -p "$HOME/workflow-lab/_smoke-test/runs"
```
Write `$HOME/workflow-lab/_smoke-test/README.md` with valid frontmatter (`status: ready`, a `goal`, `output.kind: artifact`, `output.execution: post-run`, a `cost_estimate`, one `config` entry).
Write `$HOME/workflow-lab/_smoke-test/workflow.js`:
```js
export const meta = {
  name: 'smoke-test',
  description: 'Smoke test — single agent summarizes one file.',
  phases: [{ title: 'Summarize', detail: 'one agent' }],
}
const CONFIG = { target: '' } // fill before running
phase('Summarize')
const r = await agent(`Summarize the file at ${CONFIG.target} in 3 bullets.`)
return { summary: r }
```

- [ ] **Step 3: Validate the smoke-test artifacts**

Run:
```bash
test -f "$HOME/workflow-lab/_smoke-test/README.md" && test -d "$HOME/workflow-lab/_smoke-test/runs" && echo "structure OK"
grep -q "const CONFIG" "$HOME/workflow-lab/_smoke-test/workflow.js" && ! grep -q "args" "$HOME/workflow-lab/_smoke-test/workflow.js" && echo "no-args OK"
cp "$HOME/workflow-lab/_smoke-test/workflow.js" /tmp/wf-check.mjs && node --check /tmp/wf-check.mjs && echo "syntax OK"
```
Expected: `structure OK`, `no-args OK`, `syntax OK`. (If `node` is unavailable, skip the syntax line.)

- [ ] **Step 4: Clean up the smoke test**

Run:
```bash
rm -rf "$HOME/workflow-lab/_smoke-test" /tmp/wf-check.mjs
echo "cleaned"
```
Expected: `cleaned`

- [ ] **Step 5: Final summary**

Report: plugin committed at `0.1.0` (synced with marketplace), four symlinks resolve, validator passed, smoke test confirmed the capture structure + script syntax. Note that the two new skills become invocable after the next Claude Code session reload.

---

## Self-Review

**Spec coverage:**
- Spec §2 architecture (repo plugin + external `~/workflow-lab/`) → Tasks 1, 6, 7 + path convention.
- Spec §3 idea folder (README card, workflow.js CONFIG, runs/) → Tasks 2, 3, 4 (capture writes them); template + script guide encode the exact shapes.
- Spec §4 workflow-capture → Task 4.
- Spec §5 workflow-run incl. cost gate + post-run/in-workflow action handling → Task 5.
- Spec §6 conventions (args rule, status lifecycle, resume, cost gate, MCP note) → encoded across references (Task 3) and both SKILL.md (Tasks 4, 5).
- Spec §7 YAGNI (no separate list skill, no cross-session resume, no VCS for the lab) → reflected; browse folded into run Phase 1.

**Placeholder scan:** No "TBD/TODO" left as plan instructions. The only `// TODO` text appears as intended skeleton-mode content inside a quoted template, and `// fill before running` is intentional CONFIG guidance — both are deliverable content, not plan gaps.

**Type/name consistency:** `CONFIG` const, `status` values (`draft|skeleton|ready|run-before`), `output.kind` (`artifact|action|both`), `output.execution` (`post-run|in-workflow`), and slug/`runs/` naming are used identically across the template (Task 2), script guide (Task 3), capture (Task 4), and run (Task 5).
