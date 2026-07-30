---
description: Execute an approved dated spec mission from .claude/specs/ autonomously until final review — self-plan runnable tasks, fan out subagents, verify acceptance, record ROADMAP dispositions and evidence, and offer session rotation at phase boundaries.
---

You are the executor. The spec folder was written by a session that interviewed the user; you were not there, and you don't need to have been — SPEC.md, ROADMAP.md, NOTES.md, and LEDGER.md carry everything. Assume total amnesia between iterations: the files, not your memory, are the truth.

Before doing anything, read `.claude/rules/spec-workflow.md` and `.claude/rules/knowledge-management.md`. They define the loop and the boundary between mission candidates and canonical knowledge. This command does not duplicate those contracts; it drives them. Also read `.claude/rules/agent-delegation.md` before any fan-out.

In the designed loop a fresh session opens with `/start` (which surfaces active specs), then runs this command. If `/start` was skipped, Step 1 is still sufficient orientation — the spec folder is self-contained.

The loop is model-agnostic: run it on a cheap model for routine execution, and run the _same command_ from a stronger session to punch through a `blocked` spec — escalation is not a different workflow (see the rule file's unblock mode).

## Inputs

- The argument after `/spec-run` is either the short spec slug or the dated folder id (`YYYY-MM-DD-<slug>`). Resolve it by scanning `.claude/specs/*/SPEC.md` excluding `.claude/specs/done/`: exact folder-id match first, then `slug:` frontmatter match. If a short slug matches several active folders, ask which dated folder to run. If the match exists only under `.claude/specs/done/`, report its archived `done`/`cancelled` status and stop. If omitted, scan those same active SPEC frontmatters rather than trusting the INDEX cache: exactly one with status `ready`, `running`, `blocked`, or `awaiting-final-review` → select it; several → ask which; none → report any `drafting`/`poc-review` spec and suggest `/spec`, or say there is no active spec.

## Procedure

### Step 1 — Orient (every session, every time)

Read in full: `SPEC.md`, `ROADMAP.md`, `NOTES.md`, and the tail of `LEDGER.md` (~30 lines, more if the tail is mid-incident). Then gate on status:

- `drafting` / `poc-review` — refuse: the spec isn't approved. Point the user at `/spec` to finish it.
- `ready` — flip to `running`, sync INDEX, append a `run-started` LEDGER entry, go to Step 2.
- `running` — resuming. If the LEDGER tail shows activity only minutes old, another session may still be driving this spec — confirm with the user before proceeding. Check the tail for an unmatched `task-started` or `delegated` entry per the rule's terminal-event rule — that is work that was in flight when the previous session died; verify its partial state on disk before redoing anything. Then verify the last completed entry against reality (spot-check its `verify:`; unrelated commits may have landed). Drift or stronger contradictory evidence → append `validation-failed`, reopen the affected scenario and responsible work under the rule's ROADMAP disposition contract, update Current Acceptance Delta, and continue from current reality.
- `blocked` — enter unblock mode. Read the last `task-blocked`/`circuit-breaker` diagnosis and `NOTES.md → Current Acceptance Delta`. External blocker → ask the user whether it cleared (cleared → remove the task's blocker marker, flip to `running`, sync INDEX, and continue; not → stop). A task that defeated a previous session → investigate first. Resume it only with a materially different path: clear `⚠ blocked`, keep it unticked, flip to `running`, and sync INDEX; or supersede it using the rule's checked + struck form, append only the replacement work actually needed, record the NOTES decision and `replanned` entry, flip to `running`, and sync INDEX. Then offer: continue here, or rotate so a cheaper session resumes.
- `awaiting-final-review` — branch on the user's current message: explicit completion confirmation → run the rule's closeout flow, flip `status: done`, append the JOURNAL completion line, sweep `NOTES.md` graduation flags, move the dated folder to `.claude/specs/done/`, sync INDEX, and stop; explicit problem report that contradicts the frozen SPEC/POC → apply the rule's review back-edge, flip to `running`, sync INDEX, and resume the convergence flow; intent/scope change or a report with no approved anchor → keep the read-only lock, surface the scope delta, and ask whether to amend the SPEC (on explicit yes, flip to `drafting`, sync INDEX, and hand control to `/spec` for renewed review/approval); neither → keep the lock, surface the pending demo, and ask the user to verify or report what failed.
- `done` / `cancelled` — say so, including whether the folder is archived under `.claude/specs/done/`; nothing to run.

### Step 2 — Loop

Execute **The Loop** from the rule file, iteration after iteration, without asking permission — the standing approval already covers every roadmap task. In practice:

- Pick the first runnable pending task whose dependencies are satisfied; never select a task marked `⚠ blocked` or an invalid legacy struck-unticked row. Derive the _how_ yourself from the roadmap's decisions — the plan carries decisions and `verify:`, not solutions.
- Delegate per `agent-delegation.md` whenever work genuinely parallelizes; roadmap-marked waves are recorded strategy, not an authorization gate. Worker prompts carry the roadmap task text and relevant SPEC lines verbatim. Re-verify every worker result yourself before ticking.
- Verify on a real surface; UI tasks compare against the frozen POC artifact (`SPEC.md → POC Artifacts`). Use an art-generation skill against that artifact when the roadmap calls for generated assets.
- On failed verification, do not tick: append `validation-failed`, update Current Acceptance Delta, and retry only with a materially different hypothesis, implementation, or verifier. Stronger evidence that contradicts an earlier pass invalidates that pass per the rule.
- On passed verification, tick, log evidence to LEDGER, bump `updated:`, clear any delta the evidence resolves, and route mission findings into NOTES.md. NOTES is the candidate surface; promote a grounded durable descriptive fact directly only when the full capture gate and an immediate-promotion trigger in `knowledge-management.md` pass. Patch owner + route atomically and run the checker, then continue.
- Honor the SPEC's `commits:` policy: `user` → never run `git commit`; `per-task`/`per-phase` → commit at each tick / phase close with message `spec(<slug>): <summary>`. Push is never granted.
- Honor the circuit breakers exactly as written. An out-of-scope question (anything Must-NOT-Have doesn't settle) blocks the affected task with its exact unlock condition; continue independent runnable work, and stop the whole loop only through the canonical no-runnable-work breaker. Never resolve scope by guessing or weaken a `verify:` to get past it.

### Step 3 — Phase boundary

Run the phase validation. On PASS, tick the SPEC scenarios it proves and append `phase-validated`. On FAIL, follow the rule's convergence flow: keep the phase open, append `validation-failed`, update Current Acceptance Delta, and reopen responsible work under the ROADMAP disposition contract; do not create fix/replay bookkeeping pairs. Then **offer rotation** per the rule file: report `n/m` tasks + current phase + Current Acceptance Delta, ask "checkpoint and rotate, or continue?". On rotate: `rotation-checkpoint` LEDGER entry with the exact next task, then the `/checkpoint` flow (specs INDEX sync + NOTES `→ graduate:` flags collected), then tell the user to open a fresh session, `/start`, then `/spec-run <slug>`. Also offer rotation mid-phase after any compaction — finish the in-flight task first.

### Step 4 — Final gate

When every roadmap task is completed or explicitly superseded and no unresolved blocked task remains, run the Completion flow from the rule file: re-run every Acceptance Scenario fresh. Only a full PASS clears Current Acceptance Delta, gets a `final-gate` entry, and reaches `awaiting-final-review`; a failure reopens responsible work under the ROADMAP disposition contract. Report demo steps + evidence and **stop** only after the full gate passes. The user closes the mission, not you.

## Anti-Patterns

- Asking "should I continue?" between tasks or phases (rotation offers and blockers are the only pause points).
- Working from memory of a previous iteration instead of re-reading the files after compaction.
- Creating `.claude/tasks/` files, `HANDOFF.md`, or parallel plans — the spec folder is the only state.
- Ticking without running `verify:`; trusting a subagent's "done"; presenting a demo with unproven scenarios.
- Editing SPEC.md scope (Acceptance Scenarios, Must-NOT-Have) — only the user changes intent.
- Counting appended tasks or ticks as progress while Current Acceptance Delta is unchanged.
- Retrying a failed acceptance without a materially different hypothesis, implementation, or verifier.
- Selecting a task marked `⚠ blocked`, silently dropping its diagnosis, or leaving a superseded task unticked.
- Appending separate fix/replay tasks for one defect or reusing a contradicted green check as sole proof.
