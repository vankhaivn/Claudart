# Integrate CLAUDART with your agent (AI-native install)

**You are an AI coding agent** (Claude Code, Codex CLI, or similar) and your user pasted a link to this file because they want to **adopt or upgrade CLAUDART** in the current project. CLAUDART is a plain-markdown operating layer — slash commands / skills, a layered memory model, and specialized agents — for Claude Code and Codex CLI.

Source of truth: <https://github.com/vankhaivn/Claudart> (branch `main`).

This file is a **protocol, not a script** — follow it top to bottom. It exists because the one-line `install.sh` does a _fresh copy_ and will clobber an existing setup. You are smarter than that: you can read the repo, compare it to this project, and merge surgically.

> **Version-agnostic delta rule.** Never assume which CLAUDART release, feature set, or file layout the downstream project started from. Derive the delta during this run from the current upstream clone, the current downstream tree, and upstream history. Do not reuse a canned release narrative such as “we just added X”; the same protocol must work for any future upstream state.
>
> **Golden rule — read freely, write only what is approved.** NEVER overwrite or delete anything the user authored or customized. When CLAUDART and the project disagree, show a diff and ASK. Default to preserving the user's work, even when taking CLAUDART's version "seems obviously better."
>
> **"Customized" means content the user wrote — not any local file that happens to differ from upstream.** A CLAUDART-shipped file whose local copy merely lags the current template is **stale, not custom** — upgrading it is the point of this protocol. When the user says "don't touch what I customized," that protects their authored content, and is never a reason to skip upgrading stale template files. Apply the stale-vs-custom test in Scenario C before calling anything custom.

---

## Step 0 — Fetch the source and understand the intent

1. Get a clean copy of CLAUDART so you can diff against it precisely. Clone with full history — the repo is small, and you will need `git log` to tell stale template copies apart from real user customizations:
   ```bash
   rm -rf /tmp/claudart-src && git clone https://github.com/vankhaivn/Claudart /tmp/claudart-src
   ```
   If you cannot clone (no git, or no network for clone), fetch files on demand from
   `https://raw.githubusercontent.com/vankhaivn/Claudart/main/<path>` instead.
2. Before touching anything, read these in the source to integrate the _model_, not just files: `README.md`, `docs/WORKFLOW.md`, `CONTRIBUTING.md`.
3. Do **not** run `install.sh` in a project that already has its own AI setup — that is exactly the situation this protocol replaces.

## What CLAUDART contains (orientation — the clone is the source of truth)

This is a category map, not an exhaustive or versioned allowlist. Enumerate the actual current clone on every run; a path omitted from this overview must still be included when the live dependency analysis finds it.

**Claude layer** (`.claude/`):

- `commands/` — slash commands: `start`, `plan`, `spec`, `spec-run`, `checkpoint`, `handoff`, `learn`, `refactor-memory`, `doctor`, `project-discovery`
- `agents/` — specialized agents: write-capable `clean-code-reviewer` for scoped code-health implementation, plus read-only `security-auditor` and `ui-visual-critic`; all are explicit-request-only and never run automatically
- `rules/` — **prescriptive**, path-scoped behavior (`ai-behavior`, `code-health`, `agent-delegation`, `knowledge-management`, `task-management`, `spec-workflow`)
- `knowledge/INDEX.md` — root router for **descriptive** durable project facts; optional `_maps/` and detail files are read on demand
- `scripts/knowledge-check.sh` — dependency-free, read-only mechanical validation for the knowledge contract
- `CONTEXT.md` (state now), `JOURNAL.md` (history, append-only), `CLAUDE.md` (memory index)
- `tasks/` — persistent plan documents (`index.md` + `done/`)
- `specs/` — mission-scale spec workspaces (only `INDEX.md` ships; mission folders are created by `/spec`)

**Codex layer** (`.codex/` + `.agents/`):

- `.agents/skills/codex-*` — the same commands as Codex skills
- `.codex/guidelines/` (= rules, including `knowledge-management`), `.codex/knowledge/`, `.codex/scripts/knowledge-check.sh`, `.codex/agents/*.toml`, `.codex/config.toml`, `.codex/CONTEXT.md`, `.codex/JOURNAL.md`, `.codex/tasks/`, `.codex/specs/`
- `AGENTS.md` at repo root (Codex memory index; the installer copies it from `.codex/AGENTS.md`)

Every Claude command has a mirrored Codex skill. If you integrate both layers, keep them consistent.

## Step 1 — Diagnose the situation

Inventory the **current project** (not the clone). Does `.claude/` / `.codex/` / `AGENTS.md` / `CLAUDE.md` exist? Are there custom agents, commands, rules, or a home-grown memory/workflow convention? Classify into one scenario:

- **A — Clean adopt:** no AI operating layer yet (at most a bare `CLAUDE.md`).
- **B — Merge into an existing workflow:** the user already has their own agents / commands / memory and must NOT have them clobbered.
- **C — Upgrade an existing CLAUDART install:** CLAUDART files are already present; the user wants the delta between that installation and current upstream.

Then ask which **layer(s)** to target — Claude (`.claude/`), Codex (`.codex/` + `.agents/`), or both. Default to whatever the project already uses.

## Step 2 — Plan, then ask

State a short plan for the detected scenario and chosen layer(s): list **exactly** which files you would add, replace, merge, relocate, retire, or skip. **Wait for explicit approval before writing anything.**

### Scenario A — Clean adopt

Copy the chosen layer(s) from the clone. The only merge is into index files that may already exist: if a root `CLAUDE.md` / `AGENTS.md` is present, **splice** CLAUDART's Core Commands and Domain Rules / Guidelines pointers into it — do not replace it. Then go to Step 3 → Step 4.

### Scenario B — Merge into an existing workflow (do not clobber)

For each CLAUDART piece, find its counterpart in the project and act by type:

- **Upstream-only path** (present in the current clone with no downstream counterpart) → propose adding it and explain its current role. Still list it in the plan.
- **Same concept, different file** (e.g. they have their own reviewer agent) → do NOT overwrite. Show both and ask: keep theirs, take CLAUDART's, or run both under a renamed file.
- **Same filename** (`CLAUDE.md`, `AGENTS.md`, a rule of the same name) → **merge sections**, never replace. Add CLAUDART's command list / rule pointers / self-evolution section while preserving everything the user wrote.
- **Concept overlap** (they already have a "memory" or "plan" convention) → explain how CLAUDART's `CONTEXT`/`JOURNAL`/`tasks` map onto theirs and let the user choose which wins. Never silently run two competing systems.

Present the full add / replace / merge / relocate / retire / skip plan and ask before writing.

### Scenario C — Reconcile an existing CLAUDART install with current upstream

1. Diff the project's actual installed state against the current clone; do not assume all local files came from one revision. Classify every relevant path:
   - **Equivalent** (identical or demonstrably equivalent after an allowed root relocation) → keep it and record `unchanged`.
   - **Upstream-only path** (present in current upstream and absent downstream) → inspect history and downstream counterparts to distinguish an addition from a rename, move, split, consolidation, or replacement before proposing the action.
   - **Stale template copy** (the local content matches an earlier upstream state and contains no user-authored additions) → propose replacing it with current upstream **verbatim**. This is the default recommendation for recognizable CLAUDART protocol files: their purpose is to track the template, not freeze an earlier snapshot.
   - **Genuinely diverged** (the local file contains user-authored content that never shipped in any CLAUDART version — e.g. a section "Additional rules for project X") → take upstream as the **base** and **re-apply the user's additions on top**: show exactly which local sections you would carry over, and ASK before writing. Never discard their edits — and never let their edits become a reason to skip the upstream upgrade of the rest of the file.
   - **Downstream-only path** → use upstream history to decide whether it is project-authored or a CLAUDART path that current upstream removed, renamed, or consolidated. Preserve project-authored paths. For former template paths, show the replacement/owner and propose an explicit relocate or retirement; never silently leave competing protocols, and never delete before approval.
   - **Live state** (`CONTEXT.md`, `JOURNAL.md`, handoffs, task/spec bodies, knowledge topics/maps, and equivalent project-owned state) → preserve its content. Reconcile only its current contract, routing, or structure through the owning workflow; never compare it to seed content as though it were a stale template.
2. **Stale-vs-custom test — never classify by "differs from upstream" alone.** A difference is _custom_ only if you can point at the specific local lines the user authored. Use the clone's history to check: if the local content matches (or nearly matches) some past upstream version (`git -C /tmp/claudart-src log --oneline --all -- <path>`, or `git -C /tmp/claudart-src log -S"<distinctive local phrase>" -- <path>` to see whether a phrase ever existed upstream), the file is stale — take upstream. Content that names this project, its domain, or rules found in no upstream version is custom — preserve it per the diverged bucket above. When in doubt, show the specific lines and ask about **those lines**, not the whole file.
3. For _why_ things changed, recent commit messages (`git -C /tmp/claudart-src log --oneline -20`) are orientation only, never a history boundary. Trace any specific path or structural transition through full relevant history, using commands such as `git -C /tmp/claudart-src log --all --follow -- <path>` and targeted `git log -S`.
4. Produce a **current upstream reconciliation report** covering unchanged, upstream-only, changed upstream-derived, renamed/moved/split/consolidated, retired, preserved downstream-only, live-state, and genuinely customized paths. Then apply only what the user approves. Never identify the downstream as a named or assumed release unless repository evidence proves it, and never substitute a canned release narrative for that evidence.

For any added, changed, renamed, or retired cross-file contract, derive its complete dependency closure from **current upstream**. Include every selected-layer file that defines, routes, invokes, validates, installs, documents, or mirrors that contract. Derive the set from actual references and the current installer payload; do not rely on a component list copied from a previous release. Integrate the approved closure atomically. When the delta touches the knowledge contract, preserve every live downstream topic, map, and project-specific route; the shipped `knowledge/INDEX.md` is a merge template, not a replacement for project knowledge.

## Step 3 — Conflict protocol (every scenario)

- **Never** overwrite a file the user created or modified without showing a diff and getting an explicit "yes." (A stale template copy is not "modified by the user" — see the stale-vs-custom test in Scenario C.)
- For CLAUDART-shipped core files, prefer **verbatim upstream + relocated customizations**: project-specific behavior belongs in its own rule/guideline file, `knowledge/`, or the project's `CLAUDE.md`/`AGENTS.md` — not inline edits to core protocol files. When you find genuinely custom lines inside a core file, offer to move them to the right home so the core file can track upstream cleanly.
- Index / memory files (`CLAUDE.md`, `AGENTS.md`, `knowledge/INDEX.md`, `tasks/index.md`, `specs/INDEX.md`) are **spliced**, never wholesale-replaced — preserve the user's content and ordering. Preserve live `knowledge/_maps/` and topic files too; they are project state, not template payload.
- `CONTEXT.md` and `JOURNAL.md` are live user state — **never** import them from the template; only create them empty (from the template header) if missing. `HANDOFF.md` (when present) is a live one-shot session baton — never import, overwrite, or create it. Spec mission folders (`specs/<slug>/`) are likewise live state — only the `specs/INDEX.md` registry ships from the template.
- Do not touch `.env`, secrets, or anything matched by `.gitignore`.
- If integrating both layers, keep the Claude command and its Codex skill mirror consistent.

## Step 4 — Validate and hand off

1. Read the current upstream workflow documentation and the selected layer's current validation/normalization definitions, then run the reconciliation flow they declare. In the current source, that flow is `doctor → refactor-memory → doctor` (Codex: `$codex-doctor → $codex-refactor-memory → $codex-doctor`): inventory the actual on-disk state read-only, reconcile it idempotently, then verify it. Current upstream is authoritative if this sequence changes later. Do not infer a version-specific path or invent migration, recall, or other commands absent from current upstream.
2. Fix any wiring or mechanical contract failure. Park claims that cannot be safely resolved as `review-needed`; never invent evidence just to make the checker green.
3. Summarize what was **added / replaced / merged / relocated / retired / normalized / skipped**, and list any conflicts you parked for the user to decide.
4. Remind the user to review `git diff` before committing. **Do not commit, push, or merge yourself.**
5. This protocol is **idempotent** — safe to re-run later to pull the next CLAUDART update (that is Scenario C).

## Cleanup

Remove the temp clone when done: `rm -rf /tmp/claudart-src`.
