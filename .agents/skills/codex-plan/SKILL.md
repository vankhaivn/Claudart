---
name: codex-plan
description: Create a persistent implementation plan as a markdown document in .codex/tasks/. Replaces session-only /plan mode with a cross-session task file Codex maintains until completion.
---

# Codex Plan

Create a persistent task document. The file you produce — not this Codex session — is the source of truth for the plan. A future session must be able to resume work from that file alone.

Before doing anything, read `.codex/guidelines/task-management.md`. That guideline defines the file schema, status state machine, planning lock, approval signals, progress update protocol, and completion flow. Also read `.codex/guidelines/agent-delegation.md` if it exists, because large tasks may need a delegation strategy. This skill does not duplicate those contracts; it only orchestrates creation.

## Inputs

- The user's request after `$codex-plan` is the task description. If invoked with no argument, ask one short clarifying question: "What's the task?"
- If the request is ambiguous (multiple reasonable interpretations) or missing critical detail (target files, success criteria), ask up to 3 clarifying questions BEFORE writing the file. Better to ask than to write a useless plan.

## Procedure

### Step 1: Confirm a task file is the right tool

Skip `$codex-plan` and answer in chat if any of these apply:

- Pure question or explanation (no code change).
- One-line fix or rename.
- Trivial change (under 3 files, under 30 minutes, no decisions to record).

Use `$codex-plan` when the work crosses sessions, touches multiple files, requires decisions worth recording, or the user explicitly asked for one.

### Step 2: Read project context

- Read `.codex/CONTEXT.md` (current state of work).
- Read `.codex/tasks/index.md` if it exists. If an active task already covers this request, surface it and ask whether to continue that file instead of starting a new one.
- Read `.codex/knowledge/INDEX.md`, then route only relevant maps/topics within `.codex/guidelines/knowledge-management.md`'s bounds.
- Read any `docs/` directory the project provides for architectural context.
- Run `git log -5 --oneline` for recent direction.

### Step 3: Explore the codebase (read-only)

You are in planning lock from this point. Do not write implementation code. Normally write only the task file and `index.md`; the triggered knowledge-maintenance exception in `.codex/guidelines/task-management.md` still applies.

Use read-only operations to:

- Locate every file your plan will touch.
- Identify existing patterns and helpers to reuse (avoid rewriting what already exists).
- Surface constraints: linters, type checkers, framework idioms, naming conventions in the relevant area.
- Note non-obvious context worth recording for a future-session agent.
- If the task may parallelize, record a delegation _strategy_ (decomposition, ownership) in the `delegation:` field + Plan of Work — the field's semantics live in `.codex/guidelines/agent-delegation.md`. Write-scope subagents must wait for `in-progress`; read-only explorers are fine during the planning lock.

Explore to de-risk the plan's decisions, not to pre-solve the implementation — findings enter the file as decisions, constraints, and `verify:` checks, never as code (see "Plan Altitude" in the guideline file).

If you need clarification before the plan is sensible, ask now. Do not invent answers.

### Step 4: Generate the slug and filename

- Slug: 2-5 lowercase kebab-case words derived from the task. Example: `add-jwt-middleware`, `refactor-payment-retry`, `fix-cors-on-api`.
- Sequence number: scan `.codex/tasks/` and `.codex/tasks/done/` for existing files whose name starts with today's UTC date (`YYYY-MM-DD-`). The next sequence number is the highest existing NNN for that date + 1, zero-padded to 3 digits (e.g. `001`, `002`). If no files exist for today, start at `001`.
- Filename: `YYYY-MM-DD-NNN-<slug>.md` using today's UTC date and the computed sequence number.
- Path: `.codex/tasks/<filename>`.

Do not add revision suffixes to slugs; the sequence number already guarantees uniqueness per day.

### Step 5: Write the task file

Use the exact skeleton in `.codex/guidelines/task-management.md`. Fill every section:

- **Frontmatter**: `status: planning`, today's date in `created` and `updated`, `agent: codex`, `delegation:` (`none` | `strategy-only` | `authorized` — semantics per `.codex/guidelines/agent-delegation.md`; record the choice in the Decision Log), 1-5 lowercase kebab tags.
- **Purpose**: open with the user's original request quoted verbatim (paraphrase is where intent bends), then 2-3 sentences answering "who gains what, how do they verify it works".
- **Context & Orientation**: this is the handoff to future-self. Fill all three subsections:
  - _Related Code_: every file path the plan touches or reads, with one-line reason.
  - _Related Docs_: project docs (`docs/...`) AND external references (URLs, RFCs).
  - _Memory Hints_: free-form notes — non-obvious task/WIP context and uncertain discoveries that a fresh agent would otherwise re-discover. Keep these as candidates by default. A claim may move to knowledge immediately only under the task guideline's exception and the full capture gate in `knowledge-management.md`; patch the owner plus route atomically and run the checker. `$codex-checkpoint` bulk-evaluates remaining candidates; `$codex-learn` owns behavior, not fact promotion.
- **Plan of Work**: 1-3 paragraphs of prose narrating the sequence and rationale.
- **Concrete Steps**: ordered checklist. Each step is one self-contained action with target file, expected outcome, and a `(verify: <observable check>)`. Steps should be small enough that completing one is a meaningful save point, and written at plan altitude — decisions and verification, never code.
- **Validation & Acceptance**: observable success criteria — tests to pass, commands to run, behaviors to verify.
- **Decision Log**: any non-obvious choice made while planning (library, approach, trade-off), with rationale.
- **Surprises & Discoveries**: anything unexpected found during exploration that informed the plan.
- **Outcomes & Retrospective**: leave empty (filled at completion).

### Step 6: Update `index.md`

If `.codex/tasks/index.md` does not exist, create it with the canonical header (see guideline file). Add the new task under `## Active`:

```
- [<slug>](<YYYY-MM-DD-NNN-slug>.md) — planning — updated <YYYY-MM-DD>
```

Keep `index.md` under 100 lines.

### Step 7: Fresh-eyes check, then report

Before reporting, re-read the task file as if this conversation never happened. Any step that needs conversation context to execute has an **information gap** — move that context into Memory Hints now. Do not "fix" skill gaps: the executor is expected to derive the how; missing information is a defect, a missing solution is not.

Output a short summary:

```
## Plan Created

**File**: `.codex/tasks/<filename>`
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

- Do not write code while `status: planning` or `status: awaiting-review` — both are read-only locks (see `.codex/guidelines/task-management.md`).
- Do not put the plan body into chat instead of the file. The file is the plan.
- Do not skip Memory Hints. A plan with no Memory Hints is a plan that won't survive a context reset.
- Do not treat enthusiasm ("great idea!") or questions as approval — wait for an explicit signal at each gate.
