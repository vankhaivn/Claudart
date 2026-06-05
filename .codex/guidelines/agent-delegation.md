---
paths: ["**/*"]
description: Codex subagent delegation protocol for parallel exploration and bounded implementation using the built-in explorer/worker agents.
when_to_use: When the user explicitly authorizes subagents, delegation, or parallel agent work, or when planning a Codex task that may benefit from such authorization.
tags: [subagents, delegation, parallelism, orchestration]
---

# Agent Delegation

Codex subagents are a parallel-work capability, not a default behavior. Use them only when the user explicitly asks for subagents, delegation, or parallel agent work. Requests for depth, thoroughness, investigation, or "be comprehensive" are not authorization by themselves.

This protocol governs the built-in `explorer`/`worker` delegation pattern. Project-specific custom agents (defined under `.codex/agents/`) carry their own instructions and are invoked directly by name when the user asks for them; they are out of scope here.

## Delegation Gate

Before spawning a subagent, write a short decomposition:

- **Main agent critical path**: the next work the parent Codex session will do locally.
- **Sidecar tasks**: bounded tasks that can run in parallel without blocking that critical path.
- **Ownership**: exact files, modules, or read-only question each subagent owns.
- **Merge plan**: how returned findings or patches will be reviewed and integrated.

Do not spawn if the next parent step is blocked on the subtask. Do that work locally instead.

## Pre-authorized Delegation (task-file `delegation:` field)

The "explicit authorization" requirement above can be satisfied **at planning time** and persisted, not only at runtime. When a `$codex-plan` task records `delegation: authorized` in its frontmatter, the user authorized subagents for execution during planning — the approval signal ("go") then activates delegation **without a second request**. `delegation: strategy-only` means a strategy is recorded but only _discussed_, not authorized: make a single one-line offer at "go" before spawning. See `task-management.md` → "Delegation Authorization" for the field's full semantics.

The authorization bar itself is unchanged. A _question_ about subagents ("can they handle the non-conflicting parts?") is `strategy-only`, not `authorized`; only an explicit instruction to use them for the work sets `authorized`. Persisting the decision removes the redundant re-confirmation, not the gate.

## Delegate-and-Consume vs. Delegate-and-Continue

The deciding signal is **task structure, not the user's exact words.** Before spawning, ask: _does the request decompose into work genuinely separate from the delegated question, or IS the delegated question the whole task?_

- **Whole task** — the delegated question is the entire request (a single read-only investigation, one bounded fix) → **spawn, then wait and consume the result.** Do NOT shadow-run the same investigation in the parent thread. Codex already pauses to consolidate subagent results (_"waits until all requested results are available"_); racing it locally pays for one answer twice and duplicates the subagent's work.
- **Decomposable** — the request splits into disjoint units → **fan out one subagent per unit** (each owning a non-overlapping file set or sub-question) and let Codex consolidate, rather than answering one unit in the parent while a subagent answers another. Multi-subagent fan-out — not parent-vs-subagent racing — is Codex's native parallel idiom.

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

Codex spawns subagents from natural-language requests and never delegates on its own; name the agent and the unit of work explicitly.

- **Built-in agents** (always available): `default` (general-purpose fallback), `worker` (execution-focused, for implementation and fixes), `explorer` (read-heavy codebase exploration). Custom agents are invoked by their `name`.
- **Single delegation**: name the agent and hand it a self-contained task, e.g. "Spawn an explorer to find every call site of `parseConfig` and return each as `file:line`."
- **Parallel fan-out**: ask for one agent per independent unit, then wait-and-summarize, e.g. "Spawn one explorer per point above, wait for all of them, and summarize the result for each point." Codex waits until every requested result is available, then returns a single consolidated response.
- **Steering threads**: use `/agent` in the CLI to switch between and inspect active agent threads; ask Codex directly to steer a running subagent, stop it, or close completed threads.

Reference: OpenAI Codex Subagents (https://developers.openai.com/codex/subagents). Subagents are enabled by default in current Codex releases and are still evolving, so prefer explicit, bounded delegation over relying on implicit behavior.

## Worker Prompt Contract

A subagent does not inherit the parent session's conversation. It starts with fresh context and sees only what the spawn prompt gives it, so the most common failure is a prompt that assumes shared knowledge. Make every prompt self-contained — carry the file paths, the exact question, and the constraints into the prompt itself.

Every worker prompt must include:

- Goal: the exact user-visible outcome.
- Scope: files or modules the worker may edit.
- Non-overlap: the worker is not alone in the codebase and must not revert changes by others.
- Constraints: tests, style, security, and compatibility requirements.
- Output: a structured result the parent can consume directly, not a chat reply — changed files, the validation command run and its result, and residual risks. For a read-only explorer, return concrete findings anchored to `file:line`, not prose.

Prefer read-only explorers before workers when ownership is unclear.

## Parent Responsibilities

The parent Codex session remains responsible for the final result:

- Prefer collapsing parallel work into multiple subagents over doing part of it yourself. If you do keep a local task running alongside, it must not overlap the delegated question. If the delegation covers the whole request, just wait for the consolidated result. "Stay busy after spawning" is not a goal; non-redundant progress is.
- Wait when the next critical-path step needs a subagent result, or when the delegated task is the entire request.
- Review subagent outputs quickly and integrate only the useful parts.
- Run the relevant validation yourself or verify that the validation evidence is trustworthy.
- Record important subagent findings in task files first; use `$codex-checkpoint` for active `CONTEXT.md` handoffs or eventual `JOURNAL.md` entries. Do not rely on subagent thread history for persistence.

## Task Documents

For planned work, capture delegation under `## Plan of Work` or `### Memory Hints` rather than creating a separate always-required schema section. Include:

- whether the user authorized subagents;
- intended subagent roles;
- read/write ownership boundaries;
- validation and review responsibilities;
- any concurrency or cost limits.

If the user did not authorize subagents, note only "Delegation opportunity: <short idea>" when it would materially help later.

## Safety And Cost

Keep `max_depth = 1` (the Codex default) unless the user explicitly asks for recursive delegation. Keep `max_threads` conservative — the default is **6**; raising it, in OpenAI's own words, _"can turn broad delegation instructions into repeated fan-out, which increases token usage, latency, and local resource consumption."_ For template projects keep it low so downstream repos do not accidentally fan out expensive work. Use read-only sandboxing for explorers and any read-only delegation whenever possible.
