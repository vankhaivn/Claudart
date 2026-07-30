#!/bin/bash

# Read-only validator for CLAUDART knowledge stores.
# Runtime dependencies are limited to Bash 3.2 and common POSIX utilities.

set -u

LC_ALL=C
export LC_ALL

PROGRAM=${0##*/}
FAIL_ON=error
TODAY=$(date +%Y-%m-%d 2>/dev/null || :)
ROOT_OVERRIDE=
LAYER_OVERRIDE=
SEP=$(printf '\034')

usage() {
  cat <<'EOF'
Usage: knowledge-check.sh [options]

Read-only validation for a CLAUDART knowledge store.

Options:
  --root DIR                 Repository root (default: inferred from script path)
  --layer claude|codex       Runtime layer (default: inferred from script path)
  --today YYYY-MM-DD         Date used for deterministic freshness checks
  --fail-on error|warning    Exit 1 at this severity (default: error)
  --help                     Show this help

Exit status:
  0  no finding at or above the selected threshold
  1  at least one finding at or above the selected threshold
  2  invalid usage or an internal runtime failure
EOF
}

usage_error() {
  printf '%s: %s\n' "$PROGRAM" "$1" >&2
  printf '%s\n' "Try '$PROGRAM --help' for usage." >&2
  exit 2
}

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P) ||
  usage_error "cannot resolve the script directory"
INFERRED_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/../.." 2>/dev/null && pwd -P) ||
  usage_error "cannot infer the repository root"

case "$SCRIPT_DIR" in
  */.claude/scripts) INFERRED_LAYER=claude ;;
  */.codex/scripts) INFERRED_LAYER=codex ;;
  *) INFERRED_LAYER= ;;
esac

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      [ "$#" -ge 2 ] || usage_error "--root requires a directory"
      ROOT_OVERRIDE=$2
      shift 2
      ;;
    --layer)
      [ "$#" -ge 2 ] || usage_error "--layer requires claude or codex"
      LAYER_OVERRIDE=$2
      shift 2
      ;;
    --today)
      [ "$#" -ge 2 ] || usage_error "--today requires YYYY-MM-DD"
      TODAY=$2
      shift 2
      ;;
    --fail-on)
      [ "$#" -ge 2 ] || usage_error "--fail-on requires error or warning"
      FAIL_ON=$2
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    --*)
      usage_error "unknown option: $1"
      ;;
    *)
      usage_error "unexpected argument: $1"
      ;;
  esac
done

case "$FAIL_ON" in
  error | warning) ;;
  *) usage_error "--fail-on must be error or warning" ;;
esac

if [ -n "$LAYER_OVERRIDE" ]; then
  LAYER=$LAYER_OVERRIDE
else
  LAYER=$INFERRED_LAYER
fi
case "$LAYER" in
  claude | codex) ;;
  *) usage_error "cannot infer layer; pass --layer claude or --layer codex" ;;
esac

if [ -n "$ROOT_OVERRIDE" ]; then
  [ -d "$ROOT_OVERRIDE" ] || usage_error "--root is not a directory"
  ROOT=$(CDPATH='' cd -- "$ROOT_OVERRIDE" 2>/dev/null && pwd -P) ||
    usage_error "cannot resolve --root"
else
  ROOT=$INFERRED_ROOT
fi

valid_date() {
  printf '%s\n' "$1" | awk '
    function leap(y) {
      return (y % 400 == 0 || (y % 4 == 0 && y % 100 != 0))
    }
    function valid(s, y, m, d, max) {
      if (s !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return 0
      y = substr(s, 1, 4) + 0
      m = substr(s, 6, 2) + 0
      d = substr(s, 9, 2) + 0
      if (y < 1 || m < 1 || m > 12) return 0
      max = 31
      if (m == 4 || m == 6 || m == 9 || m == 11) max = 30
      if (m == 2) max = leap(y) ? 29 : 28
      return d >= 1 && d <= max
    }
    { exit(valid($0) ? 0 : 1) }
  '
}

date_ordinal() {
  printf '%s\n' "$1" | awk '
    {
      y = substr($0, 1, 4) + 0
      m = substr($0, 6, 2) + 0
      d = substr($0, 9, 2) + 0
      if (m <= 2) y--
      era = int(y / 400)
      yoe = y - era * 400
      mp = m + (m > 2 ? -3 : 9)
      doy = int((153 * mp + 2) / 5) + d - 1
      doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
      print era * 146097 + doe
    }
  '
}

valid_date "$TODAY" || usage_error "--today must be a valid ISO date"
TODAY_ORDINAL=$(date_ordinal "$TODAY") ||
  usage_error "cannot calculate the selected date"

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/claudart-knowledge-check.XXXXXX" 2>/dev/null) ||
  usage_error "cannot create a temporary directory"

# Invoked indirectly by trap.
# shellcheck disable=SC2329
cleanup() {
  if [ -n "${TMP_DIR:-}" ] && [ -d "$TMP_DIR" ]; then
    rm -rf -- "$TMP_DIR"
  fi
}
# Invoked indirectly by trap.
# shellcheck disable=SC2329
on_signal() {
  trap - HUP INT TERM
  exit 2
}
trap cleanup EXIT
trap on_signal HUP INT TERM

FINDINGS=$TMP_DIR/findings
CATALOG=$TMP_DIR/catalog
VALID=$TMP_DIR/valid
ROUTES_RAW=$TMP_DIR/routes-raw
ROUTES_VALID=$TMP_DIR/routes-valid
ROOT_MAP_HITS=$TMP_DIR/root-map-hits
REACH_HITS=$TMP_DIR/reach-hits
ACTIVE_ROOT_MAP_HITS=$TMP_DIR/active-root-map-hits
ACTIVE_REACH_HITS=$TMP_DIR/active-reach-hits
ACTIVE_ROUTE_HITS=$TMP_DIR/active-route-hits
DIRECT_ACTIVE=$TMP_DIR/direct-active
: >"$FINDINGS"
: >"$CATALOG"
: >"$VALID"
: >"$ROUTES_RAW"
: >"$ROUTES_VALID"
: >"$ROOT_MAP_HITS"
: >"$REACH_HITS"
: >"$ACTIVE_ROOT_MAP_HITS"
: >"$ACTIVE_REACH_HITS"
: >"$ACTIVE_ROUTE_HITS"
: >"$DIRECT_ACTIVE"

add_finding() {
  severity=$1
  code=$2
  path=$3
  line=$4
  message=$5
  case "$line" in
    '' | *[!0-9]*) line=1 ;;
  esac
  # Messages are fixed strings and never include detected sensitive content.
  printf '%s|%s|%s:%s|%s\n' "$severity" "$code" "$path" "$line" "$message" >>"$FINDINGS"
}

append_diagnostics() {
  diagnostic_path=$1
  diagnostic_file=$2
  [ -s "$diagnostic_file" ] || return 0
  while IFS="$SEP" read -r severity code line message; do
    [ -n "$severity" ] || continue
    add_finding "$severity" "$code" "$diagnostic_path" "$line" "$message"
  done <"$diagnostic_file"
}

lowercase() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

is_slug() {
  printf '%s\n' "$1" |
    grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'
}

forbidden_env_path() {
  # This is lexical only. It deliberately runs before any filesystem or Git check.
  printf '/%s/\n' "$1" |
    grep -Eq '/\.env([.][^/]*)?(/|$)'
}

has_glob_syntax() {
  case "$1" in
    *'*'* | *'?'* | *'['* | *']'* | *'{'* | *'}'*) return 0 ;;
    *) return 1 ;;
  esac
}

meta_get() {
  awk -v FS="$SEP" -v wanted="$2" '
    $1 == "S" && $2 == wanted { print $3; exit }
  ' "$TMP_DIR/meta.$1"
}

meta_line() {
  result=$(awk -v FS="$SEP" -v wanted="$2" '
    $1 == "S" && $2 == wanted { print $4; exit }
  ' "$TMP_DIR/meta.$1")
  if [ -n "$result" ]; then
    printf '%s\n' "$result"
  else
    printf '%s\n' 1
  fi
}

parse_metadata() {
  parse_id=$1
  parse_file=$2
  parse_kind=$3
  parse_rel=$4
  parse_meta=$TMP_DIR/meta.$parse_id
  parse_diag=$TMP_DIR/diag.$parse_id
  : >"$parse_meta"
  : >"$parse_diag"

  awk -v sep="$SEP" -v meta="$parse_meta" -v diag="$parse_diag" -v kind="$parse_kind" '
    function error(code, line, message) {
      print "ERROR" sep code sep line sep message >> diag
      invalid = 1
    }
    function known(key) {
      return key == "name" || key == "description" || key == "type" ||
        key == "status" || key == "updated" || key == "last_verified" ||
        key == "aliases" || key == "triggers" || key == "scope" ||
        key == "sources" || key == "related" || key == "supersedes" ||
        key == "verify" || key == "status_note" || key == "sensitivity"
    }
    function list_key(key) {
      return key == "aliases" || key == "triggers" || key == "scope" ||
        key == "sources" || key == "related" || key == "supersedes"
    }
    function free_text_key(key) {
      return key == "description" || key == "verify" || key == "status_note"
    }
    function quoted(value, i, c, nextc, inner) {
      if (length(value) < 2 || substr(value, 1, 1) != "\"" ||
          substr(value, length(value), 1) != "\"") return 0
      inner = substr(value, 2, length(value) - 2)
      for (i = 1; i <= length(inner); i++) {
        c = substr(inner, i, 1)
        if (c ~ /[[:cntrl:]]/) return 0
        if (c == "\"") return 0
        if (c == "\\") {
          i++
          if (i > length(inner)) return 0
          nextc = substr(inner, i, 1)
          if (nextc !~ /^["\\\/bfnrt]$/) return 0
        }
      }
      return 1
    }
    function decode(value, i, c, nextc, inner, output) {
      inner = substr(value, 2, length(value) - 2)
      output = ""
      for (i = 1; i <= length(inner); i++) {
        c = substr(inner, i, 1)
        if (c == "\\") {
          i++
          nextc = substr(inner, i, 1)
          if (nextc == "\"" || nextc == "\\" || nextc == "/") {
            output = output nextc
          } else {
            output = output "\\" nextc
          }
        } else {
          output = output c
        }
      }
      return output
    }
    function leap(y) {
      return (y % 400 == 0 || (y % 4 == 0 && y % 100 != 0))
    }
    function valid_date(value, y, m, d, max) {
      if (value !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return 0
      y = substr(value, 1, 4) + 0
      m = substr(value, 6, 2) + 0
      d = substr(value, 9, 2) + 0
      if (y < 1 || m < 1 || m > 12) return 0
      max = 31
      if (m == 4 || m == 6 || m == 9 || m == 11) max = 30
      if (m == 2) max = leap(y) ? 29 : 28
      return d >= 1 && d <= max
    }
    function finish_list() {
      if (current_list != "" && list_count[current_list] == 0) {
        error("K114", list_line[current_list],
          "empty list must be omitted instead of declared")
      }
      current_list = ""
    }
    function scalar(key, value, line) {
      if (free_text_key(key)) {
        if (!quoted(value)) {
          error("K102", line,
            "free-text scalar must be one-line double-quoted text with safe escapes")
          return
        }
        decoded = decode(value)
        if (decoded == "") {
          error("K106", line, "scalar value must not be empty")
          return
        }
        scalar_value[key] = decoded
      } else {
        if (value == "" || value ~ /[[:space:]]/ ||
            value !~ /^[A-Za-z0-9._-]+$/) {
          error("K106", line, "plain scalar must be a safe unquoted token")
          return
        }
        scalar_value[key] = value
      }
      scalar_line[key] = line
      print "S" sep key sep scalar_value[key] sep line >> meta
    }
    function validate_contract( required, i, key, value, status, type) {
      finish_list()
      required[1] = "name"
      required[2] = "description"
      required[3] = "type"
      required[4] = "status"
      required[5] = "updated"
      for (i = 1; i <= 5; i++) {
        key = required[i]
        if (!seen[key]) error("K105", 1, "missing required metadata key: " key)
      }
      if (seen["name"] &&
          scalar_value["name"] !~ /^[a-z0-9]+(-[a-z0-9]+)*$/) {
        error("K106", scalar_line["name"], "name must be a lowercase kebab-case slug")
      }
      type = scalar_value["type"]
      if (kind == "map") {
        if (seen["type"] && type != "map") {
          error("K111", scalar_line["type"], "map metadata type must be map")
        }
        if (list_count["related"] > 0) {
          error("K111", list_line["related"],
            "map metadata must not declare related topic edges")
        }
        if (list_count["supersedes"] > 0) {
          error("K111", list_line["supersedes"],
            "map metadata must not declare supersedes edges")
        }
      } else if (seen["type"] &&
          type != "domain" && type != "architecture" &&
          type != "integration" && type != "glossary" &&
          type != "reference" && type != "agent-context") {
        error("K107", scalar_line["type"], "topic type is outside the canonical enum")
      }
      status = scalar_value["status"]
      if (kind == "map") {
        if (seen["status"] && status != "active" && status != "review-needed") {
          error("K111", scalar_line["status"],
            "map status must be active or review-needed")
        }
      } else if (seen["status"] &&
          status != "active" && status != "review-needed" &&
          status != "superseded" && status != "retired") {
        error("K107", scalar_line["status"], "topic status is outside the canonical enum")
      }
      if (seen["updated"] && !valid_date(scalar_value["updated"])) {
        error("K108", scalar_line["updated"], "updated must be a valid ISO date")
      }
      if (seen["last_verified"] && !valid_date(scalar_value["last_verified"])) {
        error("K108", scalar_line["last_verified"],
          "last_verified must be a valid ISO date")
      }
      if (seen["sensitivity"] &&
          scalar_value["sensitivity"] != "public" &&
          scalar_value["sensitivity"] != "internal" &&
          scalar_value["sensitivity"] != "restricted") {
        error("K107", scalar_line["sensitivity"],
          "sensitivity must be public, internal, or restricted")
      }
      if (status == "active") {
        if (!seen["last_verified"]) {
          error("K109", scalar_line["status"],
            "active entry requires last_verified")
        }
        if (list_count["sources"] == 0 && !seen["verify"]) {
          error("K109", scalar_line["status"],
            "active entry requires at least sources or verify")
        }
      } else if (status == "review-needed" || status == "superseded" ||
          status == "retired") {
        if (!seen["status_note"]) {
          error("K110", scalar_line["status"],
            "non-active entry requires a double-quoted status_note")
        }
      }
    }
    NR == 1 {
      started = 1
      if ($0 != "---") {
        error("K100", 1, "file must start with an exact frontmatter delimiter")
        finished = 1
        exit
      }
      next
    }
    {
      if ($0 == "---") {
        validate_contract()
        finished = 1
        exit
      }
      if (index($0, "\t") != 0) {
        error("K102", NR, "tabs are not supported in canonical frontmatter")
        next
      }
      if ($0 == "") {
        finish_list()
        next
      }
      if ($0 ~ /^  - /) {
        if (current_list == "") {
          error("K102", NR, "list item has no canonical list key")
          next
        }
        value = substr($0, 5)
        if (!quoted(value)) {
          error("K102", NR,
            "list item must use exactly two spaces and one double-quoted value")
          next
        }
        decoded = decode(value)
        if (decoded == "") {
          error("K106", NR, "list item must not be empty")
          next
        }
        list_count[current_list]++
        print "L" sep current_list sep decoded sep NR >> meta
        next
      }
      if ($0 ~ /^[[:space:]]*-/ || $0 ~ /^[[:space:]]+/) {
        error("K102", NR,
          "unsupported list indentation or nested YAML structure")
        next
      }
      colon = index($0, ":")
      if (colon == 0) {
        error("K102", NR, "unsupported multiline or legacy frontmatter syntax")
        next
      }
      finish_list()
      key = substr($0, 1, colon - 1)
      if (key !~ /^[A-Za-z_][A-Za-z0-9_-]*$/) {
        error("K102", NR, "metadata key uses unsupported syntax")
        next
      }
      if (!known(key)) {
        error("K103", NR, "unknown metadata key: " key)
        next
      }
      if (seen[key]) {
        error("K104", NR, "duplicate metadata key: " key)
        next
      }
      seen[key] = 1
      if (list_key(key)) {
        if ($0 != key ":") {
          error("K102", NR,
            "list must use a bare key and two-space double-quoted block items")
          next
        }
        current_list = key
        list_line[key] = NR
        next
      }
      if (substr($0, colon, 2) != ": ") {
        error("K102", NR, "scalar must use exactly one space after the colon")
        next
      }
      value = substr($0, colon + 2)
      scalar(key, value, NR)
    }
    END {
      if (!finished) {
        if (!started) {
          error("K100", 1, "file is empty and has no frontmatter")
        } else {
          error("K101", NR > 0 ? NR : 1, "frontmatter has no closing delimiter")
        }
      }
      exit(invalid ? 1 : 0)
    }
  ' "$parse_file"
  parse_status=$?
  append_diagnostics "$parse_rel" "$parse_diag"
  if [ "$parse_status" -eq 0 ]; then
    return 0
  fi
  return 1
}

LAYER_DIR=.$LAYER
KNOWLEDGE=$ROOT/$LAYER_DIR/knowledge
KNOWLEDGE_REL=$LAYER_DIR/knowledge
INDEX=$KNOWLEDGE/INDEX.md
INDEX_REL=$KNOWLEDGE_REL/INDEX.md

if [ ! -d "$KNOWLEDGE" ]; then
  add_finding ERROR K001 "$KNOWLEDGE_REL" 1 "knowledge directory is missing"
else
  if [ -L "$KNOWLEDGE" ]; then
    add_finding ERROR K001 "$KNOWLEDGE_REL" 1 "knowledge directory must not be a symlink"
  fi
fi

FILE_ID=0

scan_artifact() {
  artifact_file=$1
  artifact_kind=$2
  artifact_rel=${artifact_file#"$ROOT"/}
  FILE_ID=$((FILE_ID + 1))
  artifact_id=$FILE_ID
  artifact_base=${artifact_file##*/}
  artifact_slug=${artifact_base%.md}
  artifact_valid=0

  if [ -L "$artifact_file" ]; then
    add_finding ERROR K003 "$artifact_rel" 1 "knowledge artifact must not be a symlink"
  elif [ ! -f "$artifact_file" ] || [ ! -r "$artifact_file" ]; then
    add_finding ERROR K003 "$artifact_rel" 1 "knowledge artifact is not a readable regular file"
  elif parse_metadata "$artifact_id" "$artifact_file" "$artifact_kind" "$artifact_rel"; then
    artifact_valid=1
  fi

  if ! is_slug "$artifact_slug"; then
    add_finding ERROR K112 "$artifact_rel" 1 "filename must be a lowercase kebab-case slug plus .md"
  fi

  if [ "$artifact_kind" = topic ] &&
    [ -n "$(find "$artifact_file" -prune -size +10240c -print 2>/dev/null)" ]; then
    add_finding WARN K116 "$artifact_rel" 1 "topic exceeds the 10 KiB detail budget"
  fi

  artifact_lower=$(lowercase "$artifact_rel")
  printf '%s%s%s%s%s%s%s%s%s\n' \
    "$artifact_id" "$SEP" "$artifact_rel" "$SEP" "$artifact_kind" "$SEP" \
    "$artifact_lower" "$SEP" "$artifact_valid" >>"$CATALOG"

  [ "$artifact_valid" -eq 1 ] || return 0

  artifact_name=$(meta_get "$artifact_id" name)
  artifact_type=$(meta_get "$artifact_id" type)
  artifact_status=$(meta_get "$artifact_id" status)
  artifact_description=$(meta_get "$artifact_id" description)
  artifact_description_line=$(meta_line "$artifact_id" description)
  artifact_updated=$(meta_get "$artifact_id" updated)
  artifact_updated_line=$(meta_line "$artifact_id" updated)
  artifact_verified=$(meta_get "$artifact_id" last_verified)
  artifact_verified_line=$(meta_line "$artifact_id" last_verified)

  if [ "$artifact_name" != "$artifact_slug" ]; then
    add_finding ERROR K112 "$artifact_rel" "$(meta_line "$artifact_id" name)" \
      "metadata name must exactly match the filename slug"
  fi
  if [ "${#artifact_description}" -gt 320 ]; then
    add_finding WARN K115 "$artifact_rel" "$artifact_description_line" \
      "description exceeds the 320-byte routing budget"
  fi
  if [ "$artifact_status" = active ] && [ -n "$artifact_verified" ]; then
    verified_ordinal=$(date_ordinal "$artifact_verified")
  else
    verified_ordinal=$TODAY_ORDINAL
  fi
  if [ $((TODAY_ORDINAL - verified_ordinal)) -gt 90 ]; then
    add_finding WARN K150 "$artifact_rel" "$artifact_verified_line" \
      "last_verified is more than 90 days older than the selected date"
  fi

  printf '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n' \
    "$artifact_id" "$SEP" "$artifact_rel" "$SEP" "$artifact_kind" "$SEP" \
    "$artifact_name" "$SEP" "$artifact_type" "$SEP" "$artifact_status" "$SEP" \
    "$artifact_description" "$SEP" "$artifact_description_line" "$SEP" \
    "$artifact_updated" "$SEP" "$artifact_updated_line" "$SEP" \
    "$artifact_verified" "$SEP" "$artifact_verified_line" >>"$VALID"
}

if [ -d "$KNOWLEDGE" ] && [ ! -L "$KNOWLEDGE" ]; then
  for topic_file in "$KNOWLEDGE"/*.md; do
    [ -e "$topic_file" ] || [ -L "$topic_file" ] || continue
    [ "${topic_file##*/}" = INDEX.md ] && continue
    scan_artifact "$topic_file" topic
  done

  MAPS=$KNOWLEDGE/_maps
  if [ -L "$MAPS" ]; then
    add_finding ERROR K003 "$KNOWLEDGE_REL/_maps" 1 "maps directory must not be a symlink"
  elif [ -d "$MAPS" ]; then
    for map_file in "$MAPS"/*.md; do
      [ -e "$map_file" ] || [ -L "$map_file" ] || continue
      scan_artifact "$map_file" map
    done
  fi
fi

# Detect case-insensitive filename collisions, including files whose metadata is invalid.
if [ -s "$CATALOG" ]; then
  awk -v FS="$SEP" -v OFS="$SEP" '
    {
      count[$4]++
      paths[$4] = paths[$4] $2 ORS
    }
    END {
      for (key in count) {
        if (count[key] > 1) printf "%s", paths[key]
      }
    }
  ' "$CATALOG" | LC_ALL=C sort -u >"$TMP_DIR/file-collisions"
  while IFS= read -r collision_rel; do
    [ -n "$collision_rel" ] || continue
    add_finding ERROR K113 "$collision_rel" 1 \
      "knowledge filename collides under case-insensitive comparison"
  done <"$TMP_DIR/file-collisions"
fi

# Detect duplicate canonical names even when the filenames differ.
if [ -s "$VALID" ]; then
  awk -v FS="$SEP" '
    {
      key = tolower($4)
      count[key]++
      paths[key] = paths[key] $2 "\034" $1 ORS
    }
    END {
      for (key in count) {
        if (count[key] > 1) printf "%s", paths[key]
      }
    }
  ' "$VALID" | LC_ALL=C sort -u >"$TMP_DIR/name-collisions"
  while IFS="$SEP" read -r collision_rel collision_id; do
    [ -n "$collision_rel" ] || continue
    add_finding ERROR K113 "$collision_rel" "$(meta_line "$collision_id" name)" \
      "knowledge name collides with another canonical entry"
  done <"$TMP_DIR/name-collisions"
fi

GIT_READY=0
if command -v git >/dev/null 2>&1; then
  git_top=$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null || :)
  if [ -n "$git_top" ] && [ -d "$git_top" ]; then
    git_top=$(CDPATH='' cd -- "$git_top" 2>/dev/null && pwd -P || :)
    if [ "$git_top" = "$ROOT" ]; then
      GIT_READY=1
    fi
  fi
fi

validate_source() {
  source_id=$1
  : "$source_id"
  source_rel=$2
  source_value=$3
  source_line=$4
  source_verified=$5
  source_status=$6

  case "$source_value" in
    http://* | https://*)
      if ! printf '%s\n' "$source_value" |
        grep -Eq '^https?://[A-Za-z0-9.-]+(:[0-9]+)?([/?#][^[:space:]]*)?$'; then
        add_finding ERROR K130 "$source_rel" "$source_line" \
          "URL source does not use canonical HTTP(S) syntax"
      fi
      return 0
      ;;
  esac

  if forbidden_env_path "$source_value"; then
    add_finding ERROR K130 "$source_rel" "$source_line" \
      "local source must not reference an environment file"
    return 0
  fi
  case "$source_value" in
    /* | \~/* | [A-Za-z]:[\\/]* | *://*)
      add_finding ERROR K130 "$source_rel" "$source_line" \
        "local source must be a repository-relative path"
      return 0
      ;;
  esac

  source_path=${source_value%%#*}
  if [ -z "$source_path" ] || printf '%s' "$source_path" | grep -q '?'; then
    add_finding ERROR K130 "$source_rel" "$source_line" \
      "local source path is empty or contains an unsupported query"
    return 0
  fi
  if has_glob_syntax "$source_path"; then
    add_finding ERROR K130 "$source_rel" "$source_line" \
      "local source must name one file and must not contain glob syntax"
    return 0
  fi

  source_owner=$ROOT/$source_rel
  source_candidate=$(dirname -- "$source_owner")/$source_path
  if [ -L "$source_candidate" ]; then
    add_finding ERROR K132 "$source_rel" "$source_line" \
      "local source must not be a symlink"
    return 0
  fi
  if [ ! -f "$source_candidate" ]; then
    add_finding ERROR K131 "$source_rel" "$source_line" \
      "local source file does not exist"
    return 0
  fi
  source_directory=$(CDPATH='' cd -- "$(dirname -- "$source_candidate")" 2>/dev/null && pwd -P)
  if [ -z "$source_directory" ]; then
    add_finding ERROR K131 "$source_rel" "$source_line" \
      "local source directory cannot be resolved"
    return 0
  fi
  source_physical=$source_directory/$(basename -- "$source_candidate")
  case "$source_physical" in
    "$ROOT"/*) ;;
    *)
      add_finding ERROR K132 "$source_rel" "$source_line" \
        "local source resolves outside the repository"
      return 0
      ;;
  esac

  if [ "$GIT_READY" -eq 1 ] && [ "$source_status" = active ] &&
    [ -n "$source_verified" ]; then
    source_git_rel=${source_physical#"$ROOT"/}
    if [ -n "$(git -C "$ROOT" status --porcelain -- "$source_git_rel" 2>/dev/null)" ]; then
      add_finding WARN K133 "$source_rel" "$source_line" \
        "local source is dirty or untracked since its last verification"
    fi
    source_commit_date=$(git -C "$ROOT" log -1 --format=%cs -- "$source_git_rel" 2>/dev/null || :)
    if [ -n "$source_commit_date" ] && valid_date "$source_commit_date" &&
      [ "$source_commit_date" \> "$source_verified" ]; then
      add_finding WARN K134 "$source_rel" "$source_line" \
        "local source has a commit newer than last_verified"
    fi
  fi
}

validate_relation() {
  relation_id=$1
  : "$relation_id"
  relation_rel=$2
  relation_key=$3
  relation_value=$4
  relation_line=$5

  relation_namespace=${relation_value%%:*}
  relation_slug=${relation_value#*:}
  if [ "$relation_namespace" = "$relation_value" ] || ! is_slug "$relation_slug"; then
    add_finding ERROR K140 "$relation_rel" "$relation_line" \
      "relation must use a typed namespace and lowercase kebab-case slug"
    return 0
  fi

  case "$relation_key:$relation_namespace" in
    supersedes:knowledge | related:knowledge)
      relation_match=$(awk -v FS="$SEP" -v name="$relation_slug" '
        $3 == "topic" && $4 == name { print $1; exit }
      ' "$VALID")
      if [ -z "$relation_match" ]; then
        add_finding ERROR K141 "$relation_rel" "$relation_line" \
          "knowledge relation does not resolve to a canonical topic"
      fi
      ;;
    related:rule)
      if [ "$LAYER" != claude ]; then
        add_finding ERROR K140 "$relation_rel" "$relation_line" \
          "rule relation is not native to the selected layer"
      elif [ ! -f "$ROOT/.claude/rules/$relation_slug.md" ]; then
        add_finding ERROR K141 "$relation_rel" "$relation_line" \
          "rule relation target does not exist"
      fi
      ;;
    related:guideline)
      if [ "$LAYER" != codex ]; then
        add_finding ERROR K140 "$relation_rel" "$relation_line" \
          "guideline relation is not native to the selected layer"
      elif [ ! -f "$ROOT/.codex/guidelines/$relation_slug.md" ]; then
        add_finding ERROR K141 "$relation_rel" "$relation_line" \
          "guideline relation target does not exist"
      fi
      ;;
    *)
      add_finding ERROR K140 "$relation_rel" "$relation_line" \
        "relation namespace is not allowed for this metadata key"
      ;;
  esac
}

validate_scope() {
  scope_rel=$1
  scope_value=$2
  scope_line=$3
  scope_kind=${scope_value%%:*}
  scope_target=${scope_value#*:}
  if [ "$scope_kind" = "$scope_value" ] || [ -z "$scope_target" ]; then
    add_finding ERROR K120 "$scope_rel" "$scope_line" \
      "scope must use a typed selector with a non-empty value"
    return 0
  fi
  case "$scope_kind" in
    path | component | platform | environment | version | symbol) ;;
    *)
      add_finding ERROR K120 "$scope_rel" "$scope_line" \
        "scope selector kind is outside the canonical enum"
      return 0
      ;;
  esac
  case "$scope_target" in
    /* | \~/* | *[[:space:]]*)
      add_finding ERROR K120 "$scope_rel" "$scope_line" \
        "scope selector value must be compact and repository-relative"
      ;;
  esac
}

# Source, relation, and scope checks run only for files whose entire frontmatter
# parsed canonically. Invalid files are never treated as partial authority.
while IFS="$SEP" read -r valid_id valid_rel valid_kind valid_name valid_type \
  valid_status valid_description valid_description_line valid_updated \
  valid_updated_line valid_verified valid_verified_line; do
  [ -n "$valid_id" ] || continue
  while IFS="$SEP" read -r record_kind record_key record_value record_line; do
    [ "$record_kind" = L ] || continue
    case "$record_key" in
      sources)
        validate_source "$valid_id" "$valid_rel" "$record_value" "$record_line" \
          "$valid_verified" "$valid_status"
        ;;
      related | supersedes)
        validate_relation "$valid_id" "$valid_rel" "$record_key" "$record_value" \
          "$record_line"
        ;;
      scope)
        validate_scope "$valid_rel" "$record_value" "$record_line"
        ;;
    esac
  done <"$TMP_DIR/meta.$valid_id"
done <"$VALID"

parse_router() {
  router_file=$1
  router_rel=$2
  router_kind=$3
  router_name=$4
  router_id=$5
  router_authoritative=$6
  router_diag=$TMP_DIR/router-diag.$router_id
  router_visible=$TMP_DIR/router-visible.$router_id
  : >"$router_diag"
  : >"$router_visible"

  awk -v sep="$SEP" -v rel="$router_rel" -v kind="$router_kind" \
    -v mapname="$router_name" -v routerid="$router_id" \
    -v authoritative="$router_authoritative" \
    -v diag="$router_diag" -v visible="$router_visible" '
    function report(severity, code, line, message) {
      print severity sep code sep line sep message >> diag
    }
    function strip_comments(input, start, finish, output) {
      output = ""
      while (1) {
        if (in_comment) {
          finish = index(input, "-->")
          if (finish == 0) return output
          input = substr(input, finish + 3)
          in_comment = 0
        } else {
          start = index(input, "<!--")
          if (start == 0) return output input
          output = output substr(input, 1, start - 1)
          input = substr(input, start + 4)
          in_comment = 1
        }
      }
    }
    function route_line(line, number, first, rest, closepos, payload, pieces,
      count, title, target, hook, type, status) {
      if (index(line, "\t") != 0) return 0
      if (substr(line, 1, 3) != "- [") return 0
      first = index(line, "](")
      if (first <= 4) return 0
      title = substr(line, 4, first - 4)
      if (title ~ /[\[\]]/) return 0
      rest = substr(line, first + 2)
      closepos = index(rest, ") — ")
      if (closepos <= 1) return 0
      target = substr(rest, 1, closepos - 1)
      if (target !~ /\.md$/ || target ~ /[()]/) return 0
      payload = substr(rest, closepos + length(") — "))
      count = split(payload, pieces, " · ")
      if (count != 3) return 0
      hook = pieces[1]
      type = pieces[2]
      status = pieces[3]
      if (hook == "") return 0
      if (type != "domain" && type != "architecture" &&
          type != "integration" && type != "glossary" &&
          type != "reference" && type != "agent-context" &&
          type != "map") return 0
      if (status != "active" && status != "review-needed" &&
          status != "superseded" && status != "retired") return 0
      if (authoritative == "1") {
        print rel sep kind sep mapname sep routerid sep number sep title sep \
          target sep hook sep type sep status
      }
      return 1
    }
    {
      clean = strip_comments($0)
      print clean >> visible
      if (clean ~ /^[[:space:]]*-[[:space:]]*\[/) {
        if (!route_line(clean, NR)) {
          report("ERROR", "K200", NR,
            "route must match the exact title, relative path, hook, type, and status grammar")
        }
      }
      lower = tolower(clean)
      if (lower ~ /\/users\/[^[:space:]]+/ ||
          lower ~ /\/home\/[^[:space:]]+/ ||
          lower ~ /[a-z]:\\users\\[^[:space:]]+/ ||
          lower ~ /(^|[[:space:]])~\//) {
        report("ERROR", "K212", NR,
          "always-read router contains an absolute home path")
      }
      if (index(lower, ".env") != 0) {
        report("ERROR", "K213", NR,
          "always-read router contains an environment-file path")
      } else if (index(lower, "/secret") != 0 ||
          index(lower, "\\secret") != 0 ||
          index(lower, "/credential") != 0 ||
          index(lower, "\\credential") != 0 ||
          index(lower, "/id_rsa") != 0 ||
          index(lower, "\\id_rsa") != 0 ||
          index(lower, ".pem") != 0 ||
          index(lower, ".p12") != 0 ||
          index(lower, ".pfx") != 0) {
        report("WARN", "K214", NR,
          "always-read router appears to contain a sensitive local path")
      }
    }
  ' "$router_file" >>"$ROUTES_RAW"
  router_status=$?
  if [ "$router_status" -ne 0 ]; then
    printf '%s: router parser failed for %s\n' "$PROGRAM" "$router_rel" >&2
    exit 2
  fi
  append_diagnostics "$router_rel" "$router_diag"
  router_words=$(awk '{ total += NF } END { print total + 0 }' "$router_visible")
  if [ "$router_words" -gt 1200 ]; then
    add_finding WARN K210 "$router_rel" 1 \
      "router exceeds the 1200-visible-word budget"
  fi
}

if [ -d "$KNOWLEDGE" ] && [ ! -L "$KNOWLEDGE" ]; then
  if [ -L "$INDEX" ]; then
    add_finding ERROR K002 "$INDEX_REL" 1 "knowledge INDEX must not be a symlink"
  elif [ ! -f "$INDEX" ]; then
    add_finding ERROR K002 "$INDEX_REL" 1 "knowledge INDEX is missing"
  elif [ ! -r "$INDEX" ]; then
    add_finding ERROR K002 "$INDEX_REL" 1 "knowledge INDEX is not readable"
  else
    parse_router "$INDEX" "$INDEX_REL" root - index 1
  fi
fi

# Every regular map is scanned for route grammar, budgets, and sensitive paths.
# Only a map whose complete metadata is canonical may establish reachability.
# Positional placeholders keep the catalog record shape stable.
# shellcheck disable=SC2034
while IFS="$SEP" read -r catalog_id catalog_rel catalog_kind catalog_lower \
  catalog_valid; do
  [ "$catalog_kind" = map ] || continue
  catalog_file=$ROOT/$catalog_rel
  [ -f "$catalog_file" ] && [ ! -L "$catalog_file" ] &&
    [ -r "$catalog_file" ] || continue
  if [ "$catalog_valid" = 1 ]; then
    catalog_name=$(meta_get "$catalog_id" name)
  else
    catalog_name=-
  fi
  parse_router "$catalog_file" "$catalog_rel" map "$catalog_name" "$catalog_id" \
    "$catalog_valid"
done <"$CATALOG"

resolve_route_target() {
  resolve_base=$1
  resolve_raw=$2
  RESOLVE_STATUS=ok
  RESOLVE_REL=

  if forbidden_env_path "$resolve_raw"; then
    RESOLVE_STATUS=environment
    return 0
  fi
  case "$resolve_raw" in
    /* | \~/* | [A-Za-z]:[\\/]* | *://*)
      RESOLVE_STATUS=absolute
      return 0
      ;;
  esac
  if has_glob_syntax "$resolve_raw"; then
    RESOLVE_STATUS=glob
    return 0
  fi
  resolve_candidate=$resolve_base/$resolve_raw
  if [ -L "$resolve_candidate" ]; then
    RESOLVE_STATUS=symlink
    return 0
  fi
  if [ ! -f "$resolve_candidate" ]; then
    RESOLVE_STATUS=missing
    return 0
  fi
  resolve_directory=$(CDPATH='' cd -- "$(dirname -- "$resolve_candidate")" 2>/dev/null && pwd -P)
  if [ -z "$resolve_directory" ]; then
    RESOLVE_STATUS=missing
    return 0
  fi
  resolve_physical=$resolve_directory/$(basename -- "$resolve_candidate")
  case "$resolve_physical" in
    "$ROOT"/*) RESOLVE_REL=${resolve_physical#"$ROOT"/} ;;
    *) RESOLVE_STATUS=outside ;;
  esac
}

# Positional placeholders keep the route record shape stable.
# shellcheck disable=SC2034
while IFS="$SEP" read -r router_rel router_kind router_name router_id route_line \
  route_title route_target route_hook route_type route_status; do
  [ -n "$router_rel" ] || continue
  if [ "${#route_hook}" -gt 320 ]; then
    add_finding WARN K209 "$router_rel" "$route_line" \
      "route hook exceeds the 320-byte routing budget"
  fi

  router_directory=$(dirname -- "$ROOT/$router_rel")
  resolve_route_target "$router_directory" "$route_target"
  case "$RESOLVE_STATUS" in
    missing)
      add_finding ERROR K201 "$router_rel" "$route_line" \
        "route target does not exist"
      continue
      ;;
    absolute)
      add_finding ERROR K202 "$router_rel" "$route_line" \
        "route target must be repository-relative"
      continue
      ;;
    environment)
      add_finding ERROR K202 "$router_rel" "$route_line" \
        "route target must not reference an environment file"
      continue
      ;;
    glob)
      add_finding ERROR K202 "$router_rel" "$route_line" \
        "route target must not contain glob syntax"
      continue
      ;;
    symlink)
      add_finding ERROR K202 "$router_rel" "$route_line" \
        "route target must not be a symlink"
      continue
      ;;
    outside)
      add_finding ERROR K202 "$router_rel" "$route_line" \
        "route target resolves outside the repository"
      continue
      ;;
  esac

  route_class=external
  route_target_id=-
  case "$RESOLVE_REL" in
    "$KNOWLEDGE_REL"/_maps/*.md)
      if [ "$(dirname -- "$RESOLVE_REL")" = "$KNOWLEDGE_REL/_maps" ]; then
        route_class=map
      else
        route_class=knowledge-other
      fi
      ;;
    "$KNOWLEDGE_REL"/*.md)
      if [ "$RESOLVE_REL" = "$INDEX_REL" ]; then
        route_class=index
      elif [ "$(dirname -- "$RESOLVE_REL")" = "$KNOWLEDGE_REL" ]; then
        route_class=topic
      else
        route_class=knowledge-other
      fi
      ;;
  esac

  if [ "$router_kind" = root ]; then
    case "$route_class" in
      topic | map | external) ;;
      *)
        add_finding ERROR K203 "$router_rel" "$route_line" \
          "root route must target a direct topic, domain map, or local external document"
        continue
        ;;
    esac
  else
    if [ "$route_class" != topic ]; then
      add_finding ERROR K203 "$router_rel" "$route_line" \
        "domain map may route direct topics only; nesting and external routes are forbidden"
      continue
    fi
  fi

  if [ "$route_class" = topic ] || [ "$route_class" = map ]; then
    route_record=$(awk -v FS="$SEP" -v wanted="$RESOLVE_REL" '
      $2 == wanted { print; exit }
    ' "$VALID")
    if [ -z "$route_record" ]; then
      # The target exists, but invalid metadata must never become partial authority.
      continue
    fi
    # Positional placeholders keep the canonical metadata record shape stable.
    # shellcheck disable=SC2034
    IFS="$SEP" read -r target_id target_rel target_kind target_name target_type \
      target_status target_description target_description_line target_updated \
      target_updated_line target_verified target_verified_line <<EOF
$route_record
EOF
    route_target_id=$target_id
    if [ "$route_type" != "$target_type" ]; then
      add_finding ERROR K204 "$router_rel" "$route_line" \
        "route type does not match canonical target metadata"
    fi
    if [ "$route_status" != "$target_status" ]; then
      add_finding ERROR K204 "$router_rel" "$route_line" \
        "route status does not match canonical target metadata"
    fi
  fi

  printf '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n' \
    "$router_rel" "$SEP" "$router_kind" "$SEP" "$router_name" "$SEP" \
    "$router_id" "$SEP" "$route_line" "$SEP" "$route_target" "$SEP" \
    "$route_hook" "$SEP" "$route_type" "$SEP" "$route_status" "$SEP" \
    "$RESOLVE_REL" "$SEP" "$route_class" "$SEP" "$route_target_id" >>"$ROUTES_VALID"

  if [ "$router_kind" = root ] && [ "$route_class" = topic ] &&
    [ "$route_target_id" != - ]; then
    printf '%s\n' "$route_target_id" >>"$REACH_HITS"
    if [ "$route_status" = active ]; then
      printf '%s\n' "$route_target_id" >>"$ACTIVE_REACH_HITS"
      printf '%s\n' "$route_target_id" >>"$ACTIVE_ROUTE_HITS"
      printf '%s\n' "$route_target_id" >>"$DIRECT_ACTIVE"
    fi
  elif [ "$router_kind" = root ] && [ "$route_class" = map ] &&
    [ "$route_target_id" != - ]; then
    printf '%s\n' "$route_target_id" >>"$ROOT_MAP_HITS"
    if [ "$route_status" = active ]; then
      printf '%s\n' "$route_target_id" >>"$ACTIVE_ROOT_MAP_HITS"
      printf '%s\n' "$route_target_id" >>"$ACTIVE_ROUTE_HITS"
    fi
  fi
done <"$ROUTES_RAW"

# Routes inside a map become reachable only through root routes to that map.
# Positional placeholders keep the validated-route record shape stable.
# shellcheck disable=SC2034
while IFS="$SEP" read -r router_rel router_kind router_name router_id route_line \
  route_target route_hook route_type route_status resolved_rel route_class \
  route_target_id; do
  [ "$router_kind" = map ] || continue
  [ "$route_class" = topic ] || continue
  [ "$route_target_id" != - ] || continue
  map_hits=$(awk -v wanted="$router_id" '$0 == wanted { count++ } END { print count + 0 }' \
    "$ROOT_MAP_HITS")
  hit_index=0
  while [ "$hit_index" -lt "$map_hits" ]; do
    printf '%s\n' "$route_target_id" >>"$REACH_HITS"
    if [ "$route_status" = active ]; then
      printf '%s\n' "$route_target_id" >>"$ACTIVE_ROUTE_HITS"
    fi
    hit_index=$((hit_index + 1))
  done
  active_map_hits=$(awk -v wanted="$router_id" '
    $0 == wanted { count++ } END { print count + 0 }
  ' "$ACTIVE_ROOT_MAP_HITS")
  active_hit_index=0
  if [ "$route_status" = active ]; then
    while [ "$active_hit_index" -lt "$active_map_hits" ]; do
      printf '%s\n' "$route_target_id" >>"$ACTIVE_REACH_HITS"
      active_hit_index=$((active_hit_index + 1))
    done
  fi
done <"$ROUTES_VALID"

direct_count=$(wc -l <"$DIRECT_ACTIVE" | awk '{ print $1 + 0 }')
if [ "$direct_count" -gt 24 ]; then
  add_finding WARN K211 "$INDEX_REL" 1 \
    "root has more than 24 active direct topic routes without maps"
fi

# Positional placeholders keep the canonical metadata record shape stable.
# shellcheck disable=SC2034
while IFS="$SEP" read -r valid_id valid_rel valid_kind valid_name valid_type \
  valid_status valid_description valid_description_line valid_updated \
  valid_updated_line valid_verified valid_verified_line; do
  [ -n "$valid_id" ] || continue
  case "$valid_status" in
    active)
      if [ "$valid_kind" = map ]; then
        reachable_count=$(awk -v wanted="$valid_id" '
          $0 == wanted { count++ } END { print count + 0 }
        ' "$ACTIVE_ROOT_MAP_HITS")
      else
        reachable_count=$(awk -v wanted="$valid_id" '
          $0 == wanted { count++ } END { print count + 0 }
        ' "$ACTIVE_REACH_HITS")
      fi
      if [ "$reachable_count" -ne 1 ]; then
        add_finding ERROR K205 "$valid_rel" "$(meta_line "$valid_id" status)" \
          "active entry must be reachable from the root exactly once"
      fi
      ;;
    review-needed)
      if [ "$valid_kind" = map ]; then
        reachable_count=$(awk -v wanted="$valid_id" '
          $0 == wanted { count++ } END { print count + 0 }
        ' "$ROOT_MAP_HITS")
      else
        reachable_count=$(awk -v wanted="$valid_id" '
          $0 == wanted { count++ } END { print count + 0 }
        ' "$REACH_HITS")
      fi
      if [ "$reachable_count" -eq 0 ]; then
        add_finding WARN K206 "$valid_rel" "$(meta_line "$valid_id" status)" \
          "review-needed entry is intentionally not auto-promoted and has no route"
      elif [ "$reachable_count" -gt 1 ]; then
        add_finding ERROR K207 "$valid_rel" "$(meta_line "$valid_id" status)" \
          "review-needed entry may be reachable at most once"
      fi
      ;;
    superseded | retired)
      active_hits=$(awk -v wanted="$valid_id" '
        $0 == wanted { count++ } END { print count + 0 }
      ' "$ACTIVE_ROUTE_HITS")
      if [ "$active_hits" -gt 0 ]; then
        add_finding ERROR K208 "$valid_rel" "$(meta_line "$valid_id" status)" \
          "superseded or retired entry must not be active-routed"
      fi
      ;;
  esac
done <"$VALID"

if ! LC_ALL=C sort "$FINDINGS"; then
  printf '%s: cannot sort checker findings\n' "$PROGRAM" >&2
  exit 2
fi

case "$FAIL_ON" in
  warning)
    if [ -s "$FINDINGS" ]; then
      exit 1
    fi
    ;;
  error)
    if grep -q '^ERROR|' "$FINDINGS"; then
      exit 1
    fi
    ;;
esac

exit 0
