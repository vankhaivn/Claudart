---
paths: ["**/*"]
description: Continuous code-health rules for correct, simple, maintainable, behavior-preserving changes across languages and stacks.
when_to_use: Every Claude Code task that inspects, creates, changes, fixes, refactors, or reviews code or code-adjacent artifacts.
tags: [code-health, architecture, maintainability, correctness, testing]
---

# Code Health and Clean Implementation Guidelines

Apply these rules throughout implementation, not only during a later cleanup or audit. Optimize for a healthier repository—not code that merely looks "clean."

## 1. Respect the Order of Authority

When guidance conflicts, use this order:

1. User outcome and acceptance criteria.
2. Applicable `CLAUDE.md` / `.claude/CLAUDE.md`, repository rules, tests, public contracts, and local conventions.
3. Correctness, security, privacy, data integrity, concurrency safety, and recoverability.
4. Backward compatibility and externally observable behavior.
5. Simplicity, cohesion, ownership, testability, and diagnosability.
6. Performance when evidence or blast radius makes it relevant.
7. Generic patterns, metrics, books, and style preferences.

NEVER trade a higher-priority concern for a lower-priority principle merely to satisfy a named pattern or "clean code" rule.

## 2. Establish the Change Contract Before Editing

Determine from repository evidence:

- requested outcome and verifiable success criteria;
- current behavior and invariants;
- behavior that MUST remain unchanged and behavior explicitly allowed to change;
- applicable API, schema, persistence, protocol, configuration, CLI, error, ordering, and side-effect contracts;
- intended scope, necessary supporting edits, and validation strategy.

Read applicable instructions and inspect the owning code, callers, callees, types, tests, and relevant docs. Discover build, format, lint, type-check, test, migration, and generation commands from repository files—never guess them. Inspect Git status/diff when available so user-owned work is not mistaken for yours.

Never refactor a line or diff hunk in isolation. Never guess silently: investigate first, then ask only when unresolved interpretations would materially change observable behavior.

## 3. Make the Smallest Coherent Change

Every changed hunk MUST trace to the requested outcome or be necessary support for it. Necessary support may include directly affected tests, types, callers, adapters, docs, schemas, migrations, and correctly generated artifacts.

Do NOT perform drive-by refactors, unrelated cleanup, broad renames, file moves, reformatting, import churn, dependency upgrades, speculative generalization, or deletion of unrelated pre-existing dead code.

Modify generated or vendored artifacts only through the repository's established workflow. Include lockfiles, snapshots, fixtures, and migrations only when they are an intentional, necessary consequence of the task. Add or upgrade dependencies only when the requested outcome requires it and project policy permits it.

Remove code made obsolete by YOUR change. Never reset, clean, checkout, stash, overwrite, or "repair" work you do not own.

Prefer a small complete solution over both a broad rewrite and a narrow patch that leaves required callers, tests, types, or contracts inconsistent.

## 4. Preserve Behavior and Contracts by Default

Treat observable behavior as a contract unless the user explicitly authorizes a change. This includes APIs, schemas, stored data, events/messages, serialization and file formats, configuration, CLI behavior, errors, ordering, authorization, timing-sensitive behavior, and side effects.

When changing a contract intentionally, update affected producers, consumers, tests, types, migrations, and docs as one coherent change. Provide compatibility handling where required and state the impact explicitly.

A refactor is not behavior-preserving merely because existing tests still pass.

## 5. Put Correctness and Safety Before Readability Polish

For the affected path, consider applicable risks: invalid and boundary inputs; partial failure; rollback and state consistency; retries, idempotency, and duplicate delivery; resource cleanup; cancellation and timeouts; races, deadlocks, and ordering; overflow, precision, encoding, and serialization; authentication, authorization, secrets, and sensitive data.

Handle reachable failure modes at the correct boundary. Do not add defensive branches for states excluded by established invariants.

Do not introduce broad catches, swallowed errors, silent fallbacks, unsafe casts, unchecked assertions, blanket suppressions, arbitrary sleeps, or blind retries merely to make checks pass.

Add actionable error context while preserving error identity when callers depend on it. Never expose secrets or sensitive payloads through errors, logs, metrics, traces, fixtures, or tests.

## 6. Optimize for Comprehension and Clear Ownership

Prefer:

- cohesive units with one clear responsibility;
- explicit inputs, outputs, state transitions, ownership, and side effects;
- names that express domain intent and match local terminology;
- guard clauses when they reduce nesting without hiding flow;
- types/data shapes that make invalid states difficult to represent;
- behavior located with the module that owns the policy, invariant, or state;
- direct code when indirection has no concrete benefit.

Avoid hidden mutation, mixed abstraction levels, temporal coupling, clever compression, tiny-function pinball, and bypassing established service/domain/repository/adapter boundaries.

Do not enforce fixed limits for function length, parameter count, class size, nesting, comments, nullability, or inheritance. These are diagnostic signals, not laws. Judge semantic cohesion, cognitive load, local idiom, and change locality.

A longer cohesive function can be clearer than fragmented helpers. Extract only when the new unit names a meaningful concept and reduces reasoning cost.

## 7. Add Abstraction Only Under Concrete Pressure

An abstraction requires a present need: duplicated domain knowledge, multiple real consumers with a coherent contract, a volatile external boundary, a required test seam, a recurring change pattern, or a boundary needed to restore ownership/dependency direction.

A single use plus imagined future growth is insufficient. Do not add interfaces, factories, registries, base classes, strategies, generic frameworks, plugin systems, event buses, queues, caches, extension points, feature flags, or configuration for hypothetical scale or flexibility.

Use these checks:

- Extract a function to name a meaningful operation—not to satisfy a line-count target.
- Introduce a parameter object for a coherent domain concept—not an argument-count target.
- Introduce polymorphism for multiple real variants with a stable contract—not merely to remove a readable conditional.
- Introduce dependency inversion at a meaningful boundary—not for every collaborator.
- Create a shared utility only when it has clear ownership and stable semantics.

Prefer reversible, mechanical refactoring steps over large rewrites.

## 8. Apply DRY to Knowledge and Follow Local Idioms

DRY means one authoritative representation of a business rule, invariant, protocol, calculation, mapping, or source of truth. Consolidate similar code only when it represents the same knowledge, changes for the same reason, shares a lifecycle, and has a natural owner. Incidental duplication can be safer than coupling unrelated concepts. Treat the Rule of Three as a heuristic, not a threshold.

Repository truth outranks generic Clean Code preferences:

- Match local naming, typing, modules, errors, async patterns, dependencies, tests, and docs.
- Use idiomatic error handling, nullability, ownership, mutability, and resource lifecycle for the language.
- Respect framework lifecycle, rendering, persistence, concurrency, and dependency-injection models.
- Let configured formatters and linters settle mechanical style; do not reformat unrelated code.
- Do not force object-oriented patterns onto functional, data-oriented, actor-based, or systems code.

Comments should explain rationale, invariants, external constraints, compatibility obligations, security warnings, or why an obvious alternative is unsafe. Do not narrate syntax, restate obvious flow, compensate for poor naming, or preserve commented-out code. Update docs only when usage, configuration, setup, operations, migration, deprecation, or troubleshooting changes.

## 9. Make Tests Behavioral Evidence

Tests MUST address the risk introduced or removed by the change.

- For a bug fix, reproduce the failure first when practical, then make it pass.
- For risky refactoring, identify or add characterization coverage for behavior that must remain stable.
- For new behavior, cover success plus meaningful boundary/failure paths.
- Assert observable behavior and contracts, not incidental implementation choreography.
- Ensure a test would fail for the regression it claims to prevent.
- Prefer focused deterministic tests over broad brittle fixtures and excessive mocking.
- Never weaken assertions, skip tests, delete coverage, or rewrite expected results merely to accommodate faulty code.

## 10. Validate Proportionally to Risk

Validation is part of implementation. Run the narrowest meaningful checks first, then broaden with blast radius:

1. formatting for touched files;
2. lint/static analysis for the affected scope;
3. type checking or compilation for the affected module;
4. targeted tests for changed behavior and failure paths;
5. broader build/test/migration/E2E checks for shared contracts, persistence, infrastructure, concurrency, or cross-module changes.

Inspect the complete final diff and working-tree state. When available, run `git diff --check`. Remove unrelated churn, debug output, placeholders, commented-out code, secrets, accidental snapshots, generated noise, lockfile changes, and unintended contract changes.

Never claim a command passed unless it ran and success was observed. On failure, read the real error, determine whether your change introduced it using baseline evidence when available, fix introduced failures within scope, and report pre-existing or environment-blocked failures precisely. Never hide failure with suppression, retries, skips, or weakened tests.

## 11. Keep Code Operable Without Speculative Ceremony

For production failure paths, preserve causal context, cancellation, timeout propagation, and resource cleanup. Add logs, metrics, or traces only when they answer an operational question; avoid noisy, duplicate, high-cardinality, or sensitive telemetry. Avoid hidden retries/fallbacks that make incidents harder to explain.

Do not optimize speculatively. When performance is relevant, inspect algorithmic complexity, query count, I/O round trips, allocation/copying, serialization volume, lock contention, unbounded work, and repeated hot-path work. Use measurement or repository evidence where practical; never trade correctness or clarity for an unverified micro-optimization.

## 12. Pass the Continuous Self-Review Gates

Re-evaluate these gates while implementing and before finishing:

- **Scope:** Every changed hunk is required or necessary support.
- **Correctness:** Invariants, edge/failure paths, state, concurrency, and resources are sound.
- **Behavior:** No unrequested observable behavior changed.
- **Compatibility:** APIs, schemas, formats, configuration, errors, and callers are preserved or intentionally migrated.
- **Architecture:** Ownership and dependency direction improved without speculative layers.
- **Comprehension:** The main reading path and likely future change path are clearer.
- **Duplication:** Domain knowledge is authoritative without coupling unrelated concepts.
- **Tests:** Meaningful coverage catches the relevant regression.
- **Operations:** Failures remain diagnosable without exposing sensitive data.
- **Diff hygiene:** No unrelated churn, generated noise, dependency churn, or user-owned work is included.
- **Net health:** The repository is demonstrably healthier, not merely different.

If a gate fails, revise the implementation or revert only the edits made for this task. A no-op is valid when the code is already healthy or the proposed change would be speculative, unsafe, or lower value than its churn.

## 13. Finish With Evidence

A task is complete only when the requested outcome is implemented, intended behavior/contracts are preserved or intentional changes are explicit, necessary supporting edits are complete, relevant validation has passed or exact blockers are reported, and the final diff passes the gates above.

In the final handoff, state what changed and why, whether behavior/contracts changed, the exact validation and observed results, and only concrete residual risks or blockers. Do not substitute confidence language or a generic principles essay for implementation evidence.
