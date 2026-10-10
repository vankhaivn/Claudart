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
    plan="$commands/cda-task.md"
    start="$commands/cda-start.md"
    checkpoint="$commands/cda-checkpoint.md"
    doctor="$commands/cda-doctor.md"
    refactor="$commands/cda-refactor-memory.md"
  else
    rule="$REPO_ROOT/.codex/guidelines/task-management.md"
    commands="$REPO_ROOT/.agents/skills"
    plan="$commands/cda-task/SKILL.md"
    start="$commands/cda-start/SKILL.md"
    checkpoint="$commands/cda-checkpoint/SKILL.md"
    doctor="$commands/cda-doctor/SKILL.md"
    refactor="$commands/cda-refactor-memory/SKILL.md"
  fi

  # Canonical artifact semantics live in the rule/guideline. The command/skill
  # keeps only the entrypoint and routing needed to invoke that contract.
  assert_contains "$plan" 'YYYY-MM-DD-NNN-<slug>/TASK.md' "$layer plan uses the workspace entrypoint"
  assert_contains "$plan" '**Default to `TASK.md` only.**' "$layer plan starts without attachments"
  assert_contains "$plan" 'Never automatically extract archives, execute attachments, or load all supporting files.' "$layer plan does not auto-process attachments"

  for file in "$rule"; do
    assert_contains "$file" 'YYYY-MM-DD-NNN-<slug>/TASK.md' "$layer rule uses the workspace entrypoint"
    assert_contains "$file" '**Default to `TASK.md` only.**' "$layer rule starts without attachments"
    assert_contains "$file" 'native-format' "$layer defines the native-format trigger"
    assert_contains "$file" 'important details would be lost in a short summary' "$layer defines necessary retained evidence"
    assert_contains "$file" 'Substantial task-specific research' "$layer defines the research trigger"
    assert_contains "$file" 'Short findings' "$layer keeps small discoveries inline"
    assert_contains "$file" 'Link existing project files' "$layer avoids duplicated canonical files"
    assert_contains "$file" 'mandatory repository checks' "$layer retains required verification"
    assert_contains "$file" 'forced session rotation' "$layer forbids spec-style ceremony"
    assert_contains "$file" 'reviewer: user # user | agent' "$layer task schema records the completion reviewer"
    assert_contains "$file" 'Every task records `reviewer: user | agent` before implementation starts.' "$layer requires explicit review ownership"
    assert_contains "$file" 'An explicit human approval requirement can be changed only by the authority that owns it.' "$layer protects approval ownership"
    assert_contains "$file" 'User-visible output alone does not require user review.' "$layer classifies acceptance rather than visibility"
    assert_contains "$file" 'Missing objective verification alone is unfinished agent work' "$layer keeps objective verification with the agent"
    assert_contains "$file" 'keep `user` until it is resolved' "$layer protects ambiguous acceptance ownership"
    assert_contains "$file" 'they never waive subjective acceptance or an explicit approval requirement' "$layer protects human gates from test-only closeout"
    assert_contains "$file" 'Present the actual reviewable result and how to access it' "$layer requires a concrete review handoff"
    assert_contains "$file" 'Do not transfer unfinished agent verification to the user.' "$layer keeps agent checks out of user acceptance"
    assert_contains "$file" 'User-reviewed tasks stop at `awaiting-review` until their genuine user gate is satisfied; agent-reviewed tasks may close only under the evidence-complete closeout contract.' "$layer anti-patterns agree with both closeout paths"
    assert_contains "$file" 'reviewer: agent + all acceptance proven' "$layer permits evidence-backed agent closeout"
    assert_contains "$file" 'reviewer: user + agent finishes validation' "$layer preserves the user review gate"
    assert_contains "$file" 'agent-facing durable execution record, not the default user-facing presentation' "$layer separates agent task storage from user presentation"
    assert_contains "$file" 'Never tell the user to open, read, or review `TASK.md` as the default approval action.' "$layer owns the user-facing plan translation"
    assert_contains "$file" 'Never automatically extract archives, execute attachments, or load all supporting files.' "$layer does not auto-process attachments"
  done

  assert_contains "$rule" '`TASK.md` is the only required file' "$layer has one required document"
  assert_contains "$rule" 'Rewrite **Current State** whenever the status, the next action, or what is waiting changes.' "$layer keeps one rewritten current state"
  assert_contains "$rule" 'Do not add top-level sections beyond the skeleton' "$layer keeps the skeleton closed"
  assert_contains "$rule" 'Record each check'"'"'s **latest result** once' "$layer keeps only the latest check result"
  assert_contains "$rule" 'A terminal task is closed.' "$layer starts follow-up work in a new task"
  assert_contains "$rule" 'Size a task to one outcome that can be accepted at once.' "$layer sizes tasks to one acceptable outcome"
  assert_contains "$rule" 'A struck step or criterion with its recorded reason counts as resolved' "$layer records waived or moved acceptance"
  assert_contains "$rule" 'Refer to another task by its workspace id' "$layer links tasks by id across archival"
  assert_contains "$rule" 'read from the system clock when the entry is written' "$layer takes log times from the clock"
  assert_contains "$rule" 'Record an authorization that applies only to this task once' "$layer records task-scoped grants once"
  assert_contains "$rule" 'reference them instead of copying them into the task' "$layer keeps standing approvals in the owner profile"
  assert_contains "$doctor" 'Active workspaces also require `## Current State`.' "$layer doctor requires a current state on active tasks"
  assert_contains "$rule" 'tasks/*/TASK.md' "$layer discovers active workspaces shallowly"
  assert_contains "$rule" 'tasks/done/*/TASK.md' "$layer discovers archived workspaces shallowly"
  assert_contains "$rule" 'including incomplete workspaces' "$layer reserves incomplete workspace ids"
  assert_contains "$rule" 'At 999, report exhaustion rather than wrapping.' "$layer never wraps sequence numbers"
  assert_contains "$rule" 'Move the entire workspace' "$layer archives all supporting material"
  assert_contains "$rule" 'including a symlink' "$layer refuses archive destination collisions"
  assert_contains "$rule" 'Verify the move succeeded before updating references or journaling.' "$layer records only successful moves"
  assert_contains "$rule" 'Repair every knowledge `sources` entry that points into the moved workspace' "$layer archive keeps knowledge sources resolvable"
  assert_contains "$rule" 'a path repair changes neither `updated` nor `last_verified`' "$layer archive repair is not a content or evidence change"
  assert_contains "$rule" 'Do NOT move the workspace' "$layer preserves the user completion gate"
  assert_contains "$rule" 'local-only' "$layer exposes non-portable inputs"
  assert_contains "$rule" 'no compatibility or automatic migration path' "$layer supports only the current layout"
  assert_contains "$plan" 'Honor an explicit request for a persistent plan' "$layer honors small explicit plans"
  assert_contains "$plan" 'File count alone is not a reason.' "$layer avoids unnecessary planning"
  assert_contains "$plan" 'resumption or review flow' "$layer resumes without resetting state"
  assert_contains "$plan" 'Classify the completion reviewer before the plan is ready' "$layer plan classifies reviewer before implementation"
  assert_contains "$plan" 'Visibility alone is not a user review requirement.' "$layer plan uses criterion-based review ownership"
  assert_contains "$plan" '**User Plan Brief**' "$layer plan presents a compact user-facing brief"
  assert_contains "$plan" 'Do not paste the task file and do not tell the user to open or review `TASK.md`' "$layer plan does not outsource comprehension to the user"
  assert_contains "$plan" '**Current state**' "$layer plan brief explains the current state"
  assert_contains "$plan" '**Desired outcome**' "$layer plan brief explains the desired outcome"
  assert_contains "$plan" '**Review / approval**' "$layer plan brief explains review responsibility"
  assert_contains "$plan" 'No implementation code, scaffolding, runnable POCs, or write-scope workers' "$layer closes the artifact planning loophole"

  assert_contains "$start" 'tasks/*/TASK.md' "$layer startup can recover a missing index"
  assert_contains "$start" 'Read `TASK.md` frontmatter' "$layer startup reads metadata only"
  assert_contains "$start" 'report a missing or invalid `reviewer` as incomplete metadata without guessing ownership' "$layer startup reports incomplete reviewer metadata"
  assert_contains "$start" 'Do not read task bodies or artifact contents' "$layer startup does not slurp workspaces"
  assert_contains "$start" 'present the reviewable result plus the specific outstanding acceptance' "$layer startup owns the resumed review handoff"
  assert_contains "$checkpoint" 'tasks/done/*/TASK.md' "$layer checkpoint recognizes directory archives"
  assert_contains "$checkpoint" 'Move the entire workspace' "$layer checkpoint preserves attachments"
  assert_contains "$checkpoint" 'Repair knowledge `sources` that point into the moved workspace' "$layer checkpoint archive keeps knowledge sources resolvable"
  assert_contains "$checkpoint" '**DO NOT archive `awaiting-review` tasks.**' "$layer checkpoint respects review"
  assert_contains "$checkpoint" 'Require a valid `reviewer: user | agent` before archiving' "$layer checkpoint requires explicit review ownership"
  assert_contains "$checkpoint" 'checkpoint never creates supporting files' "$layer checkpoint does not manufacture artifacts"
  assert_contains "$doctor" 'Validate `reviewer` as `user | agent`.' "$layer doctor validates reviewer metadata"
  assert_contains "$doctor" 'Report missing or invalid reviewer metadata as Medium; do not infer acceptance ownership.' "$layer doctor reports incomplete metadata without guessing"
  assert_contains "$doctor" 'Missing `artifacts/` or `### Workspace Files` is normal' "$layer doctor accepts the minimal workspace"
  assert_contains "$doctor" 'Do not read artifact bodies' "$layer doctor checks links without processing payloads"
  assert_contains "$doctor" '`None.` is valid' "$layer doctor does not demand filler"
  assert_contains "$refactor" 'TASK.md' "$layer maintenance recognizes the entrypoint"
  seed="$REPO_ROOT/.claudart/tasks/index.md"
  assert_contains "$seed" '<task-id>/TASK.md' "$layer seed points to the authoritative entrypoint"
  assert_not_contains "$seed" '](' "$layer ships no live task in its dashboard"
done

# These runtime-neutral sections must agree in both installed adapters.
for section in 'Artifact Discipline' 'Completion Reviewer' 'Status State Machine'; do
  for layer in claude codex; do
    if [ "$layer" = claude ]; then
      rule="$REPO_ROOT/.claude/rules/task-management.md"
    else
      rule="$REPO_ROOT/.codex/guidelines/task-management.md"
    fi
    awk -v heading="## $section" '$0==heading{capture=1; next} capture && /^## /{exit} capture{print}' \
      "$rule" > "$TMP_ROOT/$layer-contract"
  done
  if [ -s "$TMP_ROOT/claude-contract" ] && \
     cmp -s "$TMP_ROOT/claude-contract" "$TMP_ROOT/codex-contract"; then
    pass "Claude and Codex agree on $section"
  else
    fail "Claude and Codex agree on $section"
  fi
done

# Check the documented decision examples, not a test-only classifier or agent.
# Expected owners cover objective UI/text, subjective, inaccessible, explicit,
# and mixed acceptance; table whitespace is only Markdown formatting.
for layer in claude codex; do
  if [ "$layer" = claude ]; then
    rule="$REPO_ROOT/.claude/rules/task-management.md"
  else
    rule="$REPO_ROOT/.codex/guidelines/task-management.md"
  fi
  while IFS='|' read -r criterion reviewer; do
    if awk -F '|' -v criterion="$criterion" -v reviewer="\`$reviewer\`" '
      { for (i=2; i<=3; i++) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i) } }
      $2==criterion && $3==reviewer { found++ }
      END { exit found != 1 }
    ' "$rule"; then
      pass "$layer documents $reviewer review for: $criterion"
    else
      fail "$layer documents $reviewer review for: $criterion"
    fi
  done <<'CASES'
A failed request releases the submit button and retry succeeds; the agent can reproduce both|agent
A heading matches supplied text exactly|agent
The user must decide whether new copy feels reassuring|user
Behavior must be confirmed on a device or account unavailable to the agent|user
The user explicitly requests final sign-off on an otherwise deterministic fix|user
Tests pass, but the task also requires the user to choose the preferred layout|user
CASES
done

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

archive_terminal() {
  local root=$1 id=$2 source destination status reviewer
  valid_id "$id" || return 1
  source="$root/$id"
  destination="$root/done/$id"
  [ -d "$source" ] && [ ! -L "$source" ] && [ ! -L "$source/TASK.md" ] || return 1
  status=$(awk '/^---$/{n++; next} n==1 && /^status: /{print $2; exit}' "$source/TASK.md") || return 1
  case "$status" in done|cancelled) ;; *) return 1 ;; esac
  reviewer=$(awk '/^---$/{n++; next} n==1 && /^reviewer: /{print $2; exit}' "$source/TASK.md") || return 1
  case "$reviewer" in user|agent) ;; *) return 1 ;; esac
  [ ! -e "$destination" ] && [ ! -L "$destination" ] || return 1
  mkdir -p "$root/done" || return 1
  mv -- "$source" "$destination"
}

seed_task() {
  mkdir -p "$1" || exit 2
  printf '%s\n' '---' "slug: $3" "status: $2" 'created: 2026-09-10' \
    'updated: 2026-09-10' 'agent: codex' "reviewer: $4" 'delegation: none' 'tags: [test]' '---' \
    '# Synthetic task' > "$1/TASK.md"
}

root="$TMP_ROOT/tasks"
minimal=2026-09-10-001-small-change
bundle=2026-09-10-002-import-failure
cancelled=2026-09-10-003-dropped-change
seed_task "$root/$minimal" planning small-change user
seed_task "$root/$bundle" awaiting-review import-failure user
seed_task "$root/done/$cancelled" cancelled dropped-change user
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
if archive_terminal "$root" "$bundle"; then
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
if archive_terminal "$root" "$bundle" && [ ! -e "$root/$bundle" ]; then
  pass "user-reviewed completion moves the whole workspace after confirmation"
else
  fail "user-reviewed completion moves the whole workspace after confirmation"
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

agentdone=2026-09-10-007-benchmark-fix
seed_task "$root/$agentdone" done benchmark-fix agent
if archive_terminal "$root" "$agentdone" && [ -f "$root/done/$agentdone/TASK.md" ]; then
  pass "agent-reviewed done task archives without user confirmation"
else
  fail "agent-reviewed done task archives without user confirmation"
fi

incomplete=2026-09-10-012-incomplete-review
seed_task "$root/$incomplete" done incomplete-review user
grep -v '^reviewer:' "$root/$incomplete/TASK.md" > "$TMP_ROOT/incomplete-task"
cp "$TMP_ROOT/incomplete-task" "$root/$incomplete/TASK.md" || exit 2
if archive_terminal "$root" "$incomplete"; then
  fail "task with incomplete reviewer metadata cannot be archived"
elif cmp -s "$TMP_ROOT/incomplete-task" "$root/$incomplete/TASK.md"; then
  pass "incomplete reviewer metadata is preserved without guessing ownership"
else
  fail "incomplete reviewer metadata is preserved without guessing ownership"
fi

seed_task "$root/$cancelled" cancelled dropped-change user
cp "$root/$cancelled/TASK.md" "$TMP_ROOT/collision-source"
cp "$root/done/$cancelled/TASK.md" "$TMP_ROOT/collision-destination"
if archive_terminal "$root" "$cancelled"; then
  fail "archive destination collisions are refused"
elif cmp -s "$TMP_ROOT/collision-source" "$root/$cancelled/TASK.md" && \
     cmp -s "$TMP_ROOT/collision-destination" "$root/done/$cancelled/TASK.md"; then
  pass "archive destination collisions preserve both workspaces"
else
  fail "archive destination collisions preserve both workspaces"
fi
standalone=2026-09-10-006-cancelled-work
seed_task "$root/$standalone" cancelled cancelled-work user
ln -s missing-target "$root/done/$standalone" || exit 2
if archive_terminal "$root" "$standalone"; then
  fail "dangling archive symlinks are collisions"
else
  pass "dangling archive symlinks are collisions"
fi
rm -- "$root/done/$standalone"
if archive_terminal "$root" "$standalone" && [ -f "$root/done/$standalone/TASK.md" ] && \
   [ ! -e "$root/done/$standalone/artifacts" ]; then
  pass "cancellation archives a TASK.md-only workspace without manufacturing artifacts"
else
  fail "cancellation archives a TASK.md-only workspace without manufacturing artifacts"
fi

printf '1..%s\n' "$((PASS_COUNT + FAIL_COUNT))"
[ "$FAIL_COUNT" -eq 0 ]
