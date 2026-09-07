# CLAUDART Repository Instructions

This file applies only when working on the **CLAUDART source repository itself**. It is repository-maintainer guidance, not part of the installable Claude layer and must not be copied into downstream projects.

- For Git/GitHub operations in this repository — issues, branches, commits, pull requests, merge strategy, and post-merge cleanup — read and follow `CONTRIBUTING.md`.
- Downstream repositories own their own Git workflow. Do not encode CLAUDART's repository contribution policy inside `.claude/`, `.codex/`, `.agents/`, `install.sh`, or the downstream integration payload.
- For Claude-specific CLAUDART operating-layer guidance, also follow `.claude/CLAUDE.md` and the relevant files it routes to.
- Keep repository contribution changes scoped and preserve parity only where the underlying CLAUDART product concept is actually mirrored across Claude and Codex.
