---
name: cda-learn
description: Reflect on completed work, promote validated behavioral learning, and route durable descriptive facts correctly. Use only when the user asks for it, by command or in words.
---

Run a retrospective on the work you just completed, following the "Agent Self-Evolution & Context Maintenance" section in `CLAUDE.md`. `/cda-learn` may run mid-session. It owns behavioral learning; it is not a required detour before an eligible descriptive fact can enter knowledge.

## Re-Ground In The Rule Set

1. Read `CLAUDE.md` in full.
2. Read the rule, command, and agent files that governed this session. Use frontmatter and targeted search to find relevant owners; do not read every rule blindly.
3. Read every file in `.claude/agents/*.md` whose tools you used during this session.
4. Read `.claudart/CONTEXT.md` for the state the work started from, and `.claudart/OWNER.md` for the current owner working agreement.
5. Build a short index: rule name → core constraint → known loophole. If `.claude/rules/` is empty or missing, note that and continue with `CLAUDE.md` only.

## Rule Refinement

Walk the conversation chronologically, comparing each assistant turn against the rule index.

1. List every moment the user corrected you or you deviated from a rule, and name the rationalization you used to justify each deviation, not merely "I missed the rule".
2. Find rules that failed because they described only the happy path.
3. For each gap, sharpen the existing sentence so it closes the loophole; when useful, state that the constraint still applies under the rationalization that caused the violation.
4. Resolve contradictions between rules immediately in `.claude/rules/` or `CLAUDE.md`.
5. Save quiet confirmations too: an unusual judgment call the user accepted without pushback is a validated approach to keep.

## Route What Was Learned

1. Identify bug root causes, architectural decisions, or design patterns validated in this session.
2. Check recurrence in `.claudart/JOURNAL.md` without full-reading it: tail the last ~200 lines and grep targeted `| decision |` or `| pivot |` lines. A decision or pivot recurring two or more times is a candidate to graduate into `.claude/rules/`; surface it. Skip this check if JOURNAL is missing or has fewer than 5 entries.
3. Route each lesson to one owner:
   - An existing rule whose scope matches at least 80% → update that file. Below that, create a focused rule file instead of stretching a weaker match, and add its conditional route to `CLAUDE.md`.
   - A universal standard → `CLAUDE.md`, or `.claude/rules/ai-behavior.md` when it is behavioral rather than structural.
   - An owner working preference (communication, pacing, approvals, the people around the project, or a mistake to avoid) → `.claudart/OWNER.md` under `.claude/rules/ai-behavior.md`. Record missing entries, merge near-duplicates, and sharpen scope or exceptions instead of creating a rule.
   - A descriptive fact → its owner under `.claude/rules/knowledge-management.md`; leave WIP and proposals in their task, spec or CONTEXT.
4. If knowledge changed, run `bash .claude/scripts/knowledge-check.sh`. Report checker failures and never claim the mutation healthy while they remain.

`/cda-learn` updates rules, `.claudart/OWNER.md`, `.claudart/knowledge/`, and `CLAUDE.md` only. It may read CONTEXT and JOURNAL as evidence but never modifies CONTEXT or rewrites JOURNAL entries.

## Output Standard

- A reader must be able to check from the code whether a rule was followed; rewrite any rule that cannot be verified.
- Rule files carry the frontmatter `CLAUDE.md` defines, with `paths:` as a YAML flow sequence and `tags:` as a one-line inline array of 1-5 lowercase kebab-case values.
- State each rule once, in plain words. Fix a repeated violation by sharpening its wording or scope, not with capitalized emphasis, which current models over-apply.
- Rule files contain no code snippets; cite the source file and line (e.g., `src/services/foo.ts:45`).
- Make the file changes without asking for permission, then list each file touched and why.
