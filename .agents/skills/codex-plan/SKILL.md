---
name: codex-plan
description: Create a persistent implementation plan as a markdown document in .codex/tasks/. Replaces session-only /plan mode with a cross-session task file Codex maintains until completion.
---

# Codex Plan

Create a persistent task document. The file you produce — not this Codex session — is the source of truth for the plan. A future session must be able to resume work from that file alone.

Before doing anything, read `.codex/guidelines/task-management.md`. That guideline defines the file schema, status state machine, planning lock, approval signals, progress update protocol, and completion flow. This skill does not duplicate that contract; it only orchestrates creation.

## Inputs

- The user's request after `$codex-plan` is the task description. If invoked with no argument, ask one short clarifying question: "What's the task?"
- If the request is ambiguous or missing critical detail (target files, success criteria), ask up to 3 clarifying questions BEFORE writing the file. Better to ask than to write a useless plan.

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
- Read any `docs/` directory the project provides for architectural context.
- Run `git log -5 --oneline` for recent direction.

### Step 3: Explore the codebase (read-only)

You are in planning lock from this point. Do not write or edit any file other than the task file itself and `index.md`.

Use read-only operations to:

- Locate every file your plan will touch.
- Identify existing patterns and helpers to reuse.
- Surface constraints: linters, type checkers, framework idioms, naming conventions in the relevant area.
- Note non-obvious context worth recording for a future-session agent.

If you need clarification before the plan is sensible, ask now. Do not invent answers.

### Step 4: Generate the slug and filename

- Slug: 2-5 lowercase kebab-case words derived from the task. Example: `add-jwt-middleware`, `refactor-payment-retry`, `fix-cors-on-api`.
- Filename: `YYYY-MM-DD-<slug>.md` using today's UTC date.
- Path: `.codex/tasks/<filename>`.

If a file with that slug already exists in `.codex/tasks/` or `.codex/tasks/done/`, suffix with `-v2`, `-v3`, etc.

### Step 5: Write the task file

Use the exact skeleton in `.codex/guidelines/task-management.md`. Fill every section:

- **Frontmatter**: `status: planning`, today's date in `created` and `updated`, `agent: codex`, 1-5 lowercase kebab tags.
- **Purpose**: 2-3 sentences. Answer "who gains what, how do they verify it works".
- **Context & Orientation**: this is the handoff to future-self. Fill all three subsections:
  - *Related Code*: every file path the plan touches or reads, with one-line reason.
  - *Related Docs*: project docs (`docs/...`) AND external references (URLs, RFCs).
  - *Memory Hints*: free-form notes — every non-obvious thing discovered during exploration that a fresh agent would otherwise re-discover. This section is the lifeline against memory loss across sessions. Be generous.
- **Plan of Work**: 1-3 paragraphs of prose narrating the sequence and rationale.
- **Concrete Steps**: ordered checklist. Each step is one self-contained action with target file and expected outcome.
- **Validation & Acceptance**: observable success criteria.
- **Decision Log**: any non-obvious choice made while planning, with rationale.
- **Surprises & Discoveries**: anything unexpected found during exploration.
- **Outcomes & Retrospective**: leave empty (filled at completion).

### Step 6: Update `index.md`

If `.codex/tasks/index.md` does not exist, create it with the canonical header (see guideline file). Add the new task under `## Active`:

```
- [<slug>](<YYYY-MM-DD-slug>.md) — planning — updated <YYYY-MM-DD>
```

Keep `index.md` under 100 lines.

### Step 7: Report

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

Once the user gives an approval signal, follow the protocol in `.codex/guidelines/task-management.md`:

1. Flip frontmatter `status: planning -> in-progress`, bump `updated:`.
2. Execute Concrete Steps in order, marking each `[x]` with `(YYYY-MM-DD HH:MMZ)` UTC timestamp on completion.
3. Update Surprises / Decision Log as needed.
4. When all Concrete Steps + Validation boxes are checked, run the **Two-Phase Completion Gate** from the guideline file:
   - **Phase 1**: fill draft Outcomes, flip `status: in-progress -> awaiting-review`, report to user, **STOP**. Do not archive, do not write JOURNAL.
   - **Phase 2a**: only after the user gives a completion signal ("approved", "looks good", "close it", "done", "ship", "ok đóng task") — run the archive flow.
   - **Phase 2b**: if the user reports a problem, append to Surprises, flip back to `in-progress`, fix, return to Phase 1.

The agent must NEVER skip Phase 1 or self-confirm Phase 2. The completion gate is symmetric with the planning approval gate at the other end.

## Anti-Patterns

- Do not write code while `status: planning` or `status: awaiting-review`. Both are read-only locks.
- Do not auto-complete the task. When all boxes are checked, you go to `awaiting-review` and stop. The user — not you — flips it to `done`.
- Do not skip Memory Hints. A plan with no Memory Hints is a plan that won't survive a context reset.
- Do not put the plan body into chat instead of the file. The file is the plan.
- Do not auto-approve on user enthusiasm ("great idea!") — wait for an explicit approval cue at each gate.
