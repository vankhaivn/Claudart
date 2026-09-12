# Select and adapt output templates

Use this guide when creating missing documentation or reshaping an unsuitable owner. Read only the template for that responsibility; existing useful owners do not need conversion. These are adaptable document bodies, not a required folder skeleton. Templates and examples remain module resources; write project facts in their selected project owners.

## Responsibilities and suggested paths

| Responsibility                                   | Suggested output when no fitting owner exists | Template                                         | Change that warrants an update                                                          |
| ------------------------------------------------ | --------------------------------------------- | ------------------------------------------------ | --------------------------------------------------------------------------------------- |
| Entry point and source routes                    | `docs/README.md`                              | [Router](assets/templates/router.md)             | An owner, route, work/release pointer, or material gap changes                          |
| Product purpose and current approved scope       | `docs/product.md`                             | [Product](assets/templates/product.md)           | Agreed goals, users, scope, capabilities, or product constraints change                 |
| Agreed capability behavior and delivery reality  | `docs/behavior/<capability>.md`               | [Behavior](assets/templates/behavior.md)         | Business rules, quality requirements, implementation, or supported behavior changes     |
| System understanding                             | `docs/architecture.md`                        | [Architecture](assets/templates/architecture.md) | Boundaries, runtime flows, data/integrations, or technical constraints and risks change |
| Developing and checking changes                  | `docs/development.md`                         | [Development](assets/templates/development.md)   | Setup, tooling, test strategy, or the team's contribution process changes               |
| Running, updating, and recovering software       | `docs/operations.md`                          | [Operations](assets/templates/operations.md)     | Use, update, recovery, or actual delivery/support obligations change                    |
| Significant decision rationale, only when useful | The existing decision-record convention       | [Decision](assets/templates/decision.md)         | A consequential decision is accepted, replaced, or has materially changed consequences  |

The responsibilities are concrete; the filenames and number of pages are flexible. Keep a small capability in the product page. Split a growing capability by coherent behavior, not by every task or release. Use existing generated API/schema references instead of manually duplicating their contracts. Keep glossary terms near their owner unless a shared glossary solves a real retrieval problem. Keep active technical risks with architecture or operations; transient investigation questions belong in work records.

## Fit the actual use and delivery

Choose the relevant scope from existing project evidence and the user's intent, following [ownership](ownership.md). These examples guide adaptation; they are not mandatory profiles or a new configuration field.

| Actual use                        | Useful current reference                                                                    | Documentation consequence                                                                                                                         |
| --------------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Local app or direct use of `main` | Relevant branch/commit and checks; running checkout if that is the claim                    | Keep current behavior and run/check guidance. Omit a separate release/support section and operations page when they add no useful distinction.    |
| Continuous deployment             | Source revision plus successful deployment/verification for the environment being described | Describe what runs in that environment and its real update/recovery procedure. Tags and release notes are optional unless the team requires them. |
| Formal or versioned delivery      | The team's release records, required approvals/checks, artifacts, and support commitments   | Retain the required release, rollback, readiness, and supported-version guidance. Link existing process owners rather than replacing their rules. |

An active personal app can need real data recovery or operating guidance; a company prototype can have no production delivery yet. Match the affected use and commitments rather than assigning process by project category. No release stage, production-readiness checklist, or support matrix is required just because the template mentions one. Include revision detail when it helps establish a claim; unrelated merges do not require refreshing every page or adding a per-commit documentation log.

## Adapt a selected body

1. Check the existing claim owner and evidence using [ownership](ownership.md). A maintained architecture topic in knowledge may already fill the architecture responsibility; link it from the router and skip a new architecture page.
2. Fill `{{placeholders}}` from approved decisions or scoped evidence. Replace path placeholders with real links, and remove author comments and sections that do not apply. Do not publish filler, an unverified command, an invented approval, or an invented release fact. Keep a material unknown explicit in the smallest useful owner.
3. State intent and actual behavior separately where they differ. An approved requirement is not an assertion that code satisfies it. Use the relevant implementation revision, running checkout, environment, or supported version as the scope. A checked merge can establish behavior on `main`; it does not by itself prove that a running instance updated. Add a distinct release state only when the project has one.
4. Point to the owning task/spec for a pending change and to source, tests, or release records for evidence. A brief reader-facing consequence belongs here; steps, acceptance checklists, and execution logs stay with their work owner. Stable product quality requirements can remain in the behavior owner and be linked from a task's acceptance checks.
5. Check filled links and factual support. Retire superseded claims for the same scope when justified; keep useful rationale and supported versions. Use Git and existing work/release history instead of appending an edit diary or making an archive copy after each change.

No universal metadata header or duplicate ownership register is required. Identify scope, responsible team, and evidence where they help a reader assess the claim. Follow existing knowledge metadata and checker requirements only when actually writing knowledge.

## Respond to relevant lifecycle events

These are update contexts, not a required sequence of project stages.

- **Init:** a brief product owner and router can capture agreed scope and meaningful unknowns. Leave technical and operating pages absent until there is something useful to describe.
- **Plan:** link the current owners from the task/spec; keep the proposed delta, steps, and acceptance there. A pending summary in current docs is useful when readers need to know an approved change is not yet delivered.
- **Implement:** update affected current owners with evidenced reality. Preserve the approved requirement when code is incomplete or incorrect. Current `main` can be the project's maintained behavior scope.
- **Deliver, when applicable:** update running/deployed or supported scopes from the evidence relevant to that delivery method. Retain separate release and older-version claims only where those distinctions and commitments exist.
- **Compact:** replace obsolete current guidance and remove resolved pending summaries; retain consequential rationale in a decision record when useful. A decision record is not required for ordinary edits.

Read the [new-project example](examples/new-project.md) for a minimal initial output, the [main-latest example](examples/main-latest.md) for an app already used during development, or the [adopted-project example](examples/adopted-project.md) for an existing owner map and versioned delivery. Select only the relevant example. They are synthetic illustrations, not evidence about real applications.

## Design references

These templates adapt selected concerns from [arc42](https://arc42.org/overview/) and [C4](https://c4model.com/diagrams) for system understanding, [Diátaxis](https://diataxis.fr/) for reader needs, and [architecture decision records](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) for consequential rationale. They do not require every section, diagram, or document in those approaches and do not claim standards compliance.
