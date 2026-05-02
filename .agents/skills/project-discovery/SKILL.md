---
name: project-discovery
description: Interview a user with a rough project idea, synthesize raw discovery notes, and create presentation-ready project documentation. Use when the user wants to clarify a new project before coding, define a product spec from vague ideas, or prepare project docs for stakeholders.
---

# Project Discovery

Use this skill as the Codex-native equivalent of Claude Code `/project-discovery`.

Read `.codex/commands/project-discovery.md` for the full discovery interview protocol.

The workflow is:

1. Interview the user one question at a time.
2. Maintain confirmed facts, assumptions, rejected options, open questions, domain language, and scope boundaries.
3. Use the user's language for the interview and generated docs unless they ask for another language.
4. Match the interview and docs depth to the project: Lite for personal/local/family projects, Standard for serious solo or internal tools, Full for stakeholder handoff or public publishing.
5. Keep asking until the project can be explained clearly to another person.
6. Stress-test the working model for problem/appetite/solution fit, risks, no-gos, stakeholder objections, distribution path, and implementation readiness.
7. Write `docs/project/00-raw-discovery.md` first.
8. Split the raw synthesis into the smallest useful structured project docs defined in the command protocol.

Do not start implementation code from this skill. Its output is documentation and project clarity.
