---
description: Execute an approved dated spec mission from .claudart/specs/ under its standing approval until the canonical final-review gate or a real blocker.
---

Execute an approved mission. Before acting, read `.claude/rules/spec-workflow.md`; it is the canonical contract for state, roadmap dispositions, evidence, verification gates, circuit breakers, rotation, and closeout. Read `.claude/rules/agent-delegation.md` before delegation. This command supplies only runner routing.

## Resolve the mission

The argument is a short slug or dated folder id. Resolve it from active `.claudart/specs/*/SPEC.md` frontmatter under the rule's rules, excluding `done/`. If omitted, select the only active `ready`, `running`, `blocked`, or `awaiting-final-review` mission. Ask only when several candidates remain ambiguous. Report an archived match without running it; route `drafting` or `poc-review` to `/spec`.

## Load state at the right boundary

On the initial run, a new session, recovery after interruption/compaction, an unmatched in-flight LEDGER event, or suspected drift, read `SPEC.md`, `ROADMAP.md`, and `NOTES.md` in full plus enough of the LEDGER tail to cover the open incident. During uninterrupted execution, load the selected ROADMAP task and dependencies, applicable SPEC scenarios and Must-NOT-Have constraints, Current Acceptance Delta, and LEDGER entries since the previous selection. Expand to full files whenever those scoped reads reveal ambiguity or drift.

## Route by status

- `ready`: flip to `running`, sync INDEX, append `run-started`, and enter the canonical loop.
- `running`: recover unmatched work and validate relevant drift as the rule requires, then continue the canonical loop under the standing approval.
- `blocked`: apply the canonical unblock test. Continue with a materially different evidence-backed path when available; stop only for the recorded external unlock condition or when no independent runnable work remains.
- `awaiting-final-review`: apply the canonical closeout or review-back-edge classification from the user's current message. Completion confirmation closes; an anchored defect or approved bounded review patch resumes; a material or ambiguous amendment stays locked for user approval.
- `done` / `cancelled`: report the terminal state and stop.

The current request controls routing. A direct request to run, implement, continue, or resume an approved mission needs no additional confirmation. Approval-only may leave the mission at `ready` until `/spec-run` is invoked.

## Execute and finish

Run the rule's loop until its final-review gate or a circuit breaker. Preserve the SPEC and Must-NOT-Have fences, ROADMAP disposition forms, Current Acceptance Delta, append-only LEDGER evidence, and smallest non-redundant verification rules. Derive impact from the actual changed surface when selecting `full-baseline` or `scoped-review`; every successful gate records the resulting revision or bounded worktree fingerprint and its `executed`, `covered`, and `reused` evidence.

Honor `commits:` exactly; it never authorizes push or history rewrite. Honor explicit user/runtime budgets, but do not invent estimates, attempt limits, model tiers, or rotation thresholds.

At a useful rotation boundary, surface phase progress and Current Acceptance Delta with an option to checkpoint and rotate. Continue authorized work when the user declines or gives no reply; the offer is never a pause gate. On affirmative rotation, follow the rule's checkpoint flow. A fresh session is optional.

Stop at `awaiting-final-review` after the applicable gate passes. The user confirms `done`; the runner never treats its own successful evidence as that confirmation.
