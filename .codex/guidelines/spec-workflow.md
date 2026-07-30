---
paths: ["**/*"]
description: Dated mission-scale spec workspaces in `.codex/specs/` with `done/` archives — a POC-frozen SPEC plus a decision-complete ROADMAP that any later session (often a cheaper model) executes autonomously until final review, with self-QA, circuit breakers, and session rotation.
when_to_use: Whenever the user invokes `$codex-spec` or `$codex-spec-run`, when a spec folder under `.codex/specs/` is open or referenced, or when resuming mission-scale work that spans many sessions.
tags: [specs, loop-engineering, autonomy, cross-session, missions]
---

# Spec Workflow (Loop Engineering)

A **spec** is a mission: work too large for one task file — a whole game, a feature system, a client-demo POC. While active, it lives as a dated folder in `.codex/specs/YYYY-MM-DD-<slug>/` written once by an expensive planning session (`$codex-spec`), then executed to the final-review gate across many sessions by `$codex-spec-run` — often on a cheaper model — **without per-task human approval**. Completed and cancelled missions are archived under `.codex/specs/done/YYYY-MM-DD-<slug>/`. The folder, not any session, is the source of truth; every iteration assumes total amnesia and re-orients from files.

Missions sit **above** the task layer (`task-management.md`): a spec supersedes `$codex-plan` for its scope, and its executor never creates `.codex/tasks/` files. Use `$codex-plan` for a single feature or fix; use `$codex-spec` when the deliverable is a demoable whole.

## File Layout

```
.codex/specs/
├── INDEX.md                    # Registry: one line per spec
├── done/                       # Archive for done/cancelled spec folders
│   └── YYYY-MM-DD-<slug>/
└── YYYY-MM-DD-<slug>/
    ├── SPEC.md                 # What "done" means. Frozen at approval; only the user changes it.
    ├── ROADMAP.md              # Phases → checkbox tasks with explicit dispositions.
    ├── NOTES.md                # Working memory: orientation, pitfalls, decisions. Curated, re-read every iteration.
    ├── LEDGER.md               # Append-only evidence & history. Never rewritten.
    └── artifacts/              # POC HTML, mockups, generated references
```

- **Naming**: folder id is `YYYY-MM-DD-<slug>`, using the spec creation date and a slug of 2-5 lowercase kebab-case words. `SPEC.md` frontmatter keeps the short `slug: <slug>`; the folder name must equal `<created>-<slug>`. One folder per mission; never nest specs except the single archive folder `done/`.
- **Resolving a spec**: `$codex-spec-run <arg>` accepts either a full folder id (`YYYY-MM-DD-<slug>`) or the short slug. Match active top-level folders first; if a short slug matches more than one active folder, ask the user to choose the dated folder. If the match exists only under `done/`, report its archived status and do not run it.
- **`SPEC.md` holds intent, `ROADMAP.md` holds the plan, `NOTES.md` holds mission working knowledge/candidates, `LEDGER.md` holds the proof.** Canonical durable descriptive facts live under `.codex/knowledge/` only after the capture gate passes.

## SPEC.md

```markdown
---
slug: <kebab-slug>
status: drafting # drafting | poc-review | ready | running | blocked | awaiting-final-review | done | cancelled
created: YYYY-MM-DD
updated: YYYY-MM-DD
agent: codex # claude | codex | both
commits: user # user | per-task | per-phase — the executor's git-commit grant, chosen at approval; push is never granted
---

# <Mission Title>

## Mission

> "<the user's original ask, quoted verbatim>"

<2-3 sentences: what exists when this is done, who it will be demoed to.>

## Acceptance Scenarios

<Defined at spec time, each one binary. A scenario names the exact action and the exact observable —
"open artifacts/poc.html → wave counter advances and enemies spawn within 3s", not "game works".
The first final gate establishes fresh evidence for every scenario. Later review back-edges may carry
forward baseline evidence only for scenarios proven outside the changed surface. Keep scenarios
non-redundant; when a composite check covers several scenarios, name that coverage explicitly.>

- [ ] S1 — <literal action / command> → <binary observable>
- [ ] S2 — ...

## Must-NOT-Have

<Scope fence. Options the user rejected, features deferred, gold-plating to refuse. The executor treats
this as hard as the acceptance list.>

## POC Artifacts

- `artifacts/<file>` — <what it locks in; e.g. "approved UI reference — layout, palette, HUD placement">

## Definition of Done

Every ROADMAP task completed or explicitly superseded, no unresolved blocked task remains, AND every Acceptance Scenario has valid PASS evidence: fresh evidence at the first full final gate, then fresh evidence for the impacted closure plus explicitly retained baseline evidence after any scoped review back-edge.
```

POC artifacts are not decoration: they are the **frozen references for intent**, at whatever fidelity the user chose during drafting — often several narrow artifacts, each locking one aspect (core interaction with primitive placeholders, a visual-style reference, a flow demo) rather than one high-fidelity build. UI and UX tasks verify against them (side-by-side comparison, or feeding one to an art-generation skill), which is what lets a cheaper executor make presentation-quality calls without re-interviewing the user.

## ROADMAP.md — the decision-complete bar

The roadmap is the interface between the session that interviewed the user and a session that has **zero interview context**. It must be _decision-complete_: exact paths, chosen approaches (and rejected alternatives where a future session might re-litigate), per-task `verify:`, and phase-level validation commands. If executing a task would require asking "what did the user mean?", the roadmap is defective — fix the roadmap, don't guess.

Plan Altitude from `task-management.md` still applies: decisions and verification, **never code**. A task may be vague about _how_ as long as its `verify:` is sharp about _what success is_.

```markdown
# ROADMAP — <Mission Title>

<1-2 paragraphs: build order and why. Note which phases/tasks are parallelizable (waves) for fan-out.>

## Phase 1 — <name>

Goal: <one line — what is demoable when this phase closes>

- [ ] P1.1 <action, target files, decisions it carries> (verify: <observable check>)
- [ ] P1.2 ... (verify: ...)

**Phase validation**: <commands/scenarios proving the phase goal on a real surface — which SPEC scenarios it advances and any composite coverage it provides>

## Phase 2 — ...
```

- Top-level checkbox state is mechanical:
  - `- [ ] <task>` is pending work; it is runnable only when its dependencies are satisfied and it carries no `⚠ blocked` marker.
  - `- [x] <task>` is completed work backed by a `task-completed` evidence entry.
  - `- [x] ~~<task>~~ — superseded by <task-id or reason>` is terminal superseded work backed by a `replanned` entry.
  - `- [ ] <task> — ⚠ blocked: <condition>; unlock: <required input/change>` is unresolved and **not runnable**. It stays unticked, is skipped by selection, and prevents the final gate.
  - `- [ ] ~~<task>~~` is an invalid legacy state, never runnable. Reconcile it from LEDGER/NOTES into one of the valid forms above before selection; if its disposition is ambiguous, mark it blocked with the exact evidence or user decision needed to unlock it.
- Continue while a runnable pending task exists. A blocked task does not make later work runnable by itself; normal phase dependencies still apply.
- Size each task to fit comfortably in one iteration of one context window.
- Verification plans prove acceptance with the **smallest non-redundant command set**. A composite check may provide fresh evidence for every scenario whose action and observable it actually exercises with failure propagation; do not rerun covered leaf checks for bookkeeping. A literal user-facing action still runs directly when transitive invocation would not prove that entrypoint.
- The executor may **append** genuinely missing implementation work discovered mid-flight (log the addition in LEDGER), but never appends a separate fix task plus replay/verification task for the same defect — verification stays with the implementation task. Supersede dead work only with the checked + struck form above; never rewrite phase goals or delete history. Scope changes belong to the user alone; the executor may record only an explicit bounded review patch under the Completion flow, exactly within the user's stated delta.
- Reopening responsible work means un-ticking only the current non-superseded owner whose completion evidence was invalidated. If none exists, append one genuine implementation task under the rule above. Never un-tick a superseded row.

## LEDGER.md — append-only

The roadmap holds _what_; the ledger holds _evidence and learnings_. Ticking never destroys history — a fresh session reads the ledger tail to learn what actually happened, in what order, and what to avoid.

```markdown
### YYYY-MM-DD HH:MMZ — <event> <task-id or scope>

- Evidence: <command run → observed result; file:line touched>
- Surprise/Decision: <optional — what diverged from the roadmap and why>
```

Events: `run-started`, `task-started`, `task-completed`, `validation-failed`, `phase-validated`, `task-blocked`, `replanned`, `delegated`, `circuit-breaker`, `rotation-checkpoint`, `scope-change` (user-initiated only), `final-gate`. Never edit or delete prior entries.

Every `final-gate` entry records `mode: full-baseline | scoped-review`. A full baseline names why it ran (`initial`, `material-amendment`, or conservative fallback), the fresh scenario evidence, and the revision or worktree state proved. A scoped review names the latest successful `final-gate` evidence state it extends, the actual changed surface, `executed` checks, scenarios `covered` by those checks, evidence `reused` from that state, and why each reused scenario is outside the impact closure. Every successful gate also records the resulting revision or bounded worktree fingerprint it proved, then becomes the cumulative baseline for the next review change; the chain must remain rooted in an identifiable full baseline. For a dirty worktree, the fingerprint is the base revision plus mission-relevant changed paths and content digests; exclude secrets, ignored live state, and unrelated user files. This record, not chat memory, makes repeated evidence reuse auditable.

An unmatched `task-started` or `delegated` (no later `task-completed`, `validation-failed`, `task-blocked`, supersession, or consumed delegated result) is the crash-recovery marker: it tells a resuming session exactly what was in flight when the previous one died or compacted.

## NOTES.md — the mission's working memory

The ledger answers _what happened, in order_; NOTES answers _what every future iteration must know_. It is the spec-layer equivalent of a task file's Memory Hints + Decision Log — declarative and curated, re-read at every iteration, where the ledger's tail scrolls away.

```markdown
# NOTES — <Mission Title>

## Orientation

- `path/to/...` — role in this mission (key files, helpers to reuse, where things live)

## Constraints & Pitfalls

- <non-obvious constraint or trap discovered, and how to avoid it>

## Current Acceptance Delta

- None. <!-- Or: <S# or named review/final-gate check>: <observed failure or user-approved bounded delta>; baseline: <latest successful final-gate>; provisional impact: <S#/checks>; owner: <task-id>; last attempt: <material change> → <result>; next: <materially different hypothesis/check, or blocked> -->

## Decisions

- (YYYY-MM-DD HH:MMZ) <what was chosen> — <why; what was rejected>

## Open Questions / Deferred

- <question awaiting the user, or work deliberately pushed past this mission>
```

- **Seeded by `$codex-spec`** from planning-time exploration; **grown by the executor** whenever a finding or mid-flight decision matters to this mission. Route by kind: evidence → LEDGER; WIP, proposals, mission state, and uncertain discoveries → NOTES.
- **Scope-check as you write**: a candidate that may outlive the mission gets flagged in place — `→ graduate: knowledge/` for descriptive facts, `→ graduate: $codex-learn` for recurring behavior. Checkpoint bulk-evaluates flags at rotations and close.
- **Curated, not append-only**: rewrite or drop entries that stopped being true. Hard ceiling 150 lines — past it, distill rather than moving unverified material into another tier.
- **Current Acceptance Delta is not a score or a second roadmap.** Keep only currently contradicted/unproven acceptance surfaces, keyed by stable SPEC scenario id or named phase/final-gate check. For a review back-edge, also keep the latest successful `final-gate` baseline and provisional impact set so a rotated session cannot silently broaden or shrink verification; recompute that set from the actual changed surface before the scoped gate. Record the responsible task as `owner`, never as the key, so replanning cannot erase failure history. Keep the last material attempt and result plus the next materially different attempt; reset to `None` only when every scenario again has valid evidence. A new task, owner, or tick alone does not shrink the delta.
- Decisions that change _approach_ belong here; decisions that change _scope_ belong to the user in SPEC.md — never blur the two.

### Knowledge-maintenance exception

NOTES remains the default home for mission-local and uncertain material. A direct knowledge mutation is allowed only when the full capture gate and one of `knowledge-management.md`'s immediate-promotion triggers pass. Scope may be narrow. Read that rule in full, patch the existing owner first, update its reachable route atomically, and run `bash .codex/scripts/knowledge-check.sh --root .`. This exception does not authorize implementation code during a read-only spec state.

## Standing Approval — the one human gate that replaces many

The user approves **SPEC + ROADMAP once** ("go" / "approved" / "ok làm đi" → status `ready`). That signal is a _standing approval_ covering every task and phase in the roadmap. **This is an explicit exception to `task-management.md`'s per-task gates**: inside a `running` spec the executor does not ask permission per task or per phase, does not park at `awaiting-review` between phases, and does not create task files.

Approval also fixes the **commit policy** (`commits:` in SPEC frontmatter): `user` (default — the executor never runs `git commit`; the user commits at rotations and gates), `per-task` or `per-phase` (the executor commits at each tick / phase close, message `spec(<slug>): <summary>`, so a long run always has restore points). The grant covers `git commit` only — never push, never history rewrites, regardless of policy.

Planned human interaction points are exactly three:

1. **Approval** — user reviews POC + SPEC + ROADMAP, says go.
2. **Rotation offers** — see Session Rotation below (user picks the stopping moment; the work itself never blocks on them).
3. **Final gate** — `awaiting-final-review` at mission end; the user, not the agent, confirms `done`.

Everything else stays autonomous. A task blocker stops that task; it stops the whole loop with a report only when no independent runnable work remains. Treat scope questions and SPEC-acceptance ambiguity as blockers on the affected work: record the missing decision and exact unlock condition in its ROADMAP row and Current Acceptance Delta, continue independent runnable work, and take the canonical `blocked` transition below when none remains. The executor never resolves scope by guessing.

## The Loop (per iteration)

1. **Re-orient.** Read `SPEC.md`, `ROADMAP.md`, `NOTES.md`, and the LEDGER tail (~30 lines). Never trust session memory of earlier iterations — after any compaction, these files are the only truth.
2. **Pick** the first runnable pending task whose dependencies are satisfied. Skip tasks marked `⚠ blocked` and invalid legacy struck-unticked rows; they are not runnable and keep their phase incomplete. Independent tasks in the same wave may fan out in parallel.
3. **Execute.** Append `task-started` to the LEDGER before touching code — a mid-task compaction must be able to see what was in flight. Work solo, or delegate under the active harness policy and `agent-delegation.md`; roadmap wave markings carry a prepared strategy, not a separate permission gate. Record each spawn as a `delegated` LEDGER entry (unit, expected output) so a compaction never orphans a running worker — the LEDGER plays the role the active task file plays for `$codex-plan` work. Worker prompts are self-contained (Goal / Boundary / Scope / Non-overlap / Constraints / Output — carry the roadmap task text and relevant SPEC lines; the worker has no other context).
4. **Verify on a real surface.** Run the task's `verify:`. Tests alone never prove user-facing behavior — drive the app, open the page, compare UI against the POC artifact. A worker's "done" is a claim to check, not a result to record.
5. **Tick and log.** Flip `- [ ]` → `- [x]`, re-read to confirm the intended task changed state, append a `task-completed` LEDGER entry with evidence, bump `updated:` in SPEC frontmatter. Clear any Current Acceptance Delta this evidence actually resolves. Route mission-local constraints, pitfalls, decisions, and knowledge candidates into `NOTES.md`; promote an eligible fact immediately only under the knowledge-maintenance exception.
6. **Phase boundary**: run the phase validation. On PASS, tick the SPEC scenarios it proves, clear the resolved delta, append `phase-validated`, then make a rotation offer. On FAIL, do not close the phase: append `validation-failed`, update Current Acceptance Delta, and reopen responsible work under the ROADMAP rule above. Never create a separate replay/verification task. Then continue under the convergence rules below.

## Convergence & Circuit Breakers

- **Progress means an acceptance surface cleared, or its remaining failure/diagnosis narrowed enough to change the next action.** Appending a task, ticking a checkbox, renaming/replacing its owner, or gathering more evidence that only confirms the same gap does not count.
- **A retry must be materially different.** Before retrying a failed acceptance, record in Current Acceptance Delta what changes in the hypothesis, implementation, or verification. If there is no evidence-backed difference to try, do not repeat the attempt: mark the responsible roadmap task `⚠ blocked` with its condition and unlock requirement, append `task-blocked` plus the diagnosis, and move to the next independent runnable task.
- **Stronger contradictory evidence invalidates a green check.** "Stronger" means it exercises the SPEC's exact action and observable more directly or under more representative conditions; disagreement alone is not evidence. Un-tick the affected scenario, reopen responsible work under the ROADMAP rule, append `validation-failed`, and treat the old verifier as insufficient. Do not use that same check as the sole proof again until its coverage is repaired or replaced.
- **Evidence follows semantic impact, its verifier, and its dependency surface.** Changing a verifier invalidates the evidence it produced. A change that can alter a shared runtime, public interface, dependency/lockfile, migration/schema, authentication/security boundary, global build/test behavior, or another cross-cutting contract expands the impact set accordingly; merely touching a broadly named path does not. If the executor cannot defend the boundary from the actual semantic change, it falls back to the full baseline gate.
- **Two exploration passes with no new facts** → stop researching and act on what is known; if no defensible action remains, block as above.
- **No runnable task remains while a blocker is unresolved** → append `circuit-breaker`, set SPEC status to `blocked`, sync INDEX, and stop with the diagnosis and exact unlock condition.

A tripped breaker is a stop-and-report, never a silent retry loop and never a reason to weaken a `verify:`. An explicit user- or runtime-level budget remains authoritative, but this workflow does not invent mandatory resource estimates or a separate attempt-accounting system.

**Unblocking is `$codex-spec-run` again — typically from a stronger session.** The executor is model-agnostic: run the loop on a cheap model for routine work; when a task defeats it, the escalation is the _same command_ in a stronger session, not a side-channel. That session's `blocked` gate enters unblock mode: read the `task-blocked`/`circuit-breaker` diagnosis and Current Acceptance Delta, then investigate. If it has a materially different path, clear the task's `⚠ blocked` marker, keep it unticked, flip back to `running`, sync INDEX, and execute it under the standing approval. If the old task is no longer the right approach, mark it `- [x] ~~...~~ — superseded by <replacement/reason>`, append only the decision-complete replacement work actually needed, record the decision and why in NOTES, log `replanned`, flip back to `running`, and sync INDEX. Then offer: continue here, or rotate so a cheaper session resumes. Never hand the fix over as a pasted prompt or chat instructions: the amendment travels through ROADMAP/NOTES/LEDGER like everything else, and the next `$codex-spec-run` picks it up from disk.

## Session Rotation

Long sessions degrade (context pressure, compaction, host lag). Rotation is the designed unit of work, not an emergency:

- **Offer rotation** at every phase boundary; mid-phase whenever a compaction occurred or context feels degraded (finish the in-flight task first); and in any case after ~8-10 completed tasks inside a long phase — don't wait for degradation to show.
- The offer: report current phase, task inventory (`n/m`), and Current Acceptance Delta, then ask: _checkpoint and rotate now, or continue?_
- **On yes**: append a `rotation-checkpoint` LEDGER entry (one-line state + exact next task), bump `updated:`, then run the `$codex-checkpoint` flow — it syncs the specs INDEX, refreshes CONTEXT's spec pointer, and collects NOTES' `→ graduate:` flags — and tell the user: open a fresh session, orient with `$codex-start`, and run `$codex-spec-run <slug>`.
- **On no**: continue the loop.
- Do **not** write `.codex/HANDOFF.md` for spec work — SPEC + ROADMAP + NOTES + LEDGER _are_ the baton, and the loop is amnesia-first by design.

## Pausing & Interrupting

**Stopping anytime is safe by design.** A user interrupt is indistinguishable from a crash: the loop's re-orientation rebuilds state from disk, and an unmatched `task-started`/`delegated` entry marks the in-flight work to verify before redoing. No need to wait for a rotation offer — a tick boundary is cleanest, but mid-task is recoverable.

## Completion — Final Gate

When every roadmap task is completed or explicitly superseded and no unresolved blocked task remains:

1. Choose the gate mode:
   - **Full baseline** — when the mission has no successful full-baseline `final-gate`, or a material amendment received renewed approval. Establish fresh evidence for **every** Acceptance Scenario, but use the smallest non-redundant command set: one composite check may cover several scenarios when it actually exercises their actions and observables with failure propagation.
   - **Scoped review** — only after returning from `awaiting-final-review` for an anchored defect or an explicit bounded review patch. Start from the latest successful `final-gate` cumulative evidence state, verify that its chain still reaches an identifiable full baseline, recompute the impact closure from the actual changed files, interfaces, configuration, dependencies, and verifiers, then run fresh only the affected scenarios plus the smallest relevant consumer/integration checks. Carry forward evidence for unaffected scenarios only with an explicit exclusion rationale. If the cumulative baseline is not identifiable or the boundary is uncertain, use the full baseline mode.
2. Append `final-gate` with its mode, resulting revision or bounded worktree fingerprint, and the required baseline/executed/covered/reused evidence. Reset Current Acceptance Delta to `None` only when every scenario has valid PASS evidence. If any required fresh check fails or retained evidence is invalidated, follow the failure path below.
3. Flip status → `awaiting-final-review`, sync INDEX, and report: how to demo (exact steps), scenario results split into fresh/covered/reused evidence, and anything deferred.
4. **STOP.** `awaiting-final-review` is a read-only lock (as `awaiting-review` in `task-management.md`) until the user confirms completion or explicitly requests a review change.
5. User confirms → `done`: flip `status: done`, append one line to `.codex/JOURNAL.md` (`YYYY-MM-DD | completed | spec <slug> — <one-line outcome>, see specs/done/YYYY-MM-DD-<slug>/SPEC.md`), and sweep `NOTES.md` before shelving — evaluate remaining `→ graduate: knowledge/` candidates against the full capture gate, write eligible facts under the atomic owner/map contract, run the checker after mutations, and leave uncertainty in NOTES; propose `$codex-learn` for behavioral lessons. Then move the entire folder from `.codex/specs/YYYY-MM-DD-<slug>/` to `.codex/specs/done/YYYY-MM-DD-<slug>/` and sync INDEX.

If the user reports a problem or requests a change at `awaiting-final-review`, classify it before unlocking:

- **Anchored defect** — the observed result contradicts an exact approved SPEC scenario, Must-NOT-Have clause, or POC observable. Return to `running`, record the latest successful `final-gate` baseline plus provisional impact set in Current Acceptance Delta, un-tick only affected scenarios, reopen responsible work, append `validation-failed`, sync INDEX, and later run one scoped review gate.
- **Bounded review patch** — the user explicitly requests a concrete, decision-complete delta that fits one narrow implementation unit, conflicts with no POC or Must-NOT-Have, introduces no unresolved product/design choice, and has effects that remain inside a defensible local boundary. The request itself approves only that delta: record it verbatim as a `scope-change`, update SPEC with its exact binary observable, append the smallest necessary ROADMAP work, record the baseline and provisional impact set in Current Acceptance Delta, flip to `running`, and sync INDEX. Implement only the direct dependency closure and proof required by the request; do not add adjacent hardening, documentation, refactors, or quality gates merely because they seem beneficial.
- **Material or ambiguous amendment** — anything that cannot satisfy the bounded-patch test remains under the read-only lock. Surface the scope delta and ask whether to amend the SPEC. On explicit yes, flip to `drafting`, sync INDEX, and return control to `$codex-spec` for amendment and renewed approval.

Never infer a defect from broad language such as "quality", "production-ready", or Definition of Done alone: quote the exact approved anchor. Never append mechanical fix/replay task pairs.

If any required evidence fails, the mission is **not** complete: append `validation-failed`, update Current Acceptance Delta, and reopen responsible work under the ROADMAP rule. Never add validation bookkeeping as a task. Keep looping under the convergence rules. Never present a failing scenario as "done with caveats".

## Status State Machine

```
drafting ──(POC + SPEC + ROADMAP written, presented)──▶ poc-review
poc-review ──(user requests changes)──▶ drafting
poc-review ──(user approves: standing "go")──▶ ready
ready ──($codex-spec-run picks it up)──▶ running
running ──(all tasks completed/superseded; no blocker; full-baseline/scoped-review PASS)──▶ awaiting-final-review
awaiting-final-review ──(user confirms)──▶ done
awaiting-final-review ──(anchored defect or explicit bounded review patch)──▶ running
awaiting-final-review ──(user approves a material scope amendment)──▶ drafting
running ──(blocker; nothing independent left)──▶ blocked ──(cleared)──▶ running
{any active} ──(user cancels)──▶ cancelled
```

- `drafting` / `poc-review`: `$codex-spec` owns these; **no implementation code may be written** — only spec-folder files and artifacts.
- `ready`: approved, not yet started. `running`: the loop is live. Both belong to `$codex-spec-run`.
- `awaiting-final-review`: read-only lock; waiting on the user's demo verification. Only completion confirmation, an anchored defect, an explicit bounded review patch, or an approved return to drafting changes state.

## INDEX.md

```markdown
<!-- .codex/specs/INDEX.md — registry of spec missions. Maintained by $codex-spec, $codex-spec-run, $codex-checkpoint. -->

## Active

- [<slug>](YYYY-MM-DD-<slug>/SPEC.md) — <status> — updated <YYYY-MM-DD> — <goal one-liner>

## Done

- [<slug>](done/YYYY-MM-DD-<slug>/SPEC.md) — <done|cancelled> <YYYY-MM-DD>
```

SPEC frontmatter is the source of truth; INDEX is a cache. Active lists status ∈ {drafting, poc-review, ready, running, blocked, awaiting-final-review} from top-level dated folders — append ` ⏳ awaiting your review` to `poc-review` and `awaiting-final-review` lines. Done lists status ∈ {done, cancelled} from `.codex/specs/done/`. A top-level folder whose SPEC status is `done` or `cancelled` is stale and must be archived before INDEX is rewritten. Spec folders are never deleted.

## Relationship to the Rest of CLAUDART

- **Tasks**: a spec replaces `$codex-plan` for its scope. Never mirror roadmap tasks into `.codex/tasks/`; never run both layers over the same work.
- **CONTEXT.md**: may carry one pointer line (`Running spec \`<slug>\` (see .codex/specs/YYYY-MM-DD-<slug>/SPEC.md)`); never absorbs spec content.
- **`$codex-start`**: surfaces Active specs from INDEX and directs the user to `$codex-spec`, `$codex-spec-run`, or final verification according to status.
- **`$codex-checkpoint`**: syncs INDEX from SPEC frontmatter, same as it syncs `tasks/index.md`.
- **knowledge/**: read at `$codex-spec` planning time using map-first bounded routing. Mid-run discoveries default to NOTES candidates. The executor may write an eligible fact directly only under the knowledge-maintenance exception; otherwise checkpoint bulk-evaluates flags at rotation and close.
- **guidelines/**: the executor obeys them but never edits them mid-loop. A recurring behavioral lesson (the same correction needed twice) gets a NOTES flag `→ graduate: $codex-learn`, proposed at rotation or mission close — guideline changes stay user-gated.

## Anti-Patterns

- Asking permission per task or per phase while `running` — the standing approval exists precisely so the loop never blocks on the user.
- A roadmap that needs interview context ("as discussed", "the style we agreed on") — decision-complete or defective.
- Code snippets in the roadmap (see Plan Altitude), or an executor "improving" SPEC acceptance criteria.
- Ticking a box without running its `verify:`, or trusting a subagent's "done" without re-verifying.
- Rewriting or deleting LEDGER history; rewriting phase goals instead of appending/striking tasks.
- Burying durable knowledge in the LEDGER tail instead of NOTES.md — the ledger scrolls away; NOTES is what every iteration re-reads.
- Writing `HANDOFF.md` for spec work, or mirroring spec state into `tasks/index.md`.
- Counting appended tasks or fresh ticks as progress while the same acceptance failure remains.
- Retrying a failed acceptance without a materially different hypothesis, implementation, or verification.
- Reusing a green check as sole proof after stronger evidence contradicted it.
- Replaying unrelated scenarios after a bounded change, re-running leaf checks already proved by a qualifying composite check, or carrying evidence forward without an identifiable full baseline and impact rationale.
- Expanding a bounded user request into adjacent hardening, documentation, refactors, or extra quality gates that its observable and direct dependency closure do not require.
- Appending fix/replay task pairs instead of keeping verification with the responsible implementation task.
- Continuing past a tripped circuit breaker or selecting a task marked `⚠ blocked`.
- Marking the mission done (or presenting the demo) while any Acceptance Scenario is unproven.
