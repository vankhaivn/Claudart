# Integrate CLAUDART with your agent (AI-native install)

**You are an AI coding agent** (Claude Code, Codex CLI, or similar) and your user pasted a link to this file because they want to **adopt or upgrade CLAUDART** in the current project. CLAUDART is a plain-markdown operating layer — slash commands / skills, a layered memory model, and review agents — for Claude Code and Codex CLI.

Source of truth: <https://github.com/vankhaivn/Claudart> (branch `main`).

This file is a **protocol, not a script** — follow it top to bottom. It exists because the one-line `install.sh` does a _fresh copy_ and will clobber an existing setup. You are smarter than that: you can read the repo, compare it to this project, and merge surgically.

> **Golden rule — read freely, write only what is approved.** NEVER overwrite or delete anything the user authored or customized. When CLAUDART and the project disagree, show a diff and ASK. Default to preserving the user's work, even when taking CLAUDART's version "seems obviously better."

---

## Step 0 — Fetch the source and understand the intent

1. Get a clean copy of CLAUDART so you can diff against it precisely. Prefer a shallow clone:
   ```bash
   rm -rf /tmp/claudart-src && git clone --depth 1 https://github.com/vankhaivn/Claudart /tmp/claudart-src
   ```
   If you cannot clone (no git, or no network for clone), fetch files on demand from
   `https://raw.githubusercontent.com/vankhaivn/Claudart/main/<path>` instead.
2. Before touching anything, read these in the source to integrate the _model_, not just files: `README.md`, `docs/WORKFLOW.md`, `CONTRIBUTING.md`.
3. Do **not** run `install.sh` in a project that already has its own AI setup — that is exactly the situation this protocol replaces.

## What CLAUDART contains (orientation — the clone is the source of truth)

**Claude layer** (`.claude/`):

- `commands/` — slash commands: `start`, `plan`, `checkpoint`, `handoff`, `learn`, `refactor-memory`, `doctor`, `project-discovery`
- `agents/` — review agents: `clean-code-reviewer`, `security-auditor` (read-only on user code)
- `rules/` — **prescriptive**, path-scoped behavior (`ai-behavior`, `task-management`)
- `knowledge/INDEX.md` — **descriptive** durable project facts (a map; detail files read on demand)
- `CONTEXT.md` (state now), `JOURNAL.md` (history, append-only), `CLAUDE.md` (memory index)
- `tasks/` — persistent plan documents (`index.md` + `done/`)

**Codex layer** (`.codex/` + `.agents/`):

- `.agents/skills/codex-*` — the same commands as Codex skills
- `.codex/guidelines/` (= rules), `.codex/knowledge/`, `.codex/agents/*.toml`, `.codex/config.toml`, `.codex/CONTEXT.md`, `.codex/JOURNAL.md`, `.codex/tasks/`
- `AGENTS.md` at repo root (Codex memory index; the installer copies it from `.codex/AGENTS.md`)

Every Claude command has a mirrored Codex skill. If you integrate both layers, keep them consistent.

## Step 1 — Diagnose the situation

Inventory the **current project** (not the clone). Does `.claude/` / `.codex/` / `AGENTS.md` / `CLAUDE.md` exist? Are there custom agents, commands, rules, or a home-grown memory/workflow convention? Classify into one scenario:

- **A — Clean adopt:** no AI operating layer yet (at most a bare `CLAUDE.md`).
- **B — Merge into an existing workflow:** the user already has their own agents / commands / memory and must NOT have them clobbered.
- **C — Upgrade an existing CLAUDART install:** CLAUDART files are already present; the user wants whatever changed upstream since they installed (e.g. a new `knowledge/` tier).

Then ask which **layer(s)** to target — Claude (`.claude/`), Codex (`.codex/` + `.agents/`), or both. Default to whatever the project already uses.

## Step 2 — Plan, then ask

State a short plan for the detected scenario and chosen layer(s): list **exactly** which files you would add, merge, or skip. **Wait for explicit approval before writing anything.**

### Scenario A — Clean adopt

Copy the chosen layer(s) from the clone. The only merge is into index files that may already exist: if a root `CLAUDE.md` / `AGENTS.md` is present, **splice** CLAUDART's Core Commands and Domain Rules / Guidelines pointers into it — do not replace it. Then go to Step 3 → Step 4.

### Scenario B — Merge into an existing workflow (do not clobber)

For each CLAUDART piece, find its counterpart in the project and act by type:

- **Net-new** (no counterpart — e.g. `knowledge/`, `tasks/`, a command they lack) → safe to add. Still list it in the plan.
- **Same concept, different file** (e.g. they have their own reviewer agent) → do NOT overwrite. Show both and ask: keep theirs, take CLAUDART's, or run both under a renamed file.
- **Same filename** (`CLAUDE.md`, `AGENTS.md`, a rule of the same name) → **merge sections**, never replace. Add CLAUDART's command list / rule pointers / self-evolution section while preserving everything the user wrote.
- **Concept overlap** (they already have a "memory" or "plan" convention) → explain how CLAUDART's `CONTEXT`/`JOURNAL`/`tasks` map onto theirs and let the user choose which wins. Never silently run two competing systems.

Present the full add / merge / skip plan and ask before writing.

### Scenario C — Upgrade an existing CLAUDART install ("what changed?")

1. Diff the project's CLAUDART files against the clone and bucket every difference:
   - **New upstream** (absent locally, e.g. `.claude/knowledge/`) → propose adding, with a one-line "what it's for."
   - **Updated upstream, untouched locally** (local matches an older CLAUDART version) → propose replacing with the new version.
   - **Diverged** (the user edited this file locally) → **3-way reconcile**: show the upstream change beside their version and ASK how to merge. Never discard their edits.
2. For _why_ things changed, skim recent commit messages in the clone: `git -C /tmp/claudart-src log --oneline -20`.
3. Produce a **"What's new since your version"** summary first, then apply only what the user approves.

## Step 3 — Conflict protocol (every scenario)

- **Never** overwrite a file the user created or modified without showing a diff and getting an explicit "yes."
- Index / memory files (`CLAUDE.md`, `AGENTS.md`, `knowledge/INDEX.md`, `tasks/index.md`) are **spliced**, never wholesale-replaced — preserve the user's content and ordering.
- `CONTEXT.md` and `JOURNAL.md` are live user state — **never** import them from the template; only create them empty (from the template header) if missing. `HANDOFF.md` (when present) is a live one-shot session baton — never import, overwrite, or create it.
- Do not touch `.env`, secrets, or anything matched by `.gitignore`.
- If integrating both layers, keep the Claude command and its Codex skill mirror consistent.

## Step 4 — Validate and hand off

1. If you touched the Claude layer, run `/doctor`; for Codex, `$codex-doctor`. Fix any wiring it flags.
2. Summarize what was **added / merged / skipped**, and list any conflicts you parked for the user to decide.
3. Remind the user to review `git diff` before committing. **Do not commit, push, or merge yourself.**
4. This protocol is **idempotent** — safe to re-run later to pull the next CLAUDART update (that is Scenario C).

## Cleanup

Remove the temp clone when done: `rm -rf /tmp/claudart-src`.
