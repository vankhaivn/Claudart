---
description: Reflect on completed work, promote validated behavioral learning, and route durable descriptive facts correctly
---

Please execute a Retrospective & Learning Protocol on the work you just completed.

Based on the "Agent Self-Evolution & Context Maintenance" section in `.claude/CLAUDE.md`, perform this protocol. `/learn` may run mid-session. It primarily owns behavioral learning; it is not a required detour before an eligible descriptive fact can enter knowledge.

## Re-Ground In The Rule Set

Before any retrospective:

1. Read `.claude/CLAUDE.md` in full.
2. Read every file in `.claude/rules/*.md` in full (use Glob first if you don't already know what exists).
3. Read every file in `.claude/agents/*.md` whose tools you used during this session.
4. Read `.claude/CONTEXT.md` to know what state the work was in when this session started.
5. Build a short mental index: rule name → core constraint → loophole keyword (if any).

You cannot judge deviations against rules you haven't re-read. If `.claude/rules/` is empty or missing, note that and continue with `.claude/CLAUDE.md` only.

## Rule Refinement

Walk the conversation chronologically, comparing each assistant turn against the rule index from the re-grounding pass.

1. List every moment the human corrected you OR you deviated from a rule. For each one, answer: _"What rationalization did I use to justify the deviation?"_ — do not just say "I missed the rule".
2. Did any rule fail because it only described the happy path without closing obvious loopholes?
3. For each identified gap, update the rule using this pattern: `NEVER do X, even when Y seems like a good reason` — explicitly name the rationalization so future runs cannot reuse it.
4. If rules contradict each other, resolve the contradiction immediately in `.claude/rules/` or `.claude/CLAUDE.md`.
5. Also save quiet _confirmations_: if the human accepted an unusual judgment call without pushback, that's a validated approach — record it so you don't drift away from it next time.

## Route What Was Learned

1. Identify any core bug root-causes, architectural decisions, or new design patterns successfully validated in this session.
2. **Pattern check via JOURNAL** — `.claude/JOURNAL.md` can grow to thousands of lines, so NEVER full-read it. Use this token-efficient strategy:
   - **Tail first**: read only the last ~200 lines via `tail -n 200 .claude/JOURNAL.md` (Bash) or `Read` with an `offset` near EOF.
   - **Grep when targeted**: if you suspect a specific pattern is recurring, use `grep '| decision |' .claude/JOURNAL.md` (or `pivot`) to surface only matching lines without loading the rest.
   - Look for the same `decision` or `pivot` recurring 2+ times in what you read. A repeating decision is a strong signal that the underlying principle should graduate from CONTEXT/JOURNAL into `.claude/rules/`. Surface these candidates explicitly.
   - Skip this step entirely if `.claude/JOURNAL.md` doesn't exist or has fewer than 5 entries.
3. Before updating files:
   - First, use the rule-file list from the re-grounding pass.
   - Compare the new knowledge with the scope of these existing files.
   - **CRITICAL CONSTRAINT**: DO NOT shoehorn or force new concepts into an existing file if the match is less than 80%. It is strictly PREFERRED to create a new domain file rather than polluting existing specific rules.
   - Then, decide:
     - Existing domain (perfect match) → Update the exact file in `.claude/rules/`.
     - New domain (no strong match) → Create a new `.md` file in `.claude/rules/` with complete YAML frontmatter and append the `@` import to `.claude/CLAUDE.md`.
     - Global standard (applies universally) → Update `.claude/CLAUDE.md` (or `.claude/rules/ai-behavior.md` if it's a behavioral rather than structural rule).
     - Descriptive fact → apply `.claude/rules/knowledge-management.md`. Promote it directly only if it is durable beyond the current work, current, evidenced, and correctly scoped. Patch the existing owner and reachable map atomically; leave WIP/proposals in the task/spec/CONTEXT surface and uncertainty/conflict as a candidate or `review-needed`.

4. If knowledge changed, run `bash .claude/scripts/knowledge-check.sh`. Report checker failures and never claim the mutation healthy while they remain.

**Boundary**: `/learn` updates **rules, `.claude/knowledge/`, and `.claude/CLAUDE.md` only**. Do NOT modify `.claude/CONTEXT.md` (that's `/checkpoint`'s job) and do NOT rewrite `.claude/JOURNAL.md` entries (it's append-only). You may read both as evidence. `/checkpoint` bulk-maintains remaining candidates but is not the sole knowledge write gate.

## Output Standard

- Rules must be **verifiable**: a reader must be able to check whether the rule was followed by reading the code. If you cannot verify it, rewrite it.
- New or updated rule files must include frontmatter with `paths:`, `description:`, `when_to_use:`, and `tags:`. Write `paths:` as a YAML flow sequence, e.g. `paths: ["src/**/*.ts", "test/**/*.ts"]`; never use block-list style. Write `tags:` as an inline YAML array on one line, e.g. `tags: [architecture, nestjs, boundaries]`; never use block-list style. Use 1-5 lowercase kebab-case tags that describe the domain or scope.
- Use `NEVER`, `YOU MUST`, or `IMPORTANT` emphasis for rules that have been violated before — this signals priority to future runs.
- **NO CODE SNIPPETS** in rule files. Reference the source file and line (e.g., `src/services/foo.ts:45`) so context never goes stale. Code in rule files rots.
- Execute file changes autonomously without asking for permission, then generate a brief summary listing each file touched and the reason.
