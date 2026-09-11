---
description: Validate the CLAUDART installation in this repository and report any drift, broken rules, or missing wiring
---

Please run a health check on this repository's CLAUDART installation. Your job is **diagnostic only** — do NOT auto-fix anything. Report findings; the user will run `/refactor-memory` or edit files manually based on your output.

## What to Check

### 0. Knowledge Checker First

Before the semantic audit, run:

```bash
bash .claude/scripts/knowledge-check.sh
```

Record its exit status and every finding. The checker is read-only and owns mechanical knowledge validation; do not reproduce or reinterpret its parser. Exit `1` means contract findings were reported; preserve their stated severity and continue the semantic audit. Exit `2` means checker usage, precondition, or internal/runtime failure; report **High** and continue only with the semantic audit. If the script is missing, report **High** and continue with the bounded semantic audit using `.claude/rules/knowledge-management.md`. A missing or exit-`2` checker means this installation cannot be declared healthy.

### 1. Required Structure

- `.claude/` exists at the repository root
- `.claude/commands/` exists and contains at least: `start.md`, `learn.md`, `refactor-memory.md`, `doctor.md`, `checkpoint.md`, `plan.md`, `handoff.md`, `project-discovery.md`, `spec.md`, `spec-run.md`
- `.claude/agents/` exists (may be empty if user removed shipped agents)
- `.claude/rules/` exists (may be empty before the user runs `/refactor-memory`)
- `.claude/rules/code-health.md` exists and is referenced from `.claude/CLAUDE.md`
- `.claude/rules/knowledge-management.md` exists and is referenced from `.claude/CLAUDE.md`
- `.claude/knowledge/` exists with `INDEX.md` (warn if missing — `/refactor-memory` will recreate it)
- `.claude/scripts/knowledge-check.sh` exists (missing is **High**, not a routine warning)
- `.claude/tasks/` exists with `index.md` and `done/` subdirectory (warn if missing — `/plan` will create on first use)
- `.claude/specs/` exists with `INDEX.md` and `done/` archive folder (informational if missing — `/spec` creates it on first use)
- `.claude/CLAUDE.md` exists
- `.claude/CONTEXT.md` exists (warn if missing — the user may not have run `/checkpoint` yet)
- `.claude/JOURNAL.md` exists (warn if missing)

For each missing path, report which command would create it (e.g., "missing → run `/refactor-memory`").

### 2. YAML Frontmatter Validity

For every `.md` file under `.claude/commands/`, `.claude/agents/`, `.claude/rules/`:

- Verify the file starts with a YAML frontmatter block delimited by `---`.
- For agents: confirm `name`, `description`, `tools`, and `model` keys are present. If `description` should auto-trigger the agent, confirm it contains `PROACTIVELY` (note when missing — may be intentional). Keep explorers and review-only/audit-only agents without `Edit`; allow `Edit` only when the declared purpose explicitly requires implementation. Every write-capable agent must define scope, protect unrelated user work, require validation, and account for parallel edits.
- For rules: confirm `paths:` (a list of glob patterns), `description:`, `when_to_use:`, and `tags:` keys are present.
- For rule `paths:`, confirm paths use YAML flow sequence style, e.g. `paths: ["src/**/*.ts", "test/**/*.ts"]`. Flag block-list style (`paths:` followed by `- item`) because frontmatter conventions should stay compact and grep-friendly.
- For rule `tags:`, confirm tags use inline YAML array style on one line, e.g. `tags: [architecture, nestjs, boundaries]`. Flag block-list style (`tags:` followed by `- item`) because tag indexing depends on single-line frontmatter.
- Confirm there are 1-5 lowercase kebab-case tags describing domain or scope.
- For commands: confirm `description:` is present.
- Report any malformed YAML, missing required keys, or obviously broken frontmatter.

For every `.agents/skills/*/SKILL.md` file:

- Verify the file starts with YAML frontmatter.
- Confirm `name:` and `description:` are present.

### 3. Rule Path Coverage

For every rule file in `.claude/rules/*.md`:

- Read each glob pattern in `paths:`.
- Use Glob to verify each pattern matches at least one real file in the repo.
- Patterns matching zero files → flag as **possibly dead rule**: either the codebase moved or the rule was scoped wrong. Suggest re-scoping or removal.
- `paths: ["**/*"]` is allowed for universal rules such as `ai-behavior.md`.

### 4. .claude/CLAUDE.md ↔ Rules Cross-Linking

- Read `.claude/CLAUDE.md`.
- Find the `## Domain Rules` section.
- For every `@.claude/rules/*.md` import there, confirm the target file exists.
- For every file under `.claude/rules/`, confirm there is a matching `@` import in `.claude/CLAUDE.md`. Files without an import are loaded only when their `paths:` glob fires — flag this as **isolated rule** so the user knows it won't be globally visible.

### 5. AI Behavior Wiring

- Confirm `.claude/rules/ai-behavior.md` exists.
- Confirm `.claude/CLAUDE.md` has `@.claude/rules/ai-behavior.md` (or equivalent reference) under Domain Rules. If missing, the universal behavior guidelines are not loaded — flag as **High** severity.

### 5a. Code Health Wiring

- Confirm `.claude/rules/code-health.md` exists.
- Confirm `.claude/CLAUDE.md` has `@.claude/rules/code-health.md` (or equivalent reference) under Domain Rules. If missing, ordinary implementation bypasses the shared correctness, scope, behavior-preservation, testing, and validation contract — flag as **High** severity.

### 5b. CONTEXT/JOURNAL Wiring (token hygiene)

- Confirm `@.claude/CONTEXT.md` is referenced in `.claude/CLAUDE.md` Domain Rules. If missing, current-state handoff isn't loaded — flag as **Medium**.
- `.claude/CONTEXT.md` line count must be ≤ 150 (use `wc -l`, do NOT full-read the file just to count). Also report approximate tokens using `wc -w .claude/CONTEXT.md | awk '{printf "~%d tokens", $1 * 1.3}'` and cross-check with `wc -c .claude/CONTEXT.md | awk '{printf "~%d tokens", $1 / 4}'`. If line count exceeded, flag as **High** — past the declarative ceiling, needs trimming or graduation via `/learn`.
- **CRITICAL**: search `.claude/CLAUDE.md` AND every file in `.claude/rules/` for any `@.claude/JOURNAL.md` reference (use `grep -r '@.claude/JOURNAL.md' .claude/CLAUDE.md .claude/rules/`). If found, flag as **Critical** — JOURNAL must NEVER be loaded into session context (defeats the entire token-saving purpose). Recommend immediate removal.
- Search `.claude/CONTEXT.md` for `<!-- since: YYYY-MM-DD -->` comments. Flag items older than 30 days as graduation candidates if they remain in Recent Decisions or otherwise look durable. If an obviously long-lived decision has no `since:` comment, warn that future `/checkpoint` should preserve/add one.
- For `.claude/JOURNAL.md` integrity, use spot-checks rather than full reads (the file may be large):
  - `head -n 20 .claude/JOURNAL.md` — verify the canonical header is intact.
  - `wc -l .claude/JOURNAL.md` — report total entry count for the user.
  - `tail -n 5 .claude/JOURNAL.md` — sample-check the most recent lines match the `YYYY-MM-DD | <type> | <summary>` format.
  - Skip deeper validation. If a malformed line is suspected, ask the user; do not slurp the whole file just to verify format.

### 5c. Task Workspace Health (`.claude/tasks/`)

Skip this section if `.claude/tasks/` does not exist. Follow `.claude/rules/task-management.md`; this audit does not create or repair task content.

- Confirm `.claude/tasks/index.md` exists. Missing -> Medium; suggest `/checkpoint` to regenerate it. Count lines with `wc -l`: the 100-line ceiling and trim ladder remain unchanged.
- Inspect only `.claude/tasks/*/TASK.md` and `.claude/tasks/done/*/TASK.md` in directly contained `YYYY-MM-DD-NNN-<slug>` directories. Exclude `done/` itself; never follow workspace or `TASK.md` symlinks or recursively parse attachments as tasks. Flat task files are outside the current contract, not a second discovery format.
- Flag a dated directory missing `TASK.md`, or an invalid directory name, as Medium; preserve it for explicit repair. Do not invent metadata, migrate flat files, or remove unknown content.
- Check `TASK.md` frontmatter: required `slug`, `status`, `created`, `updated`, `agent`, `delegation`, `tags`; `status` in {planning, in-progress, awaiting-review, blocked, done, cancelled}; `agent` in {claude, codex, both}; `delegation` in {none, strategy-only, authorized}. The directory must equal `<created>-<NNN>-<slug>`, with UTC date, sequence 001–999, and a 2–5-word lowercase kebab-case slug. Tags remain an inline array of 1–5 lowercase kebab-case values.
- Flag top-level `done`/`cancelled` workspaces for whole-directory archival by `/checkpoint`. Flag an archive destination collision or an archived non-terminal task as Medium; never overwrite, relocate, or change status during this audit. `awaiting-review` must remain active until the user confirms.
- Cross-check index links against the actual `TASK.md` paths and status: every active workspace appears under Active, every listed entry exists, and Recently Done links use `done/<task-id>/TASK.md`. Suggest `/checkpoint` for mismatches.
- Required body sections remain `## Purpose`, `## Context & Orientation`, `## Plan of Work`, `## Concrete Steps`, `## Validation & Acceptance`, `## Decision Log`, `## Surprises & Discoveries`, and `## Outcomes & Retrospective`. Require `### Memory Hints`; `None.` is valid when no non-obvious context exists. Do not demand filler for simple tasks.
- A `TASK.md`-only workspace is complete. Missing `artifacts/` or `### Workspace Files` is normal and must never produce a warning. Do not require NOTES, ROADMAP, LEDGER, manifests, or placeholder reports.
- When `### Workspace Files` exists, check only its explicit local references for existence and a concrete purpose. Flag missing required input/evidence or unexplained local-only dependencies; a documented external/reproducible reference is not a broken local link. Do not read artifact bodies, fetch external inputs, extract archives, execute files, generate replacements, or create directories as part of doctor.
- Apply the canonical **Staleness Thresholds** in `.claude/rules/task-management.md`; surface stalled work and review gates without automatically changing status.
- A `tasks/done/.gitkeep` beside a real archived `<task-id>/TASK.md` is redundant (Low); `/refactor-memory` may remove that placeholder only. Task evidence is not a cleanup target.

### 5d. Knowledge Tier Wiring (`.claude/knowledge/`)

Skip this section if `.claude/knowledge/` does not exist.

Read `.claude/rules/knowledge-management.md` and use the checker output as the mechanical baseline. Then audit only what requires semantic judgment:

- Confirm the root is a compact router and routing is root → optional domain map → topic, with no nested maps. Preserve intentional external routes. If active topics exceed 24 or the root exceeds 1,200 visible words without domain maps, flag **Low**.
- Treat an empty tier as informational. An unindexed file with ambiguous intent is a review candidate, not automatically active, retired, or orphaned.
- Verify sampled concrete claims against their stated sources/current repository evidence. If evidence is insufficient, stale, or conflicting while status is `active`, flag **Medium** and recommend `review-needed` plus a `status_note`; do not change the file.
- Flag prescriptive behavior, WIP, proposals, roadmap/acceptance state, or task chronology in knowledge as **Medium** tier leakage. A locally scoped durable fact is valid and must not be rejected merely because it is not project-wide.
- Flag likely duplicate owners or unsupported supersession/retirement as **Low** for controlled curation. Never recommend automatic deletion.
- Treat a topic over 10 KiB as an outline/section-first split candidate, not an automatic split.
- Confirm no knowledge topic or INDEX is `@`-imported into `.claude/CLAUDE.md`; the plain root-router pointer is valid.

### 5e. Session Handoff Hygiene (`.claude/HANDOFF.md`)

`.claude/HANDOFF.md` is a transient single-slot baton written by `/handoff` and consumed (deleted) by the next `/start`. **Absent is the normal state — never warn when it is missing.**

- If present, it is an unconsumed baton. Report it informationally. If its frontmatter `created:` is more than 7 days old, flag as **Medium** — reasoning state rots fast; suggest resuming via `/start` or deleting it.
- Line count must be ≤ 150 (use `wc -l`). If exceeded, flag as **High** — the baton is drifting toward a transcript dump; `/handoff`'s distillation rules were not honored.
- **CRITICAL**: run `grep -rn '@.claude/HANDOFF.md' .claude/CLAUDE.md .claude/rules/`. If found, flag as **Critical** — the baton is consumed once by `/start`, NEVER auto-loaded into every session.
- Multiple handoff artifacts (`HANDOFF-*.md`, dated copies, a `handoff/` directory under `.claude/`) → flag as **Medium** — violates the single-slot contract; suggest consolidating into one `HANDOFF.md` or deleting stale copies.

### 5f. Spec Workspace Health (`.claude/specs/`)

Skip this section if `.claude/specs/` does not exist.

- Confirm `.claude/specs/INDEX.md` exists. If missing, flag as **Medium** — `/spec` or `/checkpoint` should regenerate it.
- Confirm `.claude/specs/done/` exists. If missing, flag as **Low** — `/spec` or `/checkpoint` should create it.
- **INDEX ↔ folders match** (both directions): every active `YYYY-MM-DD-<slug>/` folder directly under `.claude/specs/` with an active status must be listed under `## Active`; every archived `done/YYYY-MM-DD-<slug>/` folder with `status: done` or `status: cancelled` must be listed under `## Done`; every INDEX entry must point to an existing `SPEC.md` (dead → **Low**).
- Ignore `.claude/specs/done/` itself when enumerating active spec folders.
- For every active or archived spec folder, confirm the core files exist: `SPEC.md`, `ROADMAP.md`, `NOTES.md`, `LEDGER.md`. Missing → **Medium**.
- `NOTES.md` line count ≤ 150 (`wc -l`). Exceeded → **Medium** — the working memory is drifting toward a log; distill it and route eligible durable descriptive facts under the knowledge rule.
- `SPEC.md` frontmatter: required keys `slug`, `status`, `created`, `updated`, `agent`; `status` ∈ {drafting, poc-review, ready, running, blocked, awaiting-final-review, done, cancelled}; folder name must be `created` + `-` + `slug`; `commits` (if present) ∈ {user, per-task, per-phase}.
- For specs at `poc-review` or later: every `artifacts/` path referenced under `## POC Artifacts` must exist on disk. Missing → **Medium** (the executor's frozen UI reference is gone).
- **ROADMAP disposition consistency**: `- [ ] ~~task~~` → **Medium** (invalid legacy state; reconcile it to checked + superseded or an explicit blocker before `/spec-run`); a checked + struck row missing `superseded by <task-id or reason>` → **Medium**; a blocked row missing either its condition or `unlock:` requirement → **Medium**. Do not equate every plain unticked row with runnable work — honor dependency notes. `running` where dependency inspection finds no runnable pending row and at least one blocker → **Medium** (the circuit-breaker/status transition was missed); `running` with every row terminal → **Medium** (the final gate never ran); `blocked` with no explicit blocked row → **Medium** (the diagnosis/unlock state is not durable); `blocked` where dependency inspection finds any independent runnable row → **Medium** (the whole-loop transition happened too early); `awaiting-final-review` or `done` with any unticked row → **Medium** (the final gate contradicts ROADMAP state). Top-level spec folder with `status: done`/`cancelled` → **Low** (resync via `/checkpoint` to archive it under `done/`). Archived spec folder whose status is not `done`/`cancelled` → **Medium** (it is shelved in the wrong place). `status: done`/`cancelled` still listed under `## Active` in INDEX → **Low** (resync via `/checkpoint`).
- **Staleness** (mirror the Staleness Thresholds table in `.claude/rules/task-management.md`; do not redefine the numbers): `running` stale as `in-progress`; `poc-review` and `awaiting-final-review` stale as `awaiting-review` — surface prominently, these wait on the user's verdict; `drafting` stale as `planning`.
- `LEDGER.md` spot-check via `tail -n 15`: recent entries match the `### YYYY-MM-DD HH:MMZ — <event>` heading format. Do not slurp the whole file.

### 6. Anti-Patterns Inside Rules and Agents

- **Inlined code blocks**: any triple-backtick code block longer than ~5 lines inside a rule or agent file is a likely violation of the "NO CODE SNIPPETS" principle. Report file + line.
- **Stale metadata**: lines like `Last Updated: <date>` rot quickly. Flag for removal.
- **Hardcoded shell patterns** (e.g., long `grep -r` lists) inside agent files. Flag — these belong in the project's tooling, not the agent prompt.
- **Mis-tiered rule (descriptive, not prescriptive)**: a `.claude/rules/` file whose body states only facts (how a subsystem works, an integration detail, a domain term, a doc pointer) with no behavioral constraint (`MUST`/`NEVER`/`should`/`avoid`/`always`/`never`) → flag as **Low**: it likely belongs in `.claude/knowledge/`. This is the mirror of §5d's descriptive-only check — the boundary runs both ways. Universal guidance like `ai-behavior.md` is exempt.

### 7. .claude/CLAUDE.md Size Sanity

- Count lines of `.claude/CLAUDE.md`. The target is < 100 lines.
- Report approximate tokens using both estimates:
  - `wc -w .claude/CLAUDE.md | awk '{printf "~%d tokens\n", $1 * 1.3}'`
  - `wc -c .claude/CLAUDE.md | awk '{printf "~%d tokens (byte estimate)\n", $1 / 4}'`
- If significantly larger, recommend running `/refactor-memory` to extract domains.

### 8. Rule Tag Index And Overlap

- Build a tag index from rule frontmatter only, e.g. `grep -h '^tags:' .claude/rules/*.md | sort -u`.
- Flag rules missing `tags:`, using block-list tags, or using vague/non-domain tags.
- Use overlapping tags as an initial signal for possible duplicate rules; read bodies only when tags or paths suggest overlap.

### 9. Agent Overlap

- For all files in `.claude/agents/`, compare their `description:` fields.
- If two agents share >50% of trigger keywords (e.g., both contain "review", "code", "PROACTIVELY"), flag as **possible overlap** — they may both auto-trigger on the same situation and waste tokens.

## Output Format

```
# CLAUDART Health Check

## ✅ Passing
- [item 1]
- [item 2]

## ⚠️ Warnings
**[file:line or section]** — [what's wrong] → [suggested action]

## ❌ Errors
**[file or section]** — [what's broken] → [suggested action]

## Recommended Next Step
[Single actionable suggestion: e.g., "Run /refactor-memory to extract domains and create missing ai-behavior import."]
```

Only if the checker exists, exits successfully, and every semantic/structural check passes, output: `✅ CLAUDART installation healthy. <n> rules, <n> knowledge entries, <n> agents, <n> commands, <n> specs.` Otherwise never claim healthy.

**Reminder**: this command is read-only. Never modify files.

For an existing project that needs normalization, keep the upgrade flow explicit: `/doctor` → `/refactor-memory` → `/doctor`.
