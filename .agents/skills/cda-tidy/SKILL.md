---
name: cda-tidy
description: Clean project docs, knowledge, CONTEXT, OWNER and project guidelines to the Keep Documents Current contract, reviewing only what changed since the last tidy commit. Use only when the user asks for it, by command or in words.
---

# Tidy

Bring current documentation and state back to the "Keep Documents Current" contract in `.codex/guidelines/ai-behavior.md` without losing anything that still matters. Each run is marked in Git, so the next one reviews only what changed since in each scope it tidied.

The bundled scripts in `.agents/skills/cda-tidy/scripts/` do the mechanical work and are read-only. Run them from the project root with `bash`; `--help` describes each output line. Their lines are places to look, not verdicts.

## Scope

- **Tidy:** project docs (Markdown at the root, in `docs/` trees and READMEs), `.claudart/CONTEXT.md`, `.claudart/OWNER.md`, `.claudart/knowledge/`, and project guidelines in `.codex/guidelines/` (not the CLAUDART core guidelines). A user request may narrow this, for example to docs only.
- **Read only:** active tasks and specs. They show what current work depends on. Never edit them; report their bloat so the next resume or their owner can rewrite them.
- **Leave alone:** JOURNAL, HANDOFF, archived tasks and specs, changelogs and decision records, loaders, adapter files, untracked files, Markdown shipped with the code such as prompts or templates, and nested repositories, which are tidied in their own run.

## 1. Survey

1. Run `git status --short`. If in-scope files hold uncommitted changes you do not own, stop and ask; a tidy commit carries only tidy edits.
2. Run `bash .agents/skills/cda-tidy/scripts/scope.sh`. For each scope it finds the last commit whose `Claudart-Tidy:` trailer names that scope and lists the files changed since; a scope never tidied, or every scope with `--full`, is reviewed in full. On a root without Git, add `--snapshot <dir outside the root>`; verify needs that copy. Add `--include <path>` for each other folder the user names as project docs, and pass the same flags to signals and verify. A Git repository needs at least one commit.
3. Run `bash .codex/scripts/doctor-check.sh --root . --layer codex` once as the mechanical baseline.
4. Run `bash .agents/skills/cda-tidy/scripts/signals.sh` with the same `--full` and `--include` flags.
5. When `.agents/skills/cda-project-docs/references/ownership.md` exists, read it and use its owner table to decide where each fact belongs. Otherwise follow the repository's existing documentation layout.

Read each file under review in full before judging it. Signals miss paraphrased duplicates, stale claims and caveats that change nothing; find those by reading.

## 2. Propose

Before writing, present per file what will change: what is removed and why, where history or evidence moves, which facts merge into which owner page, and each entry you are unsure about as a question. Wait for the user's approval. A deletion or a file outside the approved plan needs its own confirmation.

## 3. Rewrite

Apply the contract to each file under review:

- **Docs:** describe the present. Remove dated update notes, changelog fragments, transition narration, test totals, run or job IDs and caveats that change nothing; link to the task, spec or commit that holds the evidence instead. Give each fact one owner page and replace other copies with a link. Keep reasons that still constrain future changes. Keep page purposes and the headings other pages link to.
- **CONTEXT:** apply the CONTEXT rules of `$cda-checkpoint` (rules 1, 2, 4 and 5): current state only, one short sentence per bullet, links instead of evidence, and other sessions' unresolved work kept.
- **OWNER:** apply the owner-profile section of `ai-behavior`: one line per entry, near-duplicates merged, entries that belong to an existing project guideline moved there and the rest reported. Never drop a preference the owner stated.
- **Knowledge:** follow `.codex/guidelines/knowledge-management.md` and `.codex/references/knowledge-maintenance.md` for every write, including frontmatter, routes, status and lifecycle. Reduce a topic to a route when another current source owns its facts.
- **Guidelines:** check every `RULEREF` line and each concrete claim in a reviewed guideline against the source. Update a stale guideline; keep a guideline the source violates and report the debt; ask when neither clearly wins. Move a guideline body that only describes and constrains nothing to its fact owner or knowledge, and confirm before deleting the guideline. Keep a mirrored Claude rule identical in content.

A file listed under `PROTECTED` is named by active work: reword its facts if needed, but keep what that work relies on unless the user confirms it no longer does. Removing text is safe when Git holds the previous version. On a root without Git, move history that still matters into one JOURNAL line or ask the user.

## 4. Verify

1. Run `bash .agents/skills/cda-tidy/scripts/verify.sh`, or `--before <snapshot>` on a root without Git. Restore every `LOST` fact or state why it no longer applies, fix every `LINK`, confirm each `REMOVED` line moved or no longer applies, and report `OLDLINK` breakage you did not cause.
2. After knowledge changes, run `bash .codex/scripts/knowledge-check.sh --root . --fail-on warning`. Exit `2` blocks completion; only budget warnings may remain.
3. Run `git diff --check` and read the final diff for accidental loss.

## 5. Commit and Report

Commit under `.codex/guidelines/git-workflow.md`. Stage only tidy edits and end the message body with a trailer naming each scope this run fully tidied, from `docs`, `knowledge`, `state` and `rules`, for example:

```text
Claudart-Tidy: docs, knowledge, state
```

The trailer marks the anchor for the next run; never add it to another commit. A scope left out of the trailer stays under full review next time. If the commit is not authorized, leave the changes for review and say the next run will start from the previous tidy commit.

Report the files changed per scope, what moved and where, removed facts accepted as obsolete with their reason, open questions, bloat found in active tasks or specs, nested repositories still to tidy, and the commit.
