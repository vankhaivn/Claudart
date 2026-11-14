---
name: cda-whiteboard
description: Turn an explanation (your last answer, or a subject the user names) into a visual with short notes, so the user grasps it faster than prose without losing what matters. Use only when the user asks for it, by command or in words.
---

# Whiteboard

The user asked for this because prose was too long to follow, or a summary dropped what they needed. Explain the subject the user names, or your last substantive answer when they name none, in whatever visual form makes that subject clear. Nothing below fixes the form.

## What a good result is

- **Correct.** Check each claim against code, docs or command output before drawing it: a wrong picture is believed faster than wrong prose. Mark what you could not check as unverified on the visual itself.
- **Shaped by the subject.** Let the facts choose the form: parts and how they connect, a process, who calls whom, states, a schedule, numbers to compare, options against criteria, a hierarchy, a timeline, or something else. Several small visuals beat one dense one.
- **Readable at a glance.** Labels in the reader's words and the conversation's language, not identifiers. Colour only where it carries meaning, and readable in light and dark themes.
- **Nothing important lost.** Keep the visual light and put detail where the reader can reach it: steps that open on click, a table, or the notes.
- **Words around it.** Open with the answer in a sentence or two. After the visual, add brief notes for what it cannot show: causes, limits, where numbers come from, a decision left to the user. Do not repeat what the visual already says.

## Where to show it

- **The host can draw inline** (for example the Claude desktop app): draw it in the conversation, and write the answer and notes as ordinary text around the visual.
- **Otherwise:** write a Markdown page, with the answer and the notes on it, and render it with `bash .claude/skills/cda-whiteboard/scripts/render.sh <page>.md`. The page supports Mermaid blocks and `bars` blocks. Put it in the active task's `artifacts/` when a task covers the subject, otherwise in the system temp directory; never among the project's source files or on a public host. Open it in a browser pane when there is one, otherwise give the path.

## Look before you send

You cannot see an inline visual after you send it, and the host's font runs wider than you expect: leave slack in fixed boxes, break long labels, and ask the user to say if anything is cut off. For a dense visual, when a browser pane can open project files, `bash .claude/skills/cda-whiteboard/scripts/render.sh --preview <fragment>.html` shows the fragment in light and dark at chat width so you can check layout before sending. Look at a rendered HTML page before replying.

## Building blocks

`.claude/skills/cda-whiteboard/references/components.md` holds tested pieces you may reuse or ignore: Mermaid set up for the host theme with its known pitfalls, bars with a reference mark, steps that open detail, and a week calendar. They cover only a few shapes; draw your own when the subject needs another. Read only the part you need.
