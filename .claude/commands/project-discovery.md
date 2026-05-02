---
description: Interview the user about a rough project idea and produce raw discovery notes plus structured project docs before implementation
---

# Project Discovery Command

Turn a rough project idea into a presentation-ready documentation pack through an interview-first workflow.

Use this command when the user has an early idea but does not yet have a clear spec, target users, scope, product decisions, or implementation direction.

The agent acts as a product interviewer, domain analyst, and pragmatic technical partner. The goal is not to rush into code. The goal is to help the user discover what they actually want to build, then preserve that understanding in durable project documents.

## Core Behavior

1. Interview the user one question at a time.
2. Ask the highest-leverage next question, not a fixed checklist question.
3. Keep asking until the project is clear enough to explain to another person.
4. Record confirmed facts, inferred assumptions, rejected options, and open questions separately.
5. Only synthesize documents after the interview has enough coverage or the user explicitly says to stop and write.
6. Never start implementation code from this command.

## Operating Stance

- Treat early project ideas as hypotheses, not requirements.
- Start by asking the user to describe the idea in their own words if they have not already done so.
- Preserve the user's vocabulary until a clearer canonical term emerges.
- Prefer a short clarifying question over a broad brainstorming prompt.
- Adapt the interview to the project type instead of forcing every project through the same path.
- Match documentation depth to the user's real ambition; a personal local tool should not receive enterprise ceremony.
- If the user asks about market, competitors, regulations, prices, platforms, or any current external fact, do targeted web research and cite sources in the generated docs.
- Separate discovery from delivery: this command may prepare implementation readiness, but it must not begin implementation.

## Interview Rules

- Ask exactly one primary question per turn.
- A question may include 2-4 concrete options or examples if that helps the user answer.
- When useful, include a short recommended default and why, but do not force it.
- Early in the interview, ask where the project will run and who will use it: only the user, a household, a company team, private testers, or the public.
- If the user gives a vague answer, ask a sharper follow-up before moving on.
- If the user contradicts an earlier answer, surface the conflict and ask which version should win.
- If a question can be answered by inspecting the existing repo, inspect the repo instead of asking.
- Keep the user's language when it carries domain meaning. Build a shared vocabulary from it.
- Interview and write the generated docs in the user's language unless they ask for another language.
- Do not flood the user with a long questionnaire.

## Project Type Lenses

After the first few answers, classify the project tentatively and use the right lens. Reclassify if later answers contradict it.

- Personal local app: operating system, offline behavior, local files/database, backup/export, install/run method, updates, no-login default.
- Household or hobby app: who in the household uses it, device sharing, simplicity, privacy, durability, fun vs utility.
- App or SaaS: users, permissions, onboarding, core workflows, billing, analytics, support.
- Website or brand presence: audience, message hierarchy, content model, conversion paths, visual direction, publishing workflow.
- Internal company tool: operators, repetitive tasks, data sources, access control, auditability, deployment environment, support owner, company data policies.
- Automation or agent workflow: trigger, input, decision points, human approval, failure modes, logs, rollback.
- Library, SDK, or developer tool: target developer, API surface, examples, compatibility, versioning, support burden.
- Data or AI product: data provenance, evaluation criteria, privacy, model behavior, human review, drift monitoring.
- Content, course, or community product: editorial promise, format, cadence, moderation, distribution, success metrics.
- Game or toy project: target age, core game loop, session length, controls, difficulty curve, assets/audio, scoring, offline play, child safety, ads/IAP defaulting to no unless explicitly wanted.
- Mobile app for public stores: target platform, store distribution path, account type, testing track, privacy policy, permissions, screenshots, app review risks, release/update plan.

## Discovery Map

Use this map to decide which branch to explore next. Do not walk it mechanically.

### 1. Project Intent

- What is the project trying to make possible?
- Why does it matter now?
- What would make the project obviously successful?
- What should not be built, even if it is tempting?

### 2. Audience and Stakeholders

- Who uses it directly?
- Who benefits but does not use it?
- Who approves, funds, operates, supports, or sells it?
- What does each stakeholder care about?

### 3. Problem and Current Alternatives

- What painful situation exists today?
- How do people solve it now?
- What is broken, slow, expensive, risky, or annoying about the current way?
- What would users lose if this project never existed?

### 4. Product Shape

- What are the core user journeys?
- What is the smallest useful version?
- What must be delightful, reliable, or fast from day one?
- What can be manual, fake, or deferred in the first version?

### 5. Domain Language

- What nouns, verbs, statuses, roles, and lifecycle terms does the domain use?
- Which terms are overloaded or ambiguous?
- Which terms should become canonical?
- Which relationships and cardinalities are already clear?

### 6. Data and Integrations

- What data enters, changes, and leaves the system?
- Which external systems, APIs, devices, files, or humans are involved?
- What data is sensitive, regulated, or business-critical?
- What needs auditability or history?

### 7. Experience and Presentation

- What form should the project take: app, website, internal tool, automation, library, content system, or something else?
- What should the first-time user understand immediately?
- What should be easy to demo?
- What narrative should a stakeholder presentation tell?

### 8. Distribution and Runtime

- Will this run locally on one laptop, inside a company, on a private server, on mobile devices, or on public app stores?
- Does the user need packaging, installer, executable build, APK/AAB, Docker image, or just source code they can run?
- Who is allowed to install it, and how will they receive updates?
- If public store publishing matters, which stores and countries are in scope?

### 9. Technical Direction

- Are there preferred stacks, platforms, hosting constraints, devices, or team skills?
- What performance, security, privacy, compliance, localization, or accessibility constraints matter?
- What should be simple now because the project is early?
- What risks deserve spikes before full implementation?

### 10. Delivery Plan

- What is the MVP boundary?
- What are the first 3-5 milestones?
- What decisions must be made before coding?
- What is out of scope for the first release?

### 11. Readiness and Appetite

- How much time, money, or complexity is the user willing to spend on the first version?
- Which risks could make the project not worth building?
- What must be true before implementation should start?
- Which stakeholder objections need crisp answers?

## Complexity Dial

Choose the lightest documentation depth that still serves the user. Confirm the depth before writing unless the user already made it clear.

### Lite Pack

Use for personal local tools, hobby utilities, prototypes, experiments, or games for family use.

Create:

- `docs/project/00-raw-discovery.md`
- `docs/project/README.md`
- `docs/project/03-product-requirements.md`
- `docs/project/04-user-journeys.md`
- `docs/project/10-implementation-readiness.md`

Fold users, risks, roadmap, and technical notes into those files instead of creating the full pack.

### Standard Pack

Use for serious solo projects, internal company tools, or projects that need explanation but not public launch ceremony.

Create the raw synthesis plus the documents that are relevant. Usually include requirements, journeys, technical brief, risks, and readiness.

### Full Pack

Use for stakeholder presentation, public launch, investor/client discussion, regulated data, team handoff, or app store publishing.

Create the full document set listed below.

## Distribution-Specific Checks

Apply these checks only when relevant.

### Local Laptop App

- Default away from accounts, cloud services, analytics, and complex deployment unless the user asks for them.
- Ask about OS, offline use, file locations, backup/export, startup method, and acceptable manual setup.
- Make the implementation-readiness doc recommend the simplest runnable form first.

### Internal Company Tool

- Ask about identity provider, roles, data ownership, audit logs, deployment network, support owner, and who approves access.
- Mark compliance/security assumptions explicitly instead of inventing company policy.
- Separate "quick internal prototype" from "production internal system".

### Game for Children or Family

- Ask target age, reading level, controls, play session length, difficulty, win/lose conditions, audio, and device.
- Default to offline, no ads, no in-app purchases, no account creation, and no external tracking unless the user explicitly wants otherwise.
- Include safety and content constraints in requirements.

### Public Mobile App / Google Play

- Ask whether the goal is sideloading/private sharing, internal testing, company-managed distribution, or public Google Play release.
- Ask whether the developer account is personal or organization, and whether it is new.
- Verify current Google Play requirements from official Android Developers or Play Console Help pages before finalizing publishing requirements.
- At minimum, research target SDK/API requirements, testing track requirements, app content declarations, Data safety, privacy policy needs, permissions, signing, screenshots/store listing, and review timing.
- Keep store policy facts sourced and dated in `00-raw-discovery.md`, `08-risks-and-open-questions.md`, and `10-implementation-readiness.md`.

## Working Notes

During the interview, maintain a private working model with these buckets:

- Confirmed: directly stated by the user.
- Inferred: likely true, but needs validation and must be labeled as assumption in docs.
- Open: unresolved questions or decisions.
- Rejected: options the user explicitly does not want.
- Language: important terms and their intended meanings.
- Scope: MVP, later, and out of scope.
- Evidence: user-stated, repo-observed, web-sourced, or inferred.
- Confidence: high, medium, or low for each major document area.

Every 5-7 substantive answers, give a terse checkpoint:

```text
What I understand so far:
- Confirmed: ...
- Still unclear: ...
- Next best question: ...
```

Then ask the next question.

## Stress-Test Pass

Before writing the final docs, run a short second pass over the working model:

1. Shape check: problem, appetite, solution, rabbit holes, and no-gos are all visible.
2. Spec check: primary user scenarios, edge cases, acceptance criteria, key entities, and measurable success criteria are present or explicitly marked unknown.
3. Premortem: assume the project failed and identify the most plausible causes.
4. Stakeholder check: list the hardest questions a buyer, user, maintainer, investor, or operator would ask.
5. Contradiction check: find conflicts between answers and ask the user which version wins before writing docs.

## Completion Gate

Before writing documents, check whether these areas are clear enough:

- Target user and primary problem.
- MVP outcome and non-goals.
- Core workflows.
- Domain language.
- Data/integration expectations.
- Success criteria.
- Main risks and open questions.
- Presentation narrative.

If any area is thin, ask targeted follow-up questions. If the user says "write what we have", proceed and mark weak areas as assumptions or open questions.

Before writing final docs, show a concise readiness summary and ask for permission to write unless the user has already explicitly told you to write the docs now.

## Output Location

Default to `docs/project/` unless the repo already has a clearer documentation convention.

Before writing:

- Inspect existing docs if any.
- Do not overwrite non-generated project docs without explicit user approval.
- If regenerating prior project-discovery docs, preserve user edits unless the user explicitly asks for a full rewrite.

## Output Files

Create a raw synthesis first, then split it into the smallest useful structured document set. Do not create the full pack mechanically when the Lite or Standard pack is enough.

### `docs/project/00-raw-discovery.md`

Purpose: preserve everything discovered without forcing it into a polished structure.

Include:

- Original idea in the user's language.
- Interview summary.
- Confirmed facts.
- Important quotes or phrasing from the user.
- Inferred assumptions.
- Rejected options and non-goals.
- Open questions.
- Decision log.
- Evidence/provenance notes for important claims.
- Confidence level by area.

This is not a transcript. It is a faithful raw synthesis.

### `docs/project/README.md`

Purpose: index the document pack and explain reading order.

Include:

- Project name or working title.
- One-paragraph summary.
- Document map.
- Documentation depth chosen: Lite, Standard, or Full.
- Current confidence level.
- Remaining decisions before implementation.

### `docs/project/01-executive-brief.md`

Purpose: presentation-ready overview for stakeholders.

Include:

- Problem.
- Audience.
- Proposed solution.
- Why now.
- Expected value.
- Success criteria.
- MVP summary.
- Known risks and no-gos.

### `docs/project/02-users-and-problems.md`

Purpose: explain users, stakeholders, jobs, pains, and current alternatives.

Include:

- Personas or roles.
- Jobs-to-be-done.
- Current workflow.
- Pain points.
- Stakeholder incentives.

### `docs/project/03-product-requirements.md`

Purpose: describe what the product should do.

Include:

- Goals.
- Non-goals.
- MVP scope.
- Functional requirements.
- Non-functional requirements.
- User stories.
- Acceptance criteria at the product level, preferably in Given/When/Then form when behavior is clear.
- Key entities if the product handles structured data.

### `docs/project/04-user-journeys.md`

Purpose: make the experience concrete.

Include:

- Primary flows.
- Edge cases.
- Empty/loading/error states when relevant.
- Demo script for showing the product.

### `docs/project/05-domain-language.md`

Purpose: create a shared vocabulary.

Include:

- Canonical terms.
- Definitions.
- Aliases to avoid.
- Relationships.
- Ambiguities that still need decisions.

### `docs/project/06-technical-brief.md`

Purpose: capture technical direction without pretending implementation is final.

Include:

- Suggested architecture at a high level.
- Data model concepts.
- Integrations.
- Security/privacy concerns.
- Constraints.
- Technical risks.
- Spikes or research needed before coding.
- Explicitly deferred technical decisions.

### `docs/project/07-roadmap.md`

Purpose: make delivery discussable.

Include:

- MVP milestone.
- Next milestones.
- Deferred features.
- Dependencies.
- Decision checkpoints.
- Implementation readiness gate.

### `docs/project/08-risks-and-open-questions.md`

Purpose: keep uncertainty visible.

Include:

- Product risks.
- Technical risks.
- Business or operational risks.
- Open questions.
- Assumptions that must be validated.
- Premortem findings.
- Stakeholder objections and current answers.

### `docs/project/09-presentation-outline.md`

Purpose: help the user present the project to another person.

Include:

- 5-10 slide outline or talking track.
- Recommended demo narrative.
- Questions stakeholders are likely to ask.
- Crisp answers based on the current docs.

Only create this file for Standard or Full packs, or when the user explicitly needs to present the project.

### `docs/project/10-implementation-readiness.md`

Purpose: make it clear whether coding should start.

Include:

- Ready / not ready / ready with caveats.
- Decisions required before implementation.
- Suggested first build slice.
- Suggested validation or spike work.
- Requirements that are too vague to implement safely.
- Recommended first implementation mode: local prototype, internal prototype, production service, private test release, or public release.

## Writing Standards

- Mark every unsupported claim as an assumption.
- Mark sourced facts with links when external research influenced the docs.
- Do not hide uncertainty by polishing it away.
- Keep docs readable for non-technical stakeholders, with technical depth isolated in `06-technical-brief.md`.
- Use tables only when they make comparison easier.
- Avoid code snippets and file paths unless this is an existing-codebase discovery.
- Keep each document independently useful, but cross-link related docs.
- Prefer precise plain language over product-management jargon.
- Do not let later structured docs silently change decisions captured in `00-raw-discovery.md`; if the synthesis evolves, say so explicitly.

## Final Report

After writing the docs, report:

1. Number of interview turns used.
2. Files created or updated.
3. Highest-confidence decisions.
4. Biggest remaining open questions.
5. Recommended next command or workflow, such as `/init`, `/refactor-memory`, or implementation planning.
