# Project-doc ownership

## Assign authority by topic

For each fact or topic, identify one current owner and make other surfaces point to it or summarize only what their own purpose needs. Ownership follows the meaning and scope of a claim, not a blanket rule that all Markdown in one directory wins. Retain a fitting source already owned by the project team, including a source outside the repository, instead of copying it into an agent-owned file. Respect access and edit permissions for those sources.

Retain an existing owner whose claims are evidenced, correctly scoped, and still maintained there, including a knowledge topic. Directory and whether people or agents read it are not sufficient reasons to move it. For example, an existing architecture synthesis in knowledge can remain authoritative, with the docs router linking to it. Source code may support that synthesis without making it a project-doc obligation. The table below guides ownership where it is missing or unsuitable; it does not override a valid existing owner.

| Claim                                                                           | Likely owner                                                                                            |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Agreed product behavior, domain rules, and active constraints                   | Current project docs or an existing team/business source                                                |
| Actual code behavior, API, schema, configuration, and supported deployment      | Source, schema, generated reference, or evidence-backed project reference, according to the topic       |
| Proposed changes, work steps, acceptance checks, and execution evidence         | The chosen task, spec, issue, or other work record                                                      |
| Durable technical facts with no suitable existing owner and agent-facing routes | Knowledge topic and its map; when another owner exists, keep the topic a concise route or distinct fact |
| Current session/work state and next action                                      | Existing CONTEXT/task/spec surface                                                                      |
| History and prior execution                                                     | Git, release records, or archived work; a decision record only if its rationale is still useful         |

The project's existing docs router is the entry point. If a router is useful and none exists, `docs/README.md` is a default only when it fits the repository; a small project may need only one current page. The router should direct readers to the owner for each relevant topic and identify unresolved or unverified claims. Do not create a mandatory doc set, parallel backlog, owner database, or empty file merely to satisfy a category.

Changing owners requires a concrete reason such as overlap, scope mismatch, or changed maintenance responsibility, within the user's existing authorization. Do not request per-file reconfirmation for an already authorized move. When evidence cannot resolve competing owners, leave their content intact and report the decision needed. Knowledge changes still follow the selected runtime's capture and checker contract.

## Keep intent and reality distinct

An approved product direction describes what the project intends to build. Code, tests, release artifacts, and operating evidence describe what currently works or has shipped. A proposed but unapproved direction is neither. For example, if E is approved while the application still implements C, state E as the approved direction and C as current behavior, with the gap visible. Do not present E as implemented, or treat current C as proof that C remains the desired product behavior. Supported older versions may retain their own documented behavior.

When a formerly approved A, B, or C is truly superseded by E for the same scope, keep E in the current intent owner once its approval is established. Replace claims about implemented or released behavior only when implementation or release evidence supports them. Retain only rationale that still helps current decisions. Preserve older supported behavior and any genuinely distinct scope. Use existing history for chronology; do not append every transition to current guidance or create an archive copy on every edit.

## Reconcile a disputed claim

1. Name the exact claim, audience, scope, and candidate owners. Check source and decision evidence before choosing the winner; a newer timestamp or a longer document is not proof.
2. Separate what is approved, implemented, released, proposed, and unknown. If evidence is incomplete, mark the gap in the appropriate current surface rather than asserting a replacement.
3. Update the chosen owner and affected links or short summaries together when edits are authorized. Keep task/spec execution evidence in its work record. Apply the selected runtime's knowledge write and checker contract if changing `.codex/knowledge/` or `.claude/knowledge/`.
4. If a conflict depends on a team decision or a source outside edit authority, report the precise question and keep that source intact. Do not silently take ownership by copying it.
