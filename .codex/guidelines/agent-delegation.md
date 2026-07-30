---
paths: ["**/*"]
description: Codex subagent delegation protocol — how to decompose work, write self-contained worker prompts, avoid shadow-running delegates, and integrate results from the built-in explorer/worker agents.
when_to_use: When work may parallelize across subagents, when planning a task that records a delegation strategy, or when consuming results returned by delegated agents.
tags: [subagents, delegation, parallelism, orchestration]
---

# Agent Delegation

**Trust the harness on _whether and when_ to delegate.** Codex spawns subagents from a direct request or an applicable project or skill instruction, and at the Ultra intelligence level it delegates proactively — deciding on its own when suitable independent work should parallelize. Reach for subagents when work parallelizes, when a search spans many files, when an independent investigation can run on the side. Requests for depth, thoroughness, or "be comprehensive" are normal grounds to fan out; this guideline does not gate that decision and does not require the user to pre-authorize routine delegation.

**What this rule adds is the _how_, not the _whether_**: how to decompose work, how to avoid shadow-running a delegate, how to write a self-contained worker prompt, and how delegated findings persist into CLAUDART memory. One practical caveat: below Ultra, instruction-triggered spawning is newer and less proven than a direct request — if an expected fan-out does not materialize, name the delegation explicitly ("spawn one explorer per module …") instead of assuming the harness acted on this file.

This protocol governs the built-in `explorer`/`worker`/`default` delegation pattern. Project-specific custom agents (defined under `.codex/agents/`) carry their own instructions and are invoked directly by name when the user asks for them; they are out of scope here.

## Decompose before you fan out

When a task is a candidate for delegation, sketch a short decomposition first — this is strategy guidance, not a permission gate:

- **Main agent critical path**: the next work the parent Codex session will do locally.
- **Sidecar tasks**: bounded tasks that can run in parallel without blocking that critical path.
- **Ownership**: exact files, modules, or read-only question each subagent owns.
- **Merge plan**: how returned findings or patches will be reviewed and integrated.

Do not spawn if the next parent step is blocked on the subtask — that is the dependency test below, not reluctance to delegate. Do blocked work locally; fan out genuinely independent work freely.

## The task-file `delegation:` field records strategy, not permission

The `$codex-plan` task-file `delegation:` field carries a **recorded delegation strategy** from planning into execution — it is a hint, not an authorization switch. The harness still decides whether to delegate at run time; the field just pre-loads a plan so a good decomposition isn't re-derived.

- **`none`** — no specific strategy recorded. On "go", use harness judgment: delegate if the work genuinely parallelizes, run solo if it doesn't. `none` is _not_ an instruction to avoid subagents.
- **`strategy-only`** — a decomposition is recorded as a hint (in Plan of Work / Memory Hints). On "go", proceed by harness judgment, applying the recorded strategy where it fits. No mandatory permission round-trip.
- **`authorized`** — the user recorded a specific delegation plan they want followed. On "go", begin per that plan directly and say you are following the recorded strategy.

This section is the single source of truth for the field's values; `task-management.md` → "Approval Signal" only describes how "go" carries the field into execution.

## Delegate-and-Consume vs. Delegate-and-Continue

The deciding signal is **task structure, not the user's exact words.** Before spawning, ask: _does the request decompose into work genuinely separate from the delegated question, or IS the delegated question the whole task?_

- **Whole task** — the delegated question is the entire request (a single read-only investigation, one bounded fix) → **spawn, then wait and consume the result.** Do NOT shadow-run the same investigation in the parent thread. Codex already pauses to consolidate subagent results (_"waits until all requested results are available"_); racing it locally pays for one answer twice and duplicates the subagent's work.
- **Decomposable** — the request splits into disjoint units → either **fan out one subagent per unit** (each owning a non-overlapping file set or sub-question), or advance a parent-owned lane that was named before spawning and provably needs nothing from delegated output. Multi-subagent fan-out is the normal parallel idiom; parent work is valid only under that independence test.

Infer this from what the request _decomposes into_, never from a magic phrase. "Spawn an explorer to check X and tell me what it finds", "giao cho 1 agent điều tra repo Y", "delegate this audit and read its output" all describe **one delegated unit with no separate parent work** — the same shape, regardless of wording. The reliable tell is **overlap of the same sub-question**: if your own next step (or another subagent) would answer the _same_ sub-question this subagent owns, that is redundancy, not parallelism — collapse it.

Redundancy is acceptable only when **deliberate and disclosed**: independent review (intentionally asking N agents the same question to cross-check), or a hedge the user authorized on a flaky path. The anti-pattern is _silent, unrequested_ duplication. In particular, if you are unsure the subagent will honor a constraint — e.g. a per-agent `model` override — **surface that constraint and choose one path** (delegate or do it locally), or ask. Never hedge by silently running both.

## Good Uses

- Use `explorer` for read-heavy, specific codebase questions: entry points, call paths, test locations, ownership maps, and risk scans.
- Use `worker` for bounded patches with disjoint write scopes. Tell every worker that other agents may be changing nearby code and they must not revert others' work.

## Bad Uses

- Do not use subagents for trivial one-file work, ambiguous requests, or speculative exploration.
- Do not delegate urgent blocking work needed for the next parent action.
- Do not assign overlapping write scopes to multiple workers.
- Do not ask multiple agents the same broad question unless you intentionally need independent review.
- Do not treat a subagent patch as final without parent review and validation.

## How to Invoke

Codex spawns subagents from natural-language requests and applicable project/skill instructions; at the Ultra intelligence level it also delegates proactively. When you want a specific decomposition rather than the harness's own, name the agent and the unit of work explicitly.

- **Built-in agents** (always available): `default` (general-purpose fallback), `worker` (execution-focused, for implementation and fixes), `explorer` (read-heavy codebase exploration). Custom agents are invoked by their `name`.
- **Single delegation**: name the agent and hand it a self-contained task, e.g. "Spawn an explorer to find every call site of `parseConfig` and return each as `file:line`."
- **Parallel fan-out**: ask for one agent per independent unit, then wait-and-summarize, e.g. "Spawn one explorer per point above, wait for all of them, and summarize the result for each point." Codex waits until every requested result is available, then returns a single consolidated response.
- **Steering threads**: use `/agent` in the CLI to switch between and inspect active agent threads; ask Codex directly to steer a running subagent, stop it, or close completed threads.

Reference: Codex Subagents (https://learn.chatgpt.com/docs/agent-configuration/subagents). Subagents are enabled by default in current Codex releases and still evolving, so when a precise decomposition matters, state it explicitly rather than relying on implicit behavior.

## Worker Prompt Contract

A subagent does not inherit the parent session's conversation. It starts with fresh context and sees only what the spawn prompt gives it, so the most common failure is a prompt that assumes shared knowledge. Make every prompt self-contained — carry the file paths, the exact question, and the constraints into the prompt itself.

Every worker prompt must include:

- Goal: the exact user-visible outcome.
- Boundary: state plainly that the worker IS the delegated agent for this one unit — not the main/control session — and that any inherited context is reference only. Codex subagents can otherwise misread inherited parent context as active instructions and drift into the parent's role ([openai/codex#24150](https://github.com/openai/codex/issues/24150)); explicit boundary text is the standing workaround.
- Scope: files or modules the worker may edit.
- Non-overlap: the worker is not alone in the codebase and must not revert changes by others.
- Constraints: tests, style, security, and compatibility requirements.
- Output: a structured result the parent can consume directly, not a chat reply — changed files, the validation command run and its result, and residual risks. For a read-only explorer, return concrete findings anchored to `file:line`, not prose.

Prefer read-only explorers before workers when ownership is unclear.

## Integrating Results

- Integrate returned patches **one at a time, in dependency order**, running the relevant validation after each merge — batch-merging N patches and testing once makes a failure unattributable.
- Conflicts between two returned patches are resolved by the parent directly. Never spawn another agent to mediate a conflict.
- When a worker returns a wrong or partial result: retry **once**, with a sharpened prompt that names exactly what the first attempt got wrong; if the retry also fails, pull the unit back and do it locally. Never respawn the identical prompt hoping for a different outcome.

## Parent Responsibilities

The parent Codex session remains responsible for the final result. **Codex's documented orchestration model is spawn → wait → consolidate** — per the official docs it _"waits until all requested results are available, then returns a consolidated response"_ ([Codex Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)). So after you delegate, the default is to **wait**, not to stay busy.

- **Default to waiting.** Once you spawn a delegate-and-consume unit, do not issue further reads, searches, or edits that touch the delegated question — wait for the consolidated result and build on it. Re-running the same investigation locally is the single most common failure: the parent re-derives what a still-running explorer was sent to find. "Stay busy after spawning" is not a goal; non-redundant progress is.
- **Parallel local work is the exception, not the rule** — and only for a lane named _before_ spawning that provably needs nothing from the delegated output. If the lane would consume the delegated answer (e.g. seed/docs that depend on the routes an explorer is mapping), it is blocked on the subtask: wait, do not shadow-run it.
- **A silent subagent is not a stalled one.** A healthy explorer/worker on a long task often emits no intermediate signal; treat silence as in-progress, not failure. Misreading liveness and duplicating the work is a known Codex pitfall ([openai/codex#16900](https://github.com/openai/codex/issues/16900)). If you genuinely suspect it is stuck, steer or stop it explicitly via `/agent` — never quietly redo its work.
- Review subagent outputs quickly and integrate only the useful parts.
- Run the relevant validation yourself or verify that the validation evidence is trustworthy.
- Record each delegation **at spawn time** in the active task file (the CONTEXT micro-handoff for un-planned work; the spec LEDGER as a `delegated` entry for mission work): the unit, the agent, the expected output, and where it will be integrated; mark it consumed when integrated. A compaction or handoff must never orphan a running subagent — the file, not session memory, is what remembers outstanding delegations.
- Classify returned findings before persistence. WIP, proposals, task state, and uncertainty stay in the task/spec/CONTEXT candidate surface; reusable behavior goes through `$codex-learn`. Immediate fact promotion requires the full capture gate plus a user request, a verified correction needed to avoid continued reliance on known-wrong canonical knowledge, confirmed source drift, or a lifecycle promotion boundary. Otherwise persist the finding as a candidate. For a promotion, read `knowledge-management.md`, patch the existing owner plus reachable route atomically, and run the checker.
- Treat a subagent's knowledge claim as evidence to verify, not canonical truth. If a worker is explicitly assigned a knowledge mutation, its ownership must include both the topic and reachable map so no other agent splits the atomic write; the parent re-runs `bash .codex/scripts/knowledge-check.sh --root .` after integration.
- Do not rely on subagent thread history for persistence.

## Task Documents

For planned work, capture delegation under `## Plan of Work` or `### Memory Hints` rather than creating a separate always-required schema section. Include:

- the intended decomposition;
- intended subagent roles;
- read/write ownership boundaries;
- validation and review responsibilities;
- any concurrency or cost limits.

When a task is likely to parallelize, record the strategy; otherwise note "Delegation opportunity: <short idea>" when it would materially help a later session.

## Safety And Cost

- Keep delegation one level deep unless the user explicitly asks for recursive delegation.
- Keep concurrency conservative — the shipped config caps `[agents] max_concurrent_threads_per_session` at **6**. Raising it, in OpenAI's own words, _"can turn broad delegation instructions into repeated fan-out, which increases token usage, latency, and local resource consumption."_
- Ultra coordinates multiple agents in parallel by default and Codex itself warns that high multi-agent concurrency can increase usage quickly — match fan-out to the size of the request so a trivial ask doesn't spin up expensive parallel work; judgment, not a brake on genuinely parallel work.
- Use read-only sandboxing for explorers and any read-only delegation whenever possible.
