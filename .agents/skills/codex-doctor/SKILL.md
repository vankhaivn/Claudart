---
name: codex-doctor
description: Run a read-only Codex installation health check with a mechanical baseline and bounded semantic audits.
---

# Codex Doctor

Run a read-only health check of the selected Codex CLAUDART layer. Do not auto-fix anything. Report findings for the user to address with `$codex-refactor-memory` or a deliberate manual edit.

## Mechanical Baseline

Run the doctor helper exactly once before semantic review. For a normal downstream installation, use:

```bash
bash .codex/scripts/doctor-check.sh --root . --layer codex
```

For explicit upstream CLAUDART source-template work, use `--layout source` and inspect `.codex/AGENTS.md` as the loader. Do not treat the maintainer root `AGENTS.md` as a duplicate installed loader.

For nondefault options or coverage boundaries, read `.codex/references/doctor-check.md`.

The helper owns its default selected-layer structural/readability checks, declared metadata subset and supported types, clear Markdown-resource/local-link checks, real Claude imports, loader/CONTEXT/HANDOFF size checks, and its single nested knowledge-check invocation. It does not claim full YAML/TOML validation or semantic health. Optional Project Docs may be absent. Use `--include` only for an explicitly requested extra Markdown source tree or file; do not turn doctor into a documentation-wide scan.

Preserve the helper output and exit status:

- Exit `0`: the mechanical baseline passed. Warnings and review items still require judgment.
- Exit `1`: report its findings at the stated severity and continue semantic review.
- Exit `2`, a missing/unreadable helper, or another helper runtime failure: report **High** and mark the mechanical health check incomplete; this installation cannot be declared healthy. Do not reproduce helper checks with ad hoc parsing.

Only if the helper was unavailable and never started, the legacy `bash .codex/scripts/knowledge-check.sh --root .` may run once as a limited fallback. Label that result as incomplete mechanical health. If the helper ran, never rerun the knowledge checker.

## Semantic and Remaining Structural Review

The baseline cannot decide whether prose is accurate or well-owned. Use bounded inspection and retain these reviews:

- Confirm the selected loader routes to CONTEXT and universal behavior guidance, selectively routes other relevant guidance, and does not blindly auto-load guidelines, JOURNAL, or HANDOFF. A missing universal behavior or code-health route is **High**.
- Confirm code-health and delegation guidance are usable for their stated triggers. Review delegation limits and whether delegation instructions preserve ownership, validation, parallel-edit safety, and the active harness policy.
- For knowledge, read `.codex/guidelines/knowledge-management.md` and `.codex/references/knowledge-maintenance.md`; review sampled claims for capture quality, tier separation, ownership, authority, evidence, and bounded routing. Preserve intentional external routes and curated hooks. An ambiguous unindexed file or heuristic duplicate is a review item, not proof of an error. Confirm start loads only the knowledge root router, never runs a checker, and does not globally load topic bodies; Claude must not auto-import knowledge. Do not run a repository-wide documentation audit.
- Confirm review-only/explorer agents use a read-only sandbox; write-capable agents need an implementation purpose, bounded ownership, protection of unrelated work, and validation. Review unsupported metadata with its native format contract; a parser review warning does not prove it malformed.
- Check guideline tags follow the compact contract of 1–5 lowercase kebab-case tags. Review tag meaning, path coverage, agent descriptions, and overlap only as signals. A zero glob, matching tags, a short snippet, or prose wording alone is not a defect without contextual evidence.
- Review operational path mentions excluded by the parser when they declare required inputs or routes; confirm those targets exist. Examples and bare path mentions alone do not make a file mandatory.
- Keep JOURNAL checks to a header/head, line count, and tail spot-check. Review old CONTEXT `since:` decisions as graduation candidates; do not full-read state merely to count it.
- Report stale metadata, long inlined snippets, hardcoded shell lists, vague skills, or descriptive-only guidelines as candidates for review after considering purpose and scope.

### Task Workspace Health (`.codex/tasks/`)

Skip this section if `.codex/tasks/` does not exist. Follow `.codex/guidelines/task-management.md`; this audit does not create or repair task content.

- Confirm `.codex/tasks/index.md` exists. Missing -> Medium; suggest `$codex-checkpoint` to regenerate it. Count lines with `wc -l`: the 100-line ceiling and trim ladder remain unchanged.
- Inspect only `.codex/tasks/*/TASK.md` and `.codex/tasks/done/*/TASK.md` in directly contained `YYYY-MM-DD-NNN-<slug>` directories. Exclude `done/` itself; never follow workspace or `TASK.md` symlinks or recursively parse attachments as tasks. Flat task files are outside the current contract, not a second discovery format.
- Flag a dated directory missing `TASK.md`, or an invalid directory name, as Medium; preserve it for explicit repair. Require `slug`, `status`, `created`, `updated`, `agent`, `delegation`, and `tags`; valid task status, agent, delegation, dated `<created>-<NNN>-<slug>` naming, and inline lowercase tags. Do not invent metadata, migrate flat files, or remove unknown content.
- Flag a top-level `done`/`cancelled` workspace for whole-directory archival by `$codex-checkpoint`; flag archive collisions or archived non-terminal tasks as Medium. `awaiting-review` stays active until the user confirms. Cross-check index paths and status, including `done/<task-id>/TASK.md` under Recently Done.
- Require `## Purpose`, `## Context & Orientation`, `## Plan of Work`, `## Concrete Steps`, `## Validation & Acceptance`, `## Decision Log`, `## Surprises & Discoveries`, and `## Outcomes & Retrospective`.
- A `TASK.md`-only workspace is complete. Missing `artifacts/` or `### Workspace Files` is normal and must never produce a warning. `### Memory Hints` must exist; `None.` is valid. Do not require NOTES, ROADMAP, LEDGER, manifests, or placeholder reports.
- When `### Workspace Files` exists, check only its explicit local references for existence and a concrete purpose. Flag missing required input/evidence or unexplained local-only dependencies; a documented external/reproducible reference is not a broken local link. Do not read artifact bodies, fetch external inputs, extract archives, execute files, generate replacements, or create directories as part of doctor.

### Session Handoff and Spec Health

Absent `.codex/HANDOFF.md` is normal. If present, report it informationally; check its age and single-slot contract. Do not follow symlinks or create, delete, or consolidate handoff artifacts.

For `.codex/specs/`, follow `.codex/guidelines/spec-workflow.md` for metadata, status, commits, and disposition contracts. Inspect only direct active and archived dated folders; never follow workspace/core-file symlinks, recursively parse attachments, or rewrite state.

- Verify INDEX ↔ folder agreement in both directions; each active/archived folder has `SPEC.md`, `ROADMAP.md`, `NOTES.md`, and `LEDGER.md`. Missing core files are Medium. `NOTES.md` stays at most 150 lines; spot-check the last 15 LEDGER lines for `### YYYY-MM-DD HH:MMZ — <event>` headings.
- Require `SPEC.md` keys `slug`, `status`, `created`, `updated`, and `agent`; validate the dated folder name and valid spec status. At `poc-review` or later, every path under `## POC Artifacts` must exist.
- Review ROADMAP dispositions: unchecked struck rows, struck terminal rows without `superseded by`, blocked rows without condition and `unlock:`, and status that contradicts runnable, blocked, or terminal rows are Medium. A top-level terminal spec should be archived; an archived non-terminal spec is Medium.
- Apply the canonical staleness thresholds from `.codex/guidelines/task-management.md`; do not redefine them.

## Reporting

Use passing, warnings, errors, and one recommended next step. State whether the mechanical baseline ran and its result. Only declare the installation healthy when all mandatory mechanical checks ran and passed and the semantic and remaining structural checks also pass. Doctor is read-only and does not require a `$codex-doctor` → `$codex-refactor-memory` → `$codex-doctor` chain.
