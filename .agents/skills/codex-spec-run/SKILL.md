---
name: codex-spec-run
description: Execute an approved dated spec mission from .codex/specs/ autonomously until final review — self-plan runnable tasks, delegate where the roadmap authorizes it, verify acceptance, record ROADMAP dispositions and evidence, and offer session rotation at phase boundaries.
---

# Codex Spec Run

You are the executor. The spec folder was written by a session that interviewed the user; you were not there, and you don't need to have been — SPEC.md, ROADMAP.md, NOTES.md, and LEDGER.md carry everything. Assume total amnesia between iterations: the files, not your memory, are the truth.

Before doing anything, read `.codex/guidelines/spec-workflow.md`. It defines the loop contract, standing approval, verification bar, circuit breakers, session rotation, and the final gate. This skill does not duplicate that contract; it drives it. Also read `.codex/guidelines/agent-delegation.md` before any fan-out.

In the designed loop a fresh session opens with `$codex-start` (which surfaces active specs), then runs this skill. If `$codex-start` was skipped, Step 1 is still sufficient orientation — the spec folder is self-contained.

The loop is model-agnostic: run it on a cheap model for routine execution, and run the _same skill_ from a stronger session to punch through a `blocked` spec — escalation is not a different workflow (see the guideline file's unblock mode).

## Inputs

- The argument after `$codex-spec-run` is either the short spec slug or the dated folder id (`YYYY-MM-DD-<slug>`). Resolve it by scanning `.codex/specs/*/SPEC.md` excluding `.codex/specs/done/`: exact folder-id match first, then `slug:` frontmatter match. If a short slug matches several active folders, ask which dated folder to run. If the match exists only under `.codex/specs/done/`, report its archived `done`/`cancelled` status and stop. If omitted, scan those same active SPEC frontmatters rather than trusting the INDEX cache: exactly one with status `ready`, `running`, `blocked`, or `awaiting-final-review` → select it; several → ask which; none → report any `drafting`/`poc-review` spec and suggest `$codex-spec`, or say there is no active spec.

## Procedure

### Step 1 — Orient (every session, every time)

Read in full: `SPEC.md`, `ROADMAP.md`, `NOTES.md`, and the tail of `LEDGER.md` (~30 lines, more if the tail is mid-incident). Then gate on status:

- `drafting` / `poc-review` — refuse: the spec isn't approved. Point the user at `$codex-spec` to finish it.
- `ready` — flip to `running`, sync INDEX, append a `run-started` LEDGER entry, go to Step 2.
- `running` — resuming. If the LEDGER tail shows activity only minutes old, another session may still be driving this spec — confirm with the user before proceeding. Check the tail for an unmatched `task-started` or `delegated` entry per the guideline's terminal-event rule — that is work that was in flight when the previous session died; verify its partial state on disk before redoing anything. Then verify the last completed entry against reality (spot-check its `verify:`; unrelated commits may have landed). Drift or stronger contradictory evidence → append `validation-failed`, reopen the affected scenario and responsible work under the guideline's ROADMAP disposition contract, update Current Acceptance Delta, and continue from current reality.
- `blocked` — enter unblock mode. Read the last `task-blocked`/`circuit-breaker` diagnosis and `NOTES.md → Current Acceptance Delta`. External blocker → ask the user whether it cleared (cleared → remove the task's blocker marker, flip to `running`, sync INDEX, and continue; not → stop). A task that defeated a previous session → investigate first. Resume it only with a materially different path: clear `⚠ blocked`, keep it unticked, flip to `running`, and sync INDEX; or supersede it using the guideline's checked + struck form, append only the replacement work actually needed, record the NOTES decision and `replanned` entry, flip to `running`, and sync INDEX. Then offer: continue here, or rotate so a cheaper session resumes.
- `awaiting-final-review` — branch on the user's current message: explicit completion confirmation → run the guideline's closeout flow, flip `status: done`, append the JOURNAL completion line, sweep `NOTES.md` graduation flags, move the dated folder to `.codex/specs/done/`, sync INDEX, and stop; explicit problem report that contradicts the frozen SPEC/POC → apply the guideline's review back-edge, flip to `running`, sync INDEX, and resume the convergence flow; intent/scope change or a report with no approved anchor → keep the read-only lock, surface the scope delta, and ask whether to amend the SPEC (on explicit yes, flip to `drafting`, sync INDEX, and hand control to `$codex-spec` for renewed review/approval); neither → keep the lock, surface the pending demo, and ask the user to verify or report what failed.
- `done` / `cancelled` — say so, including whether the folder is archived under `.codex/specs/done/`; nothing to run.

### Step 2 — Loop

Execute **The Loop** from the guideline file, iteration after iteration, without asking permission — the standing approval already covers every roadmap task. In practice:

- Pick the first runnable pending task whose dependencies are satisfied; never select a task marked `⚠ blocked` or an invalid legacy struck-unticked row. Derive the _how_ yourself from the roadmap's decisions — the plan carries decisions and `verify:`, not solutions.
- Delegate only where the approved roadmap marks waves for fan-out — per `agent-delegation.md`'s explicit-authorization gate and `spec-workflow.md`, the standing approval of that marking is the recorded authorization; unmarked tasks run solo, and the loop never pauses to offer delegation. Worker prompts follow the Worker Prompt Contract (including the Boundary line) and carry the roadmap task text and relevant SPEC lines verbatim. Re-verify every worker result yourself before ticking.
- Verify on a real surface; UI tasks compare against the frozen POC artifact (`SPEC.md → POC Artifacts`). Use an art-generation skill against that artifact when the roadmap calls for generated assets.
- On failed verification, do not tick: append `validation-failed`, update Current Acceptance Delta, and retry only with a materially different hypothesis, implementation, or verifier. Stronger evidence that contradicts an earlier pass invalidates that pass per the guideline.
- On passed verification, tick, log evidence to LEDGER, bump `updated:`, clear any delta the evidence resolves, and route durable findings into NOTES.md (evidence → LEDGER, knowledge → NOTES). Then next runnable task.
- Honor the SPEC's `commits:` policy: `user` → never run `git commit`; `per-task`/`per-phase` → commit at each tick / phase close with message `spec(<slug>): <summary>`. Push is never granted.
- Honor the circuit breakers exactly as written. An out-of-scope question (anything Must-NOT-Have doesn't settle) blocks the affected task with its exact unlock condition; continue independent runnable work, and stop the whole loop only through the canonical no-runnable-work breaker. Never resolve scope by guessing or weaken a `verify:` to get past it.

### Step 3 — Phase boundary

Run the phase validation. On PASS, tick the SPEC scenarios it proves and append `phase-validated`. On FAIL, follow the guideline's convergence flow: keep the phase open, append `validation-failed`, update Current Acceptance Delta, and reopen responsible work under the ROADMAP disposition contract; do not create fix/replay bookkeeping pairs. Then **offer rotation** per the guideline file: report `n/m` tasks + current phase + Current Acceptance Delta, ask "checkpoint and rotate, or continue?". On rotate: `rotation-checkpoint` LEDGER entry with the exact next task, then the `$codex-checkpoint` flow (specs INDEX sync + NOTES `→ graduate:` flags collected), then tell the user to open a fresh session, `$codex-start`, then `$codex-spec-run <slug>`. Also offer rotation mid-phase after any compaction — finish the in-flight task first.

### Step 4 — Final gate

When every roadmap task is completed or explicitly superseded and no unresolved blocked task remains, run the Completion flow from the guideline file: re-run every Acceptance Scenario fresh. Only a full PASS clears Current Acceptance Delta, gets a `final-gate` entry, and reaches `awaiting-final-review`; a failure reopens responsible work under the ROADMAP disposition contract. Report demo steps + evidence and **stop** only after the full gate passes. The user closes the mission, not you.

## Anti-Patterns

- Asking "should I continue?" between tasks or phases (rotation offers and blockers are the only pause points).
- Working from memory of a previous iteration instead of re-reading the files after compaction.
- Creating `.codex/tasks/` files, `HANDOFF.md`, or parallel plans — the spec folder is the only state.
- Spawning subagents for tasks the roadmap never marked for fan-out, or pausing the loop to ask for delegation permission.
- Ticking without running `verify:`; trusting a subagent's "done"; presenting a demo with unproven scenarios.
- Editing SPEC.md scope (Acceptance Scenarios, Must-NOT-Have) — only the user changes intent.
- Counting appended tasks or ticks as progress while Current Acceptance Delta is unchanged.
- Retrying a failed acceptance without a materially different hypothesis, implementation, or verifier.
- Selecting a task marked `⚠ blocked`, silently dropping its diagnosis, or leaving a superseded task unticked.
- Appending separate fix/replay tasks for one defect or reusing a contradicted green check as sole proof.
