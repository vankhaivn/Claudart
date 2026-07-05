---
name: codex-spec-run
description: Execute an approved spec mission from .codex/specs/ autonomously until done — self-plan each task, delegate where the roadmap authorizes it, self-QA against the SPEC, tick the ROADMAP, log evidence to the LEDGER, and offer session rotation at phase boundaries.
---

# Codex Spec Run

You are the executor. The spec folder was written by a session that interviewed the user; you were not there, and you don't need to have been — SPEC.md, ROADMAP.md, and LEDGER.md carry everything. Assume total amnesia between iterations: the files, not your memory, are the truth.

Before doing anything, read `.codex/guidelines/spec-workflow.md`. It defines the loop contract, standing approval, verification bar, circuit breakers, session rotation, and the final gate. This skill does not duplicate that contract; it drives it. Also read `.codex/guidelines/agent-delegation.md` before any fan-out.

In the designed loop a fresh session opens with `$codex-start` (which surfaces active specs), then runs this skill. If `$codex-start` was skipped, Step 1 is still sufficient orientation — the spec folder is self-contained.

The loop is model-agnostic: run it on a cheap model for routine execution, and run the _same skill_ from a stronger session to punch through a `blocked` spec — escalation is not a different workflow (see the guideline file's unblock mode).

## Inputs

- The argument after `$codex-spec-run` is the spec slug. If omitted, read `.codex/specs/INDEX.md`: exactly one spec with status `ready` or `running` → run it; several → ask which; none → say so and suggest `$codex-spec`.

## Procedure

### Step 1 — Orient (every session, every time)

Read in full: `SPEC.md`, `ROADMAP.md`, `NOTES.md`, and the tail of `LEDGER.md` (~30 lines, more if the tail is mid-incident). Then gate on status:

- `drafting` / `poc-review` — refuse: the spec isn't approved. Point the user at `$codex-spec` to finish it.
- `ready` — flip to `running`, sync INDEX, append a `run-started` LEDGER entry, go to Step 2.
- `running` — resuming. If the LEDGER tail shows activity only minutes old, another session may still be driving this spec — confirm with the user before proceeding. Check the tail for an unmatched `task-started` or `delegated` entry — that is work that was in flight when the previous session died; verify its partial state on disk before redoing anything. Then verify the last completed entry against reality (spot-check its `verify:`; unrelated commits may have landed). Drift → log it, adapt, continue.
- `blocked` — enter unblock mode. Read the last `task-blocked`/`circuit-breaker` diagnosis. External blocker → ask the user whether it cleared (cleared → flip to `running` and continue; not → stop). A task that defeated a previous session → investigate and either execute it directly or re-plan it per the guideline file (strike + decision-complete replacements + NOTES decision + `replanned` entry), flip to `running`, then offer: continue here, or rotate so a cheaper session resumes.
- `awaiting-final-review` — don't run: surface the pending demo and ask the user to verify (or report what failed).
- `done` / `cancelled` — say so; nothing to run.

### Step 2 — Loop

Execute **The Loop** from the guideline file, iteration after iteration, without asking permission — the standing approval already covers every roadmap task. In practice:

- Pick the first unticked task; derive the _how_ yourself from the roadmap's decisions — the plan carries decisions and `verify:`, not solutions.
- Delegate only where the approved roadmap marks waves for fan-out — per `agent-delegation.md`'s explicit-authorization gate and `spec-workflow.md`, the standing approval of that marking is the recorded authorization; unmarked tasks run solo, and the loop never pauses to offer delegation. Worker prompts follow the Worker Prompt Contract (including the Boundary line) and carry the roadmap task text and relevant SPEC lines verbatim. Re-verify every worker result yourself before ticking.
- Verify on a real surface; UI tasks compare against the frozen POC artifact (`SPEC.md → POC Artifacts`). Use an art-generation skill against that artifact when the roadmap calls for generated assets.
- Tick, log evidence to LEDGER, bump `updated:`, and route durable findings into NOTES.md (evidence → LEDGER, knowledge → NOTES). Then next task.
- Honor the SPEC's `commits:` policy: `user` → never run `git commit`; `per-task`/`per-phase` → commit at each tick / phase close with message `spec(<slug>): <summary>`. Push is never granted.
- Honor the circuit breakers exactly as written. A breaker or an out-of-scope question (anything Must-NOT-Have doesn't settle) stops the loop with a report — never resolve scope by guessing, never weaken a `verify:` to get past it.

### Step 3 — Phase boundary

Run the phase validation, tick the SPEC scenarios it proves, append `phase-validated`, then **offer rotation** per the guideline file: report `n/m` tasks + current phase, ask "checkpoint and rotate, or continue?". On rotate: `rotation-checkpoint` LEDGER entry with the exact next task, then the `$codex-checkpoint` flow (specs INDEX sync + NOTES `→ graduate:` flags collected), then tell the user to open a fresh session, `$codex-start`, then `$codex-spec-run <slug>`. Also offer rotation mid-phase after any compaction — finish the in-flight task first.

### Step 4 — Final gate

When every box is ticked, run the Completion flow from the guideline file: re-run every Acceptance Scenario fresh, `final-gate` LEDGER entry, flip to `awaiting-final-review`, report demo steps + evidence, and **stop**. The user closes the mission, not you.

## Anti-Patterns

- Asking "should I continue?" between tasks or phases (rotation offers and blockers are the only pause points).
- Working from memory of a previous iteration instead of re-reading the files after compaction.
- Creating `.codex/tasks/` files, `HANDOFF.md`, or parallel plans — the spec folder is the only state.
- Spawning subagents for tasks the roadmap never marked for fan-out, or pausing the loop to ask for delegation permission.
- Ticking without running `verify:`; trusting a subagent's "done"; presenting a demo with unproven scenarios.
- Editing SPEC.md scope (Acceptance Scenarios, Must-NOT-Have) — only the user changes intent.
- Retrying an identical failing approach past the breaker, or silently skipping a blocked task's diagnosis.
