#!/usr/bin/env bash
# Read-only: list what a tidy run should review, since the last Claudart-Tidy
# commit when one exists, and what active work depends on.
set -u

usage() {
  cat <<'EOF'
Usage: scope.sh [--root DIR] [--full] [--include PATH]... [--snapshot DIR]

  --root DIR      Project root; a path inside a Git work tree uses its top level.
  --full          Review every in-scope file, ignoring earlier Claudart-Tidy commits.
  --include PATH  Treat Markdown under PATH as project docs; repeatable.
  --snapshot DIR  Copy every in-scope file to DIR (outside the root) before editing,
                  for verify.sh --before on a root without Git.

Lines: ROOT, ANCHOR|scope|commit|date (one per tidied scope), MODE,
FILE|scope|path (to review), RECORD, NESTED,
ACTIVE|item|words, PROTECTED|path|item, RULEREF|rule:line|path|missing or changed,
SUMMARY. Exit 0 on success, 2 on a usage or runtime failure.
EOF
}

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib.sh"

root_arg=; full=0; snapshot=
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || tidy_die "--root needs a directory"; root_arg=$2; shift 2 ;;
    --full) full=1; shift ;;
    --include)
      [ $# -ge 2 ] || tidy_die "--include needs a repository-relative path"
      case "$2" in /*|../*|*/../*) tidy_die "--include must stay inside the root" ;; esac
      TIDY_INCLUDES="${TIDY_INCLUDES:-}${TIDY_INCLUDES:+
}${2%/}"; shift 2 ;;
    --snapshot) [ $# -ge 2 ] || tidy_die "--snapshot needs a directory"; snapshot=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

tidy_root "$root_arg"
if [ -n "$snapshot" ]; then
  snap_parent=$(cd "$(dirname "$snapshot")" 2>/dev/null && pwd -P) || tidy_die "snapshot parent directory not found: $snapshot"
  snap="$snap_parent/$(basename "$snapshot")"
  case "$snap/" in "$ROOT"/*) tidy_die "snapshot must be outside the root" ;; esac
fi
tidy_tmp
tidy_scope "$full"

if [ "$IS_GIT" = 1 ]; then
  dirty=$(git -C "$ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  printf 'ROOT|%s|git|%s|dirty=%s\n' "$ROOT" "${HEAD:-no-commits}" "$dirty"
else
  printf 'ROOT|%s|no-git\n' "$ROOT"
fi
if [ -s "$TIDY_TMP/anchors" ]; then
  sed 's/^/ANCHOR|/' "$TIDY_TMP/anchors"
else
  printf 'ANCHOR|none\n'
fi
printf 'MODE|%s\n' "$TIDY_MODE"

awk -F'|' '$3 == "review" { print "FILE|" $1 "|" $2 }' "$TIDY_TMP/scope"
awk -F'|' '$1 == "record" { print "RECORD|" $2 }' "$TIDY_TMP/classified"
sed 's/^/NESTED|/' "$TIDY_TMP/nested"

# Active work is read for context and never edited by tidy.
: >"$TIDY_TMP/active"
for item in "$ROOT"/.claudart/tasks/*/ "$ROOT"/.claudart/specs/*/; do
  [ -d "$item" ] && [ ! -L "${item%/}" ] || continue
  rel=${item#"$ROOT/"}; rel=${rel%/}
  case "$rel" in */done) continue ;; esac
  [ -f "$item/TASK.md" ] || [ -f "$item/SPEC.md" ] || continue
  words=$(cat "$item"/*.md 2>/dev/null | wc -w | tr -d ' ')
  printf 'ACTIVE|%s|%s\n' "$rel" "$words"
  for f in "$item"/*.md; do [ -f "$f" ] && [ ! -L "$f" ] && printf '%s|%s\n' "$rel" "$f"; done >>"$TIDY_TMP/active"
done

cut -d'|' -f2 "$TIDY_TMP/scope" >"$TIDY_TMP/paths"
if [ -s "$TIDY_TMP/active" ] && [ -s "$TIDY_TMP/paths" ]; then
  while IFS='|' read -r item file; do
    grep -oF -f "$TIDY_TMP/paths" "$file" 2>/dev/null | sed "s#\$#|$item#"
  done <"$TIDY_TMP/active" | sort -u | sed 's/^/PROTECTED|/'
fi

# Concrete path references in project rules that no longer exist or changed since the rules anchor.
awk -F'|' '$1 == "rules" { print $2 }' "$TIDY_TMP/scope" | while IFS= read -r rule; do
  awk '
    {
      line = $0
      while (match(line, /`[^`]+`/)) {
        t = substr(line, RSTART + 1, RLENGTH - 2); line = substr(line, RSTART + RLENGTH)
        sub(/:[0-9]+(-[0-9]+)?$/, "", t)
        # Paths only: a file with an extension or a directory ending in a slash.
        if (t ~ /[^\/]\/[^\/]/ && t ~ /^[A-Za-z0-9_.\/-]+$/ && t ~ /(\/|\.[A-Za-z0-9]+)$/ && t !~ /^(\/|~|-)/) print FNR "|" t
      }
    }' "$ROOT/$rule" | while IFS='|' read -r line ref; do
    if [ ! -e "$ROOT/$ref" ]; then
      printf 'RULEREF|%s:%s|%s|missing\n' "$rule" "$line" "$ref"
    elif grep -qxF "rules|$ref" "$TIDY_TMP/changed" 2>/dev/null; then
      printf 'RULEREF|%s:%s|%s|changed\n' "$rule" "$line" "$ref"
    fi
  done
done

if [ -n "$snapshot" ]; then
  mkdir -p "$snap" || tidy_die "cannot create snapshot directory: $snap"
  while IFS= read -r rel; do
    mkdir -p "$snap/$(dirname "$rel")" && cp "$ROOT/$rel" "$snap/$rel" || tidy_die "cannot copy $rel"
  done <"$TIDY_TMP/paths"
  printf 'SNAPSHOT|%s|%s files\n' "$snap" "$(wc -l <"$TIDY_TMP/paths" | tr -d ' ')"
fi

awk -F'|' -v nested="$(wc -l <"$TIDY_TMP/nested" | tr -d ' ')" '
  FILENAME ~ /scope$/ { all++; if ($3 == "review") { review++; n[$1]++ } }
  FILENAME ~ /classified$/ && $1 == "record" { records++ }
  END {
    printf "SUMMARY|review=%d of %d|state=%d knowledge=%d docs=%d rules=%d|records=%d nested=%d\n",
      review, all, n["state"], n["knowledge"], n["docs"], n["rules"], records, nested
  }' "$TIDY_TMP/scope" "$TIDY_TMP/classified"
