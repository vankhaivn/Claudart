# Discovery Document Pack

Read this reference only when the interview is ready for synthesis or the user has explicitly asked to write with the available evidence.

## Choose The Smallest Useful Pack

Confirm the depth before writing unless the user's intended audience and use already make it clear.

### Lite

Use for personal local tools, hobby utilities, prototypes, experiments, or family games. Create:

- `docs/project/00-raw-discovery.md`
- `docs/project/README.md`
- `docs/project/03-product-requirements.md`
- `docs/project/04-user-journeys.md`
- `docs/project/10-implementation-readiness.md`

Fold relevant users, risks, roadmap, and technical notes into those files.

### Standard

Use for serious solo projects, internal company tools, or projects that need clear explanation without public-launch ceremony. Create the raw synthesis plus only relevant structured documents. Requirements, journeys, technical brief, risks, and readiness are usually useful.

### Full

Use for stakeholder presentations, public launches, investor/client discussions, regulated data, team handoffs, or public app-store publishing. Create the complete set below.

## Output Schemas

Create the raw synthesis first. Then derive structured documents without silently changing its decisions.

### `00-raw-discovery.md`

Faithful synthesis rather than a transcript:

- original idea in the user's language;
- interview summary and important user phrasing;
- confirmed facts and their evidence;
- inferred assumptions, rejected options, and non-goals;
- open questions and decision log;
- provenance notes for important claims;
- confidence by area.

### `README.md`

Index and reading order:

- project name or working title and one-paragraph summary;
- document map and selected depth;
- current confidence;
- remaining decisions before implementation.

### `01-executive-brief.md`

Stakeholder overview:

- problem, audience, and proposed solution;
- why now and expected value;
- success criteria and MVP summary;
- known risks and no-gos.

### `02-users-and-problems.md`

Users and current reality:

- personas or roles and stakeholder incentives;
- jobs-to-be-done and current workflow;
- pain points and current alternatives.

### `03-product-requirements.md`

Product behavior:

- goals, non-goals, and MVP scope;
- functional and non-functional requirements;
- user stories and product-level acceptance criteria, using Given/When/Then when behavior is clear;
- key entities when the product handles structured data.

### `04-user-journeys.md`

Concrete experience:

- primary flows and relevant edge cases;
- empty, loading, and error states where relevant;
- demo script.

### `05-domain-language.md`

Shared vocabulary:

- canonical terms and definitions;
- aliases to avoid;
- relationships;
- unresolved ambiguities.

### `06-technical-brief.md`

Technical direction without pretending implementation is final:

- high-level architecture and data-model concepts;
- integrations, constraints, and security/privacy concerns;
- technical risks and research or spikes needed;
- explicitly deferred technical decisions.

### `07-roadmap.md`

Discussable delivery:

- MVP and later milestones;
- deferred features and dependencies;
- decision checkpoints;
- implementation-readiness gate.

### `08-risks-and-open-questions.md`

Visible uncertainty:

- product, technical, business, and operational risks;
- open questions and assumptions to validate;
- premortem findings;
- stakeholder objections and current answers.

### `09-presentation-outline.md`

Create only for Standard or Full packs, or when the user explicitly needs to present:

- 5-10 slide outline or talking track;
- recommended demo narrative;
- likely stakeholder questions and evidence-based answers.

### `10-implementation-readiness.md`

Readiness decision:

- ready, not ready, or ready with caveats;
- decisions required before implementation;
- suggested first build slice and validation/spike work;
- requirements still too vague for safe implementation;
- recommended first mode: local prototype, internal prototype, production service, private test release, or public release.

## Writing Standards

- Mark unsupported claims as assumptions and link sourced facts when external research influenced the docs.
- Preserve uncertainty instead of polishing it away.
- Write for non-technical stakeholders; isolate technical depth in `06-technical-brief.md`.
- Use tables only for comparisons they make easier.
- Avoid code snippets and file paths unless discovering an existing codebase.
- Make each document useful on its own and cross-link related documents.
- Prefer precise plain language over product-management jargon.
- If synthesis evolves beyond `00-raw-discovery.md`, state the change instead of silently rewriting the decision.

## Final Report

After writing, report:

1. Interview turns used.
2. Files created or updated.
3. Highest-confidence decisions.
4. Biggest remaining open questions.
5. Recommended next skill or workflow, such as `$codex-spec`, `$codex-plan`, or implementation planning.
6. Knowledge routing result:
   - If the user asked to capture knowledge and the pack contains a descriptive, durable-beyond-current-work, current, evidenced reference fact, read `.codex/guidelines/knowledge-management.md` and `.codex/references/knowledge-maintenance.md`. Patch the existing owner first, or create one focused `reference` topic when no owner exists; point `sources` to the discovery docs instead of duplicating them, update the reachable route atomically, and run the checker.
   - If the user did not request knowledge capture, offer it as an optional natural-language next step; no checkpoint is required.
   - Keep proposed product behavior, implementation intent, and unresolved assumptions in `docs/project/` as candidates.
   - Report the topic updated or created and checker result, or `none` with the reason no claim qualified.
