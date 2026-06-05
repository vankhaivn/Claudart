---
paths: ["**/*"]
description: Claude Code subagent delegation protocol — project judgment layered on top of the Agent tool's built-in mechanics.
when_to_use: When the user explicitly authorizes subagents, delegation, or parallel agent work, or when planning a Claude task that may benefit from such authorization.
tags: [subagents, delegation, parallelism, orchestration]
---

# Agent Delegation

The Agent tool is a parallel-work capability, not a default behavior. Use it only when the user explicitly asks for subagents, delegation, or parallel agent work. Requests for depth, thoroughness, investigation, or "be comprehensive" are not authorization by themselves.

**This rule does not restate the harness.** Claude's Agent tool already encodes the mechanics — when to delegate, launching parallel agents in a single message, `SendMessage` to continue a thread, `run_in_background`, `isolation: worktree`, and crucially: _"once you've delegated a search, don't also run it yourself — wait for the result."_ This rule adds only the project-specific judgment on top: the decomposition gate, the overlap test, the no-silent-hedge rule, and how delegated findings persist into CLAUDART memory.

This protocol governs general-purpose delegation (`subagent_type: general-purpose`, `Explore`, `Plan`). Project review agents (`clean-code-reviewer`, `security-auditor` under `.claude/agents/`) carry their own instructions and are invoked by name; they are out of scope here.

## Delegation Gate

Before spawning a subagent, write a short decomposition:

- **Main agent critical path**: the next work the parent session will do locally.
- **Sidecar tasks**: bounded tasks that can run in parallel without blocking that critical path.
- **Ownership**: exact files, modules, or read-only question each subagent owns.
- **Merge plan**: how returned findings or patches will be reviewed and integrated.

Do not spawn if the next parent step is blocked on the subtask. Do that work locally instead.

## Pre-authorized Delegation (task-file `delegation:` field)

The "explicit authorization" requirement above can be satisfied **at planning time** and persisted, not only at runtime. When a `/plan` task records `delegation: authorized` in its frontmatter, the user authorized subagents for execution during planning — the approval signal ("go") then activates delegation **without a second request**. `delegation: strategy-only` means a strategy is recorded but only _discussed_, not authorized: make a single one-line offer at "go" before spawning. See `task-management.md` → "Delegation Authorization" for the field's full semantics.

The authorization bar itself is unchanged. A _question_ about subagents ("can they handle the non-conflicting parts?") is `strategy-only`, not `authorized`; only an explicit instruction to use them for the work sets `authorized`. Persisting the decision removes the redundant re-confirmation, not the gate.

## Delegate-and-Consume vs. Delegate-and-Continue

The deciding signal is **task structure, not the user's exact words.** Before spawning, ask: _does the request decompose into work genuinely separate from the delegated question, or IS the delegated question the whole task?_

- **Whole task** — the delegated question is the entire request (a single read-only investigation, one bounded fix) → **spawn, then wait and consume the result.** Do NOT shadow-run the same investigation yourself. The harness already says this for searches; it holds for any single delegated unit. Racing it pays for one answer twice and duplicates the subagent's work.
- **Decomposable** — the request splits into disjoint units → either **fan out one agent per unit in a single message**, or advance a genuinely non-overlapping part yourself while a subagent owns another. Claude lets the parent work in parallel, so both shapes are valid — the constraint is non-overlap, not who does the work.

Infer this from what the request _decomposes into_, never from a magic phrase. "Launch an agent to check X and tell me what it finds", "giao cho 1 agent điều tra repo Y", "delegate this audit and read its output" all describe **one delegated unit with no separate parent work** — the same shape, regardless of wording. The reliable tell is **overlap of the same sub-question**: if your own next step (or another agent) would answer the _same_ sub-question this agent owns, that is redundancy, not parallelism — collapse it.

Redundancy is acceptable only when **deliberate and disclosed**: independent review (intentionally asking N agents the same question to cross-check), or a hedge the user authorized on a flaky path. The anti-pattern is _silent, unrequested_ duplication. In particular, if you are unsure the Agent tool will honor a constraint — e.g. a `model` override — **surface that constraint and choose one path** (delegate or do it locally), or ask. Never hedge by silently running both.

## Worker Prompt Contract

A subagent does not inherit the parent's conversation — it sees only the spawn prompt. The most common failure is a prompt that assumes shared knowledge. Make every prompt self-contained: carry the file paths, the exact question, and the constraints into the prompt itself.

Every worker prompt must include: **Goal** (the exact user-visible outcome), **Scope** (files the worker may edit), **Non-overlap** (other agents may be changing nearby code; do not revert their work), **Constraints** (tests, style, security, compatibility), and **Output** (a structured result the parent can consume directly — changed files, the validation command and its result, residual risks; for a read-only explorer, findings anchored to `file:line`, not prose). Prefer read-only explorers before workers when ownership is unclear.

## Parent Responsibilities

The parent session remains responsible for the final result. Beyond the harness mechanics:

- The subagent's final message returns to you as the tool result and is NOT shown to the user — relay what matters.
- Review subagent outputs and integrate only the useful parts; do not treat a subagent patch as final without parent review and validation.
- Run the relevant validation yourself, or verify the validation evidence is trustworthy.
- Persist important subagent findings in task files; use `/checkpoint` for active `CONTEXT.md` handoffs or eventual `JOURNAL.md` entries. Do not rely on subagent thread history for persistence.

## Task Documents

For planned work, capture delegation under `## Plan of Work` or `### Memory Hints`, not a separate schema section. Include: whether the user authorized subagents; intended roles; read/write ownership boundaries; validation and review responsibilities; any concurrency or cost limits. If the user did not authorize subagents, note only "Delegation opportunity: <short idea>" when it would materially help later.

## Safety And Cost

- Keep delegation one level deep unless the user explicitly asks for recursive delegation.
- Use read-only subagents (`Explore`) for any read-only delegation whenever possible.
- Give parallel writers `isolation: worktree` so concurrent edits cannot conflict.
- For template/downstream projects, prefer conservative fan-out so a small request does not accidentally launch expensive parallel work.
