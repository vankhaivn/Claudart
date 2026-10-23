# Shared read-only helpers for the cda-tidy scripts. Source it; do not run it.
# Output lines use `KIND|field|...`. Exit 2 means a usage or runtime failure.

export LC_ALL=C

# Core rules are template-owned and change through INTEGRATE.md, not tidy.
TIDY_CORE_RULES=" ai-behavior code-health git-workflow task-management agent-delegation spec-workflow knowledge-management "

tidy_die() {
  printf 'ERROR|%s\n' "$*" >&2
  exit 2
}

# Sets ROOT, IS_GIT and HEAD. A path inside a Git work tree resolves to its top
# level, unless it holds its own `.claudart/` inside an unrelated parent repository.
tidy_root() {
  tidy_arg=${1:-$PWD}
  [ -d "$tidy_arg" ] || tidy_die "root is not a directory: $tidy_arg"
  tidy_real=$(cd "$tidy_arg" && pwd -P)
  tidy_top=$(git -C "$tidy_arg" rev-parse --show-toplevel 2>/dev/null) || tidy_top=
  [ -z "$tidy_top" ] || [ ! -d "$tidy_real/.claudart" ] || [ "$(cd "$tidy_top" && pwd -P)" = "$tidy_real" ] || tidy_top=
  if [ -n "$tidy_top" ]; then
    ROOT=$tidy_top
    IS_GIT=1
    HEAD=$(git -C "$ROOT" rev-parse --verify -q HEAD 2>/dev/null) || HEAD=
    [ -n "$HEAD" ] || tidy_die "the Git repository has no commits; commit the project before tidying"
  else
    ROOT=$tidy_real
    IS_GIT=0
    HEAD=
  fi
}

# Repository-relative directories of nested repositories; their docs are tidied separately.
tidy_nested() {
  find "$ROOT" -mindepth 1 \( -path "$ROOT/.git" -o -name node_modules \) -prune -o -name .git -print 2>/dev/null |
    awk -v root="$ROOT/" '{ p = substr($0, length(root) + 1); sub(/\/\.git$/, "", p); print p }' | sort
}

# Every candidate Markdown file: tracked files in Git, all files otherwise.
# Symlinks, dependency trees and nested repositories are left out.
tidy_list_md() {
  tidy_nested >"$TIDY_TMP/nested"
  if [ "$IS_GIT" = 1 ]; then
    git -C "$ROOT" -c core.quotePath=false ls-files -- '*.md'
  else
    find "$ROOT" \( -name node_modules -o -name .git \) -prune -o -type f -name '*.md' -print |
      awk -v root="$ROOT/" '{ print substr($0, length(root) + 1) }'
  fi | awk -v nested="$TIDY_TMP/nested" '
    BEGIN { while ((getline n < nested) > 0) skip[n] = 1 }
    {
      for (d = $0; sub(/\/[^\/]*$/, "", d) > 0; ) if (d in skip) next
      print
    }' | while IFS= read -r tidy_path; do
    [ -L "$ROOT/$tidy_path" ] || [ ! -f "$ROOT/$tidy_path" ] || printf '%s\n' "$tidy_path"
  done | sort
}

# Reads relative paths and prints `scope|path`.
# Scopes: state, knowledge, docs, rules (tidied); record, work, skip (not tidied).
# Docs are root Markdown, docs/ trees, READMEs and paths added with --include
# (TIDY_INCLUDES, one per line); other Markdown ships with the code.
tidy_classify() {
  printf '%s\n' "${TIDY_INCLUDES:-}" >"$TIDY_TMP/includes"
  awk -v core="$TIDY_CORE_RULES" -v includes="$TIDY_TMP/includes" '
    BEGIN { while ((getline line < includes) > 0) if (line != "") inc[++ninc] = line }
    {
      p = $0; n = split(p, part, "/"); b = part[n]; lb = tolower(b)
      extra = 0
      for (i = 1; i <= ninc; i++) if ((p == inc[i] || index(p, inc[i] "/") == 1)) extra = 1
      if (p ~ /(^|\/)(node_modules|vendor|third_party|fixtures|testdata|__snapshots__)\//) { print "skip|" p; next }
      if (p == "CLAUDE.md" || p == "AGENTS.md") { print "skip|" p; next }
      if (p ~ /^\.claudart\/(tasks|specs)\//) { print "work|" p; next }
      if (p == ".claudart/CONTEXT.md" || p == ".claudart/OWNER.md") { print "state|" p; next }
      if (p ~ /^\.claudart\/knowledge\//) { print "knowledge|" p; next }
      if (p ~ /^\.claudart\//) { print "skip|" p; next }
      if (p ~ /^\.claude\/rules\/.+\.md$/ || p ~ /^\.codex\/guidelines\/.+\.md$/) {
        r = b; sub(/\.md$/, "", r)
        print (index(core, " " r " ") ? "skip|" : "rules|") p; next
      }
      if (p ~ /(^|\/)\./) { print "skip|" p; next }
      if (lb ~ /^(changelog|history|release[-_ ]?notes)/ || p ~ /(^|\/)(adr|adrs|decisions)\//) { print "record|" p; next }
      if (extra || p !~ /\// || p ~ /(^|\/)(docs?|documentation)\// || lb == "readme.md") print "docs|" p
      else print "skip|" p
    }'
}

# Writes $TIDY_TMP/anchors: `scope|commit|date` for the latest commit whose
# Claudart-Tidy trailer names each scope (docs, knowledge, state, rules).
tidy_anchors() {
  : >"$TIDY_TMP/anchors"
  [ "$IS_GIT" = 1 ] || return 0
  git -C "$ROOT" log --date=short --format='%x1e%H %cd%n%B' --grep='^Claudart-Tidy:' HEAD 2>/dev/null | awk '
    BEGIN { RS = "\036" }
    NF {
      n = split($0, line, "\n"); split(line[1], head, " ")
      for (i = 2; i <= n; i++) {
        v = tolower(line[i])
        if (sub(/^claudart-tidy:/, "", v) == 0) continue
        m = split(v, word, /[^a-z]+/)
        for (j = 1; j <= m; j++) {
          w = word[j]; if (w == "guidelines") w = "rules"
          if (w ~ /^(docs|knowledge|state|rules)$/ && !(w in seen)) { seen[w] = 1; print w "|" head[1] "|" head[2] }
        }
      }
    }' >"$TIDY_TMP/anchors"
}

# Writes $TIDY_TMP/scope (`scope|path|review` or `scope|path|context`) and sets TIDY_MODE.
# A scope is reviewed in full until a tidy commit names it, then only files changed since.
tidy_scope() {
  tidy_full=$1
  tidy_anchors
  tidy_list_md | tidy_classify >"$TIDY_TMP/classified"
  : >"$TIDY_TMP/changed"
  if [ "$tidy_full" = 1 ]; then
    TIDY_MODE="full|requested"
  elif [ "$IS_GIT" = 0 ]; then
    TIDY_MODE="full|no Git history to compare"
  elif [ ! -s "$TIDY_TMP/anchors" ]; then
    TIDY_MODE="full|no earlier Claudart-Tidy commit"
  else
    TIDY_MODE="incremental|each scope since the last tidy commit naming it"
    while IFS='|' read -r tidy_s tidy_sha tidy_date; do
      git -C "$ROOT" -c core.quotePath=false diff --name-only "$tidy_sha" HEAD -- |
        awk -v s="$tidy_s" '{ print s "|" $0 }'
    done <"$TIDY_TMP/anchors" >"$TIDY_TMP/changed"
  fi
  awk -F'|' -v changed="$TIDY_TMP/changed" -v anchors="$TIDY_TMP/anchors" -v full="${TIDY_MODE%%|*}" '
    BEGIN {
      while ((getline c < changed) > 0) hit[c] = 1
      while ((getline a < anchors) > 0) { split(a, f, "|"); done[f[1]] = 1 }
    }
    $1 ~ /^(state|knowledge|docs|rules)$/ {
      review = full == "full" || !($1 in done) || (($1 "|" $2) in hit)
      print $1 "|" $2 "|" (review ? "review" : "context")
    }' "$TIDY_TMP/classified" >"$TIDY_TMP/scope"
}

tidy_tmp() {
  TIDY_TMP=$(mktemp -d "${TMPDIR:-/tmp}/cda-tidy.XXXXXX") || tidy_die "cannot create a temporary directory"
  trap 'rm -rf "$TIDY_TMP"' EXIT
}
