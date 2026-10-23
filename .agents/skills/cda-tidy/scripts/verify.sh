#!/usr/bin/env bash
# Read-only: after tidy edits, list facts that may have been lost and links
# that no longer resolve. The agent confirms each item; nothing is auto-fixed.
set -u

usage() {
  cat <<'EOF'
Usage: verify.sh [--root DIR] [--include PATH]... [--base REV | --before DIR]

Compares edited Markdown with its earlier version: the working tree against
HEAD by default, against REV with --base, or against a scope.sh --snapshot
copy with --before (required on a root without Git).

Lines:
  LOST     path|token  a code span, link target or URL that was removed and
                       appears nowhere else in the tree or the new text
  REMOVED  path|text   a removed constraint, decision or reason whose wording
                       does not reappear in the new text; confirm it moved or
                       no longer applies
  LINK     path:line|target  a broken relative link in an edited file, or one
                       pointing at a file this edit removed
  OLDLINK  path:line|target  a broken relative link this edit did not cause
SUMMARY closes the output. Exit 0 when nothing is LOST and no LINK remains,
1 when LOST or LINK lines remain, 2 on a usage or runtime failure.
EOF
}

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib.sh"

root_arg=; base=; before=
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || tidy_die "--root needs a directory"; root_arg=$2; shift 2 ;;
    --include)
      [ $# -ge 2 ] || tidy_die "--include needs a repository-relative path"
      case "$2" in /*|../*|*/../*) tidy_die "--include must stay inside the root" ;; esac
      TIDY_INCLUDES="${TIDY_INCLUDES:-}${TIDY_INCLUDES:+
}${2%/}"; shift 2 ;;
    --base) [ $# -ge 2 ] || tidy_die "--base needs a revision"; base=$2; shift 2 ;;
    --before) [ $# -ge 2 ] || tidy_die "--before needs a directory"; before=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
[ -z "$base" ] || [ -z "$before" ] || tidy_die "use either --base or --before"

tidy_root "$root_arg"
tidy_tmp
tidy_scope 1

: >"$TIDY_TMP/removed"
: >"$TIDY_TMP/added"
: >"$TIDY_TMP/compared"
: >"$TIDY_TMP/deleted"
compare() {
  rel=$1; old=$2
  printf '%s\n' "$rel" >>"$TIDY_TMP/compared"
  new="$ROOT/$rel"; [ -f "$new" ] || { new=/dev/null; basename "$rel" >>"$TIDY_TMP/deleted"; }
  diff "$old" "$new" >"$TIDY_TMP/diff" 2>/dev/null
  sed -n 's/^< //p' "$TIDY_TMP/diff" | awk -v rel="$rel" '{ print rel "\t" $0 }' >>"$TIDY_TMP/removed"
  sed -n 's/^> //p' "$TIDY_TMP/diff" >>"$TIDY_TMP/added"
}

if [ -n "$before" ]; then
  [ -d "$before" ] || tidy_die "before directory not found: $before"
  before=$(cd "$before" && pwd -P)
  case "$before/" in "$ROOT"/*) tidy_die "before directory must be outside the root" ;; esac
  (cd "$before" && find . -type f -name '*.md' | sed 's#^\./##') | sort >"$TIDY_TMP/files"
  while IFS= read -r rel; do
    cmp -s "$before/$rel" "$ROOT/$rel" 2>/dev/null || compare "$rel" "$before/$rel"
  done <"$TIDY_TMP/files"
elif [ "$IS_GIT" = 1 ]; then
  base=${base:-HEAD}
  git -C "$ROOT" rev-parse --verify -q "$base^{commit}" >/dev/null || tidy_die "unknown revision: $base"
  git -C "$ROOT" -c core.quotePath=false diff --name-only "$base" -- '*.md' >"$TIDY_TMP/files"
  while IFS= read -r rel; do
    git -C "$ROOT" show "$base:$rel" >"$TIDY_TMP/old" 2>/dev/null || : >"$TIDY_TMP/old"
    compare "$rel" "$TIDY_TMP/old"
  done <"$TIDY_TMP/files"
else
  tidy_die "a root without Git needs --before DIR from scope.sh --snapshot"
fi

# Tokens from removed lines: code spans, link targets (by file name) and URLs.
awk -F'\t' '
  function emit(t, kind) { if (length(t) >= 3 && t !~ /^[0-9.,:%+-]+$/ && !seen[t]++) print $1 "\t" t "\t" kind }
  {
    line = $2
    while (match(line, /`[^`]+`/)) { emit(substr(line, RSTART + 1, RLENGTH - 2), "text"); line = substr(line, RSTART + RLENGTH) }
    line = $2
    while (match(line, /\]\([^) ]+/)) {
      t = substr(line, RSTART + 2, RLENGTH - 2); line = substr(line, RSTART + RLENGTH)
      if (t !~ /^(https?:|mailto:|#)/) { sub(/#.*/, "", t); sub(/.*\//, "", t); emit(t, "link") }
    }
    line = $2
    while (match(line, /https?:\/\/[^ )>"`\047]+/)) { emit(substr(line, RSTART, RLENGTH), "text"); line = substr(line, RSTART + RLENGTH) }
  }' "$TIDY_TMP/removed" >"$TIDY_TMP/tokens"

# A token kept in the new text is not lost.
awk -F'\t' -v added="$TIDY_TMP/added" '
  BEGIN { while ((getline a < added) > 0) text = text a "\n" }
  index(text, $2) == 0' "$TIDY_TMP/tokens" >"$TIDY_TMP/candidates"

# The project's own files: tracked and untracked in Git, otherwise the tree
# without dependency folders and nested repositories.
if [ "$IS_GIT" = 1 ]; then
  git -C "$ROOT" -c core.quotePath=false ls-files --cached --others --exclude-standard >"$TIDY_TMP/project"
else
  awk -v root="$ROOT" '{ print root "/" $0 }' "$TIDY_TMP/nested" >"$TIDY_TMP/prune"
  find "$ROOT" \( -name .git -o -name node_modules \) -prune -o -type f -print 2>/dev/null |
    awk -v prune="$TIDY_TMP/prune" '
      BEGIN { while ((getline p < prune) > 0) skip[p] = 1 }
      { for (d = $0; sub(/\/[^\/]*$/, "", d) > 0; ) if (d in skip) next; print }' >"$TIDY_TMP/project"
fi
awk -F/ '{ print $NF }' "$TIDY_TMP/project" | sort -u >"$TIDY_TMP/names"

# One fixed-string search per token with an early exit: searching for all
# tokens in one pass checks each of them on every line and stalls on large trees.
in_project() {
  if [ "$IS_GIT" = 1 ]; then
    git -C "$ROOT" grep -q -I -F --untracked -e "$1" -- . 2>/dev/null
  else
    [ -n "$(tr '\n' '\0' <"$TIDY_TMP/project" | xargs -0 grep -lIF -e "$1" -- 2>/dev/null | head -n 1)" ]
  fi
}

while IFS='	' read -r rel token kind; do
  # A removed link matters only when its target page still exists.
  if [ "$kind" = link ] && ! grep -qxF -e "$token" "$TIDY_TMP/names"; then
    continue
  fi
  in_project "$token" || printf 'LOST|%s|%s\n' "$rel" "$token"
done <"$TIDY_TMP/candidates" >"$TIDY_TMP/out"

# Removed lines that carry a constraint, decision or reason and were not moved verbatim.
awk -F'\t' -v added="$TIDY_TMP/added" '
  function norm(s) { s = tolower(s); gsub(/[`*_>#]/, "", s); gsub(/[ \t]+/, " ", s); sub(/^[ -]+/, "", s); sub(/ +$/, "", s); return s }
  BEGIN { while ((getline a < added) > 0) kept[norm(a)] = 1 }
  {
    l = norm($2)
    if (l in kept) next
    if (l ~ /(^|[^a-z])(must|never|do not|don.t|required?|requires|because|decided|decision|cannot|can.t|avoid|always|only when)([^a-z]|$)/ ||
        l ~ /(phải|không được|quyết định|tránh|vì sao|bởi vì)/) {
      e = $2; gsub(/\|/, "/", e); sub(/^[ \t]+/, "", e); if (length(e) > 160) e = substr(e, 1, 157) "..."
      print "REMOVED|" $1 "|" e
    }
  }' "$TIDY_TMP/removed" >>"$TIDY_TMP/out"

# Relative links in every in-scope file must resolve. Only breakage in edited
# files or toward removed files blocks; older breakage is reported for review.
cut -d'|' -f2 "$TIDY_TMP/scope" | while IFS= read -r rel; do
  edited=0; grep -qxF "$rel" "$TIDY_TMP/compared" && edited=1
  awk '
    FNR == 1 { fence = 0; comment = 0 }
    /^[ \t]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    {
      line = $0
      if (comment) { if (sub(/.*-->/, "", line)) comment = 0; else next }
      gsub(/<!--([^-]|-[^-]|--[^>])*-->/, "", line)
      if (sub(/<!--.*/, "", line)) comment = 1
      gsub(/`[^`]*`/, "", line)
      body = line
      while (match(line, /\]\([^)]+\)/)) {
        t = substr(line, RSTART + 2, RLENGTH - 3); line = substr(line, RSTART + RLENGTH)
        if (t ~ /^</) { sub(/^</, "", t); sub(/>.*/, "", t) } else sub(/[ \t].*/, "", t)
        gsub(/%20/, " ", t)
        if (t !~ /^(https?:|mailto:|tel:|#|\/)/ && t !~ /:\/\//) { sub(/[#?].*/, "", t); if (t != "") print FNR "|" t }
      }
      if (match(body, /^[ \t]*\[[^]]+\]:[ \t]+[^ \t]+/)) {
        t = body; sub(/^[ \t]*\[[^]]+\]:[ \t]+/, "", t); sub(/[ \t].*/, "", t)
        if (t !~ /^(https?:|mailto:|tel:|#|\/)/ && t !~ /:\/\//) { sub(/[#?].*/, "", t); if (t != "") print FNR "|" t }
      }
    }' "$ROOT/$rel" | while IFS='|' read -r line target; do
    dir=$(dirname "$ROOT/$rel")
    [ ! -e "$dir/$target" ] || continue
    kind=OLDLINK
    if [ "$edited" = 1 ] || grep -qxF "$(basename "$target")" "$TIDY_TMP/deleted"; then kind=LINK; fi
    printf '%s|%s:%s|%s\n' "$kind" "$rel" "$line" "$target"
  done
done >>"$TIDY_TMP/out"

cat "$TIDY_TMP/out"
awk -F'|' '{ n[$1]++ } END {
  printf "SUMMARY|files compared=%d|LOST=%d REMOVED=%d LINK=%d OLDLINK=%d\n", files, n["LOST"], n["REMOVED"], n["LINK"], n["OLDLINK"]
  exit (n["LOST"] + n["LINK"] > 0) }' files="$(grep -c '' "$TIDY_TMP/compared" | tr -d ' ')" "$TIDY_TMP/out"
