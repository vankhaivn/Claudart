---
name: cda-spec-run
description: Execute an approved dated spec with scoped context and evidence-driven verification until final user review or a real blocker.
disable-model-invocation: true
---

Execute an approved mission. Read `.claude/rules/spec-workflow.md` first; it is the canonical contract for ownership, scoped loading, verification, recovery and review. This skill supplies runner routing.

## Resolve and load

Resolve the argument as the rule's File Layout section defines. Load context by scope and reconcile interrupted work from LEDGER before repeating any operation.

## Route by status

- `drafting` / `poc-review`: return to `/cda-spec`.
- `ready`: set `running`, sync INDEX, append `run-started` and enter the loop.
- `running`: recover interrupted work, check relevant drift and continue.
- `blocked`: apply the rule's unblock test; continue with a different evidence-backed path or independent ready work.
- `awaiting-final-review`: stay read-only unless the user confirms completion, reports an anchored defect, explicitly requests a bounded review patch or approves a material amendment.
- `done` / `cancelled`: report terminal state and stop.

## Execute and finish

Run the rule's loop, persisting under `commits:` and `git-workflow.md` within the active harness and explicit resource budgets. Read `agent-delegation.md` before authorized delegation. Close with the rule's final gate: `full-baseline` or `scoped-review` chosen from the actual changed surface, recorded with the resulting revision or bounded worktree fingerprint.
