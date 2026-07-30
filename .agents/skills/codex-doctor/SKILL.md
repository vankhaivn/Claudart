---
name: codex-doctor
description: Run a read-only Codex installation health check using the knowledge checker plus semantic audits of memory and workflow wiring.
---

# Codex Doctor

Run a read-only health check on this repository's CLAUDART installation from the Codex side. This is diagnostic only. Do not auto-fix anything. Report findings so the user can run `$codex-refactor-memory`, `/refactor-memory`, or edit files manually.

## What to Check

### 1. Required Structure

- A Codex memory index exists: root `AGENTS.md` for an installed downstream project, or `.codex/AGENTS.md` for the CLAUDART source template copied by the installer. If both exist, compare them and flag drift.
- `.codex/CONTEXT.md` exists. Warn if missing because the user may not have run checkpoint yet.
- `.codex/JOURNAL.md` exists. Warn if missing.
- `.codex/guidelines/` exists and contains at least `ai-behavior.md`, `task-management.md`, `agent-delegation.md`, `spec-workflow.md`, and `knowledge-management.md`.
- `.codex/knowledge/` exists with `INDEX.md` (warn if missing — `$codex-refactor-memory` will recreate it).
- `.codex/scripts/knowledge-check.sh` exists and is readable. Missing checker is **High** because doctor cannot mechanically validate the canonical knowledge contract; do not emulate it with ad hoc parsing.
- `.codex/agents/` exists, even if the user removed shipped agents.
- `.codex/config.toml` exists and contains an `[agents]` table with conservative delegation limits.
- `.codex/tasks/` exists with `index.md` and `done/` subdirectory (warn if missing — `$codex-plan` will create on first use).
- `.codex/specs/` exists with `INDEX.md` and `done/` archive folder (informational if missing — `$codex-spec` creates it on first use).
- `.agents/skills/` exists and contains `codex-start`, `codex-checkpoint`, `codex-learn`, `codex-doctor`, `codex-refactor-memory`, `codex-plan`, `codex-handoff`, `codex-project-discovery`, `codex-spec`, and `codex-spec-run`.

For each missing path, report which workflow would create or repair it.

### 2. Frontmatter and Metadata Validity

For every `.md` file under `.codex/guidelines/`:

- Verify the file starts with YAML frontmatter delimited by `---`.
- Confirm `paths:`, `description:`, `when_to_use:`, and `tags:` are present.
- Confirm `paths:` uses YAML flow sequence style, e.g. `paths: ["src/**/*.ts", "test/**/*.ts"]`. Flag block-list style (`paths:` followed by `- item`) because frontmatter conventions should stay compact and grep-friendly.
- Confirm `tags:` uses inline YAML array style on one line, e.g. `tags: [architecture, nestjs, boundaries]`. Flag block-list style (`tags:` followed by `- item`) because tag indexing depends on single-line frontmatter.
- Confirm `tags:` contains 1-5 lowercase kebab-case tags describing domain or scope.
- Report malformed YAML, missing required keys, or obviously broken frontmatter.

For every `.agents/skills/*/SKILL.md` file:

- Verify the file starts with YAML frontmatter.
- Confirm `name:` and `description:` are present.
- Confirm the skill contains sufficient procedure detail to execute the workflow.

For every `.codex/agents/*.toml` file:

- Confirm `name`, `description`, `model`, `model_reasoning_effort`, `sandbox_mode`, and `developer_instructions` keys are present.
- Confirm review/explorer agents use `sandbox_mode = "read-only"` unless their purpose clearly requires writes.
- Confirm any worker-style agent clearly describes its write scope expectations and warns that other agents may be editing in parallel.

### 3. Guideline Path Coverage

For every guideline file in `.codex/guidelines/*.md`:

- Read each glob pattern in `paths:`.
- Verify each pattern matches at least one real file in the repo.
- Patterns matching zero files -> flag as possibly dead guideline. Suggest re-scoping or removal.

`paths: ["**/*"]` is allowed for universal guidelines such as `ai-behavior.md`.

### 4. Codex Memory Cross-Linking

- Determine the active memory index to inspect:
  - If root `AGENTS.md` exists, read it.
  - Otherwise read `.codex/AGENTS.md` and report that this is the template source copied to root by `install.sh`.
  - If both exist, compare them and flag drift unless the project deliberately documents a different canonical file.
- Confirm the memory index points Codex to `.codex/CONTEXT.md`, requires the universal behavior guideline, and tells agents to load other guidelines selectively by task.
- Find the guideline section in the memory index.
- For every explicit `.codex/guidelines/*.md` reference there, confirm the target file exists.
- Require direct references for globally relevant workflow guidelines. A task-scoped guideline may instead be discoverable through clear frontmatter and targeted routing; do not require a pointer that would force every guideline to load.
- Flag any instruction that blindly full-reads `.codex/guidelines/*.md`.

### 5. AI Behavior Wiring

- Confirm `.codex/guidelines/ai-behavior.md` exists.
- Confirm the active memory index references `.codex/guidelines/ai-behavior.md`.
- If missing, flag as High severity because universal behavior guidelines are not loaded.

### 5b. Agent Delegation Wiring

- Confirm `.codex/guidelines/agent-delegation.md` exists.
- Confirm the active memory index references `.codex/guidelines/agent-delegation.md`.
- Confirm `.codex/config.toml` caps subagent concurrency: `[agents] max_concurrent_threads_per_session` set to a positive integer. Flag values above 6 as Medium unless documented, because broad fan-out can create token cost and merge-conflict risk.
- Confirm delegation guidance covers the "how" of delegation: decomposition before fan-out, self-contained worker prompts, no shadow-running a delegated question, and one-level delegation depth unless the user asks for recursion. If missing, flag as High because delegated work may be duplicated or unbounded.

### 5c. Knowledge Base Wiring (`.codex/knowledge/`)

Skip this section if `.codex/knowledge/` does not exist.

Read `.codex/guidelines/knowledge-management.md` in full before this audit.

#### Mechanical pass

1. If `.codex/scripts/knowledge-check.sh` is missing or unreadable, report **High** and continue only with the semantic pass. Do not invent a replacement parser.
2. Otherwise run `bash .codex/scripts/knowledge-check.sh --root .` exactly once with its default failure threshold. The checker is read-only; any changed file is a High-severity integrity failure.
3. Interpret exit `1` as reported contract findings. Exit `2` is a checker usage, precondition, or internal/runtime failure; report it as High and continue only with the semantic pass.
4. Report every checker finding with its path and severity. The checker owns restricted frontmatter grammar, enum/date/name checks, route reachability, map depth, typed relations/scope, local source resolution and source-newer-than-`last_verified` warnings, map/topic size thresholds, and sensitive absolute-path leakage.
5. Treat an empty tier as informational. Treat an ambiguous unindexed file as a review item, not proof that it is active, retired, or safe to delete.

#### Semantic pass

The checker cannot decide whether prose is true or correctly tiered. Audit:

- **Capture quality**: active claims are descriptive, durable beyond current work, current, and evidenced; narrowly scoped claims carry an accurate typed `scope`.
- **Tier separation**: roadmap, backlog, acceptance state, WIP, proposals, and behavioral `MUST`/`NEVER` content do not masquerade as descriptive knowledge.
- **Authority**: `review-needed`, conflicting, superseded, or retired topics are not presented as current authority; `status_note` and evidence explain the state.
- **Ownership**: overlapping facts have one focused canonical owner; related topics link rather than copy. Preserve deliberate external routes and curated hooks.
- **Verification meaning**: `updated` means content edit and `last_verified` means evidence check. Source drift takes priority over age; age alone is only a review nudge.
- **Retrieval shape**: root → topic is acceptable for a small store; root → `_maps/<domain>.md` → topic is the only mapped shape. Maps never nest. A topic over 10 KiB is a reviewed split candidate, not an automatic rewrite.
- **Loading behavior**: `$codex-start` reads only the root router and never runs this checker. Detail topics are not globally auto-loaded.

Use bounded source inspection to verify suspicious claims. Never fetch URLs merely to satisfy doctor unless the user separately requested current external verification. Doctor remains read-only and never fixes, promotes, retires, supersedes, or deletes knowledge.

### 6. CONTEXT/JOURNAL Wiring

- Confirm `.codex/CONTEXT.md` is referenced in the active memory index.
- `.codex/CONTEXT.md` line count must be at most 150. Use `wc -l`; do not full-read the file just to count.
- Report approximate `.codex/CONTEXT.md` tokens using both estimates:
  - `wc -w .codex/CONTEXT.md | awk '{printf "~%d tokens\n", $1 * 1.3}'`
  - `wc -c .codex/CONTEXT.md | awk '{printf "~%d tokens (byte estimate)\n", $1 / 4}'`
- Search the active memory index and `.codex/guidelines/` for any operational auto-load instruction for `.codex/JOURNAL.md`. If found, flag as Critical.
- Search `.codex/CONTEXT.md` for `<!-- since: YYYY-MM-DD -->` comments. Flag items older than 30 days as graduation candidates if they remain in Recent Decisions or otherwise look durable. If an obviously long-lived decision has no `since:` comment, warn that future `$codex-checkpoint` should preserve/add one.
- For `.codex/JOURNAL.md` integrity, use spot-checks rather than full reads:
  - `head -n 20 .codex/JOURNAL.md`
  - `wc -l .codex/JOURNAL.md`
  - `tail -n 5 .codex/JOURNAL.md`
- Skip deeper validation unless a malformed line is suspected.

### 6b. Task Document Health (`.codex/tasks/`)

Skip this section if `.codex/tasks/` does not exist.

- Confirm `.codex/tasks/index.md` exists. If missing, flag as Medium — `$codex-checkpoint` or `$codex-plan` should regenerate it.
- Count `.codex/tasks/index.md` lines via `wc -l`. Hard ceiling 100. If exceeded, flag as High — trim Recently Done.
- For every `.codex/tasks/*.md` file (excluding `index.md` and `done/`), check the YAML frontmatter:
  - Required keys: `slug`, `status`, `created`, `updated`, `agent`, `tags`.
  - `status` must be one of: `planning`, `in-progress`, `awaiting-review`, `blocked`, `done`, `cancelled`.
  - `slug` must match the filename (excluding the `YYYY-MM-DD-NNN-` prefix and `.md` suffix).
  - `tags` must be inline YAML array style with 1-5 lowercase kebab-case tags.
- Flag any task in the top-level folder with `status: done` or `status: cancelled` — these should have been moved to `done/` by `$codex-checkpoint`. Suggest running `$codex-checkpoint`.
- Apply the **Staleness Thresholds** table in `.codex/guidelines/task-management.md` (the canonical numbers — do not redefine them here): flag stalled `in-progress` and stuck `awaiting-review` tasks as Medium severity (for the latter, surface prominently and suggest the user verify and give the close-out signal, or reject), and flag abandoned `planning` tasks as cancellation candidates.
- Cross-check `index.md` Active entries against actual task files: every Active entry must correspond to a real file; every real file with `status` in {planning, in-progress, awaiting-review, blocked} must appear in Active. Mismatches -> suggest `$codex-checkpoint` to resync.
- Required sections in every task file body: `## Purpose`, `## Context & Orientation`, `## Plan of Work`, `## Concrete Steps`, `## Validation & Acceptance`, `## Decision Log`, `## Surprises & Discoveries`, `## Outcomes & Retrospective`. Flag missing sections.
- Within `## Context & Orientation`, flag if `### Memory Hints` is missing or empty — that section is the cross-session lifeline.
- Redundant `.gitkeep`: if `.codex/tasks/done/.gitkeep` exists AND `.codex/tasks/done/` contains at least one real `.md` file, flag as Low severity. The `.gitkeep` exists only to track an empty folder; once real archived tasks live there, it is redundant. Mention that `$codex-refactor-memory` will clean it up, or the user can `rm` it manually.

### 6c. Session Handoff Hygiene (`.codex/HANDOFF.md`)

`.codex/HANDOFF.md` is a transient single-slot baton written by `$codex-handoff` and consumed (deleted) by the next `$codex-start`. Absent is the normal state — never warn when it is missing.

- If present, it is an unconsumed baton. Report it informationally. If its frontmatter `created:` is more than 7 days old, flag as Medium — reasoning state rots fast; suggest resuming via `$codex-start` or deleting it.
- Line count must be at most 150 (use `wc -l`). If exceeded, flag as High — the baton is drifting toward a transcript dump; `$codex-handoff`'s distillation rules were not honored.
- Search the active memory index (`AGENTS.md` / `.codex/AGENTS.md`) and `.codex/guidelines/` for any operational auto-load instruction for `.codex/HANDOFF.md`. If found, flag as Critical — the baton is consumed once by `$codex-start`, never auto-loaded into every session.
- Multiple handoff artifacts (`HANDOFF-*.md`, dated copies, a `handoff/` directory under `.codex/`) -> flag as Medium — violates the single-slot contract; suggest consolidating into one `HANDOFF.md` or deleting stale copies.

### 6d. Spec Workspace Health (`.codex/specs/`)

Skip this section if `.codex/specs/` does not exist.

- Confirm `.codex/specs/INDEX.md` exists. If missing, flag as Medium — `$codex-spec` or `$codex-checkpoint` should regenerate it.
- Confirm `.codex/specs/done/` exists. If missing, flag as Low — `$codex-spec` or `$codex-checkpoint` should create it.
- INDEX ↔ folders match (both directions): every active `YYYY-MM-DD-<slug>/` folder directly under `.codex/specs/` with an active status must be listed under `## Active`; every archived `done/YYYY-MM-DD-<slug>/` folder with `status: done` or `status: cancelled` must be listed under `## Done`; every INDEX entry must point to an existing `SPEC.md` (dead -> Low).
- Ignore `.codex/specs/done/` itself when enumerating active spec folders.
- For every active or archived spec folder, confirm the core files exist: `SPEC.md`, `ROADMAP.md`, `NOTES.md`, `LEDGER.md`. Missing -> Medium.
- `NOTES.md` line count ≤ 150 (`wc -l`). Exceeded -> Medium — the working memory is drifting toward a log; distill it and evaluate any durable descriptive candidates under the knowledge capture gate.
- `SPEC.md` frontmatter: required keys `slug`, `status`, `created`, `updated`, `agent`; `status` in {drafting, poc-review, ready, running, blocked, awaiting-final-review, done, cancelled}; folder name must be `created` + `-` + `slug`; `commits` (if present) in {user, per-task, per-phase}.
- For specs at `poc-review` or later: every `artifacts/` path referenced under `## POC Artifacts` must exist on disk. Missing -> Medium (the executor's frozen UI reference is gone).
- ROADMAP disposition consistency: `- [ ] ~~task~~` -> Medium (invalid legacy state; reconcile it to checked + superseded or an explicit blocker before `$codex-spec-run`); a checked + struck row missing `superseded by <task-id or reason>` -> Medium; a blocked row missing either its condition or `unlock:` requirement -> Medium. Do not equate every plain unticked row with runnable work — honor dependency notes. `running` where dependency inspection finds no runnable pending row and at least one blocker -> Medium (the circuit-breaker/status transition was missed); `running` with every row terminal -> Medium (the final gate never ran); `blocked` with no explicit blocked row -> Medium (the diagnosis/unlock state is not durable); `blocked` where dependency inspection finds any independent runnable row -> Medium (the whole-loop transition happened too early); `awaiting-final-review` or `done` with any unticked row -> Medium (the final gate contradicts ROADMAP state). Top-level spec folder with `status: done`/`cancelled` -> Low (resync via `$codex-checkpoint` to archive it under `done/`). Archived spec folder whose status is not `done`/`cancelled` -> Medium (it is shelved in the wrong place). `status: done`/`cancelled` still listed under `## Active` in INDEX -> Low (resync via `$codex-checkpoint`).
- Staleness (mirror the Staleness Thresholds table in `.codex/guidelines/task-management.md`; do not redefine the numbers): `running` stale as `in-progress`; `poc-review` and `awaiting-final-review` stale as `awaiting-review` — surface prominently, these wait on the user's verdict; `drafting` stale as `planning`.
- `LEDGER.md` spot-check via `tail -n 15`: recent entries match the `### YYYY-MM-DD HH:MMZ — <event>` heading format. Do not slurp the whole file.

### 7. Anti-Patterns

- Inlined code blocks longer than about 5 lines inside guideline or agent files. These usually violate the no-stale-snippets rule.
- Stale metadata such as `Last Updated: <date>`.
- Hardcoded shell pattern lists inside agent instructions. Agents should use repository tooling or discover patterns from the codebase.
- Vague Codex skills that do not contain sufficient detail to execute the workflow.
- Agent delegation instructions that override the active harness policy or omit bounded decomposition, ownership, and parent validation.
- Worker agent instructions that allow overlapping writes or omit ownership boundaries.
- Mis-tiered guideline (descriptive, not prescriptive): a `.codex/guidelines/` file whose body states only facts (how a subsystem works, an integration detail, a domain term, a doc pointer) with no behavioral constraint (`MUST`/`NEVER`/`should`/`avoid`/`always`/`never`) -> flag as Low: it likely belongs in `.codex/knowledge/`. Mirror of §5c's descriptive-only check; the boundary runs both ways. Universal guidance like `ai-behavior.md` is exempt.

### 8. Size Sanity

- Count lines in the active memory index. Target is under 100 lines.
- Report approximate tokens using both estimates:
  - `wc -w <active-memory-index> | awk '{printf "~%d tokens\n", $1 * 1.3}'`
  - `wc -c <active-memory-index> | awk '{printf "~%d tokens (byte estimate)\n", $1 / 4}'`
- If bloated, recommend `$codex-refactor-memory`.

### 9. Guideline Tag Index And Overlap

- Build a tag index from guideline frontmatter only, e.g. `grep -h '^tags:' .codex/guidelines/*.md | sort -u`.
- Flag guidelines missing `tags:`, using block-list tags, or using vague/non-domain tags.
- Use overlapping tags as an initial signal for possible duplicate guidelines; read bodies only when tags or paths suggest overlap.

### 10. Agent Overlap

For all files in `.codex/agents/`, compare their `description` and responsibilities.

If two agents share more than 50% of trigger keywords or review scope, flag possible overlap. They may waste tokens or compete for the same work.

## Output Format

```text
# CLAUDART Codex Health Check

## Passing
- [item 1]
- [item 2]

## Warnings
[file:line or section] - [what is wrong] -> [suggested action]

## Errors
[file or section] - [what is broken] -> [suggested action]

## Recommended Next Step
[Single actionable suggestion]
```

If everything passes, output:

```text
CLAUDART Codex installation healthy. <n> guidelines, <n> knowledge entries, <n> agents, <n> skills, <n> specs. Delegation wiring: <ok/warnings>.
```

Reminder: this command is read-only. Never modify files.
