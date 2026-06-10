---
name: codex-handoff
description: Write a single-slot session baton (.codex/HANDOFF.md) that distills this session's reasoning state — objective, hypothesis, evidence, dead ends, exact next step — so a fresh session can resume seamlessly. Run when the context window is nearly full or when pausing mid-investigation.
---

# Codex Handoff

You are about to hand off this session's **reasoning state** to a future session that has none of your context. This is not `$codex-checkpoint`: checkpoint records the state of the **project** (what is true now, which tasks exist); handoff records the state of the **conversation** — the working hypothesis, the evidence gathered, the dead ends ruled out, and the exact next move. The two are complementary; neither replaces the other.

Distill. Never dump transcript.

## Hard Rules (read before doing anything)

1. **Single slot.** `.codex/HANDOFF.md` is the only handoff file, and it is **overwritten**, not appended. It is a baton, not an archive: written once here, consumed once by the next `$codex-start`, then deleted. NEVER create dated copies, a `handoff/` folder, or a second slot.
2. **Distill, don't transcribe.** No raw chat history, no message-by-message replay. Hard ceiling: 150 lines; target under 100. Repeated compaction is cumulatively lossy — a tight baton beats a long echo.
3. **Verbatim tier.** Three things must be quoted word-for-word, never paraphrased:
   - explicit constraints or instructions the user stated (security rules, "don't touch X", style preferences);
   - the user's most recent request;
   - the quote anchoring where work stopped (see Hard Rule 7).
     Everything else gets distilled.
4. **Route durable content out FIRST.** The baton holds conversational residue only — content with no durable home. Before writing it: durable project facts → `.codex/knowledge/` (+ register in `INDEX.md`); discoveries tied to an active task → that task file's `Memory Hints` / `Surprises & Discoveries`; a recurring behavioral lesson → name it in chat as a `$codex-learn` candidate. Whatever you routed out does NOT also go into the baton.
5. **Active task wins.** If an active task file covers this session's work, most content belongs THERE. The baton then holds only a pointer to the task plus live reasoning not yet written into it. Never duplicate task content into the baton.
6. **No code edits.** This skill writes memory only — `HANDOFF.md`, and optionally a task file and knowledge entries. Never code, and never `CONTEXT.md` (that is `$codex-checkpoint`'s file).
7. **Next Step is anchored, not invented.** It must trace directly to the user's most recent explicit request and the work in flight immediately before this handoff, with a verbatim quote proving it. Never list tangential ideas, speculative improvements, or already-completed work.

## Procedure

### Step 1 — Chronological analysis pass

Before writing anything, walk the conversation oldest → newest. For each phase identify:

- the user's explicit requests and intents (mark which are verbatim-tier)
- decisions made, and what alternatives were rejected
- hypotheses formed — and whether each was confirmed, killed, or is still open
- errors encountered and how they were fixed
- files read or touched, with the reason each mattered

Do not skip this pass. Writing the baton from general impressions produces a vibe summary; the chronological pass is what makes the distillation faithful.

### Step 2 — Route durable content out

Apply Hard Rule 4 now: write the knowledge entries and task-file updates first, so the baton can reference them instead of carrying them.

### Step 3 — Write `.codex/HANDOFF.md` (overwrite)

Use exactly this skeleton. When a section is truly empty, write `None` — never invent content to fill it.

```markdown
---
created: YYYY-MM-DD HH:MMZ
agent: codex
task: <active task slug, or none>
---

# Session Handoff

## Objective

<What this session set out to do — in the user's words where possible.>

## State of Play

<What was accomplished and verified; what is mid-flight. 3-8 bullets.>

## Working Hypothesis

<Current mental model — for a debug session, the suspected cause; for design work, the chosen model.>

## Evidence

- `path/to/file.ext:42` — what this shows and why it matters

## Dead Ends — do not retry

- <Approach ruled out> — <why it is ruled out>

## User Constraints (verbatim)

> "<exact words>"

## Next Step

<The single exact next action.>

Anchor: "<verbatim quote from the most recent exchange showing where work stopped>"

## Open Questions

- <question the user still must answer, or unknown still blocking>
```

### Step 4 — Report and stop

Tell the user, briefly: the baton is written, what was routed to knowledge or the task file, and that the next `$codex-start` will pick the baton up. Do not continue working after a handoff; the session is considered closed.

## Consumption Contract (what the next session does)

`$codex-start` owns consumption — the flow lives there. The contract this file must honor:

- the next `$codex-start` reads the baton in full, surfaces it, and offers to resume;
- claims in the baton are **point-in-time**: the resuming session verifies Evidence and State of Play against current code before acting;
- once the user picks the work up, the baton is deleted — its durable parts were already routed in Step 2, and its residue now lives in the new session's context.

## Anti-Patterns

- ❌ Dumping transcript fragments or message lists into the baton.
- ❌ Dated handoff files, multiple slots, or a handoff archive. One file; overwrite; delete on consumption.
- ❌ Putting durable facts in the baton "to be safe" instead of routing them to `knowledge/` or the task file.
- ❌ Copying any part of a task file's body into the baton.
- ❌ A Next Step that doesn't trace to the user's latest explicit request.
- ❌ Running `$codex-handoff` as a routine session-end ritual. Session end is `$codex-checkpoint`'s job; handoff is for when the **conversation itself** must survive a context boundary — the window is nearly full, or an investigation pauses mid-flight.
