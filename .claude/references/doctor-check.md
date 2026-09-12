# Mechanical doctor checks

Use `doctor-check.sh` for the mechanical part of doctor or an installation verification. It reads the selected CLAUDART layer and calls the existing sibling `knowledge-check.sh` once. It does not repair files, run application code, fetch URLs, or decide whether instructions and project claims are correct.

## Run

```bash
# Installed downstream project; run only the selected layer.
bash .codex/scripts/doctor-check.sh --root . --layer codex
bash .claude/scripts/doctor-check.sh --root . --layer claude

# Validate another project using the trusted upstream copy.
bash /tmp/claudart-src/.codex/scripts/doctor-check.sh --root /path/to/project --layer codex

# CLAUDART source checkout: use the installable loader, not maintainer AGENTS.md.
bash .codex/scripts/doctor-check.sh --root . --layer codex --layout source

# Also inspect explicit links in project Markdown outside the default sources.
bash .codex/scripts/doctor-check.sh --root . --layer codex --include docs
```

`--root` and `--layer` default to the script's location; `--layout` defaults to `installed`. `--include` is repeatable and selects an additional Markdown file or directory inside the target repository. `--today YYYY-MM-DD` makes date checks repeatable; `--fail-on warning` treats warnings as failures. Bash 3.2 and common POSIX utilities are sufficient; no package installation is required. Keep the script and any adjacent helper files together when using a trusted upstream copy against another root.

## Coverage and boundaries

- Check required selected-layer structure, readable loaders, core rules/guidelines and workflows, declared metadata fields/types, and relevant size limits. Empty lazy workspace seeds and absent transient handoff files are normal. Optional modules are checked when present; no byte comparison against upstream or required inventory of shipped specialist names is imposed.
- Inspect explicit Markdown links and reference definitions outside examples, and actual Claude loader imports. Resolve relative links from their containing file and leading `/` links from the target repository root. Common space/dot/slash URL encodings are supported; other encoded destinations are reported for review. Targets can be source code or docs anywhere inside that root; only existence is checked, not the target file's contents or heading/symbol anchors.
- Default Markdown sources are the selected loader, rules/guidelines, commands/skills and their resources, plus shared references. Task/spec bodies and attachments, journals, and arbitrary project docs are not recursively audited. Use `--include` for additional project Markdown. Knowledge remains the existing checker's responsibility.
- Skip fenced examples, inline code, comments, URLs, and template/glob destinations. Bare path mentions are not definite references. Do not follow links into arbitrary project docs to expand the scan automatically. Symlink references are reported for review. `.env`-named paths, `.local`, `.git`, and dependency directories are excluded from source scanning; the checker is not a general secret detector.
- Metadata checks cover the documented CLAUDART scalar/inline-array conventions and known config fields. They are not a full YAML/TOML parser. Unsupported custom syntax is surfaced for review instead of being silently accepted as validated or assumed malformed. Custom model names and additional fields are not rejected merely for differing from upstream.

The checker does not decide whether a zero-match glob is obsolete, two agents overlap, a code example is useful, a prose mention causes auto-loading, or a claim is true. It also does not validate task/spec state transitions, archive/index consistency, or artifact semantics; doctor retains those checks separately.

## Interpret output

Findings use `SEVERITY|CODE|path:line|message`. `D` codes belong to doctor checks; `K` findings retain the knowledge checker's original codes and severities. Paths are relative to the target repository. The report avoids printing document bodies or configuration values.

- **Exit 0:** no finding meets the selected failure threshold. Review warnings and unsupported checks; this is not a declaration of semantic health.
- **Exit 1:** contract findings meet that threshold. Report them with their original paths and severities.
- **Exit 2:** usage/runtime failure or an incomplete mandatory checker. Report the failure; never declare the installation healthy.

Do not run knowledge validation again after this wrapper has invoked it. If the wrapper itself is missing, the doctor workflow may use the legacy knowledge checker once and report the broader mechanical checks as unavailable. Never manufacture a replacement parser during a doctor run.
