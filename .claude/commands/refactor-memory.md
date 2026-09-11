---
description: Consolidate Claude memory and perform one idempotent in-place normalization of knowledge topics and maps
---

Analyze the existing Claude memory layer in this repository and refactor it into a coherent Claude-native Modular Rules System.

The target shape is:

- a concise `.claude/CLAUDE.md` as the Claude instruction index and entrypoint;
- durable prescriptive behavior in scoped files under `.claude/rules/`;
- durable descriptive facts under `.claude/knowledge/`;
- current live state in `.claude/CONTEXT.md`;
- append-only history in `.claude/JOURNAL.md`;
- self-contained skills in `.agents/skills/` or `.claude/commands/`;
- optional specialized agents in `.claude/agents/`, with write access only for roles whose declared purpose explicitly requires implementation.

> **Pre-flight checks**: confirm `git status --short` is clean or that the user understands there is in-progress work before you begin. Refuse to proceed if unrelated uncommitted changes could be swallowed by the refactor. Confirm `.claude/scripts/knowledge-check.sh` exists, then run `bash .claude/scripts/knowledge-check.sh` and retain its complete output as the mechanical baseline. Exit `1` is the finding baseline. Exit `2` is a checker usage/runtime failure and blocks all knowledge mutation. A missing checker is also a blocker.

Execute the following steps systematically, without losing essential project context.

## 1. Resolve The Memory Shape

- Confirm whether the canonical memory file is root `CLAUDE.md` or `.claude/CLAUDE.md`.
- If both root `CLAUDE.md` and `.claude/CLAUDE.md` exist, compare them.
  - If they are identical, remove or ignore the duplicate according to the repository convention.
  - If they differ, ask which file should win before overwriting either one. Typically `.claude/CLAUDE.md` is canonical for CLAUDART projects; root `CLAUDE.md` is what `/init` generates.
- Search skills, agents, and rules for references to deleted or deprecated memory files and update them during the refactor.

## 2. Analyze The Project

- Determine the main framework, language, runtime, and architectural layers from `.claude/CLAUDE.md`, project structure, package manifests, build files, and existing docs.
- Identify the core logical layers, such as docs/contracts, database/repositories, API/controllers, UI/components, background jobs, runtime/deploy, or AI/model workflows.
- Note linters, formatters, test runners, and validation commands detected. Delegate style rules to those tools instead of encoding them into `.claude/CLAUDE.md`.
- For docs-first repositories, identify document layers, templates, workflows, and source-of-truth contracts.

## 3. Ensure The Rules Directory Exists

Create `.claude/rules/` if it does not already exist.

Use `.claude/rules/*.md` for durable semantic guidance with YAML frontmatter.

## 4. Extract Domain-Specific Rules

Group detailed coding rules, boundaries, and validation requirements from `.claude/CLAUDE.md`, deprecated memory files, and repeated workflow decisions into a small set of logical rule files under `.claude/rules/`.

**Route by type first.** Split the candidate content: **prescriptive** material (an enforceable `MUST`/`NEVER`/should-avoid invariant — how to behave) becomes a rule; **descriptive** material (how a subsystem works, an integration detail, a domain term, a pointer to a doc — a fact) goes to `.claude/knowledge/` instead (Step 10), never a rule. Do not file a fact as a rule and rely on Step 5 to re-route it later.

Common examples:

- `architecture.md`
- `api.md`
- `db.md`
- `ui.md`
- `runtime.md`
- `testing.md`

Do not create rule files just to create files. A small docs repo may only need one or two rules.

Required for each rule file:

- YAML frontmatter with `paths:`, `description:`, `when_to_use:`, and `tags:`.
- `paths:` must be a glob or list of globs scoped to the files the rule governs.
- `paths:` must use YAML flow sequence style, e.g. `paths: ["src/**/*.ts", "test/**/*.ts"]`. Never use block-list style (`paths:` followed by `- item`).
- `description:` must say what domain the rule controls.
- `when_to_use:` must say when future agents should consult the rule.
- `tags:` must be an inline YAML array on one line, e.g. `tags: [architecture, nestjs, boundaries]`. Never use block-list style (`tags:` followed by `- item`) because tag indexing depends on single-line frontmatter.
- `tags:` must contain 1-5 lowercase kebab-case values that describe the rule domain or scope.
- No long code snippets. Prefer `file:line` references and behavior-level rules so context does not go stale.
- No secrets, tokens, private keys, production credentials, or real `.env` values.

Rule Quality Checklist:

1. Verifiable: a reader can check whether the rule was followed by reading the repo.
2. Loophole-closed: if a rule has an obvious bypass, add `NEVER do X, even when Y seems like a good reason`.
3. Critical-tagged: prefix high-priority constraints with `NEVER`, `YOU MUST`, `IMPORTANT`, or similar unambiguous language.
4. Scoped: the rule belongs in the named file and does not duplicate unrelated guidance elsewhere.

## 5. Audit Domain Rule Semantics

Do not stop at frontmatter, link, and glob hygiene. A successful memory refactor must also check whether the domain-specific rule content still reflects the repository's current behavior.

For every non-universal rule under `.claude/rules/`:

1. Read the rule body and identify concrete claims.
   - Claims include named files, modules, classes, functions, commands, config keys, environment variables, endpoints, schemas, database models, event names, message/queue topics, feature flags, UI routes, document contracts, or operational workflows.
   - Ignore purely stylistic rules unless they contradict the codebase's current conventions.
2. Verify each concrete claim against the actual repository.
   - Use repository-native source files, package manifests, schemas, database change history, generated types, tests, docs/contracts, and config loaders as evidence.
   - Prefer structured files and source-of-truth contracts over comments or stale prose.
   - Use `rg` / `rg --files` first; use language/framework tooling only when it materially improves confidence.
3. Classify each finding:
   - **accurate**: rule matches source and remains useful.
   - **rule-stale**: source/contract has intentionally moved on; update the rule.
   - **source-debt**: rule is still the desired invariant, but source currently violates it; keep the rule and report the code/doc debt instead of weakening it.
   - **open-work**: a task, issue, TODO, or explicit user decision already tracks the gap; keep or update the rule so future agents see the intended direction and the active gap.
   - **needs-user-decision**: source and rule disagree and neither clearly wins from local evidence; ask before rewriting either.
4. Detect overbroad or kitchen-sink rules.
   - If one rule mixes unrelated domains, propose splitting it into focused files.
   - Split only when the new files have clear `paths:` scopes and durable ownership. Do not create files just to satisfy symmetry.
   - Preserve generic cross-cutting rules in broad files; move business/domain invariants into focused files.
5. Detect near-duplicates and stale detail.
   - If two rules repeat the same invariant, keep the rule in the most specific owner and replace the other copy with a pointer.
   - Replace fragile line-number references and long source excerpts with stable symbol/file references where possible.
   - Remove "future" or "temporary" wording once the feature is implemented, unless it still describes a real future state.
6. Promote stable live-state decisions.
   - Read `.claude/CONTEXT.md` for Recent Decisions. If a decision is now durable project behavior, move it into the relevant rule and remove it from CONTEXT through the checkpoint workflow.
   - If a decision is still temporary, keep it in CONTEXT and do not bury it in rules.
7. Detect mis-tiered content (a rule that belongs in knowledge).
   - `.claude/rules/` is **prescriptive** — each rule constrains behavior (an enforceable `MUST`/`NEVER`/should-avoid invariant). If a rule body is purely **descriptive** — it only states how a subsystem works, an integration detail, a domain term, or a doc pointer, with no constraint a reader could "follow" — it is misfiled.
   - Propose moving it to `.claude/knowledge/`: create or update the topic file + its `INDEX.md` entry, then remove the rule and its `@`-import from `.claude/CLAUDE.md`. Confirm with the user before removing a rule.
   - This is the exact reverse of the Step 10 boundary (which pushes prescriptive content out of knowledge into rules). The descriptive/prescriptive boundary runs **both ways**.

Semantic audit output must list:

- rules updated automatically;
- stale rules fixed;
- source-debt items intentionally left as code/doc follow-up;
- split/merge actions performed;
- split/merge actions that still need user confirmation;
- rules proposed for reclassification into `.claude/knowledge/` (descriptive content misfiled as behavior).

## 6. Refactor .claude/CLAUDE.md

Trim `.claude/CLAUDE.md` so it stays a concise memory index, not a knowledge dump.

It should contain only:

- project identity and overview;
- core CLI commands and skill selection;
- a project map or pointers to primary docs;
- security and repository-wide constraints;
- a `## Domain Rules` section linking `.claude/CONTEXT.md` and `.claude/rules/*.md`;
- a clear rule that `.claude/JOURNAL.md` is not auto-loaded;
- the `## Agent Self-Evolution & Context Maintenance` section.

Target: keep `.claude/CLAUDE.md` under 100 lines where practical. If it exceeds 100 lines, extract more into `.claude/rules/`, workflows, or project docs. If it exceeds 150 lines, flag it in the final summary.

**CRITICAL**: PURGE all domain-specific logic AND style/formatting rules — delegate styling to standard tools (Prettier, ESLint, Ruff, gofmt). Do not duplicate info already in `package.json` or `README.md`. Less is more. Descriptive project facts you pull out of `.claude/CLAUDE.md` belong in `.claude/knowledge/` (Step 10), not `.claude/rules/`.

## 7. Cross-Link Rules

Under a `## Domain Rules` heading in `.claude/CLAUDE.md`, add `@` imports for every rule file plus the live-state context file.

Example:

```markdown
See @.claude/CONTEXT.md for current session state, updated by `/checkpoint`.
See @.claude/rules/ai-behavior.md for universal AI behavior guidelines.
See @.claude/rules/architecture.md for architecture boundaries.
```

**NEVER add `@.claude/JOURNAL.md`** as a loaded context reference. JOURNAL is intentionally excluded from session context to save tokens. If you find such an import or auto-load instruction in `.claude/CLAUDE.md` or `.claude/rules/`, remove it and warn the user in the final summary.

For the knowledge tier, add a **plain pointer line** (not an `@` import), e.g. `Project knowledge: see .claude/knowledge/INDEX.md (surfaced by /start; route entries on demand).` `/start` reads only the root router; later workflows may route bounded detail under `knowledge-management.md`. Knowledge files are never auto-imported.

## 8. Wire Up AI Behavior Guidelines

`ai-behavior.md` is the universal behavior guideline for Claude work.

- If `.claude/rules/ai-behavior.md` does not exist, create a concise version with complete frontmatter and durable behavior rules.
- If the user has customized `ai-behavior.md`, leave their content alone and only ensure the reference exists.
- Do not inline `ai-behavior.md` into `.claude/CLAUDE.md`.
- Add a single reference under `## Domain Rules`.

## 9. Audit Rules, Skills, And Agents

Report proposed audit changes in a clear list before applying risky changes. Apply safe fixes such as missing references, stale deleted-file references, frontmatter corrections, missing `@.claude/CONTEXT.md` references, and JOURNAL `@` import removal. Ask before merging or deleting agents, rules, or skills.

For every file in `.claude/rules/`:

- Verify YAML frontmatter exists with valid `paths:`, `description:`, `when_to_use:`, and `tags:`.
- Flag block-list `paths:`; rules must use flow-style `paths: ["glob-a", "glob-b"]`.
- Flag block-list `tags:`; rules must use inline `tags: [tag-a, tag-b]` style.
- Run a glob check on each `paths:` entry. `paths: ["**/*"]` is valid for universal rules.
- If a glob matches zero files, flag the rule as potentially dead and ask whether to remove or rescope it.
- Replace long inlined code with `file:line` references.
- Apply the Rule Quality Checklist.
- Apply the semantic audit from Step 5 before declaring a rule healthy.
- Use tag overlap as an initial signal for near-duplicates; read bodies only when tags or paths suggest overlap. Merge near-duplicates only after user confirmation.

For every file in `.agents/skills/*/SKILL.md` and `.claude/commands/*.md`:

- Verify the file starts with YAML frontmatter.
- Confirm `name:` (for SKILL.md) and `description:` are present.
- Confirm the skill contains sufficient procedure and routing detail to execute the workflow. Shared canonical contracts may be referenced one hop instead of copied; resolve and validate every required reference.
- Keep skills complete and actionable without duplicating canonical rules. A future Claude session should know exactly what to do, which contract to read, and which files it may update.
- Remove stale generated-marker comments or references to deleted memory files.

For every file in `.claude/agents/`:

- Verify YAML frontmatter has `name`, `description` (with `PROACTIVELY` if it should auto-trigger), `tools`, and `model`.
- Keep explorers and review-only/audit-only agents read-only. Allow `Edit` only when the declared purpose explicitly requires implementation, as with a refiner or worker.
- Confirm every write-capable agent defines ownership boundaries, protects unrelated user work, validates its changes, and says it must not revert edits made by others in parallel.
- Replace hardcoded grep pattern lists with guidance to scan the codebase and use project tooling when present.
- Confirm the agent's responsibilities do not overlap more than 50% with another agent. If they do, propose a merge.

## 10. Maintain CONTEXT And JOURNAL

For `.claude/CONTEXT.md`:

- Confirm it exists. If not, create a concise template.
- Verify line count is at most 150. If exceeded, flag for user review and propose trimming or graduating long-lived items into `.claude/rules/`.
- Confirm `@.claude/CONTEXT.md` is imported in `.claude/CLAUDE.md`. If missing, add it.
- Ensure it describes current state only.

For `.claude/JOURNAL.md`:

- Confirm it exists. If not, create a concise append-only template.
- Search `.claude/CLAUDE.md` and `.claude/rules/` for instructions that auto-load `.claude/JOURNAL.md`. If found, remove them and warn the user.
- Do not full-read JOURNAL by default. Use `tail` and targeted `rg` searches for pattern analysis.
- Do not prune or rewrite JOURNAL entries. The file is append-only by contract.

For `.claude/tasks/`:

- If the folder does not exist but `/plan` is documented in `.claude/commands/`, create only the canonical seed `index.md` and `done/.gitkeep`.
- Inventory only `.claude/tasks/*/TASK.md` and `.claude/tasks/done/*/TASK.md` at the depths defined in `.claude/rules/task-management.md`. Do not recursively read attachments or follow workspace/`TASK.md` symlinks.
- If `.claude/tasks/done/.gitkeep` exists beside a real archived `<task-id>/TASK.md`, remove only that redundant placeholder and report the removal.
- Preserve task workspaces and their supporting files. Do not modify, move, close, or normalize `TASK.md` or attachments; `/plan` and `/checkpoint` own task state and archival. Do not create `artifacts/`, extract archives, rewrite evidence, migrate flat tasks, or treat missing optional files as repair targets.

For `.claude/specs/`:

- If the folder does not exist but `/spec` is documented in `.claude/commands/`, create it with a seed `INDEX.md` (canonical header plus empty `## Active` and `## Done` sections) and a `done/.gitkeep`.
- If `.claude/specs/` exists but `.claude/specs/done/` is missing, create `.claude/specs/done/.gitkeep`.
- Do not modify or move any spec folder content. Spec folders are mission documents owned by `/spec`, `/spec-run`, and `/checkpoint`; refactor-memory only touches the archive placeholder and (if missing) the seed `INDEX.md`.

For `.claude/knowledge/`:

- Read `.claude/rules/knowledge-management.md`; it is the semantic source of truth. If the folder or root router is missing, create the lean canonical scaffold.
- Perform **one in-place normalization pass** over every topic and `_maps/*.md`, including unindexed files. Preserve every body verbatim and preserve curated root/map titles, hooks, grouping, ordering, and external routes.
- Normalize frontmatter and routes to the rule's current grammar without inventing aliases, triggers, scope, relations, evidence, or lifecycle. `updated` changes only where this pass edits content; `last_verified` changes only after an actual evidence check.
- Verify concrete claims against current sources/repository evidence. For a current canonical claim with sufficient evidence, set `status: active`, set `last_verified` to the verification date, and retain at least one `sources` or `verify` anchor. With insufficient or conflicting evidence, set `status: review-needed` and add a concise `status_note`; do not fabricate certainty. Preserve an explicitly evidenced `superseded` or `retired` lifecycle and its explanation.
- Patch an existing owner before creating a topic. On an empty tier, create only a small grounded set whose claims pass every capture gate; otherwise leave the tier empty. Never convert WIP, proposals, task/spec state, or unsupported inference into knowledge.
- Reconcile each already-reachable topic with its root or domain-map route atomically. Preserve ambiguous unindexed files as unindexed: normalize the file itself where safe, report it for review, and neither promote nor remove it.
- When active topics exceed 24 or the root exceeds 1,200 visible words, create `_maps/<domain>.md` routes with root → map → topic only, using existing scope/grouping evidence while preserving curated and external routes. If ownership cannot be grouped safely, preserve the direct routes and report the decision instead of guessing. Never nest maps. A topic over 10 KiB is a reported split candidate; do not split it automatically.
- Detect overlap and lifecycle tension, but never auto-merge, auto-retire, auto-supersede, delete, or rewrite bodies without unambiguous evidence and the required user decision.
- Do not add a recall command, write-on-read behavior, telemetry, database, or daemon.
- Make the result idempotent: running `/refactor-memory` again against unchanged sources must produce no knowledge diff.
- After all mutations, run `bash .claude/scripts/knowledge-check.sh --fail-on warning`. Exit `1` means findings remain and normalization cannot be claimed complete; exit `2` is a checker failure and blocks completion.

## 11. Base Template Notes

If this repository is a base template whose `.claude/` and `.agents/` directories are installed into other projects:

- Do not add generated-marker comments to base template files.
- Keep template language generic and avoid project-specific names unless the template is intentionally branded.
- If an installer copies `.claude/CLAUDE.md` to a downstream project, document that relationship clearly and keep both files synchronized.
- Do not assume a downstream project has the same languages, frameworks, docs, or tests as the template repository.

## 12. Append Agent Self-Evolution Section

At the end of `.claude/CLAUDE.md`, ensure `## Agent Self-Evolution & Context Maintenance` exists.

Include these rules:

- "Do not assume a human will document your code patterns. If you build it, document it."
- Existing rules change → update the relevant file in `.claude/rules/`.
- New domains/layers → CREATE a new rule file in `.claude/rules/` (with flow-style `paths: [...]`, `description:`, `when_to_use:`, and inline `tags: [...]` frontmatter) AND APPEND its `@` import to `.claude/CLAUDE.md`'s Domain Rules section.
- Durable descriptive facts that pass `.claude/rules/knowledge-management.md` → patch the canonical owner and reachable map atomically, then run the checker. Scope may be local; task/spec state stays local.
- Global changes → update `.claude/CLAUDE.md` directly.
- Shared live state → update `.claude/CONTEXT.md` through `/checkpoint`, not through refactor-memory.

## 13. Verification

Before the final summary, run or perform:

- `git diff --stat`
- `git status --short`
- `wc -l .claude/CLAUDE.md .claude/CONTEXT.md`
- Search for stale references to deleted memory files.
- Search `.claude/CLAUDE.md` and `.claude/rules/` for JOURNAL auto-load instructions.
- Confirm every rule listed in `.claude/CLAUDE.md` exists on disk.
- Confirm `.claude/knowledge/INDEX.md` exists and is referenced by a plain (non-`@`) pointer in `.claude/CLAUDE.md`; ambiguous unindexed files remain reported rather than silently routed.
- Run `bash .claude/scripts/knowledge-check.sh --fail-on warning` as the post-check even when the pre-check passed; record both outcomes and block completion on exit `2`.
- Confirm the in-place knowledge normalization is idempotent and every `active` entry has `last_verified` plus `sources` or `verify`.
- Confirm semantic rule findings were classified as accurate, rule-stale, source-debt, open-work, or needs-user-decision.

Do not run `git commit`, `git push`, `git merge`, `git rebase`, or similar history/remote-writing commands yourself.

## 14. Final Summary

Output a concise summary covering:

1. Rule files and `.claude/knowledge/` entries created, updated, or reclassified between tiers, including the in-place normalization result.
2. `.claude/CLAUDE.md` changes and final line count.
3. Audit findings from Step 9, separated into auto-fixed and needs user decision.
4. Semantic drift findings from Step 5, including source-debt items not fixed in memory.
5. Deprecated memory files removed or retained.
6. Verification commands/checks run.
7. Remaining risks or user decisions.
8. Suggest the user run `git diff` to review every change before committing.

Confirm completion only after every relevant step has been completed or explicitly marked not applicable.

For an existing installation, preserve the upgrade sequence: `/doctor` → `/refactor-memory` → `/doctor`.
