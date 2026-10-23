---
description: Write a single-slot session baton (.claudart/HANDOFF.md) that distills this session's reasoning state — objective, hypothesis, evidence, dead ends, exact next step — so a fresh session can resume seamlessly. Run when the context window is nearly full or when pausing mid-investigation.
---

Hand off this session's reasoning state to a future session that has none of your context. `/cda-checkpoint` records the state of the project; handoff records the state of the conversation: the working hypothesis, the evidence gathered, the dead ends ruled out, and the exact next move. Handoff is not a session-end ritual; use it when the conversation itself must survive a context boundary, such as a nearly full window or an investigation paused mid-flight.

## Rules

1. Single slot. `.claudart/HANDOFF.md` is the only handoff file. It is written once here, consumed once by the next `/cda-start`, then deleted, and it is replaced only after the existing baton is consumed, discarded or explicitly approved for replacement. Never create dated copies, a `handoff/` folder, or a second slot.
2. Distill; never transcribe chat history or replay messages. Hard ceiling: 150 lines; target under 100.
3. Quote word for word, using the shortest exact phrase that carries each:
   - explicit constraints or instructions the user stated (security rules, "don't touch X", style preferences);
   - the user's most recent request;
   - the anchor showing where work stopped (Rule 7).
     Distill everything else.
4. Route durable content out before writing. The baton holds only conversational residue with no durable home. Task/spec state, WIP, proposals, and uncertain candidates go to the owning task/spec artifact; recurring behavior becomes a named `/cda-learn` candidate; descriptive facts become knowledge when no other source owns them and they pass `.claude/rules/knowledge-management.md`. When another source owns a fact, record its pointer or needed update as a candidate in the active task/spec or baton without editing that source during handoff. Scope may be local. Content routed to another file does not also go into the baton.
5. An active task or spec wins. If an active task covers this session's work, the baton holds only a pointer to it plus live reasoning not yet written into it, and never copies task content. An active spec mission takes content into its NOTES/LEDGER; a routine spec pause needs no baton, because `/cda-spec-run` re-orients from the folder.
6. Write memory only: `HANDOFF.md`, and optionally a task/spec file and eligible knowledge entries. Never edit code or `CONTEXT.md`.
7. The Next Step traces to the user's most recent explicit request and the work in flight immediately before this handoff, with a verbatim anchor quote. Never list tangential ideas, speculative improvements, or completed work.

## Procedure

Before writing, inspect the shared handoff slot. Never silently overwrite an unconsumed baton from either runtime. Preserve it and report the conflict unless the user explicitly authorizes replacement. Re-read the slot immediately before the write; if its content changed, stop and reconcile instead of overwriting. Coordinate one writer at a time; no lock or automatic multi-writer safety is provided.

### Step 1 — Chronological analysis pass

Walk the conversation oldest → newest. For each phase identify:

- the user's explicit requests and intents (mark which must be quoted under Rule 3)
- decisions made, and what alternatives were rejected
- hypotheses formed, and whether each was confirmed, killed, or is still open
- errors encountered and how they were fixed
- files read or touched, with the reason each mattered

### Step 2 — Route durable content out

Apply Rule 4. Patch an existing knowledge owner before creating a topic, subject to the detail budget in `.claude/references/knowledge-maintenance.md`, update its reachable route atomically, and run `bash .claude/scripts/knowledge-check.sh` after any knowledge mutation. If evidence is insufficient or conflicting, keep a candidate in the owning work artifact or mark the existing owner `review-needed`; neither the baton nor a new topic may present it as certain.

### Step 3 — Write `.claudart/HANDOFF.md`

Use exactly this skeleton. When a section is truly empty, write `None` rather than inventing content.

```markdown
---
created: YYYY-MM-DD HH:MMZ
agent: claude
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

- `path/to/file.ext:42` — what this shows and why it matters (at most five items)

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

Tell the user briefly that the baton is written, what was routed to knowledge or the task file, and that the next `/cda-start` will pick it up. Do not continue working after a handoff.

`/cda-start` owns consumption: it surfaces the baton, verifies its Evidence and State of Play against current code before acting, and deletes it once the user resumes or discards it.
