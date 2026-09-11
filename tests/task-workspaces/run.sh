#!/bin/bash

set -u
LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P) || exit 2
REPO_ROOT=$(CDPATH='' cd -- "$TEST_DIR/../.." 2>/dev/null && pwd -P) || exit 2
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/claudart-task-tests.XXXXXX") || exit 2
trap 'rm -rf -- "$TMP_ROOT"' EXIT
PASS_COUNT=0
FAIL_COUNT=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf 'ok %s - %s\n' "$((PASS_COUNT + FAIL_COUNT))" "$1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf 'not ok %s - %s\n' "$((PASS_COUNT + FAIL_COUNT))" "$1" >&2
}

assert_contains() {
  if [ -f "$1" ] && grep -Fq -- "$2" "$1"; then
    pass "$3"
  else
    fail "$3 (missing '$2' in ${1#"$REPO_ROOT/"})"
  fi
}

assert_not_contains() {
  if [ ! -f "$1" ]; then
    fail "$3 (missing file ${1#"$REPO_ROOT/"})"
  elif grep -Fq -- "$2" "$1"; then
    fail "$3 (unexpected '$2' in ${1#"$REPO_ROOT/"})"
  else
    pass "$3"
  fi
}

# These checks protect the shipped Markdown instructions. They do not simulate
# an agent or claim that prompt wording guarantees runtime compliance.
if /bin/bash -n "$TEST_DIR/run.sh"; then
  pass "Bash syntax is valid"
else
  fail "Bash syntax is valid"
fi

for layer in claude codex; do
  if [ "$layer" = claude ]; then
    rule="$REPO_ROOT/.claude/rules/task-management.md"
    commands="$REPO_ROOT/.claude/commands"
    plan="$commands/plan.md"
    start="$commands/start.md"
    checkpoint="$commands/checkpoint.md"
    doctor="$commands/doctor.md"
    refactor="$commands/refactor-memory.md"
  else
    rule="$REPO_ROOT/.codex/guidelines/task-management.md"
    commands="$REPO_ROOT/.agents/skills"
    plan="$commands/codex-plan/SKILL.md"
    start="$commands/codex-start/SKILL.md"
    checkpoint="$commands/codex-checkpoint/SKILL.md"
    doctor="$commands/codex-doctor/SKILL.md"
    refactor="$commands/codex-refactor-memory/SKILL.md"
  fi

  for file in "$rule" "$plan"; do
    assert_contains "$file" 'YYYY-MM-DD-NNN-<slug>/TASK.md' "$layer uses the workspace entrypoint"
    assert_contains "$file" '**Default to `TASK.md` only.**' "$layer starts without attachments"
    assert_contains "$file" 'native-format' "$layer defines the native-format trigger"
    assert_contains "$file" 'important details would be lost in a short summary' "$layer defines necessary retained evidence"
    assert_contains "$file" 'Substantial task-specific research' "$layer defines the research trigger"
    assert_contains "$file" 'Short findings' "$layer keeps small discoveries inline"
    assert_contains "$file" 'Link existing project files' "$layer avoids duplicated canonical files"
    assert_contains "$file" 'mandatory repository checks' "$layer retains required verification"
    assert_contains "$file" 'forced session rotation' "$layer forbids spec-style ceremony"
    assert_contains "$file" 'Never automatically extract archives, execute attachments, or load all supporting files.' "$layer does not auto-process attachments"
    assert_not_contains "$file" 'One task per file.' "$layer drops the single-file storage restriction"
    assert_not_contains "$file" 'tasks/*.md' "$layer has no flat task discovery"
  done

  assert_contains "$rule" '`TASK.md` is the only required file' "$layer has one required document"
  assert_contains "$rule" 'tasks/*/TASK.md' "$layer discovers active workspaces shallowly"
  assert_contains "$rule" 'tasks/done/*/TASK.md' "$layer discovers archived workspaces shallowly"
  assert_contains "$rule" 'including incomplete workspaces' "$layer reserves incomplete workspace ids"
  assert_contains "$rule" 'At 999, report exhaustion rather than wrapping.' "$layer never wraps sequence numbers"
  assert_contains "$rule" 'Move the entire workspace' "$layer archives all supporting material"
  assert_contains "$rule" 'including a symlink' "$layer refuses archive destination collisions"
  assert_contains "$rule" 'Verify the move succeeded before updating references or journaling.' "$layer records only successful moves"
  assert_contains "$rule" 'Do NOT move the workspace' "$layer preserves the user completion gate"
  assert_contains "$rule" 'local-only' "$layer exposes non-portable inputs"
  assert_contains "$rule" 'no compatibility or automatic migration path' "$layer supports only the current layout"
  assert_contains "$plan" 'Honor an explicit request for a persistent plan' "$layer honors small explicit plans"
  assert_contains "$plan" 'File count alone is not a reason.' "$layer avoids unnecessary planning"
  assert_contains "$plan" 'If its status is not `planning`, leave this creation flow' "$layer resumes without resetting state"
  assert_contains "$plan" 'No implementation code, scaffolding, runnable POCs, or write-scope workers' "$layer closes the artifact planning loophole"
  assert_contains "$plan" 'before substantive exploration' "$layer can retain necessary findings as they arise"

  assert_contains "$start" 'tasks/*/TASK.md' "$layer startup can recover a missing index"
  assert_contains "$start" 'Read `TASK.md` frontmatter' "$layer startup reads metadata only"
  assert_contains "$start" 'Do not read task bodies or artifact contents' "$layer startup does not slurp workspaces"
  assert_contains "$checkpoint" 'tasks/done/*/TASK.md' "$layer checkpoint recognizes directory archives"
  assert_contains "$checkpoint" 'Move the entire workspace' "$layer checkpoint preserves attachments"
  assert_contains "$checkpoint" '**DO NOT archive `awaiting-review` tasks.**' "$layer checkpoint respects review"
  assert_contains "$checkpoint" 'checkpoint never creates supporting files' "$layer checkpoint does not manufacture artifacts"
  assert_contains "$doctor" 'Missing `artifacts/` or `### Workspace Files` is normal' "$layer doctor accepts the minimal workspace"
  assert_contains "$doctor" 'Do not read artifact bodies' "$layer doctor checks links without processing payloads"
  assert_contains "$doctor" '`None.` is valid' "$layer doctor does not demand filler"
  assert_contains "$refactor" 'TASK.md' "$layer maintenance recognizes the entrypoint"
  assert_not_contains "$refactor" 'tasks/*.md' "$layer maintenance has no flat task scan"

  for file in "$start" "$checkpoint" "$doctor"; do
    assert_not_contains "$file" 'tasks/*.md' "$layer consumer has no legacy active scan"
    assert_not_contains "$file" 'tasks/done/*.md' "$layer consumer has no legacy archive scan"
  done
  seed="$REPO_ROOT/.$layer/tasks/index.md"
  assert_contains "$seed" '<task-id>/TASK.md' "$layer seed points to the authoritative entrypoint"
  assert_not_contains "$seed" '](' "$layer ships no live task in its dashboard"
done

# Both mirrors must retain the same semantic artifact contract. This section is
# intentionally runtime-neutral; harness-specific policy remains elsewhere.
for layer in claude codex; do
  if [ "$layer" = claude ]; then
    rule="$REPO_ROOT/.claude/rules/task-management.md"
  else
    rule="$REPO_ROOT/.codex/guidelines/task-management.md"
  fi
  awk '/^## Artifact Discipline$/{capture=1; next} capture && /^## /{exit} capture{print}' \
    "$rule" > "$TMP_ROOT/$layer-artifact-contract"
done
if [ -s "$TMP_ROOT/claude-artifact-contract" ] && \
   cmp -s "$TMP_ROOT/claude-artifact-contract" "$TMP_ROOT/codex-artifact-contract"; then
  pass "Claude and Codex artifact contracts agree"
else
  fail "Claude and Codex artifact contracts agree"
fi

assert_contains "$REPO_ROOT/package.json" 'npm run test:task-workspaces' "repository check invokes this suite"
for file in "$REPO_ROOT/README.md" "$REPO_ROOT/README_VI.md" \
            "$REPO_ROOT/docs/WORKFLOW.md" "$REPO_ROOT/docs/WORKFLOW_VI.md" \
            "$REPO_ROOT/INTEGRATE.md"; do
  assert_contains "$file" 'TASK.md' "public documentation names the current entrypoint"
done

# Filesystem examples of the documented shallow discovery and archive protocol.
# Helpers are test-only examples, NOT an installed task engine or migration tool.
valid_id() {
  [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{3}-[a-z0-9]+(-[a-z0-9]+){1,4}$ ]] &&
    [ "${1:11:3}" != 000 ]
}

discover() {
  local root=$1 file dir
  for file in "$root"/*/TASK.md; do
    dir=${file%/TASK.md}
    [ -f "$file" ] && [ ! -L "$file" ] && [ ! -L "$dir" ] || continue
    valid_id "${dir##*/}" || continue
    printf '%s\n' "${dir##*/}"
  done
}

next_sequence() {
  local root=$1 date=$2 dir id number highest=0
  for dir in "$root"/"$date"-* "$root"/done/"$date"-*; do
    [ -d "$dir" ] && [ ! -L "$dir" ] || continue
    id=${dir##*/}
    valid_id "$id" || continue
    number=$((10#${id:11:3}))
    [ "$number" -le "$highest" ] || highest=$number
  done
  [ "$highest" -lt 999 ] || return 1
  printf '%03d\n' "$((highest + 1))"
}

archive_confirmed() {
  local root=$1 id=$2 source destination status
  valid_id "$id" || return 1
  source="$root/$id"
  destination="$root/done/$id"
  [ -d "$source" ] && [ ! -L "$source" ] && [ ! -L "$source/TASK.md" ] || return 1
  status=$(awk '/^---$/{n++; next} n==1 && /^status: /{print $2; exit}' "$source/TASK.md") || return 1
  case "$status" in done|cancelled) ;; *) return 1 ;; esac
  [ ! -e "$destination" ] && [ ! -L "$destination" ] || return 1
  mkdir -p "$root/done" || return 1
  mv -- "$source" "$destination"
}

seed_task() {
  mkdir -p "$1" || exit 2
  printf '%s\n' '---' "slug: $3" "status: $2" 'created: 2026-09-10' \
    'updated: 2026-09-10' 'agent: codex' 'delegation: none' 'tags: [test]' '---' \
    '# Synthetic task' > "$1/TASK.md"
}

root="$TMP_ROOT/tasks"
minimal=2026-09-10-001-small-change
bundle=2026-09-10-002-import-failure
cancelled=2026-09-10-003-dropped-change
seed_task "$root/$minimal" planning small-change
seed_task "$root/$bundle" awaiting-review import-failure
seed_task "$root/done/$cancelled" cancelled dropped-change
mkdir -p "$root/$bundle/artifacts/nested" "$root/2026-09-10-008-reserved-work"
printf '%s\n' 'not a task' > "$root/$bundle/artifacts/nested/TASK.md"
printf '%s\n' 'not a task' > "$root/done/TASK.md"
printf '%s\n' 'outside current contract' > "$root/2026-09-10-999-flat-task.md"
ln -s "$minimal" "$root/2026-09-10-004-linked-workspace" || exit 2
mkdir -p "$root/2026-09-10-005-linked-document"
ln -s "../$minimal/TASK.md" "$root/2026-09-10-005-linked-document/TASK.md" || exit 2
printf '%s\n' "$minimal" "$bundle" > "$TMP_ROOT/expected-active"
discover "$root" > "$TMP_ROOT/actual-active"
if cmp -s "$TMP_ROOT/expected-active" "$TMP_ROOT/actual-active"; then
  pass "shallow discovery excludes archives, nested attachments, flat files, and symlinks"
else
  fail "shallow discovery excludes archives, nested attachments, flat files, and symlinks"
fi
if [ ! -e "$root/$minimal/artifacts" ]; then
  pass "a minimal workspace has no artifact directory"
else
  fail "a minimal workspace has no artifact directory"
fi
if [ "$(next_sequence "$root" 2026-09-10)" = 009 ]; then
  pass "sequence allocation reserves incomplete directories and ignores flat files"
else
  fail "sequence allocation reserves incomplete directories and ignores flat files"
fi
mkdir -p "$root/done/2026-09-10-010-archived-reservation"
if [ "$(next_sequence "$root" 2026-09-10)" = 011 ]; then
  pass "sequence allocation includes archive reservations"
else
  fail "sequence allocation includes archive reservations"
fi
mkdir -p "$root/2026-09-10-999-last-reservation"
if next_sequence "$root" 2026-09-10 >/dev/null; then
  fail "sequence exhaustion does not wrap"
else
  pass "sequence exhaustion does not wrap"
fi

printf '%s\n' '{"synthetic":true,"result":"retained"}' > "$root/$bundle/artifacts/result.json"
# A PNG signature plus synthetic bytes and an empty ZIP end record exercise
# binary preservation. No parser, renderer, or archive extraction is involved.
printf '\211PNG\r\n\032\n\000fixture\377' > "$root/$bundle/artifacts/reference.png"
printf 'PK\005\006\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000' > "$root/$bundle/artifacts/input.zip"
tar -czf "$root/$bundle/artifacts/input.tgz" -C "$root/$bundle/artifacts" result.json || exit 2
printf '\n### Workspace Files\n\n- [Result](artifacts/result.json) - retained verification input.\n' >> "$root/$bundle/TASK.md"
cp -R "$root/$bundle/artifacts" "$TMP_ROOT/expected-artifacts" || exit 2
if archive_confirmed "$root" "$bundle"; then
  fail "awaiting-review cannot be archived"
else
  if [ -f "$root/$bundle/TASK.md" ] && [ ! -e "$root/done/$bundle" ]; then
    pass "awaiting-review cannot be archived"
  else
    fail "a refused archive preserves the source"
  fi
fi
sed 's/^status: awaiting-review$/status: done/' "$root/$bundle/TASK.md" > "$TMP_ROOT/confirmed"
cp "$TMP_ROOT/confirmed" "$root/$bundle/TASK.md" || exit 2
if archive_confirmed "$root" "$bundle" && [ ! -e "$root/$bundle" ]; then
  pass "confirmed completion moves the whole workspace"
else
  fail "confirmed completion moves the whole workspace"
fi
for name in result.json reference.png input.zip input.tgz nested/TASK.md; do
  if cmp -s "$TMP_ROOT/expected-artifacts/$name" "$root/done/$bundle/artifacts/$name"; then
    pass "archive preserves $name bytes"
  else
    fail "archive preserves $name bytes"
  fi
done
if grep -Fq '(artifacts/result.json)' "$root/done/$bundle/TASK.md" && \
   [ -f "$root/done/$bundle/artifacts/result.json" ]; then
  pass "workspace-relative attachment links survive archival"
else
  fail "workspace-relative attachment links survive archival"
fi
seed_task "$root/$cancelled" cancelled dropped-change
cp "$root/$cancelled/TASK.md" "$TMP_ROOT/collision-source"
cp "$root/done/$cancelled/TASK.md" "$TMP_ROOT/collision-destination"
if archive_confirmed "$root" "$cancelled"; then
  fail "archive destination collisions are refused"
elif cmp -s "$TMP_ROOT/collision-source" "$root/$cancelled/TASK.md" && \
     cmp -s "$TMP_ROOT/collision-destination" "$root/done/$cancelled/TASK.md"; then
  pass "archive destination collisions preserve both workspaces"
else
  fail "archive destination collisions preserve both workspaces"
fi
standalone=2026-09-10-006-cancelled-work
seed_task "$root/$standalone" cancelled cancelled-work
ln -s missing-target "$root/done/$standalone" || exit 2
if archive_confirmed "$root" "$standalone"; then
  fail "dangling archive symlinks are collisions"
else
  pass "dangling archive symlinks are collisions"
fi
rm -- "$root/done/$standalone"
if archive_confirmed "$root" "$standalone" && [ -f "$root/done/$standalone/TASK.md" ] && \
   [ ! -e "$root/done/$standalone/artifacts" ]; then
  pass "cancellation archives a TASK.md-only workspace without manufacturing artifacts"
else
  fail "cancellation archives a TASK.md-only workspace without manufacturing artifacts"
fi

printf '1..%s\n' "$((PASS_COUNT + FAIL_COUNT))"
[ "$FAIL_COUNT" -eq 0 ]
