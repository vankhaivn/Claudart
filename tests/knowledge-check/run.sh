#!/bin/bash

set -u

LC_ALL=C
export LC_ALL

TEST_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P) || exit 2
REPO_ROOT=$(CDPATH='' cd -- "$TEST_DIR/../.." 2>/dev/null && pwd -P) || exit 2
FIXTURES=$TEST_DIR/fixtures
CLAUDE_CHECKER=$REPO_ROOT/.claude/scripts/knowledge-check.sh
CODEX_CHECKER=$REPO_ROOT/.codex/scripts/knowledge-check.sh
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/claudart-knowledge-tests.XXXXXX" 2>/dev/null) ||
  exit 2

# Invoked indirectly by trap.
# shellcheck disable=SC2329
cleanup() {
  if [ -n "${TMP_ROOT:-}" ] && [ -d "$TMP_ROOT" ]; then
    rm -rf -- "$TMP_ROOT"
  fi
}
trap cleanup EXIT HUP INT TERM

PASS_COUNT=0
FAIL_COUNT=0
LAST_STATUS=0
LAST_OUTPUT=

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf 'ok %s - %s\n' "$PASS_COUNT" "$1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf 'not ok - %s\n' "$1" >&2
}

assert_status() {
  label=$1
  expected=$2
  if [ "$LAST_STATUS" -eq "$expected" ]; then
    pass "$label"
  else
    fail "$label (expected exit $expected, got $LAST_STATUS)"
    if [ -s "$LAST_OUTPUT" ]; then
      sed 's/^/  /' "$LAST_OUTPUT" >&2
    fi
  fi
}

assert_empty() {
  label=$1
  if [ ! -s "$LAST_OUTPUT" ]; then
    pass "$label"
  else
    fail "$label (unexpected checker output)"
    sed 's/^/  /' "$LAST_OUTPUT" >&2
  fi
}

assert_code() {
  label=$1
  code=$2
  if grep -q "^[A-Z][A-Z]*|$code|" "$LAST_OUTPUT"; then
    pass "$label"
  else
    fail "$label (missing $code)"
    sed 's/^/  /' "$LAST_OUTPUT" >&2
  fi
}

assert_no_code() {
  label=$1
  code=$2
  if ! grep -q "^[A-Z][A-Z]*|$code|" "$LAST_OUTPUT"; then
    pass "$label"
  else
    fail "$label (unexpected $code)"
    sed 's/^/  /' "$LAST_OUTPUT" >&2
  fi
}

run_checker() {
  checker=$1
  output=$2
  shift 2
  LAST_OUTPUT=$output
  /bin/bash "$checker" "$@" >"$output" 2>"$output.stderr"
  LAST_STATUS=$?
  if [ -s "$output.stderr" ]; then
    fail "checker emitted unexpected stderr"
    sed 's/^/  /' "$output.stderr" >&2
  fi
}

materialize() {
  fixture_name=$1
  fixture_layer=$2
  destination=$TMP_ROOT/$fixture_name-$fixture_layer
  mkdir -p "$destination/.$fixture_layer"
  cp -R "$FIXTURES/$fixture_name/layer/." "$destination/.$fixture_layer/"
  if [ -d "$FIXTURES/$fixture_name/docs" ]; then
    cp -R "$FIXTURES/$fixture_name/docs" "$destination/docs"
  fi
  MATERIALIZED=$destination
}

snapshot() {
  snapshot_root=$1
  snapshot_output=$2
  find "$snapshot_root" -type f ! -name '.env' -exec cksum {} \; |
    LC_ALL=C sort >"$snapshot_output"
}

if /bin/bash -n "$CLAUDE_CHECKER" "$CODEX_CHECKER" "$TEST_DIR/run.sh"; then
  pass "Bash syntax is valid"
else
  fail "Bash syntax is valid"
fi

if cmp -s "$CLAUDE_CHECKER" "$CODEX_CHECKER"; then
  pass "Claude and Codex checker scripts are byte-identical"
else
  fail "Claude and Codex checker scripts are byte-identical"
fi

materialize healthy-direct claude
healthy_claude=$MATERIALIZED
snapshot "$healthy_claude" "$TMP_ROOT/healthy-before"
run_checker "$CLAUDE_CHECKER" "$TMP_ROOT/healthy-claude.out" \
  --root "$healthy_claude" --today 2026-07-29 --fail-on warning
assert_status "healthy direct store exits successfully with inferred Claude layer" 0
assert_empty "healthy direct store has no findings, including its valid related cycle"
assert_no_code "old updated date is not stale when last_verified is recent" K150
snapshot "$healthy_claude" "$TMP_ROOT/healthy-after"
if diff -u "$TMP_ROOT/healthy-before" "$TMP_ROOT/healthy-after" \
  >"$TMP_ROOT/healthy.diff"; then
  pass "checker does not mutate fixture files"
else
  fail "checker does not mutate fixture files"
  sed 's/^/  /' "$TMP_ROOT/healthy.diff" >&2
fi

materialize healthy-direct codex
healthy_codex=$MATERIALIZED
run_checker "$CODEX_CHECKER" "$TMP_ROOT/healthy-codex.out" \
  --root "$healthy_codex" --today 2026-07-29 --fail-on warning
assert_status "healthy direct store exits successfully with inferred Codex layer" 0
assert_empty "Codex healthy direct store has no findings"

space_root=$TMP_ROOT/project-with-spaces/project\ with\ spaces
mkdir -p "$space_root/.claude"
cp -R "$FIXTURES/healthy-direct/layer/." "$space_root/.claude/"
cp -R "$FIXTURES/healthy-direct/docs" "$space_root/docs"
run_checker "$CLAUDE_CHECKER" "$TMP_ROOT/spaced-root.out" \
  --root "$space_root" --layer claude --today 2026-07-29 --fail-on warning
assert_status "repository root path containing spaces is handled safely" 0
assert_empty "spaced repository root has no quoting-related findings"

materialize domain-map claude
domain_claude=$MATERIALIZED
run_checker "$CLAUDE_CHECKER" "$TMP_ROOT/domain-map.out" \
  --root "$domain_claude" --layer claude --today 2026-07-29 --fail-on warning
assert_status "active domain map reaches its topic exactly once" 0
assert_empty "healthy domain map allows a curated hook richer than description"

materialize review-map-path claude
review_map_root=$MATERIALIZED
run_checker "$CLAUDE_CHECKER" "$TMP_ROOT/review-map-path.out" \
  --root "$review_map_root" --layer claude --today 2026-07-29
assert_status "review-needed map cannot establish an active authority path" 1
assert_code "active topic behind a review-needed map reports K205" K205

materialize lifecycle claude
lifecycle_claude=$MATERIALIZED
run_checker "$CLAUDE_CHECKER" "$TMP_ROOT/lifecycle-error-threshold.out" \
  --root "$lifecycle_claude" --layer claude --today 2026-07-29 --fail-on error
assert_status "warning-only lifecycle store passes the default error threshold" 0
assert_code "unrouted review-needed entry is reported without auto-promotion" K206
assert_no_code "superseded entry with reverse successor and status note is valid" K208
assert_no_code "historical non-active entries do not emit perpetual staleness warnings" K150
run_checker "$CLAUDE_CHECKER" "$TMP_ROOT/lifecycle-warning-threshold.out" \
  --root "$lifecycle_claude" --layer claude --today 2026-07-29 --fail-on warning
assert_status "warning threshold fails on lifecycle warning" 1

materialize invalid claude
invalid_claude=$MATERIALIZED
run_checker "$CLAUDE_CHECKER" "$TMP_ROOT/invalid-claude.out" \
  --root "$invalid_claude" --layer claude --today 2026-07-29
assert_status "legacy and unsupported metadata exits with contract failure" 1
for expected_code in K102 K103 K104 K108 K110 K111 K112 K113 K200; do
  assert_code "invalid fixture reports $expected_code" "$expected_code"
done
LC_ALL=C sort "$LAST_OUTPUT" >"$TMP_ROOT/invalid.sorted"
if cmp -s "$LAST_OUTPUT" "$TMP_ROOT/invalid.sorted"; then
  pass "diagnostics are emitted in stable lexical order"
else
  fail "diagnostics are emitted in stable lexical order"
fi

materialize invalid codex
invalid_codex=$MATERIALIZED
run_checker "$CODEX_CHECKER" "$TMP_ROOT/invalid-codex.out" \
  --root "$invalid_codex" --layer codex --today 2026-07-29
assert_status "Codex invalid fixture exits with contract failure" 1
awk -F '|' '{ print $1 "|" $2 "|" $4 }' "$TMP_ROOT/invalid-claude.out" \
  >"$TMP_ROOT/invalid-claude-codes"
awk -F '|' '{ print $1 "|" $2 "|" $4 }' "$TMP_ROOT/invalid-codex.out" \
  >"$TMP_ROOT/invalid-codex-codes"
if cmp -s "$TMP_ROOT/invalid-claude-codes" "$TMP_ROOT/invalid-codex-codes"; then
  pass "both layers emit the same diagnostic codes and messages"
else
  fail "both layers emit the same diagnostic codes and messages"
  diff -u "$TMP_ROOT/invalid-claude-codes" "$TMP_ROOT/invalid-codex-codes" >&2
fi

materialize broken claude
broken_claude=$MATERIALIZED
run_checker "$CLAUDE_CHECKER" "$TMP_ROOT/broken.out" \
  --root "$broken_claude" --layer claude --today 2026-07-29
assert_status "dead routes, sources, and relations fail the checker" 1
for expected_code in K120 K130 K131 K141 K201 K203 K204; do
  assert_code "broken fixture reports $expected_code" "$expected_code"
done
assert_no_code "HTML-commented dead route is ignored" K202

empty_root=$TMP_ROOT/missing-knowledge
mkdir -p "$empty_root"
run_checker "$CLAUDE_CHECKER" "$TMP_ROOT/missing-knowledge.out" \
  --root "$empty_root" --layer claude --today 2026-07-29
assert_status "missing knowledge directory is a contract failure, not runtime failure" 1
assert_code "missing knowledge directory reports K001" K001

missing_index=$TMP_ROOT/missing-index
mkdir -p "$missing_index/.claude/knowledge"
run_checker "$CLAUDE_CHECKER" "$TMP_ROOT/missing-index.out" \
  --root "$missing_index" --layer claude --today 2026-07-29
assert_status "missing INDEX is a contract failure, not runtime failure" 1
assert_code "missing INDEX reports K002" K002

materialize freshness claude
freshness_root=$MATERIALIZED
git -C "$freshness_root" init -q
git -C "$freshness_root" config user.name "Fixture Author"
git -C "$freshness_root" config user.email "fixture@example.invalid"
git -C "$freshness_root" add .
GIT_AUTHOR_DATE=2026-01-01T00:00:00Z \
  GIT_COMMITTER_DATE=2026-01-01T00:00:00Z \
  git -C "$freshness_root" commit -q -m "initial fixture"
printf '\nCommitted source change.\n' >>"$freshness_root/docs/canonical.md"
printf '\nCommitted historical change.\n' >>"$freshness_root/docs/historical.md"
git -C "$freshness_root" add docs/canonical.md docs/historical.md
GIT_AUTHOR_DATE=2026-02-01T00:00:00Z \
  GIT_COMMITTER_DATE=2026-02-01T00:00:00Z \
  git -C "$freshness_root" commit -q -m "update canonical source"
printf '\nDirty source change.\n' >>"$freshness_root/docs/canonical.md"
printf '\nDirty historical change.\n' >>"$freshness_root/docs/historical.md"
run_checker "$CLAUDE_CHECKER" "$TMP_ROOT/freshness.out" \
  --root "$freshness_root" --layer claude --today 2026-02-02 --fail-on warning
assert_status "Git source freshness warnings meet the warning threshold" 1
assert_code "dirty source reports K133" K133
assert_code "committed source newer than last_verified reports K134" K134
if [ "$(grep -c '^WARN|K133|' "$LAST_OUTPUT")" -eq 1 ] &&
  [ "$(grep -c '^WARN|K134|' "$LAST_OUTPUT")" -eq 1 ] &&
  ! grep -q 'retired-history.md' "$LAST_OUTPUT"; then
  pass "Git freshness warnings are limited to active entries"
else
  fail "Git freshness warnings are limited to active entries"
  sed 's/^/  /' "$LAST_OUTPUT" >&2
fi

/bin/bash "$CLAUDE_CHECKER" --help >"$TMP_ROOT/help.out" 2>"$TMP_ROOT/help.err"
help_status=$?
if [ "$help_status" -eq 0 ] && [ ! -s "$TMP_ROOT/help.err" ] &&
  ! grep -q -- '--fix' "$TMP_ROOT/help.out"; then
  pass "help is read-only and does not offer a fix mode"
else
  fail "help is read-only and does not offer a fix mode"
fi

/bin/bash "$CLAUDE_CHECKER" --layer invalid >"$TMP_ROOT/usage.out" \
  2>"$TMP_ROOT/usage.err"
usage_status=$?
if [ "$usage_status" -eq 2 ]; then
  pass "invalid CLI usage exits 2"
else
  fail "invalid CLI usage exits 2"
fi

if [ "$FAIL_COUNT" -ne 0 ]; then
  printf 'FAILED: %s assertion(s), %s passed\n' "$FAIL_COUNT" "$PASS_COUNT" >&2
  exit 1
fi

printf 'PASS: %s assertions\n' "$PASS_COUNT"
exit 0
