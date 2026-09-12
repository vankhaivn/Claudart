# Interview Lenses

Use this reference only after the initial idea reveals a plausible project type, distribution path, or delivery context. Read the matching sections rather than treating the file as a questionnaire. Reclassify the project when later evidence contradicts the initial lens.

## Project Type Lenses

- **Personal local app**: operating system, offline behavior, local files/database, backup/export, install/run method, updates, no-login default.
- **Household or hobby app**: household users, device sharing, simplicity, privacy, durability, fun versus utility.
- **App or SaaS**: users, permissions, onboarding, core workflows, billing, analytics, support.
- **Website or brand presence**: audience, message hierarchy, content model, conversion paths, visual direction, publishing workflow.
- **Internal company tool**: operators, repetitive tasks, data sources, access control, auditability, deployment environment, support owner, company data policies.
- **Automation or agent workflow**: trigger, input, decision points, human approval, failure modes, logs, rollback.
- **Library, SDK, or developer tool**: target developer, API surface, examples, compatibility, versioning, support burden.
- **Data or AI product**: data provenance, evaluation criteria, privacy, model behavior, human review, drift monitoring.
- **Content, course, or community product**: editorial promise, format, cadence, moderation, distribution, success metrics.
- **Game or toy project**: target age, core game loop, session length, controls, difficulty curve, assets/audio, scoring, offline play, child safety, ads or in-app purchases.
- **Mobile app for public stores**: target platform, distribution path, account type, testing track, privacy policy, permissions, screenshots, review risks, release/update plan.

## Discovery Map

Use only the branches needed to fill material gaps. Do not walk the map mechanically.

### Project Intent

- What is the project trying to make possible, and why now?
- What would make it obviously successful?
- What should remain unbuilt even if tempting?

### Audience And Stakeholders

- Who uses it directly, and who benefits without using it?
- Who approves, funds, operates, supports, or sells it?
- What does each stakeholder care about?

### Problem And Current Alternatives

- What painful situation exists today, and how is it handled now?
- What is broken, slow, expensive, risky, or annoying about the current way?
- What would users lose if the project never existed?

### Product Shape

- What are the core journeys and the smallest useful version?
- What must be delightful, reliable, or fast from day one?
- What can be manual, simulated, or deferred initially?

### Domain Language

- What nouns, verbs, statuses, roles, and lifecycle terms does the domain use?
- Which terms are overloaded, ambiguous, or candidates for canonical language?
- Which relationships and cardinalities are already clear?

### Data And Integrations

- What data enters, changes, and leaves the system?
- Which systems, APIs, devices, files, or humans are involved?
- What data is sensitive, regulated, business-critical, or needs history and auditability?

### Experience And Presentation

- What form should the project take?
- What should a first-time user understand immediately?
- What should be easy to demo, and what story should a stakeholder presentation tell?

### Distribution And Runtime

- Where will it run: one local device, a company environment, a private server, mobile devices, or public stores?
- Does delivery require source, an installer, an executable, APK/AAB, container image, or another package?
- Who may install it, how will they receive updates, and which stores or countries are in scope?

### Technical Direction

- Which stacks, platforms, hosting limits, devices, or team skills constrain it?
- Which performance, security, privacy, compliance, localization, or accessibility constraints matter?
- What should remain simple while the project is early, and which risks need a spike?

### Delivery And Readiness

- What is the MVP boundary, and what belongs in later milestones?
- Which decisions must precede coding?
- How much time, money, and complexity is acceptable for the first version?
- Which risks or stakeholder objections could make the project not worth building?

## Distribution-Specific Checks

Apply only a matching section.

### Local Laptop App

- Default away from accounts, cloud services, analytics, and complex deployment unless requested.
- Ask about OS, offline use, file locations, backup/export, startup method, and acceptable manual setup.
- Recommend the simplest runnable form first in implementation readiness.

### Internal Company Tool

- Ask about identity provider, roles, data ownership, audit logs, deployment network, support owner, and access approval.
- Mark compliance and security assumptions instead of inventing company policy.
- Distinguish a quick internal prototype from a production internal system.

### Game For Children Or Family

- Ask about target age, reading level, controls, session length, difficulty, win/lose conditions, audio, and device.
- Default to offline use without ads, in-app purchases, accounts, or external tracking unless explicitly requested.
- Include safety and content constraints in requirements.

### Public Mobile App Or Google Play

- Distinguish sideloading/private sharing, internal testing, company-managed distribution, and public store release.
- Ask whether the developer account is personal or organizational and whether it is new.
- Verify current requirements from official Android Developers or Play Console Help sources before finalizing publishing requirements.
- Research target SDK/API, testing tracks, app content declarations, Data safety, privacy policy, permissions, signing, store assets, and review timing as applicable.
- Date and cite policy facts in raw discovery, risks/open questions, and implementation readiness.
