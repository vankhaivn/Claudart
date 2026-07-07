---
paths: ["**/*"]
description: Dated mission-scale spec workspaces in `.codex/specs/` with `done/` archives — a POC-frozen SPEC plus a decision-complete ROADMAP that any later session (often a cheaper model) executes autonomously until done, with self-QA, circuit breakers, and session rotation.
when_to_use: Whenever the user invokes `$codex-spec` or `$codex-spec-run`, when a spec folder under `.codex/specs/` is open or referenced, or when resuming mission-scale work that spans many sessions.
tags: [specs, loop-engineering, autonomy, cross-session, missions]
---

# Spec Workflow (Loop Engineering)

A **spec** is a mission: work too large for one task file — a whole game, a feature system, a client-demo POC. While active, it lives as a dated folder in `.codex/specs/YYYY-MM-DD-<slug>/` written once by an expensive planning session (`$codex-spec`), then executed to completion across many sessions by `$codex-spec-run` — often on a cheaper model — **without per-task human approval**. Completed and cancelled missions are archived under `.codex/specs/done/YYYY-MM-DD-<slug>/`. The folder, not any session, is the source of truth; every iteration assumes total amnesia and re-orients from files.

Missions sit **above** the task layer (`task-management.md`): a spec supersedes `$codex-plan` for its scope, and its executor never creates `.codex/tasks/` files. Use `$codex-plan` for a single feature or fix; use `$codex-spec` when the deliverable is a demoable whole.

## File Layout

```
.codex/specs/
├── INDEX.md                    # Registry: one line per spec
├── done/                       # Archive for done/cancelled spec folders
│   └── YYYY-MM-DD-<slug>/
└── YYYY-MM-DD-<slug>/
    ├── SPEC.md                 # What "done" means. Frozen at approval; only the user changes it.
    ├── ROADMAP.md              # Phases → checkbox tasks. The loop counter.
    ├── NOTES.md                # Working memory: orientation, pitfalls, decisions. Curated, re-read every iteration.
    ├── LEDGER.md               # Append-only evidence & history. Never rewritten.
    └── artifacts/              # POC HTML, mockups, generated references
```

- **Naming**: folder id is `YYYY-MM-DD-<slug>`, using the spec creation date and a slug of 2-5 lowercase kebab-case words. `SPEC.md` frontmatter keeps the short `slug: <slug>`; the folder name must equal `<created>-<slug>`. One folder per mission; never nest specs except the single archive folder `done/`.
- **Resolving a spec**: `$codex-spec-run <arg>` accepts either a full folder id (`YYYY-MM-DD-<slug>`) or the short slug. Match active top-level folders first; if a short slug matches more than one active folder, ask the user to choose the dated folder. If the match exists only under `done/`, report its archived status and do not run it.
- **`SPEC.md` holds intent, `ROADMAP.md` holds the plan, `NOTES.md` holds the knowledge, `LEDGER.md` holds the proof.** Cross-link, never duplicate.

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
These are re-run at the final gate; vague scenarios are rejected at approval, not discovered at the end.>

- [ ] S1 — <literal action / command> → <binary observable>
- [ ] S2 — ...

## Must-NOT-Have

<Scope fence. Options the user rejected, features deferred, gold-plating to refuse. The executor treats
this as hard as the acceptance list.>

## POC Artifacts

- `artifacts/<file>` — <what it locks in; e.g. "approved UI reference — layout, palette, HUD placement">

## Definition of Done

Every ROADMAP checkbox ticked AND every Acceptance Scenario re-run PASS.
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

**Phase validation**: <commands/scenarios proving the phase goal on a real surface — which SPEC scenarios it advances>

## Phase 2 — ...
```

- Top-level checkboxes are the **loop counter**: continue while any box is unticked; stop/continue is mechanical, not a judgment call.
- Size each task to fit comfortably in one iteration of one context window.
- The executor may **append** tasks discovered mid-flight (log the addition in LEDGER) and strike dead tasks with `~~text~~` + LEDGER entry — but never rewrites phase goals or deletes history. Scope changes (SPEC edits) belong to the user alone.

## LEDGER.md — append-only

The roadmap holds _what_; the ledger holds _evidence and learnings_. Ticking never destroys history — a fresh session reads the ledger tail to learn what actually happened, in what order, and what to avoid.

```markdown
### YYYY-MM-DD HH:MMZ — <event> <task-id or scope>

- Evidence: <command run → observed result; file:line touched>
- Surprise/Decision: <optional — what diverged from the roadmap and why>
```

Events: `run-started`, `task-started`, `task-completed`, `phase-validated`, `task-blocked`, `replanned`, `delegated`, `circuit-breaker`, `rotation-checkpoint`, `scope-change` (user-initiated only), `final-gate`. Never edit or delete prior entries.

An unmatched `task-started` or `delegated` (no later `task-completed` / consumed result) is the crash-recovery marker: it tells a resuming session exactly what was in flight when the previous one died or compacted.

## NOTES.md — the mission's working memory

The ledger answers _what happened, in order_; NOTES answers _what every future iteration must know_. It is the spec-layer equivalent of a task file's Memory Hints + Decision Log — declarative and curated, re-read at every iteration, where the ledger's tail scrolls away.

```markdown
# NOTES — <Mission Title>

## Orientation

- `path/to/...` — role in this mission (key files, helpers to reuse, where things live)

## Constraints & Pitfalls

- <non-obvious constraint or trap discovered, and how to avoid it>

## Decisions

- (YYYY-MM-DD HH:MMZ) <what was chosen> — <why; what was rejected>

## Open Questions / Deferred

- <question awaiting the user, or work deliberately pushed past this mission>
```

- **Seeded by `$codex-spec`** from planning-time exploration; **grown by the executor** whenever a finding or mid-flight decision is durable. Route by kind: evidence → LEDGER, knowledge → NOTES (the LEDGER entry records _that_ it landed; NOTES records _it_).
- **Scope-check as you write**: knowledge that outlives the mission gets flagged in place — `→ graduate: knowledge/` for project-wide facts, `→ graduate: $codex-learn` for recurring behavior. Flags are collected at rotation checkpoints and mission close (see Relationship below), then cleared.
- **Curated, not append-only**: rewrite or drop entries that stopped being true. Hard ceiling 150 lines — past it, distill, and graduate project-wide facts to `knowledge/` via `$codex-checkpoint`.
- Decisions that change _approach_ belong here; decisions that change _scope_ belong to the user in SPEC.md — never blur the two.

## Standing Approval — the one human gate that replaces many

The user approves **SPEC + ROADMAP once** ("go" / "approved" / "ok làm đi" → status `ready`). That signal is a _standing approval_ covering every task and phase in the roadmap. **This is an explicit exception to `task-management.md`'s per-task gates**: inside a `running` spec the executor does not ask permission per task or per phase, does not park at `awaiting-review` between phases, and does not create task files.

Approval also fixes the **commit policy** (`commits:` in SPEC frontmatter): `user` (default — the executor never runs `git commit`; the user commits at rotations and gates), `per-task` or `per-phase` (the executor commits at each tick / phase close, message `spec(<slug>): <summary>`, so a long run always has restore points). The grant covers `git commit` only — never push, never history rewrites, regardless of policy.

Human interaction points are exactly three:

1. **Approval** — user reviews POC + SPEC + ROADMAP, says go.
2. **Rotation offers** — see Session Rotation below (user picks the stopping moment; the work itself never blocks on them).
3. **Final gate** — `awaiting-final-review` at mission end; the user, not the agent, confirms `done`.

Everything else — blockers, scope questions, SPEC-acceptance ambiguity discovered mid-run — stops the loop with a report; the executor never resolves scope by guessing.

## The Loop (per iteration)

1. **Re-orient.** Read `SPEC.md`, `ROADMAP.md`, `NOTES.md`, and the LEDGER tail (~30 lines). Never trust session memory of earlier iterations — after any compaction, these files are the only truth.
2. **Pick** the first unticked task in the earliest incomplete phase, respecting the roadmap's dependency notes. Independent tasks in the same wave may fan out in parallel.
3. **Execute.** Append `task-started` to the LEDGER before touching code — a mid-task compaction must be able to see what was in flight. Work solo, or delegate per `agent-delegation.md`. Its explicit-authorization gate still applies inside a spec: fan out only where the approved roadmap marks waves for fan-out — the user's standing approval of that marking is the recorded planning-time authorization (as `authorized` in the task-file `delegation:` field); an unmarked task runs solo, and the loop never pauses to offer delegation. Record each spawn as a `delegated` LEDGER entry (unit, expected output) so a compaction never orphans a running worker — the LEDGER plays the role the active task file plays for `$codex-plan` work. Worker prompts are self-contained (Goal / Boundary / Scope / Non-overlap / Constraints / Output — carry the roadmap task text and relevant SPEC lines; the worker has no other context).
4. **Verify on a real surface.** Run the task's `verify:`. Tests alone never prove user-facing behavior — drive the app, open the page, compare UI against the POC artifact. A worker's "done" is a claim to check, not a result to record.
5. **Tick and log.** Flip `- [ ]` → `- [x]`, re-read to confirm the unticked count decreased, append a `task-completed` LEDGER entry with evidence, bump `updated:` in SPEC frontmatter. Route anything durable the task surfaced — a constraint, a pitfall, an approach decision — into `NOTES.md` now; the next iteration re-reads NOTES, not this conversation.
6. **Phase boundary**: run the phase validation, tick the SPEC scenarios it proves, append `phase-validated`, then make a rotation offer. A failing phase validation never closes the phase: append fix tasks to it, log the failure as evidence, and keep looping — the circuit breakers still apply.

## Circuit Breakers

- **Same task fails the same way 3×** → mark it `⚠ blocked` in the roadmap, append `task-blocked` with a diagnosis, and move to the next _independent_ task. If nothing independent remains, stop and report.
- **5 iterations on one phase with no new tick** → stop, append `circuit-breaker` with a diagnosis, report to the user.
- **Two exploration passes with no new facts** → stop researching and act on what is known.

A tripped breaker is a stop-and-report, never a silent retry loop and never a reason to weaken a `verify:`.

**Unblocking is `$codex-spec-run` again — typically from a stronger session.** The executor is model-agnostic: run the loop on a cheap model for routine work; when a task defeats it, the escalation is the _same command_ in a stronger session, not a side-channel. That session's `blocked` gate enters unblock mode: read the `task-blocked`/`circuit-breaker` diagnosis, investigate, then either execute the stuck task directly (the standing approval already covers it) or **re-plan it** — strike the stuck task, append decision-complete replacements, record the decision and why in NOTES, log a `replanned` LEDGER entry — flip back to `running`, and offer rotation so a cheaper session resumes the routine work. Never hand the fix over as a pasted prompt or chat instructions: the amendment travels through ROADMAP/NOTES/LEDGER like everything else, and the next `$codex-spec-run` picks it up from disk.

## Session Rotation

Long sessions degrade (context pressure, compaction, host lag). Rotation is the designed unit of work, not an emergency:

- **Offer rotation** at every phase boundary; mid-phase whenever a compaction occurred or context feels degraded (finish the in-flight task first); and in any case after ~8-10 completed tasks inside a long phase — don't wait for degradation to show.
- The offer: report progress (`n/m` tasks, current phase) and ask: _checkpoint and rotate now, or continue?_
- **On yes**: append a `rotation-checkpoint` LEDGER entry (one-line state + exact next task), bump `updated:`, then run the `$codex-checkpoint` flow — it syncs the specs INDEX, refreshes CONTEXT's spec pointer, and collects NOTES' `→ graduate:` flags — and tell the user: open a fresh session, orient with `$codex-start`, and run `$codex-spec-run <slug>`.
- **On no**: continue the loop.
- Do **not** write `.codex/HANDOFF.md` for spec work — SPEC + ROADMAP + LEDGER _are_ the baton, and the loop is amnesia-first by design.

## Pausing & Interrupting

**Stopping anytime is safe by design.** A user interrupt is indistinguishable from a crash: the loop's re-orientation rebuilds state from disk, and an unmatched `task-started`/`delegated` entry marks the in-flight work to verify before redoing. No need to wait for a rotation offer — a tick boundary is cleanest, but mid-task is recoverable.

## Completion — Final Gate

When every roadmap box is ticked:

1. Re-run **every** Acceptance Scenario in SPEC.md fresh (not from memory of phase validations) and tick them; append a `final-gate` LEDGER entry with the evidence.
2. Flip status → `awaiting-final-review`, sync INDEX, and report: how to demo (exact steps), scenario results, anything deferred.
3. **STOP.** `awaiting-final-review` is a read-only lock (as `awaiting-review` in `task-management.md`).
4. User confirms → `done`: flip `status: done`, append one line to `.codex/JOURNAL.md` (`YYYY-MM-DD | completed | spec <slug> — <one-line outcome>, see specs/done/YYYY-MM-DD-<slug>/SPEC.md`), and sweep `NOTES.md` before shelving — graduate remaining `→ graduate: knowledge/` facts (register in its INDEX), propose `$codex-learn` for flagged behavioral lessons. Then move the entire folder from `.codex/specs/YYYY-MM-DD-<slug>/` to `.codex/specs/done/YYYY-MM-DD-<slug>/` and sync INDEX. User reports a problem → back to `running`: un-tick the affected tasks/scenarios, log the report verbatim in LEDGER, resume the loop.

If any scenario fails at step 1, the mission is **not** complete: append failing tasks to the roadmap and keep looping. Never present a failing scenario as "done with caveats".

## Status State Machine

```
drafting ──(POC + SPEC + ROADMAP written, presented)──▶ poc-review
poc-review ──(user requests changes)──▶ drafting
poc-review ──(user approves: standing "go")──▶ ready
ready ──($codex-spec-run picks it up)──▶ running
running ──(all boxes ticked + final gate PASS)──▶ awaiting-final-review
awaiting-final-review ──(user confirms)──▶ done
awaiting-final-review ──(user reports a problem)──▶ running
running ──(blocker; nothing independent left)──▶ blocked ──(cleared)──▶ running
{any active} ──(user cancels)──▶ cancelled
```

- `drafting` / `poc-review`: `$codex-spec` owns these; **no implementation code may be written** — only spec-folder files and artifacts.
- `ready`: approved, not yet started. `running`: the loop is live. Both belong to `$codex-spec-run`.
- `awaiting-final-review`: read-only lock; waiting on the user's demo verification.

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
- **`$codex-start`**: surfaces Active specs from INDEX and offers `$codex-spec-run` for `ready`/`running` ones.
- **`$codex-checkpoint`**: syncs INDEX from SPEC frontmatter, same as it syncs `tasks/index.md`.
- **knowledge/**: read at `$codex-spec` planning time (INDEX first; relevant entries feed SPEC/ROADMAP/NOTES). Mid-run, a discovery that is true project-wide — beyond this mission — is recorded in NOTES **flagged `→ graduate: knowledge/`**. The executor never writes `knowledge/` directly; flags are collected at the rotation `$codex-checkpoint` and the mission-close sweep.
- **guidelines/**: the executor obeys them but never edits them mid-loop. A recurring behavioral lesson (the same correction needed twice) gets a NOTES flag `→ graduate: $codex-learn`, proposed at rotation or mission close — guideline changes stay user-gated.

## Anti-Patterns

- Asking permission per task or per phase while `running` — the standing approval exists precisely so the loop never blocks on the user.
- A roadmap that needs interview context ("as discussed", "the style we agreed on") — decision-complete or defective.
- Code snippets in the roadmap (see Plan Altitude), or an executor "improving" SPEC acceptance criteria.
- Ticking a box without running its `verify:`, or trusting a subagent's "done" without re-verifying.
- Rewriting or deleting LEDGER history; rewriting phase goals instead of appending/striking tasks.
- Burying durable knowledge in the LEDGER tail instead of NOTES.md — the ledger scrolls away; NOTES is what every iteration re-reads.
- Writing `HANDOFF.md` for spec work, or mirroring spec state into `tasks/index.md`.
- Continuing past a tripped circuit breaker, or retrying an identical failing approach a fourth time.
- Marking the mission done (or presenting the demo) while any Acceptance Scenario is unproven.
