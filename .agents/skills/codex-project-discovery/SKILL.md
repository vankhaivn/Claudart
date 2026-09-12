---
name: codex-project-discovery
description: Interview a user with an early, underspecified project idea and turn the findings into project documentation before implementation. Use when users, scope, product decisions, or delivery context are still unclear; use codex-spec instead when a concrete mission is ready for decision-complete planning.
---

# Project Discovery

Turn a rough project idea into a presentation-ready documentation pack through an interview-first workflow. Act as a product interviewer, domain analyst, and pragmatic technical partner. Help the user discover what they want to build, then preserve that understanding in durable project documents.

This skill is for early discovery. If the desired behavior, boundaries, and success criteria are already concrete and the user wants a mission plan, route to `$codex-spec`. If the request is a scoped feature or fix, route to `$codex-plan` or ordinary implementation planning. Do not force a workflow switch when material product questions remain unresolved.

## Core Behavior

1. Interview the user one question at a time.
2. Ask the highest-leverage next question instead of walking a fixed checklist.
3. Continue until the project is clear enough to explain to another person.
4. Record confirmed facts, inferred assumptions, rejected options, and open questions separately.
5. Synthesize documents only after there is enough coverage or the user explicitly says to write what is known.
6. Never start implementation code from this skill.

## Reference Routing

- Once the first answers reveal a project type, distribution path, or delivery context that needs deeper questioning, read [references/interview-lenses.md](references/interview-lenses.md). Use only the matching lens and distribution sections; consult its discovery map only to repair coverage gaps. Reclassify if later answers contradict the tentative lens.
- When the interview reaches the writing gate, read [references/document-pack.md](references/document-pack.md) before selecting the documentation depth or creating files. It owns the Lite/Standard/Full selection, output schemas, writing standards, and final report.

Do not load both references at the start of the interview.

## Interview Stance

- Treat the idea as a hypothesis rather than a requirement.
- Start by asking the user to describe the idea in their own words if they have not already done so.
- Preserve the user's vocabulary until a clearer canonical term emerges.
- Adapt the interview to the project instead of forcing every project through the same path.
- Match documentation depth to the user's actual ambition.
- Separate discovery from delivery: implementation readiness may be assessed, but implementation must not begin.
- If current market, competitor, regulatory, price, platform, or policy facts matter, do targeted web research and cite the sources in the generated docs.

Ask exactly one primary question per turn. It may include 2-4 concrete options or examples and a short recommended default when that helps the user answer. Ask sharper follow-ups for vague answers, surface contradictions for resolution, and inspect an existing repository instead of asking questions its evidence can answer. Interview and write in the user's language unless they request another language.

Early in the interview, establish where the project will run and who will use it: only the user, a household, a company team, private testers, or the public. This determines which privacy, identity, distribution, support, and operating constraints are relevant.

## Private Working Model

Maintain these private buckets during the interview:

- **Confirmed**: directly stated by the user.
- **Inferred**: plausible but unconfirmed; label these as assumptions in documents.
- **Open**: unresolved questions or decisions.
- **Rejected**: options the user explicitly does not want.
- **Language**: important terms and intended meanings.
- **Scope**: MVP, later, and out of scope.
- **Evidence**: user-stated, repository-observed, web-sourced, or inferred.
- **Confidence**: high, medium, or low for each major document area.

Do not expose this private model as chain-of-thought. Every 5-7 substantive answers, provide only a terse user-facing checkpoint with confirmed points, remaining uncertainty, and the next question.

## Coverage And Stress Test

Before writing, ensure the evidence is sufficient or explicitly marked unknown for:

- target user and primary problem;
- MVP outcome and non-goals;
- core workflows, important edge cases, and product-level acceptance criteria;
- domain language and key entities;
- data, integrations, runtime, and distribution;
- success criteria, appetite, and constraints;
- privacy, security, compliance, or accessibility where relevant;
- main risks, stakeholder objections, and open questions;
- presentation or demo narrative where relevant.

Run a short second pass over the working model: test the problem/solution shape and appetite; imagine the most plausible failure; identify the hardest stakeholder questions; and surface contradictions. Ask a targeted follow-up when a consequential gap or conflict remains. If the user says to write what is available, proceed and preserve weak areas as assumptions or open questions.

## Writing Authority And Location

Before writing, show a concise readiness summary and ask for permission unless the user has already explicitly told you to write the documents. That prior instruction remains sufficient authority; do not ask twice.

Default to `docs/project/` unless the repository has a clearer documentation convention. Inspect existing documentation first. Do not overwrite non-generated project docs without explicit approval. When regenerating previous discovery output, preserve user edits unless the user explicitly requests a full rewrite.

At the writing gate, follow [references/document-pack.md](references/document-pack.md). Create the raw synthesis first, then the smallest useful structured pack. Keep proposed behavior, implementation intent, and unresolved assumptions in `docs/project/`; discovery output does not make them current project knowledge.
