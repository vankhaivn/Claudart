#!/usr/bin/env bash
# Read-only: point at text that likely breaks the "Keep Documents Current"
# contract in the files scope.sh selects for review. A signal is a place to
# look, never a verdict; the agent decides what the reader still needs.
set -u

usage() {
  cat <<'EOF'
Usage: signals.sh [--root DIR] [--full] [--include PATH]...

Lines (path:line|excerpt):
  LONG      state line over 400 bytes
  DATED     dated update note or heading
  EVIDENCE  test totals, run or job IDs, commit hash lists, timestamps
  HISTORY   transition narration such as "previously" or "no longer"
  DUP       sentence of 12+ words repeated in another in-scope file
SUMMARY closes the output. Exit 0 on success, 2 on a usage or runtime failure.
EOF
}

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib.sh"

root_arg=; full=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || tidy_die "--root needs a directory"; root_arg=$2; shift 2 ;;
    --full) full=1; shift ;;
    --include)
      [ $# -ge 2 ] || tidy_die "--include needs a repository-relative path"
      case "$2" in /*|../*|*/../*) tidy_die "--include must stay inside the root" ;; esac
      TIDY_INCLUDES="${TIDY_INCLUDES:-}${TIDY_INCLUDES:+
}${2%/}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

tidy_root "$root_arg"
tidy_tmp
tidy_scope "$full"

awk -F'|' '$3 == "review" { print $2 }' "$TIDY_TMP/scope" >"$TIDY_TMP/review"
# Rules are mirrored across runtimes by design, so they stay out of the duplicate corpus.
awk -F'|' '$1 != "rules" { print $2 }' "$TIDY_TMP/scope" >"$TIDY_TMP/corpus"
[ -s "$TIDY_TMP/scope" ] || { echo "SUMMARY|nothing in scope"; exit 0; }

# Line signals in review files. Frontmatter and fenced code are skipped;
# OWNER entries carry a date by contract, so they are not DATED.
awk -F'|' '$3 == "review" && $1 != "rules" { print $2 }' "$TIDY_TMP/scope" >"$TIDY_TMP/linefiles"
: >"$TIDY_TMP/lines"
[ ! -s "$TIDY_TMP/linefiles" ] || (cd "$ROOT" && tr '\n' '\0' <"$TIDY_TMP/linefiles" |
  xargs -0 awk '
    function out(kind) { e = $0; gsub(/\|/, "/", e); gsub(/^[ \t]+/, "", e); if (length(e) > 140) e = substr(e, 1, 137) "..."; print kind "|" FILENAME ":" FNR "|" e }
    function hashes(s,   n, i, w, c) {
      n = split(s, w, /[^0-9a-f]+/); c = 0
      for (i = 1; i <= n; i++) if (length(w[i]) >= 7 && length(w[i]) <= 40 && w[i] ~ /[0-9]/ && w[i] ~ /[a-f]/) c++
      return c
    }
    FNR == 1 { fence = 0; front = 0; state = (FILENAME ~ /^\.claudart\/(CONTEXT|OWNER)\.md$/); owner = (FILENAME == ".claudart/OWNER.md") }
    FNR == 1 && /^---[ \t]*$/ { front = 1; next }
    front { if (/^---[ \t]*$/) front = 0; next }
    /^[ \t]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    {
      l = tolower($0); plain = $0; gsub(/[ \t]*<!--[^>]*-->/, "", plain)
      if (state && length(plain) > 400) out("LONG")
      if (!owner && (l ~ /(updated|update|as of|last verified|verified on|cập nhật)[^|.;]*20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ || l ~ /^#+ .*20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) out("DATED")
      if (l ~ /[0-9][0-9,]* (tests?|passed|failed|passing|assertions)([^a-z]|$)/ || l ~ /(run|job|pipeline|build)( id)?[ #:]*[0-9][0-9][0-9][0-9]/ || l ~ /20[0-9][0-9]-[0-9][0-9]-[0-9][0-9][ t][0-9][0-9]:[0-9][0-9]/ || hashes(l) >= 2) out("EVIDENCE")
      if (l ~ /(^|[^a-z])(previously|no longer|used to|formerly|was changed|has been replaced|now uses)([^a-z]|$)/ || l ~ /(trước đây|không còn|đã được thay)/) out("HISTORY")
    }' ) >"$TIDY_TMP/lines"

# Repeated sentences across in-scope files, reported when one copy is under review.
(cd "$ROOT" && awk -v review="$TIDY_TMP/review" -v corpus="$TIDY_TMP/corpus" '
  BEGIN {
    while ((getline r < review) > 0) rev[r] = 1
    while ((getline f < corpus) > 0) {
      fence = 0; front = 0; ln = 0
      while ((getline line < f) > 0) {
        ln++
        if (ln == 1 && line ~ /^---[ \t]*$/) { front = 1; continue }
        if (front) { if (line ~ /^---[ \t]*$/) front = 0; continue }
        if (line ~ /^[ \t]*(```|~~~)/) { fence = !fence; continue }
        if (fence || line ~ /^[ \t]*\|/) continue
        n = split(line, part, /[.!?][ \t]+/)
        for (i = 1; i <= n; i++) {
          s = tolower(part[i])
          gsub(/\]\([^)]*\)/, " ", s); gsub(/[`*_>#()":;,]/, " ", s); gsub(/[][]/, " ", s); gsub(/\047/, " ", s)
          gsub(/[ \t]+/, " ", s); sub(/^[ -]+/, "", s); sub(/ +$/, "", s)
          if (split(s, w, " ") < 12) continue
          if (index(files[s] "|", "|" f "|")) continue
          files[s] = files[s] "|" f; locs[s] = locs[s] "|" f ":" ln; count[s]++
          if (f in rev) hit[s] = 1
        }
      }
      close(f)
    }
  }
  END {
    for (s in count) if (count[s] > 1 && hit[s]) {
      e = s; if (length(e) > 100) e = substr(e, 1, 97) "..."
      print "DUP" locs[s] "|" e
    }
  }' </dev/null | sort) >>"$TIDY_TMP/lines"

cat "$TIDY_TMP/lines"
awk -F'|' '{ n[$1]++ } END { printf "SUMMARY|LONG=%d DATED=%d EVIDENCE=%d HISTORY=%d DUP=%d\n", n["LONG"], n["DATED"], n["EVIDENCE"], n["HISTORY"], n["DUP"] }' "$TIDY_TMP/lines"
