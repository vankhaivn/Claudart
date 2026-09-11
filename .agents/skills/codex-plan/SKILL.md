---
name: codex-plan
description: Create a lightweight persistent task workspace in .codex/tasks/ with TASK.md as the authoritative plan and supporting artifacts only when concretely needed.
---

# Codex Plan

Create a persistent task workspace. `.codex/tasks/<task-id>/TASK.md` — not this session — is the authoritative plan. A future session must understand status, decisions, and the next action from `TASK.md`, then load only the linked supporting files that action needs.

Before doing anything, read `.codex/guidelines/task-management.md`. That guideline defines the workspace layout, task schema, status state machine, planning lock, approval signals, progress update protocol, and completion flow. Read `.codex/guidelines/agent-delegation.md` only when delegation is relevant. This skill does not duplicate those contracts; it only orchestrates creation.

## Inputs

- The user's request after `$codex-plan` is the task description. If invoked with no argument, ask one short clarifying question: "What's the task?"
- Inspect relevant evidence first. Ask only about unresolved ambiguity that materially changes scope or acceptance; do not turn an ordinary task into an interview cycle.

## Artifact Discipline

**Default to `TASK.md` only.** Create `artifacts/` only when a concrete deliverable, step, acceptance check, or necessary handoff needs one of:

- A native-format input/output that Markdown cannot adequately replace (for example JSON consumed by a tool, a reproduction ZIP/tgz, or an image needed for review).
- Retained evidence whose important details would be lost in a short summary.
- Substantial task-specific research that would obscure the actionable plan; keep its conclusions in `TASK.md`.

Short findings and ordinary check results stay inline. Link existing project files instead of duplicating them. Add only the needed supporting file and a relative purpose link under optional `### Workspace Files`; no empty artifact directories, placeholder reports, or required manifests. Follow the task contract's privacy/storage rules; missing required input is a blocker. Never automatically extract archives, execute attachments, or load all supporting files.

A workspace changes storage, not execution scope or approval semantics. No mandatory POC, phase roadmap, separate notes/ledger, repeated review rounds, or forced session rotation. Artifact presence, count, size, or format does not justify a spec workflow. Investigate material uncertainty, implement the approved scope, run the smallest sufficient verification set plus mandatory repository checks, then stop at the existing review gate. Extra investigation or reruns need an observed failure, relevant change, unresolved acceptance, or user feedback.

## Procedure

### Step 1: Decide whether a persistent task is needed

Honor an explicit request for a persistent plan, even for a small change; keep it brief. Otherwise, answer pure questions directly and perform simple, clear changes under normal project rules without a task workspace. Adjusting a few buttons or tweaking an API does not need a plan merely because several files are touched.

Use `$codex-plan` when meaningful decisions, coordination, interruption, or review benefit from persistence. File count alone is not a reason. Whether to create a task and whether to create artifacts are separate decisions.

### Step 2: Read project context

- Read `.codex/CONTEXT.md` (current state of work).
- Read `.codex/tasks/index.md` if it exists and check workspace metadata using the task contract's shallow discovery rules; the index is a cache. Reuse an active task already covering this request rather than creating a duplicate. Ask only when the intended task is ambiguous. If its status is not `planning`, leave this creation flow and follow the task contract’s resumption/review rules without resetting status, redrafting the plan, or creating another workspace.
- Read `.codex/knowledge/INDEX.md`, then route only relevant maps/topics within `.codex/guidelines/knowledge-management.md`'s bounds.
- Read only project documentation relevant to the requested scope.
- Run `git log -5 --oneline` for recent direction.

### Step 3: Allocate and seed the workspace

For a new task, choose a 2-5-word lowercase kebab-case slug. Scan directory names at `.codex/tasks/` and `.codex/tasks/done/` under the task contract's allocation rules: today's UTC date, highest reserved NNN + 1, zero-padded to three digits. Include incomplete workspaces when reserving numbers. Re-check for collisions; never overwrite a directory, reuse an id, add revision suffixes, or wrap after 999.

Create `.codex/tasks/YYYY-MM-DD-NNN-<slug>/TASK.md` with `status: planning`, `created`/`updated`, `slug`, `agent`, `delegation`, and tags, plus the original request and known context. Register it in `index.md` using the link format in Step 6. Do this before substantive exploration so necessary findings have a durable home; fill the remaining sections as evidence arrives. **Do not create `artifacts/` unless an actual supporting file is needed.** For a resumed task, keep its existing id, status, and history.

### Step 4: Explore the codebase (read-only)

You are in planning lock. Write `TASK.md`/`index.md` and only supporting inputs, notes, or evidence allowed by Artifact Discipline. **No implementation code, scaffolding, runnable POCs, or write-scope workers—even inside `artifacts/`.** The narrow knowledge-maintenance exception in `.codex/guidelines/task-management.md` still applies.

Use read-only operations to:

- Locate every file your plan will touch.
- Identify existing patterns and helpers to reuse (avoid rewriting what already exists).
- Surface constraints: linters, type checkers, framework idioms, naming conventions in the relevant area.
- Note non-obvious context worth recording for a future-session agent.
- If the task may parallelize, record a delegation _strategy_ (decomposition, ownership) in the `delegation:` field + Plan of Work — the field's semantics live in `.codex/guidelines/agent-delegation.md`. Write-scope subagents must wait for `in-progress`; read-only explorers are fine during the planning lock.

Explore to de-risk the plan's decisions, not to pre-solve the implementation — record short findings as decisions, constraints, and `verify:` checks in `TASK.md`, never as code; retain separate detail only when an artifact trigger passes (see "Plan Altitude" in the guideline file).

If you need clarification before the plan is sensible, ask now. Do not invent answers.

### Step 5: Finalize `TASK.md`

Use the skeleton in `.codex/guidelines/task-management.md`. Keep sections concise and proportional; `None.` is valid when nothing substantive belongs there. Do not invent work to fill the template:

- **Frontmatter**: `status: planning`, the creation date in `created` and today's UTC date in `updated`, `agent: codex`, `delegation:` (`none` | `strategy-only` | `authorized` — semantics per `.codex/guidelines/agent-delegation.md`; record the choice in the Decision Log), 1-5 lowercase kebab tags.
- **Purpose**: open with the user's original request quoted verbatim (paraphrase is where intent bends), then 2-3 sentences answering "who gains what, how do they verify it works".
- **Context & Orientation**: this is the handoff to future-self. Fill all three subsections:
  - _Related Code_: every file path the plan touches or reads, with one-line reason.
  - _Related Docs_: relevant project docs and any genuinely needed external references; do not research unrelated material to fill this section.
  - _Memory Hints_: free-form notes — non-obvious task/WIP context and uncertain discoveries that a fresh agent would otherwise re-discover. Keep these as candidates by default. A claim may move to knowledge immediately only under the task guideline's exception and the full capture gate in `knowledge-management.md`; patch the owner plus route atomically and run the checker. `$codex-checkpoint` bulk-evaluates remaining candidates; `$codex-learn` owns behavior, not fact promotion.
- **Plan of Work**: a short narrative of the sequence and rationale; one sentence is enough for a simple explicitly requested plan.
- **Concrete Steps**: ordered checklist. Each step is one self-contained action with target file, expected outcome, and a `(verify: <observable check>)`. Steps should be small enough that completing one is a meaningful save point, and written at plan altitude — decisions and verification, never code.
- **Validation & Acceptance**: observable success criteria — tests to pass, commands to run, behaviors to verify.
- **Decision Log**: any non-obvious choice made while planning (library, approach, trade-off), with rationale.
- **Surprises & Discoveries**: anything unexpected found during exploration that informed the plan.
- **Outcomes & Retrospective**: leave empty during planning; draft for review and finalize only on closure.
- **Workspace Files**: optional under Context & Orientation, only when supporting material exists. Link meaningful files with their purpose and when to inspect them; keep status, conclusions, and next actions in `TASK.md`.

### Step 6: Update `index.md`

If `.codex/tasks/index.md` does not exist, create it with the canonical header (see guideline file). Add or refresh the task under `## Active`:

```
- [<slug>](<YYYY-MM-DD-NNN-slug>/TASK.md) — planning — updated <YYYY-MM-DD>
```

Keep `index.md` under 100 lines.

### Step 7: Fresh-eyes check, then report

Before reporting, read `TASK.md` once as if this conversation never happened and verify any required supporting references exist or have explicit retrieval instructions. Do not recursively load artifacts or repeat review without a concrete gap. Any step that needs conversation context to execute has an **information gap** — move that context into Memory Hints now. Do not "fix" skill gaps: the executor is expected to derive the how; missing information is a defect, a missing solution is not.

Output a short summary:

```
## Plan Created

**Workspace**: `.codex/tasks/<task-id>/`
**Plan**: `TASK.md`
**Status**: planning (no code edits will happen until you approve)
**Steps**: <n> concrete steps + <m> validation checks
**Open questions**: <list any clarifications still needed, or "none">

Review the file, request changes by editing it directly or telling me what to change.
When ready, say "go" / "approved" / "implement" and I'll flip status to in-progress and start executing.
```

Do not begin implementing. Wait for the approval signal defined in `.codex/guidelines/task-management.md`.

## After Approval

Once the user gives an approval signal, the contract in `.codex/guidelines/task-management.md` takes over — this skill adds nothing to it. Flip `status: planning -> in-progress`, execute Concrete Steps while maintaining the task file per "Progress Updates During Implementation", honor the `delegation:` field per `.codex/guidelines/agent-delegation.md`, and finish through the **Two-Phase Completion Gate**: report at `awaiting-review` and stop; the user — not you — confirms `done`.

## Anti-Patterns

- Do not write implementation code, including under `artifacts/`, while `status: planning` or `status: awaiting-review` — both are read-only locks (see `.codex/guidelines/task-management.md`).
- Do not put the plan body into chat instead of the file. The file is the plan.
- Keep non-obvious context in Memory Hints; `None.` is valid when there is none. Do not manufacture discoveries or separate reports.
- Do not treat enthusiasm ("great idea!") or questions as approval — wait for an explicit signal at each gate.
