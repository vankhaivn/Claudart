---
name: codex-spec
description: Create a dated mission-scale spec workspace in .codex/specs/ — interview the user, freeze the intent in a reviewable POC artifact, then write a decision-complete SPEC + ROADMAP that a later (often cheaper) session can execute autonomously via $codex-spec-run.
---

# Codex Spec

You are the expensive planning session. Everything you learn from the user in this conversation dies with it — the spec folder you produce is the only thing the executor will ever see. Spend the tokens here so `$codex-spec-run` doesn't have to.

Before doing anything, read `.codex/guidelines/spec-workflow.md`. That guideline defines the folder schema, the SPEC/ROADMAP/NOTES/LEDGER formats, the decision-complete bar, the status state machine, and the standing-approval semantics. This skill does not duplicate that contract; it orchestrates drafting.

## Inputs

- The user's request after `$codex-spec` is the mission description. If empty, ask: "What's the mission?"
- If the request is actually a single feature or fix, say so and suggest `$codex-plan` instead. If it is a raw product idea with no repo and no scope at all, suggest `$codex-project-discovery` first — `$codex-spec` can then build on its `docs/project/` output.

## Procedure

### Step 1 — Read project context

Read: `.codex/CONTEXT.md`, `.codex/specs/INDEX.md` (if an active spec already covers this mission, surface it and ask whether to continue it instead), `.codex/knowledge/INDEX.md`, `docs/project/` if present, and `git log -5 --oneline`. If the user continues an existing `drafting` spec — including an approved final-review scope amendment returned by `$codex-spec-run` — reuse its dated folder; never create a duplicate mission folder.

If planning needs a knowledge route beyond the root index, read `.codex/guidelines/knowledge-management.md` in full and stay within its map/topic/section budget. Do not treat a proposed product state in discovery docs or SPEC as current project knowledge.

Ensure `.codex/specs/done/` exists. Before deciding whether an existing spec is active, check its `SPEC.md` frontmatter status; a top-level spec folder with `status: done` or `status: cancelled` is stale archive state, not an active collision, and should be moved to `.codex/specs/done/` when syncing INDEX.

For a new mission, create `.codex/specs/YYYY-MM-DD-<slug>/` using today's date and the slug rules from the guideline file, write a minimal `SPEC.md` with `slug: <slug>` and `status: drafting`, and register it in `INDEX.md` with the dated folder link. For a resumed draft, keep its existing dated id and history. From here on, the folder is where everything lands — not chat.

**Drafting lock**: while `status` is `drafting` or `poc-review`, write no implementation code and no scaffolding "to save time later". Normally write only the spec folder and `INDEX.md`; the spec guideline's narrow knowledge-maintenance exception remains available when the full capture gate and an immediate-promotion trigger in `knowledge-management.md` pass.

### Step 2 — Interview, capture-as-you-go

Interview like `$codex-project-discovery` (plain questions in chat, one highest-leverage question at a time, options with trade-offs) — but aim every question at one target: **what must a POC prove for the user to say "yes, that's it"?**

**Write every confirmed decision into `SPEC.md` as it lands** — after every few answers, not at the end. The chat does not survive compaction; the spec folder does. Keep the draft's working split visible: confirmed / rejected (→ Must-NOT-Have) / open. By the time you start the POC, the core intent is already on disk.

### Step 3 — POC loop, at the fidelity the user picks

A POC exists so the user can _judge intent_ — it is a reference the executor will later compare against, not an early build of the product. Before building anything, propose the smallest artifact set that proves the riskiest aspects of the mission, and let the user choose its shape:

- Default: one self-contained artifact in `artifacts/` — HTML with inline CSS/JS, no external requests, the user opens it in a browser by double-click.
- For complex missions, prefer **several narrow artifacts over one high-fidelity build** — each freezing a single aspect: one proving the core interaction/feel with primitive placeholders (shapes, boxes, dummy data — no polish), a separate visual-style reference, an annotated flow demo. Wiring every aspect into one polished artifact is drafting-stage overengineering; do it only if the user explicitly opts in.
- Present, collect reactions, revise. Each iteration converts an open question into a confirmed decision or a Must-NOT-Have, and updates **SPEC.md and the artifact together** — a decision that lives only in the POC, or only in chat, is a defect.
- Loop until the user says the set matches their intent. The approved artifacts are then **frozen as references** the executor verifies against — name each one and what it locks in under `SPEC.md → POC Artifacts`.

### Step 4 — Finalize SPEC.md

The skeleton is already half-full from Steps 2-3; finish it. The hard part is **Acceptance Scenarios**: each one a literal action plus a binary observable, executable by someone who never saw this conversation. Keep scenarios non-redundant. When one composite command genuinely exercises several scenario actions/observables with failure propagation, name that coverage instead of planning to replay the same leaf checks mechanically; keep a direct run where the literal user-facing entrypoint itself is part of acceptance. Push every rejected option and deferred feature into **Must-NOT-Have** — that section is what stops a cheaper executor from gold-plating or wandering.

### Step 5 — Write ROADMAP.md (decision-complete)

Explore the codebase read-only first (existing patterns, constraints, files each phase will touch) — de-risk decisions, don't pre-solve implementation. Use read-only `explorer` subagents for a broad survey when the active harness policy and `.codex/guidelines/agent-delegation.md` make that decomposition useful.

Then write phases per the guideline file. Hold the decision-complete bar: exact paths, chosen approaches with the _why_, per-task `verify:`, phase validation commands, the SPEC scenarios each phase advances, any composite verification coverage, and the smallest non-redundant final verification set. Mark parallelizable waves for fan-out only where the prepared decomposition genuinely helps; a wave records strategy for a later harness, not permission. Phase 1 should reach something demoable early — the mission must produce visible progress every phase, not a big-bang integration at the end.

For a new mission, seed `LEDGER.md` with its header and no entries, and `NOTES.md` with what exploration surfaced: how to run, build, and verify the project (dev server, test commands), key files and helpers, non-obvious constraints, pitfalls, planning-time decisions with their rejected alternatives. Include `## Current Acceptance Delta` with `- None.`; it stays compact during execution and is never a second roadmap. For a resumed scope amendment, preserve LEDGER history and existing NOTES, then amend ROADMAP using its disposition rules rather than erasing completed or superseded work. NOTES is the executor's Memory Hints — a roadmap without it forces the executor to re-discover everything you just learned.

### Step 6 — Fresh-eyes check, then present for review

Re-read SPEC.md and ROADMAP.md as if this conversation never happened, pretending you are the cheaper executor. Any task that needs interview context, any scenario that isn't binary, any duplicated leaf/composite verification with no distinct observable, any ambiguous coverage, or any "as discussed" — fix it in the file now. Flip `status: drafting → poc-review`, sync INDEX, and report:

```
## Spec Ready for Review

**Folder**: `.codex/specs/YYYY-MM-DD-<slug>/`
**POC**: `artifacts/<file>` — open it and check it still matches your intent
**Scenarios**: <n> acceptance scenarios | **Roadmap**: <m> phases, <k> tasks
**Commit policy**: `commits: user` — the loop never commits; say "per-task" or "per-phase" before approving if you want git checkpoints during the run
**Open questions**: <list, or "none">

Review SPEC.md (especially Must-NOT-Have) and ROADMAP.md. When you approve, that is a STANDING
approval: $codex-spec-run will execute the whole roadmap without asking again until the final review.
Say "go" to approve — then open a fresh session, $codex-start, and $codex-spec-run <slug> (or the dated folder id if there are multiple active specs with the same short slug).
```

Do NOT begin implementing, even after approval — on "go", flip `status → ready`, sync INDEX, and stop. Execution belongs to `$codex-spec-run`.

## Anti-Patterns

- Writing implementation code during `drafting`/`poc-review` — POC artifacts are the only runnable things this skill produces.
- Batching spec-writing to the end of the interview — confirmed decisions land in SPEC.md immediately; a compaction must never erase what the user already settled.
- Presenting a spec for approval that no POC ever proved — prose alone drifts; the artifact is how intent gets frozen.
- One monolithic high-fidelity POC when narrow artifacts would answer the same questions — fidelity is the user's call, never the default.
- Acceptance scenarios that need judgment ("looks polished") instead of observation ("HUD matches artifacts/poc.html layout").
- Acceptance scenarios or phase gates that mechanically repeat checks already covered by a composite verifier without proving a distinct observable.
- Leaving decisions in chat instead of the spec folder. The folder is the plan.
- Treating enthusiasm ("great POC!") as the standing approval — wait for an explicit go signal.
