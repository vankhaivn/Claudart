# Task workspace regression checks

Run `npm run test:task-workspaces` or `bash tests/task-workspaces/run.sh`.

The suite checks the shipped Claude/Codex Markdown contracts and their consumers: one required `TASK.md`, explicit artifact triggers, small-task restraint, shallow discovery, approval locks, whole-workspace archival, optional-artifact health, and empty template dashboards. The runtime-neutral artifact contract must agree across both mirrors.

Disposable filesystem examples exercise shallow discovery and sequence reservation, review-gated archival, destination collisions, workspace-relative links, and byte preservation for JSON, PNG-like binary data, ZIP, and tgz inputs. The discovery and archival helpers are test-only examples of the documented protocol, not an installed task runner. Fixtures are synthetic and created under `mktemp`; no live task or artifact is shipped in the installable runtime trees.

These tests protect prompt contracts and filesystem assumptions. They do not run Claude or Codex and do not prove that a model follows the instructions end to end. Binary payloads are not parsed or rendered; archival must preserve their bytes regardless of file type.
