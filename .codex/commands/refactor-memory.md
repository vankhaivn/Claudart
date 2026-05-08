# Codex Refactor Memory Command

Analyze the existing Codex memory layer in this repository and refactor it into a coherent Codex-native Modular Rules System.

The target shape is:

- a concise root `AGENTS.md` as the sole Codex memory index and instruction entrypoint;
- durable domain knowledge in scoped files under `.codex/guidelines/`;
- current live state in `.codex/CONTEXT.md`;
- append-only history in `.codex/JOURNAL.md`;
- focused commands in `.codex/commands/`;
- thin but actionable skills in `.agents/skills/`;
- optional read-only reviewer/explorer agents in `.codex/agents/`.

Codex CLI discovers `AGENTS.md` natively. If a base template keeps `.codex/AGENTS.md` as the source copied to root `AGENTS.md`, keep the two synchronized or ask the user which one is canonical. Otherwise, prefer root `AGENTS.md` as the canonical Codex memory index.

> Pre-flight check: confirm `git status --short` is clean or that the user understands there is in-progress work before you begin. Refuse to proceed if unrelated uncommitted changes could be swallowed by the refactor.

Execute the following steps systematically, without losing essential project context.

## 1. Resolve The Memory Shape

- Confirm whether the canonical memory file is root `AGENTS.md` or a template source such as `.codex/AGENTS.md`.
- If both root `AGENTS.md` and `.codex/AGENTS.md` exist, compare them.
    - If they are identical, remove or ignore the duplicate according to the repository convention.
    - If they differ, ask which file should win before overwriting either one.
- Search commands, skills, agents, and guidelines for references to deleted or deprecated memory files and update them during the refactor.

## 2. Analyze The Project

- Determine the main framework, language, runtime, and architectural layers from `AGENTS.md`, project structure, package manifests, build files, and existing docs.
- Identify the core logical layers, such as docs/contracts, database/repositories, API/controllers, UI/components, background jobs, runtime/deploy, or AI/model workflows.
- Note linters, formatters, test runners, and validation commands detected. Delegate style rules to those tools instead of encoding them into `AGENTS.md`.
- For docs-first repositories, identify document layers, source-of-truth boundaries, templates, workflows, and contract directories.

## 3. Ensure The Guideline Directory Exists

Create `.codex/guidelines/` if it does not already exist.

Use `.codex/guidelines/*.md` for durable semantic guidance. Do not use `.codex/rules/` for semantic coding guidance. Reserve `.codex/rules/*.rules` for Codex permission or environment rules if the project uses them.

## 4. Extract Domain-Specific Rules

Group detailed coding rules, boundaries, and validation requirements from `AGENTS.md`, deprecated memory files, and repeated workflow decisions into a small set of logical guideline files under `.codex/guidelines/`.

Common examples:

- `architecture.md`
- `api.md`
- `db.md`
- `ui.md`
- `runtime.md`
- `testing.md`
- `srs-integration.md`

Do not create guidelines just to create files. A small docs repo may only need one or two guidelines.

Required for each guideline file:

- YAML frontmatter with `paths:` and `description:`.
- `paths:` must be a glob or list of globs scoped to the files the guideline governs.
- `description:` must say what domain the guideline controls.
- No long code snippets. Prefer `file:line` references and behavior-level rules so context does not go stale.
- No secrets, tokens, private keys, production credentials, or real `.env` values.

Rule Quality Checklist:

1. Verifiable: a reader can check whether the rule was followed by reading the repo.
2. Loophole-closed: if a rule has an obvious bypass, add `NEVER do X, even when Y seems like a good reason`.
3. Critical-tagged: prefix high-priority constraints with `NEVER`, `YOU MUST`, `IMPORTANT`, or similar unambiguous language.
4. Scoped: the rule belongs in the named guideline and does not duplicate unrelated guidance elsewhere.

## 5. Refactor AGENTS.md

Trim root `AGENTS.md` so it stays a concise memory index, not a knowledge dump.

It should contain only:

- project identity;
- context loading order;
- core Codex workflows and skill selection;
- a project map or pointers to primary docs;
- security and repository-wide constraints;
- a `## Guidelines` section linking `.codex/CONTEXT.md` and `.codex/guidelines/*.md`;
- a clear rule that `.codex/JOURNAL.md` is not auto-loaded;
- the `## Agent Self-Evolution & Context Maintenance` section.

Target: keep `AGENTS.md` under 100 lines where practical. If it exceeds 100 lines, extract more into `.codex/guidelines/`, workflows, or project docs. If it exceeds 150 lines, flag it in the final summary.

## 6. Cross-Link Guidelines

Under a `## Guidelines` heading in `AGENTS.md`, add references for every guideline file plus the live-state context file.

Example:

```markdown
See `.codex/CONTEXT.md` for current session state, updated by `$codex-checkpoint`.
See `.codex/guidelines/ai-behavior.md` for universal AI behavior guidelines.
See `.codex/guidelines/architecture.md` for architecture boundaries.
```

NEVER add `.codex/JOURNAL.md` as a loaded context reference. JOURNAL is intentionally excluded from session context to save tokens. If you find such an import or auto-load instruction in `AGENTS.md` or `.codex/guidelines/`, remove it and warn the user in the final summary.

## 7. Wire Up AI Behavior Guidelines

`ai-behavior.md` is the universal behavior guideline for Codex work.

- If `.codex/guidelines/ai-behavior.md` does not exist, create a concise version with scoped frontmatter and durable behavior rules.
- If the user has customized `ai-behavior.md`, leave their content alone and only ensure the reference exists.
- Do not inline `ai-behavior.md` into `AGENTS.md`.
- Add a single reference under `## Guidelines`.

## 8. Audit Guidelines, Skills, Commands, And Agents

Report proposed audit changes in a clear list before applying risky changes. Apply safe fixes such as missing references, stale deleted-file references, frontmatter corrections, missing `.codex/CONTEXT.md` references, and JOURNAL auto-load removal. Ask before merging or deleting agents, guidelines, or skills.

For every file in `.codex/guidelines/`:

- Verify YAML frontmatter exists with valid `paths:` and `description:`.
- Run a glob check on each `paths:` entry. `paths: ["**/*"]` is valid for universal guidelines.
- If a glob matches zero files, flag the guideline as potentially dead and ask whether to remove or rescope it.
- Replace long inlined code with `file:line` references.
- Apply the Rule Quality Checklist.
- Merge near-duplicates only after user confirmation.

For every file in `.agents/skills/*/SKILL.md`:

- Verify the file starts with YAML frontmatter.
- Confirm `name:` and `description:` are present.
- Confirm each skill points to the full protocol in `.codex/commands/` when the command is too large to inline.
- Keep skills thin, but not vague. A future Codex session should know exactly which command file to read and which files it may update.
- Remove stale generated-marker comments or references to deleted memory files.

For every file in `.codex/commands/`:

- Confirm each command is usable from its own content.
- Remove stale template language that contradicts the repository's actual memory shape.
- Keep command protocols concise but complete.
- Ensure commands do not tell Codex to read or depend on deleted memory files.

For every file in `.codex/agents/`:

- Verify TOML includes `name`, `description`, `model`, `sandbox_mode`, and `developer_instructions`.
- Keep review/explorer agents read-only unless the agent is explicitly a worker.
- Replace hardcoded grep pattern lists with guidance to scan the codebase and use project tooling when present.
- Confirm the agent's responsibilities do not overlap more than 50% with another agent. If they do, propose a merge.

## 9. Maintain CONTEXT And JOURNAL

For `.codex/CONTEXT.md`:

- Confirm it exists. If not, create a concise template.
- Verify line count is at most 150. If exceeded, flag for user review and propose trimming or graduating long-lived items into `.codex/guidelines/`.
- Confirm `AGENTS.md` references `.codex/CONTEXT.md`.
- Ensure it describes current state only.

For `.codex/JOURNAL.md`:

- Confirm it exists. If not, create a concise append-only template.
- Search `AGENTS.md` and `.codex/guidelines/` for instructions that auto-load `.codex/JOURNAL.md`. If found, remove them and warn the user.
- Do not full-read JOURNAL by default. Use `tail` and targeted `rg` searches for pattern analysis.
- Do not prune or rewrite JOURNAL entries. The file is append-only by contract.

## 10. Base Template Notes

If this repository is a base template whose `.codex/` and `.agents/` directories are installed into other projects:

- Do not add generated-marker comments to base template files.
- Keep template language generic and avoid project-specific names unless the template is intentionally branded.
- If an installer copies `.codex/AGENTS.md` to root `AGENTS.md`, document that relationship clearly and keep both files synchronized.
- Do not assume a downstream project has the same languages, frameworks, docs, or tests as the template repository.

## 11. Append Agent Self-Evolution Section

At the end of root `AGENTS.md`, ensure `## Agent Self-Evolution & Context Maintenance` exists.

Include these rules, adapted to Codex paths:

- "Do not assume a human will document your code patterns. If you build it, document it."
- Existing guidelines change -> update the relevant file in `.codex/guidelines/`.
- New domains/layers -> create a new guideline file in `.codex/guidelines/` with `paths: [...]` frontmatter and append its reference to `AGENTS.md`.
- Global Codex changes -> update `AGENTS.md` directly.
- Shared live state -> update `.codex/CONTEXT.md` through `$codex-checkpoint`, not through refactor-memory.

## 12. Verification

Before the final summary, run or perform:

- `git diff --stat`
- `git status --short`
- `wc -l AGENTS.md .codex/CONTEXT.md`
- Search for stale references to deleted memory files, such as `.codex/AGENTS.md`, if those files were removed.
- Search `AGENTS.md` and `.codex/guidelines/` for JOURNAL auto-load instructions.
- Confirm every guideline listed in `AGENTS.md` exists.

Do not run `git commit`, `git push`, `git merge`, `git rebase`, or similar history/remote-writing commands yourself.

## 13. Final Summary

Output a concise summary covering:

1. Guideline files created or updated.
2. `AGENTS.md` changes and final line count.
3. Audit findings from step 8, separated into auto-fixed and needs user decision.
4. Deprecated memory files removed or retained.
5. Verification commands/checks run.
6. Remaining risks or user decisions.
7. Suggest the user run `git diff` to review every change before committing.

Confirm completion only after every relevant step has been completed or explicitly marked not applicable.
