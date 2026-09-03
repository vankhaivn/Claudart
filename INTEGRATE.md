# Integrate CLAUDART with your agent (AI-native install)

**You are an AI coding agent** (Claude Code, Codex CLI, or similar) and your user linked this file because they want to **adopt or upgrade CLAUDART** in the current project. CLAUDART is a plain-Markdown operating layer for commands or skills, layered memory, persistent work, project knowledge, and specialized agents.

Source of truth: <https://github.com/vankhaivn/Claudart> (branch `main`).

This file is a **protocol, not an installer**. Follow it top to bottom. It exists because a fresh-copy installer cannot safely reconcile custom instructions, live state, tasks, specifications, or project knowledge.

> **Version-agnostic delta rule.** Never assume which CLAUDART release, feature set, or file layout the downstream project started from. Derive the delta during this run from current upstream, the current downstream tree, and upstream history only where history is actually needed.
>
> **Golden rule — read freely, write only what is approved.** NEVER overwrite, delete, or relocate user-authored content without showing the proposed change and receiving explicit approval. Default to preserving the user's work.
>
> **"Customized" means user-authored content, not every local difference.** A CLAUDART-shipped file whose local copy merely matches an older upstream state is stale, not custom. Upgrade stale template content; preserve and deliberately re-apply real project-specific additions.
>
> **Mechanical verification first; semantic maintenance only when justified.** Every integration gets a bounded, read-only verification pass. Do not run `doctor → refactor-memory → doctor` merely because files were installed or upgraded. Doctor is conditional and diagnostic; refactor-memory is write-capable and requires a concrete finding plus explicit approval.
>
> **Integration validation precedence.** Step 4 governs this integration run. Generic first-run suggestions elsewhere do not make doctor or refactor-memory mandatory here.

---

## Step 0 — Diagnose first, then fetch proportionally

1. Work from the project root. Run `git status --short` when Git is available, record unrelated work, and do not disturb it.
2. Inventory only relevant AI paths: `.claude/`, `.codex/`, `.agents/skills/`, root or nested `CLAUDE.md`, root `AGENTS.md`, and any overlapping custom commands, agents, rules, memory, tasks, specs, or knowledge.
3. Resolve the target layer:
   - explicit user choice wins;
   - otherwise default to the runtime already present;
   - if neither exists and the active agent runtime makes the choice obvious, state that assumption in the plan instead of asking unnecessarily;
   - if both are selected, classify each layer independently.
4. Classify each selected layer:
   - **A — Clean adopt:** no meaningful AI operating layer exists yet; a bare loader file is allowed.
   - **B — Merge into an existing workflow:** the project already has its own agents, commands, rules, memory, or work conventions.
   - **C — Upgrade an existing CLAUDART install:** recognizable CLAUDART files are already present.
5. Get current upstream into `/tmp/claudart-src`:

   ```bash
   rm -rf /tmp/claudart-src
   ```

   For Scenario A, or the initial pass for Scenario B:

   ```bash
   git clone --depth 1 --branch main https://github.com/vankhaivn/Claudart /tmp/claudart-src
   ```

   For Scenario C, clone full history. For Scenario B, deepen only when a real collision needs stale-vs-custom evidence:

   ```bash
   git clone --branch main https://github.com/vankhaivn/Claudart /tmp/claudart-src
   # Or, after a shallow clone:
   git -C /tmp/claudart-src fetch --unshallow
   ```

   If cloning is unavailable, fetch current raw files on demand from `https://raw.githubusercontent.com/vankhaivn/Claudart/main/<path>`. Without history, preserve ambiguous differences and show the exact uncertainty instead of guessing.

6. Enumerate the actual selected-layer payload from current upstream. Read `install.sh` as a payload and relocation reference, plus the loaders and every file in the proposed dependency closure. README, workflow, and contributing docs are orientation only; read them only when a real ambiguity requires them.
7. Treat `install.sh` as a payload reference, not a merge tool. Do not execute it during Scenario B or C, do not use `--force`, and do not run any write-capable maintenance workflow before approval.

## What CLAUDART contains

This map is orientation only; the current source tree and its references are authoritative.

**Claude layer** (`.claude/`):

- `commands/`, `agents/`, and path-scoped `rules/`;
- `knowledge/INDEX.md` plus optional maps and topics;
- read-only scripts under `scripts/`;
- `CLAUDE.md`, `CONTEXT.md`, and append-only `JOURNAL.md`;
- persistent `tasks/` and mission-scale `specs/`.

**Codex layer** (`.codex/` + `.agents/skills/`):

- Codex-native skills under `.agents/skills/codex-*`;
- `.codex/guidelines/`, `.codex/knowledge/`, `.codex/scripts/`, `.codex/agents/`, and `.codex/config.toml`;
- `.codex/CONTEXT.md`, `.codex/JOURNAL.md`, `.codex/tasks/`, and `.codex/specs/`;
- `.codex/AGENTS.md` as the source template for the canonical downstream root `AGENTS.md`.

When integrating both layers, preserve intent parity between mirrored Claude and Codex contracts without forcing byte identity where tool mechanics differ.

## Step 1 — Derive the current delta

Before proposing writes, distinguish:

- **template-owned protocol:** commands, skills, rules, guidelines, agents, scripts, config, and other files intended to track current upstream;
- **merge-owned indexes:** loaders and indexes whose project routes and ordering must be preserved;
- **live state:** `CONTEXT.md`, `JOURNAL.md`, handoffs, task/spec bodies, mission folders, knowledge topics/maps, and equivalent project-owned state;
- **project-owned custom content:** instructions or workflows authored specifically for this project.

### Scenario A — Clean adopt

Copy the current selected-layer payload. Splice CLAUDART routes into any existing canonical or overlapping loader, including `.claude/CLAUDE.md`, root `CLAUDE.md`, or root `AGENTS.md` as applicable; never replace project-authored loader content. For missing live-state files, create only the current empty seed/header. For Codex, place the source loader at the current canonical downstream location, normally root `AGENTS.md`, and avoid two competing loaders.

Scenario A is the fast path: do not inspect full history and do not schedule doctor or refactor-memory when Step 4 verification can prove the installation mechanically.

### Scenario B — Merge into an existing workflow

For each current CLAUDART concept:

- **Upstream-only path** → propose adding it and explain its role.
- **Same concept, different file** → do not overwrite; propose keeping one, merging responsibilities, or keeping both under distinct names and triggers.
- **Same filename** → merge sections, preserving project-authored content and ordering.
- **Competing memory or work system** → map responsibilities and let the user choose one authority; never silently leave two systems owning the same job.
- **Project-only path** → preserve it unless retirement or relocation is explicitly approved.

Derive the complete dependency closure for each accepted concept from current upstream. Include every selected-layer file that defines, routes, invokes, validates, installs, or mirrors it.

### Scenario C — Reconcile an existing CLAUDART install

Diff the actual installed state against current upstream; do not assume all local files came from one revision. Classify every relevant path:

- **Equivalent** → keep and record `unchanged`.
- **Upstream-only** → inspect references and, when needed, history to distinguish an addition from a rename, move, split, consolidation, or replacement.
- **Stale template copy** → local content matches an earlier upstream state and has no user-authored additions; propose replacing it with current upstream verbatim.
- **Genuinely diverged** → use current upstream as the base and deliberately re-apply or relocate the exact project-authored additions.
- **Downstream-only** → preserve project-authored paths; for former template paths, propose an explicit relocation or retirement and identify the current owner.
- **Live state** → preserve its body; reconcile only its current contract or routing through the workflow that owns it.

Apply the stale-vs-custom test narrowly:

1. Never call a file custom merely because it differs from current upstream.
2. Point to the exact local lines believed to be user-authored.
3. Use history only for the relevant path or phrase, for example:

   ```bash
   git -C /tmp/claudart-src log --all --follow -- <path>
   git -C /tmp/claudart-src log -S'<distinctive local phrase>' --all -- <path>
   ```

4. If local content matches a past upstream state and contains no project-specific addition, it is stale.
5. If evidence remains ambiguous, show the specific lines and ask about those lines, not the entire file.

Produce a reconciliation report covering unchanged, upstream-only, stale replacements, genuine custom merges, moves or consolidations, retirement candidates, preserved downstream-only paths, untouched live state, and review-needed ambiguities. Preserve every live knowledge topic, map, and project-specific route; shipped indexes are merge templates, not replacements for project knowledge.

## Step 2 — Present the plan and wait

Before writing, classify the planned result under these actions:

- `add`;
- `replace verbatim`;
- `merge`;
- `relocate`;
- `retire`;
- `preserve unchanged`;
- `skip`;
- `review-needed`.

List exact paths for every write, merge, relocation, retirement, or ambiguity. Unchanged paths may be grouped by tree and count. For a collision-free Scenario A tree copied verbatim, you may report it as one grouped add with a generated file count instead of explaining every file; still list loader placement and live-state seeds separately. Any collision or non-verbatim action must be path-specific.

For each merge, identify what current upstream content will be introduced and what downstream content will be preserved or relocated. For each retirement, identify the replacement or current owner. Mark live-state files explicitly as preserved.

Also state the validation profile: mandatory fast verification, any already-justified targeted semantic review, whether a full doctor trigger exists, and that refactor-memory will not run without a later concrete finding and separate approval.

Wait for explicit approval before writing. Approval for this plan does not pre-approve additional normalization discovered later.

## Step 3 — Apply only the approved change

- Re-check `git status --short` and protect unrelated or parallel work.
- Apply the approved dependency closure atomically per concept where practical.
- Keep template-owned files verbatim unless an explicit merge was approved.
- Prefer relocating project-specific additions to project-owned rules, guidelines, knowledge, or loader sections so core protocol files can track upstream cleanly.
- Splice loaders and indexes; never wholesale-replace project routing or ordering.
- Never overwrite existing `CONTEXT.md` or `JOURNAL.md`; never import, overwrite, or create `HANDOFF.md`; never replace task bodies, spec mission folders, knowledge topics, or maps with template content.
- Create only missing seeds, indexes, or placeholders that were listed and approved.
- Do not touch `.env`, secrets, ignored private files, or unrelated project files.
- If an unplanned conflict or required write appears, stop before that write and present an amended path-level plan.
- Do not commit, push, or merge.

## Step 4 — Validate and hand off

### 4.1 Mandatory fast verification — read-only

Run bounded mechanical checks against the selected layers and changed dependency closure. Validation may use `/tmp`, but it must not mutate the project tree.

1. Check scope and patch integrity:

   ```bash
   git status --short
   git diff --name-status
   git diff --check
   ```

   Skip Git-specific checks only outside a Git repository. Confirm every changed path was approved and unrelated changes remain untouched.

2. Confirm every approved add, replacement, merge, relocation, and retirement reached its intended final path.
3. Compare every supposedly verbatim template-owned file with current upstream using `cmp`, checksums, or `git diff --no-index`, accounting only for approved relocation. Any unexplained drift fails verification.
4. For merged loaders and indexes, confirm both the required current CLAUDART routes and the project-authored sections identified in the plan remain present.
5. Confirm referenced commands, skills, rules, guidelines, agents, scripts, indexes, and config paths exist; no loader, rule, or guideline auto-loads `JOURNAL.md` or `HANDOFF.md`; existing live-state bodies were not replaced; changed shell scripts pass `bash -n`; changed command/skill/agent/rule/guideline frontmatter still satisfies the current upstream contract; and mirrored contracts remain consistent when both layers changed.
6. Inspect current upstream `scripts/`. If it ships a documented read-only installation verifier that can target another root, run it exactly as documented. If none exists, that absence is not a failure; run the current upstream knowledge checker for each selected layer instead. With the current interface:

   ```bash
   bash /tmp/claudart-src/.claude/scripts/knowledge-check.sh \
     --root "$PWD" --layer claude

   bash /tmp/claudart-src/.codex/scripts/knowledge-check.sh \
     --root "$PWD" --layer codex
   ```

   Run only selected layers. If current upstream `--help` differs, follow it instead. Prefer the trusted source script over an unreviewed downstream copy.

A mechanical failure may be fixed immediately only when its fix is already inside the approved plan. Any additional write requires a new proposed diff and explicit approval.

### 4.2 Semantic review and doctor are conditional

Do **not** run doctor solely because integration occurred. If fast verification passes and none of the triggers below exists, stop after the fast verification. Scenario A defaults to this fast path; Scenario B and C also use it for purely mechanical additions, verbatim stale-template replacements, and approved relocations that do not change semantic ownership.

When semantic judgment is needed, first review only the changed files and their dependency closure. Run the selected layer's full read-only doctor once only when at least one trigger exists:

- competing instructions, routing, memory, or work systems were merged;
- project-authored content moved between rules/guidelines, knowledge, state, tasks, specs, or loaders;
- rule scope, agent responsibility, task/spec lifecycle, or knowledge ownership changed semantically;
- history left a material `review-needed` ambiguity;
- deterministic verification found a problem that cannot be decided mechanically;
- the affected contract is repository-wide;
- the user explicitly requested a full health audit.

When triggered, run `/doctor` for Claude or `$codex-doctor` for Codex. Doctor is diagnostic only. Report findings; do not turn them into automatic writes.

### 4.3 Refactor-memory is opt-in

Never run `/refactor-memory` or `$codex-refactor-memory` automatically after integration. Run it only when a concrete finding is owned by that workflow, the exact additional files and intended changes are presented, and the user explicitly approves those writes.

After an approved refactor-memory run, repeat mandatory fast verification. Repeat doctor only when the original finding requires semantic confirmation or the user explicitly requests it. There is no default `doctor → refactor-memory → doctor` chain.

### 4.4 Report the result

Summarize the scenario and selected layer, paths added/replaced/merged/relocated/retired/preserved/skipped/review-needed, verification commands and results, why doctor was or was not run, and any normalization still awaiting approval. Remind the user to review `git diff` before committing.

This protocol is idempotent: a later run derives a fresh delta from the then-current upstream and downstream state.

## Cleanup

Remove the temporary source after all comparisons and validation are complete:

```bash
rm -rf /tmp/claudart-src
```
