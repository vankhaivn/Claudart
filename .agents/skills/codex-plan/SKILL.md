---
name: codex-plan
description: Create a persistent implementation plan as a markdown document in .codex/tasks/. Replaces session-only /plan mode with a cross-session task file Codex maintains until completion.
---

# Codex Plan

Create a persistent task document. The file you produce — not this Codex session — is the source of truth for the plan. A future session must be able to resume work from that file alone.

Before doing anything, read `.codex/guidelines/task-management.md`. That guideline defines the file schema, status state machine, planning lock, approval signals, progress update protocol, and completion flow. Also read `.codex/guidelines/agent-delegation.md` if it exists, because large tasks may need a delegation strategy. This skill does not duplicate those contracts; it only orchestrates creation.

## Inputs

- The user's request after `$codex-plan` is the task description. If invoked with no argument, ask one short clarifying question: "What's the task?"
- If the request is ambiguous or missing critical detail (target files, success criteria), state your interpretation as an explicit assumption in the Decision Log and flag it under **Open questions** in the Step 7 report. Do not block on interactive questions — document the assumption and let the user correct it.

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
- Identify existing patterns and helpers to reuse (avoid rewriting what already exists).
- Surface constraints: linters, type checkers, framework idioms, naming conventions in the relevant area.
- Note non-obvious context worth recording for a future-session agent.
- Identify whether subagents would materially help after approval. Planning may record delegation opportunities, but it must not spawn subagents while the task is `planning`.

If you need clarification before the plan is sensible, ask now. Do not invent answers.

### Step 4: Generate the slug and filename

- Slug: 2-5 lowercase kebab-case words derived from the task. Example: `add-jwt-middleware`, `refactor-payment-retry`, `fix-cors-on-api`.
- Sequence number: scan `.codex/tasks/` and `.codex/tasks/done/` for existing files whose name starts with today's UTC date (`YYYY-MM-DD-`). The next sequence number is the highest existing NNN for that date + 1, zero-padded to 3 digits (e.g. `001`, `002`). If no files exist for today, start at `001`.
- Filename: `YYYY-MM-DD-NNN-<slug>.md` using today's UTC date and the computed sequence number.
- Path: `.codex/tasks/<filename>`.

No slug suffix (`-v2`, `-v3`) is needed — the sequence number already guarantees uniqueness per day.

### Step 5: Write the task file

Use the exact skeleton in `.codex/guidelines/task-management.md`. Fill every section:

- **Frontmatter**: `status: planning`, today's date in `created` and `updated`, `agent: codex`, 1-5 lowercase kebab tags.
- **Purpose**: 2-3 sentences. Answer "who gains what, how do they verify it works".
- **Context & Orientation**: this is the handoff to future-self. Fill all three subsections:
  - *Related Code*: every file path the plan touches or reads, with one-line reason.
  - *Related Docs*: project docs (`docs/...`) AND external references (URLs, RFCs).
  - *Memory Hints*: free-form notes — every non-obvious thing discovered during exploration that a fresh agent would otherwise re-discover. This section is the lifeline against memory loss across sessions. Be generous.
- **Plan of Work**: 1-3 paragraphs of prose narrating the sequence and rationale. If subagents are useful, include a concise delegation strategy only when the user explicitly authorized subagents/delegation/parallel work; otherwise mention only the delegation opportunity and the approval needed.
- **Concrete Steps**: ordered checklist. Each step is one self-contained action with target file and expected outcome. Steps should be small enough that completing one is a meaningful save point.
- **Validation & Acceptance**: observable success criteria — tests to pass, commands to run, behaviors to verify.
- **Decision Log**: any non-obvious choice made while planning (library, approach, trade-off), with rationale. Include assumptions made due to ambiguous input.
- **Surprises & Discoveries**: anything unexpected found during exploration.
- **Outcomes & Retrospective**: leave empty (filled at completion).

### Step 6: Update `index.md`

If `.codex/tasks/index.md` does not exist, create it with the canonical header (see guideline file). Add the new task under `## Active`:

```
- [<slug>](<YYYY-MM-DD-NNN-slug>.md) — planning — updated <YYYY-MM-DD>
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
2. If the user explicitly authorized subagents, follow `.codex/guidelines/agent-delegation.md`: decompose critical-path versus sidecar work, spawn only bounded non-blocking tasks, assign disjoint worker ownership, and record durable outputs in the task file.
3. Execute Concrete Steps in order, marking each `[x]` with `(YYYY-MM-DD HH:MMZ)` UTC timestamp on completion.
4. Update Surprises / Decision Log as needed, including subagent findings that changed the plan.
5. When all Concrete Steps + Validation boxes are checked, run the **Two-Phase Completion Gate** from the guideline file:
   - **Phase 1**: fill draft Outcomes, flip `status: in-progress -> awaiting-review`, report to user, **STOP**. Do not archive, do not write JOURNAL.
   - **Phase 2a**: only after the user gives a completion signal ("approved", "looks good", "close it", "done", "ship", "ok đóng task") — run the archive flow.
   - **Phase 2b**: if the user reports a problem, append to Surprises, flip back to `in-progress`, fix, return to Phase 1.

The agent must NEVER skip Phase 1 or self-confirm Phase 2. The completion gate is symmetric with the planning approval gate at the other end.

## Anti-Patterns

- Do not write code while `status: planning` or `status: awaiting-review`. Both are read-only locks.
- Do not auto-complete the task. When all boxes are checked, you go to `awaiting-review` and stop. The user — not you — flips it to `done`.
- Do not skip Memory Hints. A plan with no Memory Hints is a plan that won't survive a context reset.
- Do not put the plan body into chat instead of the file. The file is the plan.
- Do not spawn subagents from planning lock. Record the strategy; execution waits for both task approval and explicit subagent authorization.
- Do not auto-approve on user enthusiasm ("great idea!") — wait for an explicit approval cue at each gate.
