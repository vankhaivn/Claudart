---
description: Auto-refactor .claude/CLAUDE.md, rules, and agents into a coherent Modular Rules System
---

Analyze the existing Claude memory layer in this repository and refactor it into a coherent Claude-native Modular Rules System.

The target shape is:

- a concise `.claude/CLAUDE.md` as the sole Claude memory index and instruction entrypoint;
- durable domain knowledge in scoped files under `.claude/rules/`;
- current live state in `.claude/CONTEXT.md`;
- append-only history in `.claude/JOURNAL.md`;
- self-contained skills in `.agents/skills/` or `.claude/commands/`;
- optional read-only reviewer/explorer agents in `.claude/agents/`.

> **Pre-flight check**: confirm `git status --short` is clean or that the user understands there is in-progress work before you begin. Refuse to proceed if unrelated uncommitted changes could be swallowed by the refactor.

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
- For docs-first repositories, identify document layers, source-of-truth boundaries, templates, workflows, and contract directories.

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
    - Use repository-native source files, package manifests, schemas, migrations, generated types, tests, docs/contracts, and config loaders as evidence.
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
- rules proposed for migration to `.claude/knowledge/` (descriptive content misfiled as behavior).

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

For the knowledge tier, add a **plain pointer line** (not an `@` import), e.g. `Project knowledge: see .claude/knowledge/INDEX.md (surfaced by /start; read entries on demand).` Only `/start` loads the index; knowledge detail files are never auto-loaded.

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
- Confirm the skill contains sufficient procedure detail to execute the workflow without referencing external files.
- Keep skills complete and actionable. A future Claude session should know exactly what to do and which files it may update.
- Remove stale generated-marker comments or references to deleted memory files.

For every file in `.claude/agents/`:

- Verify YAML frontmatter has `name`, `description` (with `PROACTIVELY` if it should auto-trigger), `tools`, and `model`.
- Keep review/explorer agents read-only unless the agent is explicitly a worker.
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

- If the folder does not exist but `/plan` is documented in `.claude/commands/`, create it with a seed `index.md` and a `done/.gitkeep`.
- If `.claude/tasks/done/.gitkeep` exists AND `.claude/tasks/done/` contains at least one real `.md` file, delete the `.gitkeep` — once real archives live there, the placeholder is redundant. Report what was removed.
- Do not modify or move any task `.md` file content. Task files are working documents owned by `/plan` and `/checkpoint`; refactor-memory only touches the `.gitkeep` placeholder and (if missing) the seed `index.md`.

For `.claude/knowledge/`:

- If the folder does not exist, create it with a seed `INDEX.md` (header comment + empty `## Knowledge` section).
- **Bootstrap an empty tier (opt-in, ask first).** If `knowledge/` is empty — the common case right after adopting the tier — offer to seed it; **never auto-run**. Source *only* from existing durable facts you can ground: the project `README`, `docs/`, architecture/contract files, and descriptive content removed from `.claude/CLAUDE.md` in Steps 4/6 (build on your Step 2 analysis). Propose a **small** set of DRAFT entries (domain, architecture, key integrations, glossary — a handful, not an exhaustive dump); **every entry MUST carry a `sources:` anchor** to the real file it summarizes — no source, no entry (that would be speculation). Write only entries the user approves; never bulk-generate, and never invent facts by reading raw implementation.
- **Reconcile the index**: every `.md` file (excluding `INDEX.md`) must have an `INDEX.md` entry, and every entry must point to a real file. Add missing entries; flag dead entries.
- Audit each knowledge file: frontmatter present (`name`/`description`/`type`/`updated`); `sources:` relative paths still exist (dead → report); `updated:` older than 90 days → flag for review.
- Enforce the boundary: knowledge is **descriptive**. If a file carries prescriptive rules (`MUST`/`NEVER`), propose moving that content to `.claude/rules/`. The boundary is bidirectional — Step 5 handles the reverse (a purely descriptive rule that belongs here).
- **Verify concrete claims against the repo** — apply the same rigor as Step 5, on knowledge bodies: extract concrete claims (named files, modules, symbols, endpoints, config keys, paths) and confirm they still exist. Classify accurate / stale / needs-user-decision. Knowledge is descriptive fact about the codebase, so it rots faster than rules — flag stale facts for user review, never auto-delete. Recommend a `sources:` or `verify:` anchor for any entry that has neither (unanchored facts can't be checked deterministically by `/doctor`).
- **Overlap detection** (`knowledge ↔ knowledge` and `knowledge ↔ rules`): use `description`/`type` keywords as a cheap overlap signal (as Step 9 uses tag overlap for rules); read bodies only when keywords collide. Two knowledge entries on the same topic → propose merging into the most specific owner + a `[[link]]`. A fact restated inside a rule's prose → propose keeping the *behavior* in the rule and the *fact* in knowledge, cross-linked — never duplicated. Propose only; merge after user confirmation.
- **Reconcile `related:` links**: confirm each `[[slug]]` in a knowledge file's `related:` resolves to an existing knowledge topic or rule; repair or report dead links.
- Do not auto-delete or rewrite knowledge bodies — flag staleness and dead pointers for user review. Keep `INDEX.md` a one-line-per-entry map.

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
- Durable project facts (domain, architecture, integration, glossary, external-doc pointers) → CREATE or update a topic file in `.claude/knowledge/` and register it in `.claude/knowledge/INDEX.md`. Knowledge is descriptive; rules are prescriptive.
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
- Confirm `.claude/knowledge/INDEX.md` exists, lists every topic file, and is referenced by a plain (non-`@`) pointer in `.claude/CLAUDE.md`.
- Confirm every knowledge entry you created this run (bootstrap or migration) carries a `sources:` anchor; drop or flag any that does not.
- Confirm semantic rule findings were classified as accurate, rule-stale, source-debt, open-work, or needs-user-decision.

Do not run `git commit`, `git push`, `git merge`, `git rebase`, or similar history/remote-writing commands yourself.

## 14. Final Summary

Output a concise summary covering:

1. Rule files and `.claude/knowledge/` entries created, updated, or migrated between tiers (including any opt-in bootstrap).
2. `.claude/CLAUDE.md` changes and final line count.
3. Audit findings from Step 9, separated into auto-fixed and needs user decision.
4. Semantic drift findings from Step 5, including source-debt items not fixed in memory.
5. Deprecated memory files removed or retained.
6. Verification commands/checks run.
7. Remaining risks or user decisions.
8. Suggest the user run `git diff` to review every change before committing.

Confirm completion only after every relevant step has been completed or explicitly marked not applicable.
