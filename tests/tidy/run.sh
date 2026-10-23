#!/bin/bash

set -u
LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P) || exit 2
REPO_ROOT=$(CDPATH='' cd -- "$TEST_DIR/../.." 2>/dev/null && pwd -P) || exit 2
SCRIPTS="$REPO_ROOT/.claude/skills/cda-tidy/scripts"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/claudart-tidy-tests.XXXXXX") || exit 2
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

# expect <output file> <extended regex> <name>; refute is the inverse.
expect() { if grep -Eq -- "$2" "$1"; then pass "$3"; else fail "$3"; fi; }
refute() { if grep -Eq -- "$2" "$1"; then fail "$3"; else pass "$3"; fi; }

commit_all() {
  dir=$1; shift
  git -C "$dir" add -A && git -C "$dir" -c user.name=t -c user.email=t@example.invalid commit -q "$@"
}

if diff -r "$SCRIPTS" "$REPO_ROOT/.agents/skills/cda-tidy/scripts" >/dev/null; then
  pass "Claude and Codex tidy scripts are byte-identical"
else
  fail "Claude and Codex tidy scripts are byte-identical"
fi

# Fixture: a Git project with docs, state, knowledge, a project rule, a core
# rule, an active task, a record and a nested repository.
repo="$TMP_ROOT/project"
mkdir -p "$repo/docs" "$repo/.claudart/knowledge" "$repo/.claudart/tasks/2026-01-02-001-active" \
  "$repo/.claude/rules" "$repo/src" "$repo/vendor/lib" "$repo/nested"
git -C "$repo" init -q
long=$(printf 'word %.0s' $(seq 1 100))
dup="The release pipeline signs every artifact before the registry accepts the upload from any runner."
cat >"$repo/docs/guide.md" <<EOF
# Guide

Updated 2026-01-05: the queue moved.

The suite reported 312 tests passed in run 48213.

Workers previously polled the queue every second.

$dup

Deploys must use \`unique-flag-alpha\` because the cache is shared.

See [operations](ops.md), [the plan](<my plan.md>) and [missing](gone.md). Code like \`[x](nowhere.md)\` is not a link.
EOF
printf '# Ops\n\n%s\n' "$dup" >"$repo/docs/ops.md"
printf '# Plan\n' >"$repo/docs/my plan.md"
printf '# Old\n\nSee [archived](archived.md).\n' >"$repo/docs/old.md"
printf '<!-- seed comment -->\n# Current Context\n\n- %s\n' "$long" >"$repo/.claudart/CONTEXT.md"
printf '# Owner\n\n- Prefer short replies. (2026-01-01)\n' >"$repo/.claudart/OWNER.md"
printf '# Project Knowledge\n\n<!-- - [Topic](topic.md) -->\n' >"$repo/.claudart/knowledge/INDEX.md"
printf '%s\n' '---' 'paths: ["src/**"]' '---' '# Api' '' 'Handlers live in `src/api.ts` and `src/removed.ts`, return `application/json` and sync `owner/repo`.' >"$repo/.claude/rules/api.md"
printf '# Core\n' >"$repo/.claude/rules/code-health.md"
printf 'export {}\n' >"$repo/src/api.ts"
printf '# Task\n\nUpdate docs/guide.md for the new flow.\n' >"$repo/.claudart/tasks/2026-01-02-001-active/TASK.md"
printf '# Changelog\n\n## 2026-01-01\n' >"$repo/CHANGELOG.md"
printf '# Vendored\n' >"$repo/vendor/lib/README.md"
printf '# Loader\n' >"$repo/CLAUDE.md"
printf '# Prompt shipped with the code\n' >"$repo/src/prompt.md"
mkdir -p "$repo/notes" && printf '# Notes\n' >"$repo/notes/a.md" && printf '# Lessons\n' >"$repo/src/lessons.md"
git -C "$repo/nested" init -q
printf 'nested/\n' >>"$repo/.git/info/exclude"
printf '# Nested\n' >"$repo/nested/README.md"
commit_all "$repo" -m "seed"

out="$TMP_ROOT/out"
bash "$SCRIPTS/scope.sh" --root "$repo" >"$out"; status=$?
[ "$status" -eq 0 ] && pass "scope exits 0" || fail "scope exits 0"
expect "$out" '^MODE\|full\|no earlier Claudart-Tidy commit$' "scope runs a full pass without an anchor"
expect "$out" '^FILE\|docs\|docs/guide\.md$' "scope reviews project docs"
expect "$out" '^FILE\|state\|\.claudart/CONTEXT\.md$' "scope reviews CONTEXT"
expect "$out" '^FILE\|knowledge\|\.claudart/knowledge/INDEX\.md$' "scope reviews knowledge"
expect "$out" '^FILE\|rules\|\.claude/rules/api\.md$' "scope reviews project rules"
refute "$out" 'code-health\.md' "scope leaves core rules to integration"
refute "$out" '^FILE\|.*(CLAUDE\.md|vendor/|tasks/|src/prompt)' "scope skips loaders, vendored files, task bodies and Markdown shipped with code"
expect "$out" '^RECORD\|CHANGELOG\.md$' "scope lists records without reviewing them"
expect "$out" '^NESTED\|nested$' "scope reports nested repositories"
refute "$out" 'nested/README' "scope leaves nested repository files out"
expect "$out" '^ACTIVE\|\.claudart/tasks/2026-01-02-001-active\|' "scope lists active tasks"
expect "$out" '^PROTECTED\|docs/guide\.md\|\.claudart/tasks/2026-01-02-001-active$' "scope protects docs an active task names"
expect "$out" '^RULEREF\|\.claude/rules/api\.md:6\|src/removed\.ts\|missing$' "scope flags missing rule paths"
refute "$out" '(src/api\.ts|application/json|owner/repo)\|missing' "scope checks only real path references"

bash "$SCRIPTS/scope.sh" --root "$repo" --include notes/ --include src/lessons.md >"$TMP_ROOT/inc"
expect "$TMP_ROOT/inc" '^FILE\|docs\|notes/a\.md$' "--include adds a folder to project docs"
expect "$TMP_ROOT/inc" '^FILE\|docs\|src/lessons\.md$' "--include repeats and accepts files"
refute "$out" 'notes/a\.md' "other folders stay out without --include"
bash "$SCRIPTS/signals.sh" --root "$repo" >"$out"
expect "$out" '^LONG\|\.claudart/CONTEXT\.md:4\|' "signals flag long state lines"
expect "$out" '^DATED\|docs/guide\.md:3\|' "signals flag dated update notes"
expect "$out" '^EVIDENCE\|docs/guide\.md:5\|' "signals flag test totals and run IDs"
expect "$out" '^HISTORY\|docs/guide\.md:7\|' "signals flag transition narration"
expect "$out" '^DUP\|docs/guide\.md:9\|docs/ops\.md:3\|' "signals flag sentences repeated across files"
refute "$out" 'OWNER\.md' "signals accept dated owner entries"
refute "$out" 'CHANGELOG' "signals leave records alone"

# Incremental scope from the last Claudart-Tidy commit.
printf '\nTidied.\n' >>"$repo/docs/ops.md"
commit_all "$repo" -m "docs: tidy" -m "Claudart-Tidy: docs"
printf '\nNew.\n' >>"$repo/docs/guide.md"
commit_all "$repo" -m "docs: change guide"
bash "$SCRIPTS/scope.sh" --root "$repo" >"$out"
expect "$out" '^ANCHOR\|docs\|[0-9a-f]{40}\|[0-9-]+$' "scope finds the Claudart-Tidy anchor per scope"
expect "$out" '^MODE\|incremental\|' "scope switches to an incremental pass"
expect "$out" '^FILE\|docs\|docs/guide\.md$' "incremental scope keeps files changed since the anchor"
refute "$out" '^FILE\|docs\|docs/ops\.md$' "incremental scope drops files unchanged since the anchor"
expect "$out" '^FILE\|knowledge\|' "scopes a tidy commit did not name stay under full review"
bash "$SCRIPTS/scope.sh" --root "$repo" --full >"$out"
expect "$out" '^FILE\|docs\|docs/ops\.md$' "--full reviews everything again"

# Verify: a removed unique fact is LOST, a moved one is not, links must resolve.
sed -i.bak '/unique-flag-alpha/d' "$repo/docs/guide.md" && rm -f "$repo/docs/guide.md.bak"
bash "$SCRIPTS/verify.sh" --root "$repo" >"$out"; status=$?
expect "$out" '^LOST\|docs/guide\.md\|unique-flag-alpha$' "verify reports a removed fact found nowhere else"
expect "$out" '^REMOVED\|docs/guide\.md\|Deploys must use' "verify lists removed constraints"
expect "$out" '^LINK\|docs/guide\.md:[0-9]+\|gone\.md$' "verify reports broken relative links"
refute "$out" '(topic|nowhere)\.md' "verify ignores links inside HTML comments and code spans"
refute "$out" 'my plan' "verify resolves angle-bracket links with spaces"
expect "$out" '^OLDLINK\|docs/old\.md:3\|archived\.md$' "verify separates breakage the edit did not cause"
[ "$status" -eq 1 ] && pass "verify exits 1 on lost facts or broken links" || fail "verify exits 1 on lost facts or broken links"
printf -- '- Deploys must use `unique-flag-alpha` because the cache is shared.\n' >>"$repo/.claudart/tasks/2026-01-02-001-active/TASK.md"
bash "$SCRIPTS/verify.sh" --root "$repo" >"$out"
refute "$out" '^(LOST|REMOVED)\|' "verify accepts a fact moved verbatim to a work record"
git -C "$repo" checkout -q -- .
sed -i.bak 's/ and \[missing\](gone.md)//' "$repo/docs/guide.md" && rm -f "$repo/docs/guide.md.bak"
bash "$SCRIPTS/verify.sh" --root "$repo" >"$out"; status=$?
[ "$status" -eq 0 ] && pass "verify exits 0 when nothing is lost" || fail "verify exits 0 when nothing is lost"

empty="$TMP_ROOT/empty"
mkdir -p "$empty" && git -C "$empty" init -q && printf '# Empty\n' >"$empty/README.md"
bash "$SCRIPTS/scope.sh" --root "$empty" >/dev/null 2>&1; status=$?
[ "$status" -eq 2 ] && pass "scope asks for a first commit in an empty repository" || fail "scope asks for a first commit in an empty repository"

# A root without Git compares against a snapshot taken outside the root.
plain="$TMP_ROOT/plain"
mkdir -p "$plain/docs"
printf '# Plain\n\nKeep `plain-token-beta` because exports depend on it.\n' >"$plain/docs/a.md"
bash "$SCRIPTS/scope.sh" --root "$plain" --snapshot "$TMP_ROOT/before" >"$out"
expect "$out" '^MODE\|full\|no Git history to compare$' "scope runs a full pass without Git"
expect "$out" '^SNAPSHOT\|.*\|1 files$' "scope snapshots in-scope files"
if bash "$SCRIPTS/scope.sh" --root "$plain" --snapshot "$plain/snap" >/dev/null 2>&1; then
  fail "scope refuses a snapshot inside the root"
else
  pass "scope refuses a snapshot inside the root"
fi
[ ! -e "$plain/snap" ] && pass "a refused snapshot writes nothing" || fail "a refused snapshot writes nothing"
printf '# Plain\n' >"$plain/docs/a.md"
bash "$SCRIPTS/verify.sh" --root "$plain" >/dev/null 2>&1; status=$?
[ "$status" -eq 2 ] && pass "verify needs --before without Git" || fail "verify needs --before without Git"
bash "$SCRIPTS/verify.sh" --root "$plain" --before "$TMP_ROOT/before" >"$out"
expect "$out" '^LOST\|docs/a\.md\|plain-token-beta$' "verify compares a root without Git against its snapshot"

printf '1..%s\n' "$((PASS_COUNT + FAIL_COUNT))"
[ "$FAIL_COUNT" -eq 0 ]
