---
name: codex-refactor-memory
description: Consolidate Codex project memory and perform controlled, in-place normalization of knowledge, guidelines, skills, and agent wiring.
---

# Codex Refactor Memory

Refactor the repository-local Codex operating layer without losing project context or curated routing. Use the existing files as live state, make deterministic repairs before semantic ones, and preserve user-authored bodies unless evidence supports an explicit content change.

For a knowledge contract upgrade, use this sequence:

```text
$codex-doctor
$codex-refactor-memory
$codex-doctor
```

The first doctor run establishes a read-only baseline; refactor performs one controlled in-place normalization; the final doctor run verifies the result.

## 1. Preflight

1. Run `git status --short`. Preserve unrelated user changes and stop for direction only when overlapping edits make the refactor unsafe.
2. Resolve the active memory index: installed projects normally use root `AGENTS.md`; the CLAUDART source template may use `.codex/AGENTS.md` as the installer source. If both differ and local evidence does not identify the owner, ask before overwriting either.
3. Inventory `.codex/CONTEXT.md`, `.codex/JOURNAL.md`, guidelines, knowledge, tasks, specs, skills, agents, and recent Git history. Never read `.env` or expose secrets.
4. Read `.codex/guidelines/knowledge-management.md` in full before inspecting or changing knowledge.
5. Require `.codex/scripts/knowledge-check.sh`. If it is missing, report a High-severity installation problem and stop before knowledge writes.
6. Run `bash .codex/scripts/knowledge-check.sh --root .` and retain its pre-change findings. Exit `1` is a finding baseline; exit `2` is a checker usage/runtime failure, so stop before knowledge writes.

## 2. Keep The Memory Tiers Distinct

- `AGENTS.md`: concise entrypoint and routing pointers, preferably under 100 lines.
- `.codex/guidelines/`: durable prescriptive behavior.
- `.codex/knowledge/`: durable descriptive project facts and reference pointers.
- `.codex/CONTEXT.md`: small declarative state true now.
- `.codex/JOURNAL.md`: append-only history, never auto-loaded.
- `.codex/tasks/` and `.codex/specs/`: working plans, proposals, acceptance state, and mission-local discoveries.
- `.codex/HANDOFF.md`: optional single-use conversational baton.
- `.agents/skills/` and `.codex/agents/`: executable workflows and bounded specialist roles.

Route content by meaning before reorganizing files. Do not move WIP or a proposed future state into knowledge. Do not turn a descriptive fact into a guideline merely to keep it always loaded.

## 3. Analyze The Project And Extract Owners

1. Determine the main frameworks, languages, runtime, architectural layers, and repository shape from the active memory index, manifests, build files, source tree, and existing docs.
2. Identify logical ownership boundaries such as contracts/docs, data/repositories, API/controllers, UI/components, jobs, runtime/deploy, and AI/model workflows. For docs-first repositories, identify document layers, templates, workflows, and source-of-truth contracts.
3. Discover linters, formatters, test runners, and validation commands. Delegate style enforcement to those tools instead of copying their rules into `AGENTS.md`.
4. Inspect the active `AGENTS.md`, deprecated memory files, current guidelines, and stable decisions in CONTEXT. Split candidates by type before moving them: behavior → guideline; fact → knowledge; WIP/proposal → task/spec/CONTEXT.
5. Ensure `.codex/guidelines/` exists, then extract detailed behavior into the smallest set of domain guidelines with clear ownership and useful `paths:`. Do not create files for symmetry or force a weak concept into an unrelated owner. Use `.codex/guidelines/*.md` for semantic guidance; never place it in `.codex/rules/`, whose optional `*.rules` files are reserved for Codex permission or environment rules.
6. Keep each rule verifiable, scoped, loophole-closed, and unambiguous about critical constraints. Use stable file/symbol references rather than long code snippets or fragile line excerpts.
7. Never write secrets, tokens, keys, production credentials, or real `.env` values into any memory tier.

## 4. Refactor AGENTS And Guidelines

1. Trim the active `AGENTS.md` to project identity, selective context loading, core workflows, security/repository-wide constraints, and pointers. Never require reading every guideline blindly. Keep it under 100 lines where practical; if it still exceeds 150 lines, flag that explicitly in the final report.
2. Reconcile stale references to deprecated or duplicate memory files. Follow the repository convention for byte-identical duplicates; ask before removing a divergent file or choosing a winner.
3. Keep the four compact knowledge invariants in `AGENTS.md` and the full contract in `knowledge-management.md`.
4. Ensure every relevant guideline has `paths:`, `description:`, `when_to_use:`, and `tags:` frontmatter and a clear owner. Keep flow-style `paths`/`tags`.
5. Verify concrete guideline claims against repository sources. Classify mismatches as guideline-stale, source-debt, open-work, or needs-user-decision; do not weaken a desired invariant merely because source currently violates it.
6. Detect kitchen-sink files, near-duplicates, stale temporary wording, and repeated facts. Keep a rule in its most specific owner and replace copies with pointers; merge, split, or remove semantic owners only with clear evidence and user confirmation.
7. Promote stable behavioral decisions from CONTEXT to the correct guideline through checkpoint semantics. Leave temporary decisions in CONTEXT. Route purely descriptive guideline content to the knowledge workflow only after the capture gate passes and ask before removing the original guideline.
8. Cross-link `.codex/CONTEXT.md`, the universal behavior guideline, every globally relevant workflow guideline, and the knowledge root router from `AGENTS.md`. Never auto-load JOURNAL, HANDOFF, task bodies, or knowledge details.
9. Ensure `ai-behavior.md` exists without overwriting user customizations. Follow the active harness policy for delegation; keep decomposition, disjoint ownership, non-overlap, parent validation, and durable result recording in `agent-delegation.md` instead of inventing a conflicting permission rule.
10. Ensure `## Agent Self-Evolution & Context Maintenance` remains in `AGENTS.md`: project-wide behavior updates its owner guideline, new guideline owners get indexed, eligible descriptive facts use the knowledge contract, global Codex behavior updates `AGENTS.md`, and live state uses checkpoint.

Semantic audit results must identify guidelines changed, stale rules fixed, source debt left in code/docs, split/merge actions, and decisions still requiring the user.

## 5. Normalize Knowledge In Place

Read every topic frontmatter, the root router, domain maps, and route targets. Use the canonical grammar and mutation rules from `knowledge-management.md`; do not restate or improvise a second schema.

For each topic:

1. Identify its existing canonical owner and evidence. Preserve the body, title, curated hook, grouping, ordering, and deliberate external routes.
2. Normalize frontmatter once using only supported fields and formats. Do not invent aliases, triggers, scope, sources, relations, verification dates, or lifecycle claims.
3. Set `status: active` only when current evidence was actually checked. Record `last_verified` as the evidence-check date and ensure active topics have `sources` or `verify`.
4. If evidence is insufficient or conflicting, use `status: review-needed` with a precise `status_note`; do not present uncertainty as active truth.
5. Use `superseded` or `retired` only with clear repository evidence or user confirmation. Never infer lifecycle from age or absence from the map.
6. Update the topic and its reachable root/domain-map route atomically. Route lines have no dates.

Store-wide rules:

- A small store may remain root → topic. When active topics exceed 24 or the root exceeds 1,200 visible words, introduce `_maps/<domain>.md` from existing scope/grouping evidence while preserving curated and external routes; if ownership cannot be grouped safely, report the decision instead of guessing.
- Domain maps route only to topics and never nest.
- A topic over 10 KiB is a split candidate. Preserve it and report a reviewed split proposal; do not rewrite or split its body automatically.
- Report an ambiguous unindexed file with evidence. Never auto-promote, auto-delete, retire, or supersede it.
- Do not regenerate the root or maps from frontmatter alone; hooks, grouping, ordering, and external routes carry human routing intent.
- Do not add a recall command, write-on-read behavior, telemetry, database, or daemon.

After the normalization batch, run `bash .codex/scripts/knowledge-check.sh --root . --fail-on warning`. Fix only supported mechanical failures; exit `2` blocks completion. Then repeat the normalization scan without changing inputs: it must produce no further diff. If a second pass would churn formatting or metadata, the refactor is not idempotent; stop and report the cause.

## 6. Preserve Live Workflow State

- Create concise CONTEXT and JOURNAL scaffolds when missing. Rewrite `.codex/CONTEXT.md` only through checkpoint semantics, keep it under 150 lines, and ensure `AGENTS.md` references it.
- Never rewrite or prune JOURNAL; use tail and targeted `rg`, and remove any instruction that auto-loads it.
- If task/spec directories are missing while their skills exist, create only their canonical seed indexes and archive placeholders. Do not rewrite, move, close, or change task/spec bodies; their owning workflows manage state and archives.
- Remove an archive `.gitkeep` only when a real archived Markdown file already makes it redundant, and report the removal.
- Do not store subagent ids or transient thread state in durable memory.
- Treat an empty knowledge tier as valid. Do not populate it merely to make refactor appear productive.

## 7. Audit Skills And Agents

- Validate every `SKILL.md` frontmatter and confirm the workflow remains executable with its referenced guidelines and one-hop resources. Repair stale references and generated markers without making skills duplicate canonical guideline contracts.
- Keep skills concise and load detailed contracts from their canonical guideline instead of copying them.
- For every `.codex/agents/*.toml`, require `name`, `description`, `model`, `model_reasoning_effort`, `sandbox_mode`, and `developer_instructions`. Keep reviewers/explorers read-only unless the agent is explicitly a worker.
- Confirm worker agents define ownership boundaries and say they must not revert edits made by others in parallel. Replace hardcoded grep lists with repository discovery and project tooling. If two agents' responsibilities overlap by more than 50%, propose a merge but do not perform it without user confirmation.
- Parent review remains required for delegated results.
- Apply safe wiring and frontmatter fixes. Ask before merges, deletions, or meaning-changing rewrites.

## 8. Base Template Handling

When the repository is a distributable template:

- Treat `.codex/` and `.agents/` as generic payload, not live maintainer state.
- Preserve the documented relationship between `.codex/AGENTS.md` and the downstream root `AGENTS.md`.
- Do not add generated-marker comments, project-specific frameworks, private paths, or downstream names to the payload.
- Do not assume adopters share this repository's languages, tooling, docs, tasks, specs, or knowledge.

## 9. Verify And Report

Before completion:

1. Run the knowledge checker after the final knowledge mutation and report its result.
2. Confirm every active topic is reachable exactly once; every review-needed topic is either unindexed or reachable at most once; every map is one hop; and curated/external routes remain.
3. Confirm a repeated normalization pass creates no changes.
4. Confirm `AGENTS.md` line count and links; verify live state and guideline targets exist and that JOURNAL, HANDOFF, task bodies, and knowledge details are not auto-loaded.
5. Confirm guideline globs match intended files, frontmatter is valid, semantic findings use the required classifications, and `agent-delegation.md` is wired when agents exist.
6. Confirm task/spec seed shape and archive placeholders without altering their live documents.
7. Run the available skill validator for every skill changed by this refactor.
8. Confirm `.codex/config.toml` retains a conservative positive concurrency cap unless a higher value is explicitly documented.
9. Run `git diff --stat`, `git diff --check`, `git status --short`, line/token estimates for the active memory index and CONTEXT, and relevant repository formatters.

Summarize files created/changed, cross-tier moves, final `AGENTS.md` size, checker results before/after, semantic findings and source debt, skills/agents audited, candidates left `review-needed`, ambiguous unindexed files preserved, removed placeholders/deprecated files, validation run, and decisions still needed. Suggest reviewing the full diff. Do not commit, push, merge, rebase, tag, or trigger CI/CD without explicit user permission.
