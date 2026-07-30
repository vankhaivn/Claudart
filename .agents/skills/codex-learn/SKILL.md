---
name: codex-learn
description: Run a behavior-first Codex retrospective, strengthen relevant guidelines, and route any durable descriptive facts to the canonical knowledge workflow.
---

# Codex Learn

Turn corrections and repeated lessons from completed work into durable behavior. Use the narrowest owner and keep facts, live state, and behavior in their correct tiers.

## 1. Re-Ground Selectively

1. Read `AGENTS.md` in full.
2. Read the guideline, skill, and agent files that governed this session. Use frontmatter and targeted `rg` to find relevant owners; do not read every guideline blindly.
3. Read `.codex/CONTEXT.md` for current shared state.
4. If the retrospective may retrieve or mutate project knowledge, read `.codex/guidelines/knowledge-management.md` in full. Otherwise do not load it.
5. For recurrence evidence, tail at most ~200 lines of `.codex/JOURNAL.md`, then use targeted `rg` for matching decisions or pivots. Never full-read JOURNAL by default.
6. Build a compact rule index: owner → core constraint → known loophole. Include every agent/skill instruction that materially governed the session.

## 2. Extract Behavioral Lessons

Walk the session chronologically. Compare every assistant turn against the rule index and identify:

- explicit user corrections or rule violations;
- the specific rationalization used to bypass each constraint, not merely “I missed the rule”;
- happy-path rules whose wording left an obvious loophole;
- repeated failure or workaround patterns;
- quiet confirmations: unusual judgment calls the user accepted and that should repeat;
- delegation boundaries, validation gaps, or ownership mistakes worth repeating or preventing.

Use JOURNAL recurrence as evidence: if the same decision or pivot appears at least twice, surface it as a behavioral candidate. Separate one-off environment failures and task-local narrative from reusable behavior. Do not turn a single unverified observation into a rule.

## 3. Patch The Canonical Owner

For each validated behavior:

1. Update the strongest matching existing guideline first.
2. Close the observed loophole with a verifiable constraint; when useful, state that the constraint still applies under the rationalization that caused the violation.
3. Resolve contradictions between guidelines or `AGENTS.md` immediately when evidence identifies the winner. If neither wins, surface the decision instead of silently choosing.
4. Use an existing guideline only when the semantic match is at least 80%. Create a focused owner instead of polluting a weak match; add canonical frontmatter and reference it from `AGENTS.md` when globally relevant.
5. Put delegation behavior in `.codex/guidelines/agent-delegation.md`.
6. Put a repository-wide Codex standard in `AGENTS.md`.

Guideline frontmatter uses `paths:`, `description:`, `when_to_use:`, and `tags:`. Keep `paths:` and `tags:` as compact flow sequences. Keep bodies prescriptive and concise; cite stable source paths instead of pasting code.

## 4. Route Non-Behavioral Material

- Descriptive, durable-beyond-current-work, current, evidenced fact → follow the full knowledge guideline now. Patch the existing topic owner first, update its reachable route atomically, and run `bash .codex/scripts/knowledge-check.sh --root .` after the mutation.
- WIP, proposal, acceptance state, or task-local discovery → keep it in the active task, spec, or `CONTEXT.md`.
- Uncertain or conflicting observation → keep it as a candidate, or mark a contradicted canonical owner `review-needed` with evidence and `status_note`.
- Retired chronology → leave it in JOURNAL; do not rewrite JOURNAL.

`$codex-learn` may write an eligible fact immediately. `$codex-checkpoint` performs bulk maintenance but is not an exclusive knowledge write gate.

## 5. Output Standard

- Make every rule verifiable from repository evidence.
- Keep guideline frontmatter complete, with flow-style `paths:` and `tags:` containing 1-5 lowercase kebab-case values.
- Use unambiguous critical language for constraints proven easy to violate.
- Do not paste long code snippets; cite stable sources.
- Summarize each file changed, the lesson it owns, knowledge checker results when applicable, and unresolved contradictions.

## Boundaries

- Do not modify `.codex/CONTEXT.md`; checkpoint owns it.
- Do not rewrite or delete `.codex/JOURNAL.md`.
- Do not auto-delete, retire, supersede, or promote ambiguous knowledge.
- Do not create a guideline for a descriptive fact or a knowledge topic for behavior.
- Execute safe, in-scope memory changes, validate them, and report each file touched and why.
