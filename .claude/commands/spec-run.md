---
description: Execute an approved dated spec with scoped context and evidence-driven verification until final user review or a real blocker.
---

Execute an approved mission. Read `.claude/rules/spec-workflow.md` first; it is the canonical contract for ownership, scoped loading, verification, recovery and review. This command supplies runner routing.

## Resolve and load

Resolve the argument as a dated folder id or SPEC slug under `.claudart/specs/`, excluding `done/`. With no argument, select the only active ready/running/blocked/review mission; ask only if ambiguous. Report archived matches without running them.

Apply **Load Context by Scope** from the guideline: always read mission metadata, global constraints and the contract inventory, then the selected task/dependencies, ROADMAP delta and relevant evidence/notes. Compare references with actual scope and expand reads for missing contracts, interrupted writes or legacy layouts. Compaction alone does not require full-file reloads. Reconcile observed evidence before repeating an interrupted operation.

## Route by status

- `drafting` / `poc-review`: return to `/spec`; no production implementation.
- `ready`: set `running`, sync INDEX, append `run-started` and enter the canonical loop.
- `running`: recover interrupted work, validate relevant drift and continue.
- `blocked`: apply the canonical unblock test; continue with a materially different evidence-backed path or independent ready work.
- `awaiting-final-review`: remain read-only unless the user confirms completion, reports an anchored defect, explicitly requests a bounded review patch or approves a material amendment.
- `done` / `cancelled`: report terminal state and stop.

A current or still-applicable request to execute authorizes the run under the approved scope. Approval alone may leave it ready. Existing authority is neither expanded nor forgotten.

## Execute and finish

Follow the canonical order: orient/select → implement → reconcile coverage before expensive verification → observe results → append evidence → update ROADMAP → persist under `commits:`. Keep the Current Acceptance Delta in ROADMAP; NOTES holds reasoning, and SPEC changes only for contract/lifecycle metadata.

Use the existing smallest non-redundant phase/final verification plan. Do not add per-task compliance reports or another final suite. Determine `full-baseline` or `scoped-review` from the actual changed surface; keep candidate integration and conservative invalidation. Every successful gate records the resulting revision or bounded worktree fingerprint and executed/covered/reused evidence. A fingerprint alone cannot establish a complete dependency boundary.

Honor `git-workflow.md`, the active harness and explicit resource budgets. Read `agent-delegation.md` before authorized delegation. Do not invent extra approval rounds, resource estimates, attempt-accounting systems or model/rotation thresholds.

Offer useful rotation without pausing on silence. Stop at `awaiting-final-review` only after the applicable gate passes; the user's completion confirmation is required for `done`.
