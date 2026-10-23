---
description: Consolidate Claude memory and perform one idempotent in-place normalization of knowledge topics and maps
---

Refactor the Claude memory layer in this repository into a coherent modular rules system without losing project context or curated routing. For an existing installation, run `/cda-doctor` → `/cda-refactor-memory` → `/cda-doctor`.

The target shape is:

- a concise `CLAUDE.md` as the Claude instruction index and entrypoint;
- durable prescriptive behavior in scoped files under `.claude/rules/`;
- eligible durable descriptive facts without another owner under `.claudart/knowledge/`, with compact routes or minimal unique agent context for externally owned facts;
- the bounded working agreement with the project owner in `.claudart/OWNER.md`;
- current live state in `.claudart/CONTEXT.md`;
- append-only history in `.claudart/JOURNAL.md`;
- self-contained skills in `.agents/skills/` or `.claude/commands/`;
- optional specialized agents in `.claude/agents/`, with write access only for roles whose declared purpose explicitly requires implementation.

## 1. Preflight

1. Run `git status --short`. Do not proceed if unrelated uncommitted changes could be swallowed by the refactor, unless the user confirms they understand the in-progress work.
2. Treat `CLAUDE.md` as the canonical loader. Find references to deleted or deprecated memory files in skills, agents, and rules, and update them during the refactor.
3. Confirm `.claude/scripts/knowledge-check.sh` exists, then run `bash .claude/scripts/knowledge-check.sh` and keep its complete output as the mechanical baseline. Exit `1` is the finding baseline. Exit `2` is a checker usage/runtime failure and blocks all knowledge mutation, as does a missing checker.

## 2. Analyze The Project And Extract Rules

1. Determine the main framework, language, runtime, architectural layers, and logical ownership boundaries from `CLAUDE.md`, the project structure, manifests, build files, and existing docs. For docs-first repositories, identify document layers, templates, workflows, and source-of-truth contracts.
2. Note linters, formatters, test runners, and validation commands, and delegate style rules to those tools instead of encoding them in `CLAUDE.md`.
3. Split candidate content from `CLAUDE.md`, deprecated memory files, and repeated workflow decisions by type and owner before moving it: prescriptive material becomes a rule, except guidance about working with the project owner, which goes to `.claudart/OWNER.md`; an eligible descriptive fact goes to its current authoritative source, or to `.claudart/knowledge/` (Step 9) when no other source owns it. Do not file a fact as a rule and rely on Step 3 to re-route it.
4. Create `.claude/rules/` if needed and group the prescriptive material into the smallest set of focused rule files (for example `architecture.md`, `api.md`, `testing.md`). A small docs repo may need only one or two.
5. Each rule file has YAML frontmatter with `paths:` (a YAML flow sequence of globs scoped to the files it governs, e.g. `paths: ["src/**/*.ts"]`), `description:` (the domain it controls), `when_to_use:` (when to consult it), and `tags:` (a one-line inline array of 1-5 lowercase kebab-case values, e.g. `tags: [architecture, boundaries]`; tag indexing depends on single-line frontmatter). Block-list `paths:` or `tags:` are invalid.
6. Keep each rule verifiable from the repository, loophole-closed, scoped to its file, and stated once in plain words without capitalized emphasis. Use `file:line` or symbol references instead of long code snippets. Never write secrets, tokens, private keys, production credentials, or real `.env` values.

## 3. Audit Domain Rule Semantics

Check that each non-universal rule still reflects the repository, not only its frontmatter, links and globs.

1. Verify every concrete claim (named files, symbols, commands, config keys, endpoints, schemas, events, feature flags, routes, document contracts, workflows) against repository-native sources, preferring structured files and source-of-truth contracts over comments. Use `rg` first; use language tooling only when it materially improves confidence.
2. Classify each finding:
   - accurate: the rule matches source and remains useful;
   - rule-stale: the source intentionally moved on; update the rule;
   - source-debt: the rule is still the desired invariant but source violates it; keep the rule and report the debt instead of weakening it;
   - open-work: a task, issue, TODO, or user decision already tracks the gap; keep the rule so it shows the intended direction and the active gap;
   - needs-user-decision: source and rule disagree and neither clearly wins; ask before rewriting either.
3. Propose splitting a rule that mixes unrelated domains, only into files with clear `paths:` scopes and durable ownership. Keep a repeated invariant in its most specific owner and replace the copy with a pointer. Replace fragile line references and long excerpts with stable references, and remove "future" or "temporary" wording once it no longer describes a real future state.
4. Move a Recent Decision from CONTEXT that is now durable behavior into its rule and remove it from CONTEXT through the checkpoint workflow; leave temporary decisions in CONTEXT.
5. A rule body that only describes how something works, with no constraint to follow, is misfiled. Propose moving it to its fact owner or `.claudart/knowledge/` with its route, then removing the rule and its `CLAUDE.md` import; confirm with the user before removing a rule.

Report rules updated, stale rules fixed, source debt left as follow-up, split/merge actions performed or awaiting confirmation, and rules proposed for reclassification.

## 4. Refactor CLAUDE.md

Keep `CLAUDE.md` a concise index containing only: project identity and overview; core commands and skill selection; a project map or pointers to primary docs; security and repository-wide constraints; a `## Domain Rules` section linking `.claudart/OWNER.md`, `.claudart/CONTEXT.md`, and `.claude/rules/*.md`; a rule that `.claudart/JOURNAL.md` is not auto-loaded; and the `## Agent Self-Evolution & Context Maintenance` section.

Keep it under 100 lines where practical by moving content into rules, workflows, or project docs, and flag it in the final summary if it exceeds 150. Remove domain-specific logic and style or formatting rules, which belong to formatters and linters, and do not duplicate `package.json` or `README.md`. Route descriptive facts to their authoritative owner, or to `.claudart/knowledge/` when none exists, never to `.claude/rules/`.

## 5. Cross-Link Rules

- Under `## Domain Rules`, keep a compact universal baseline and add conditional routes for domain and workflow guidance. Do not turn every rule into an automatic import or broaden its native `paths` to make it globally visible.
- Resolve imports relative to the file containing them, including nested imports.
- Never add automatic JOURNAL, HANDOFF, task-body, spec-body, or knowledge-body imports. Inspect resolved targets rather than matching one literal path spelling; remove actual prohibited auto-load edges, such as an instruction that auto-loads JOURNAL from `CLAUDE.md` or `.claude/rules/`, and warn the user. Plain conditional paths and quoted examples are valid.
- Keep a plain root-router pointer, such as `.claudart/knowledge/INDEX.md (surfaced by /cda-start; route entries on demand)`. Route retrieval to `knowledge-management.md` and knowledge mutations, audits and refactors to `.claude/references/knowledge-maintenance.md`. Verify the support files exist and preserve project-specific routing.
- Preserve `.claudart/` as the single shared state authority and the host's actual tools. Changing runtime does not select another store or alter scope, approval or review gates; current instructions stay authoritative over saved state.

## 6. Wire Up AI Behavior Guidelines

`.claude/rules/ai-behavior.md` is the universal behavior rule. Create a concise version with complete frontmatter if it is missing, leave a user-customized version alone, and reference it once under `## Domain Rules` without inlining it into `CLAUDE.md`.

## 7. Audit Rules, Skills, And Agents

List proposed changes before applying risky ones. Apply safe fixes such as missing references, stale deleted-file references, frontmatter corrections, missing conditional CONTEXT routes, and JOURNAL `@` import removal. Ask before merging or deleting agents, rules, or skills.

For every file in `.claude/rules/`:

- Validate frontmatter against Step 2 and flag block-list `paths:` or `tags:`.
- Glob-check each `paths:` entry; `paths: ["**/*"]` is valid for universal rules. If a glob matches zero files, check whether it intentionally targets a future task/spec workspace or optional feature and remains explicitly routed. Do not rescope an empty seed globally; report only genuinely unreachable or stale guidance.
- Apply the Step 2 quality bar and the Step 3 semantic audit before declaring a rule healthy.
- Use tag overlap as the first signal for near-duplicates and read bodies only when tags or paths suggest overlap. Merge only after user confirmation.

For every file in `.agents/skills/*/SKILL.md` and `.claude/commands/*.md`:

- Verify YAML frontmatter with `description:`, plus `name:` for SKILL.md.
- Confirm the workflow is executable and tells a future session which contract to read and which files it may update. Shared canonical contracts may be referenced one hop instead of copied; resolve and validate every required reference.
- Remove stale generated-marker comments and references to deleted memory files.

For every file in `.claude/agents/`:

- Verify frontmatter has `name`, `description` (with `PROACTIVELY` if it should auto-trigger), `tools`, and `model`.
- Keep explorers and review-only or audit-only agents read-only. Allow `Edit` only when the declared purpose explicitly requires implementation, as with a refiner or worker.
- Confirm every write-capable agent defines ownership boundaries, protects unrelated user work, validates its changes, and says it must not revert edits made by others in parallel.
- Replace hardcoded grep pattern lists with guidance to scan the codebase and use project tooling.
- If two agents' responsibilities overlap by more than 50%, propose a merge.

## 8. Preserve Live Workflow State

- Create a concise `.claudart/CONTEXT.md` template if it is missing. Keep it current-state only and at most 150 lines; if it is longer, flag it for user review and propose trimming or graduating long-lived items into rules. Confirm `CLAUDE.md` routes to it before meaningful work.
- Create a concise append-only `.claudart/JOURNAL.md` template if it is missing. Never prune or rewrite its entries; use `tail` and targeted `rg` instead of full reads.
- If `.claudart/tasks/` or `.claudart/specs/` is missing while its command exists, create only its canonical seed index and `done/.gitkeep`; create `.claudart/specs/done/.gitkeep` if only that is missing. If `.claudart/tasks/done/.gitkeep` sits beside a real archived `<task-id>/TASK.md`, remove only that redundant placeholder and report it.
- Inventory tasks only at `.claudart/tasks/*/TASK.md` and `.claudart/tasks/done/*/TASK.md`, the depths `.claude/rules/task-management.md` defines; never recurse into attachments or follow workspace or `TASK.md` symlinks.
- Leave task workspaces and spec folders unchanged: their owning workflows manage state and archives. Do not create `artifacts/`, extract archives, rewrite evidence, migrate flat tasks, or treat missing optional files as repair targets.

## 9. Normalize Knowledge In Place

Read `.claude/rules/knowledge-management.md` and `.claude/references/knowledge-maintenance.md`; together they define the grammar and mutation rules. If the folder or root router is missing, create the lean canonical scaffold.

1. Make one in-place normalization pass over every topic and `_maps/*.md`, including unindexed files. Preserve every body verbatim and preserve curated root and map titles, hooks, grouping, ordering, and external routes.
2. Normalize frontmatter and routes to the current grammar without inventing aliases, triggers, scope, relations, evidence, or lifecycle.
3. Set `status: active` only for a claim checked against current evidence, with `last_verified` set to the check date and at least one `sources` or `verify` anchor. With insufficient or conflicting evidence, set `status: review-needed` with a concise `status_note`. Entries under `## Point-in-time observations` are outside this verification and do not decide the status. Preserve an explicitly evidenced `superseded` or `retired` lifecycle.
4. On an empty tier, create only a small grounded set whose claims pass every capture gate, or leave it empty. Never convert WIP, proposals, task/spec state, or unsupported inference into knowledge.
5. Reconcile each reachable topic with its route atomically. Report an ambiguous unindexed file and neither promote nor remove it. Create domain maps at the reference's threshold only from existing scope or grouping evidence; if ownership cannot be grouped safely, keep the direct routes and report the decision.
6. Report budget warnings — `K116` size, `K117` section structure, `K135` source count — as candidates for a reviewed split or reduction to a route; this pass does not change bodies or ownership. Report overlap with current docs, source, or schemas for an authorized semantic cleanup. Never auto-merge, auto-retire, auto-supersede, or delete based on age or an ambiguous route.
7. Add no recall command, write-on-read behavior, telemetry, database, or daemon.
8. The pass is idempotent: running `/cda-refactor-memory` again against unchanged sources produces no knowledge diff.
9. After all mutations, run `bash .claude/scripts/knowledge-check.sh --fail-on warning`. Exit `2` is a checker failure and blocks completion. Exit `1` means findings remain: normalization is complete only when every remaining finding is a budget warning, and the report lists those.

## 10. Base Template Handling

When this repository is a template whose `.claude/` and `.agents/` are installed into other projects, keep its language generic, add no generated-marker comments, treat `.claude/CLAUDE.md` as the upstream source of the installed root `CLAUDE.md` without a second copy, and do not assume adopters share its languages, frameworks, docs, or tests.

## 11. Agent Self-Evolution Section

Ensure `## Agent Self-Evolution & Context Maintenance` ends `CLAUDE.md`: changed behavior, contracts, setup or operations update their owning document; changed rules update their file in `.claude/rules/`; new domains get a rule file with Step 2 frontmatter and a conditional Domain Rules route; eligible descriptive facts follow the knowledge contract; and global changes update `CLAUDE.md`. Live state still changes only through `/cda-checkpoint`, never through this command.

## 12. Verification

Before the final summary, run `git diff --stat`, `git status --short`, and `wc -l CLAUDE.md .claudart/CONTEXT.md`; confirm every rule `CLAUDE.md` lists exists and `.claudart/knowledge/INDEX.md` is referenced by a plain (non-`@`) pointer; confirm that a repeated normalization pass creates no changes, every active entry has `last_verified` plus `sources` or `verify`, `CLAUDE.md` and `.claude/rules/` auto-load neither JOURNAL nor HANDOFF, no reference points to a deleted memory file, and semantic findings use the required classifications; and run `bash .claude/scripts/knowledge-check.sh --fail-on warning` as the post-check even when the pre-check passed, recording both outcomes and blocking completion on exit `2`.

After validation, follow `.claude/rules/git-workflow.md` for local persistence. Commit the verified in-scope refactor result using the authority resolved by that shared policy. Push, merge, rebase/history rewrite, tags, and Git configuration remain separately authorized under that policy.

## 13. Final Summary

Summarize:

1. Rule files and `.claudart/knowledge/` entries created, updated, or reclassified between tiers, including the in-place normalization result.
2. `CLAUDE.md` changes and final line count.
3. Step 7 audit findings, separated into auto-fixed and needs user decision.
4. Step 3 semantic drift findings, including source debt not fixed in memory.
5. Deprecated memory files removed or retained.
6. Verification run.
7. Remaining risks or user decisions.
8. Git persistence result: committed SHA and message, or the concrete reason persistence remains pending; suggest reviewing the resulting diff or commit.

Confirm completion only after every relevant step is complete or marked not applicable.
