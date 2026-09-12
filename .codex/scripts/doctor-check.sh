#!/bin/bash

# Read-only mechanical installation checks. Semantic doctor decisions remain
# with the calling agent. Bash 3.2 and POSIX awk/find/sort are sufficient.
set -u
LC_ALL=C; export LC_ALL

PROGRAM=${0##*/}
FAIL_ON=error
LAYOUT=installed
ROOT_OVERRIDE=
LAYER_OVERRIDE=
TODAY_OVERRIDE=
SEP=$(printf '\034')
INCLUDES=()

usage() {
  cat <<'EOF'
Usage: doctor-check.sh [options]
  --root DIR              Repository root (default: inferred from script path)
  --layer claude|codex    Runtime layer (default: inferred from script path)
  --layout installed|source  Loader layout (default: installed)
  --include PATH          Add a Markdown file or tree under root (repeatable)
  --today YYYY-MM-DD      Forward a date to the knowledge checker
  --fail-on error|warning Threshold for exit 1 (default: error)
  --help                  Show this help

Exit: 0 below threshold; 1 contract findings; 2 usage or incomplete checker.
Findings: ERROR|Dxxx|path:line|message (also WARNING, INFO, and K codes).
EOF
}
usage_error() {
  printf '%s: %s\n' "$PROGRAM" "$1" >&2
  exit 2
}

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P) ||
  usage_error "cannot resolve script directory"
INFERRED_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/../.." 2>/dev/null && pwd -P) ||
  usage_error "cannot infer repository root"
case "$SCRIPT_DIR" in
  */.claude/scripts) INFERRED_LAYER=claude ;;
  */.codex/scripts) INFERRED_LAYER=codex ;;
  *) INFERRED_LAYER= ;;
esac

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root|--layer|--layout|--include|--today|--fail-on)
      [ "$#" -ge 2 ] || usage_error "$1 requires an argument"
      case "$1" in
        --root) ROOT_OVERRIDE=$2 ;;
        --layer) LAYER_OVERRIDE=$2 ;;
        --layout) LAYOUT=$2 ;;
        --include) INCLUDES[${#INCLUDES[@]}]=$2 ;;
        --today) TODAY_OVERRIDE=$2 ;;
        --fail-on) FAIL_ON=$2 ;;
      esac
      shift 2 ;;
    --help) usage; exit 0 ;;
    *) usage_error "unknown argument" ;;
  esac
done
case "$FAIL_ON" in error|warning) ;; *) usage_error "invalid --fail-on" ;; esac
case "$LAYOUT" in installed|source) ;; *) usage_error "invalid --layout" ;; esac
LAYER=${LAYER_OVERRIDE:-$INFERRED_LAYER}
case "$LAYER" in claude|codex) ;; *) usage_error "cannot infer layer" ;; esac
if [ -n "$ROOT_OVERRIDE" ]; then
  [ -d "$ROOT_OVERRIDE" ] && [ ! -L "$ROOT_OVERRIDE" ] ||
    usage_error "--root must be a real directory"
  ROOT=$(CDPATH='' cd -- "$ROOT_OVERRIDE" 2>/dev/null && pwd -P) ||
    usage_error "cannot resolve --root"
else
  ROOT=$INFERRED_ROOT
fi
case "$ROOT" in *"$SEP"*|*'|'*) usage_error "unsupported root pathname" ;; esac
if [ -n "$TODAY_OVERRIDE" ]; then
  # The sibling checker owns full calendar validation.
  case "$TODAY_OVERRIDE" in
    ????-??-??) ;;
    *) usage_error "--today requires YYYY-MM-DD" ;;
  esac
fi

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/claudart-doctor-check.XXXXXX" 2>/dev/null) ||
  usage_error "cannot create temporary directory"
# Invoked indirectly by trap.
# shellcheck disable=SC2329
cleanup() { [ ! -d "$TMP_DIR" ] || rm -rf -- "$TMP_DIR"; }
# Invoked indirectly by trap.
# shellcheck disable=SC2329
on_signal() { trap - HUP INT TERM; exit 2; }
trap cleanup EXIT
trap on_signal HUP INT TERM
FINDINGS=$TMP_DIR/findings
SOURCES=$TMP_DIR/sources
: >"$FINDINGS"; : >"$SOURCES"
INCOMPLETE=0

add() {
  diagnostic_path=$3
  case "$diagnostic_path" in
    *'|'*|*"$SEP"*|*'
'*|*$'\r'*) diagnostic_path='<unsupported-path>' ;;
  esac
  if private_path "$diagnostic_path"; then diagnostic_path='<private-path>'; fi
  case "$4" in ''|*[!0-9]*) diagnostic_line=1 ;; *) diagnostic_line=$4 ;; esac
  printf '%s|%s|%s:%s|%s\n' "$1" "$2" "$diagnostic_path" "$diagnostic_line" "$5" >>"$FINDINGS"
}

# Lexical normalization, before any filesystem access. Absolute paths are
# repository-root paths only. Escaping above root is rejected.
normalize() {
  printf '%s\n' "$1" | awk '
    { n=split($0,a,"/"); top=0
      for(i=1;i<=n;i++) {
        if(a[i]=="" || a[i]==".") continue
        if(a[i]=="..") { if(top==0) exit 1; top--; continue }
        stack[++top]=a[i]
      }
      out=""; for(i=1;i<=top;i++) out=out (i==1?"":"/") stack[i]
      print out
    }'
}

private_path() {
  case "/$1/" in
    */.env/*|*/.env.*/*|*/.local/*|*/.git/*|*/node_modules/*|*/.DS_Store/*) return 0 ;;
  esac
  return 1
}

excluded_prose() {
  case "/$1/" in
    */.claude/tasks/*|*/.codex/tasks/*|*/.claude/specs/*|*/.codex/specs/*|*/.claude/knowledge/*|*/.codex/knowledge/*|*/.claude/CONTEXT.md/*|*/.codex/CONTEXT.md/*|*/.claude/JOURNAL.md/*|*/.codex/JOURNAL.md/*|*/.claude/HANDOFF.md/*|*/.codex/HANDOFF.md/*) return 0 ;;
  esac
  return 1
}

# Never dereference a symlink in a source or target path. No target content is
# read: callers may only test -e/-f after this succeeds.
has_symlink() {
  symlink_rest=$1
  symlink_prefix=
  while [ -n "$symlink_rest" ]; do
    symlink_part=${symlink_rest%%/*}
    if [ "$symlink_part" = "$symlink_rest" ]; then symlink_rest=; else symlink_rest=${symlink_rest#*/}; fi
    symlink_prefix=${symlink_prefix:+$symlink_prefix/}$symlink_part
    [ ! -L "$ROOT/$symlink_prefix" ] || return 0
  done
  return 1
}

safe_source() {
  source_rel=$1
  case "$source_rel" in
    ''|/*|*'|'*|*"$SEP"*|*'
'*) return 1 ;;
  esac
  private_path "$source_rel" && return 1
  excluded_prose "$source_rel" && return 1
  has_symlink "$source_rel" && return 1
  return 0
}

queue_file() {
  queue_rel=$1
  safe_source "$queue_rel" || { add WARNING D102 "$queue_rel" 1 "source path is private or symlinked; skipped"; return; }
  case "$queue_rel" in *.md) ;; *) return ;; esac
  [ -f "$ROOT/$queue_rel" ] && [ -r "$ROOT/$queue_rel" ] || {
    add WARNING D103 "$queue_rel" 1 "Markdown source is unreadable or missing"
    [ ! -e "$ROOT/$queue_rel" ] || INCOMPLETE=1
    return
  }
  printf '%s\n' "$queue_rel" >>"$SOURCES"
}

queue_tree() {
  tree_rel=$1
  safe_source "$tree_rel" || { add WARNING D102 "$tree_rel" 1 "source tree is private or symlinked; skipped"; return; }
  [ -d "$ROOT/$tree_rel" ] || return
  if ! find "$ROOT/$tree_rel" -type f -name '*.md' \
    -exec sh -c 'printf "%s\000" "$@"' sh {} + >"$TMP_DIR/tree-files" 2>/dev/null; then
    add ERROR D904 "$tree_rel" 1 "source tree enumeration failed"
    INCOMPLETE=1
    return
  fi
  while IFS= read -r -d '' tree_file; do
    queue_file "${tree_file#"$ROOT/"}"
  done <"$TMP_DIR/tree-files"
}

require_file() {
  required_rel=$1; required_level=$2; required_repair=$3
  if has_symlink "$required_rel"; then
    add WARNING D104 "$required_rel" 1 "required path is symlinked; review it"
  elif [ ! -f "$ROOT/$required_rel" ] || [ ! -r "$ROOT/$required_rel" ]; then
    add "$required_level" D101 "$required_rel" 1 "required file missing or unreadable; $required_repair"
  fi
}
require_dir() {
  required_rel=$1; required_level=$2; required_repair=$3
  if has_symlink "$required_rel"; then
    add WARNING D104 "$required_rel" 1 "required path is symlinked; review it"
  elif [ ! -d "$ROOT/$required_rel" ]; then
    add "$required_level" D100 "$required_rel" 1 "required directory missing; $required_repair"
  fi
}

LAYER_DIR=.$LAYER
if [ "$LAYER" = codex ]; then
  if [ "$LAYOUT" = source ]; then LOADER=.codex/AGENTS.md; else LOADER=AGENTS.md; fi
else
  LOADER=.claude/CLAUDE.md
fi
require_dir "$LAYER_DIR" ERROR "restore CLAUDART installation"
require_file "$LOADER" ERROR "restore the $LAYER loader"
require_file "$LAYER_DIR/CONTEXT.md" WARNING "run the checkpoint workflow"
require_file "$LAYER_DIR/JOURNAL.md" WARNING "run the checkpoint workflow"
require_dir "$LAYER_DIR/knowledge" WARNING "run the refactor-memory workflow"
require_file "$LAYER_DIR/knowledge/INDEX.md" WARNING "run the refactor-memory workflow"
require_dir "$LAYER_DIR/tasks" WARNING "run the plan workflow"
require_file "$LAYER_DIR/tasks/index.md" WARNING "run the checkpoint workflow"
require_dir "$LAYER_DIR/tasks/done" WARNING "run the checkpoint workflow"
require_dir "$LAYER_DIR/specs" INFO "run the spec workflow when needed"
require_file "$LAYER_DIR/specs/INDEX.md" INFO "run the spec workflow when needed"
require_dir "$LAYER_DIR/specs/done" INFO "run the spec workflow when needed"
require_dir "$LAYER_DIR/scripts" ERROR "restore CLAUDART scripts"
require_file "$LAYER_DIR/scripts/knowledge-check.sh" ERROR "restore knowledge checker"

line_count_signal() {
  count_rel=$1; count_limit=$2; count_code=$3; count_level=$4
  private_path "$count_rel" && return
  has_symlink "$count_rel" && return
  [ -f "$ROOT/$count_rel" ] && [ -r "$ROOT/$count_rel" ] || return
  count_value=$(wc -l <"$ROOT/$count_rel" 2>/dev/null) || {
    add ERROR D905 "$count_rel" 1 "cannot count lines"; INCOMPLETE=1; return;
  }
  count_value=$(printf '%s' "$count_value" | tr -d '[:space:]')
  if [ "$count_value" -gt "$count_limit" ]; then
    add "$count_level" "$count_code" "$count_rel" 1 "line count exceeds $count_limit; review size"
  fi
}

line_count_signal "$LOADER" 100 D110 WARNING
line_count_signal "$LAYER_DIR/CONTEXT.md" 150 D111 WARNING
if [ -f "$ROOT/$LAYER_DIR/HANDOFF.md" ] && ! has_symlink "$LAYER_DIR/HANDOFF.md"; then
  add INFO D112 "$LAYER_DIR/HANDOFF.md" 1 "unconsumed handoff baton present"
  line_count_signal "$LAYER_DIR/HANDOFF.md" 150 D113 ERROR
  handoff_created=$(awk '
    NR==1 { if($0!="---") exit; next }
    $0=="---" { exit }
    NR>30 { exit }
    /^created:[ \t]*/ { sub(/^created:[ \t]*/,""); gsub(/["\047]/, ""); print; exit }
  ' "$ROOT/$LAYER_DIR/HANDOFF.md" 2>/dev/null) || handoff_created=
  if [ -n "$handoff_created" ]; then
    selected_today=${TODAY_OVERRIDE:-$(date +%Y-%m-%d 2>/dev/null || :)}
    handoff_age=$(printf '%s\n%s\n' "$handoff_created" "$selected_today" | awk '
      function ordinal(s, y,m,d,era,yoe,mp,doy,doe) {
        if(s !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return -1
        y=substr(s,1,4)+0; m=substr(s,6,2)+0; d=substr(s,9,2)+0
        if(m<1 || m>12 || d<1 || d>31) return -1
        if(m<=2) y--
        era=int(y/400); yoe=y-era*400; mp=m+(m>2?-3:9)
        doy=int((153*mp+2)/5)+d-1
        doe=yoe*365+int(yoe/4)-int(yoe/100)+doy
        return era*146097+doe
      }
      NR==1 { created=ordinal($0) }
      NR==2 { today=ordinal($0); if(created<0 || today<0) print "invalid"; else print today-created }
    ')
    case "$handoff_age" in
      invalid) add WARNING D114 "$LAYER_DIR/HANDOFF.md" 1 "handoff created date needs review" ;;
      -*) add WARNING D114 "$LAYER_DIR/HANDOFF.md" 1 "handoff created date is in the future" ;;
      ''|*[!0-9]*) add WARNING D114 "$LAYER_DIR/HANDOFF.md" 1 "handoff created date needs review" ;;
      *) [ "$handoff_age" -le 7 ] || add WARNING D115 "$LAYER_DIR/HANDOFF.md" 1 "handoff is older than seven days" ;;
    esac
  fi
fi
if [ "$LAYER" = codex ]; then
  require_dir .codex/guidelines ERROR "restore core guidelines"
  for rule in ai-behavior code-health task-management agent-delegation spec-workflow knowledge-management; do
    require_file ".codex/guidelines/$rule.md" ERROR "restore core guideline"
  done
  require_dir .codex/agents WARNING "restore agent metadata directory"
  require_file .codex/config.toml ERROR "restore Codex configuration"
  require_dir .agents/skills ERROR "restore core skills"
  for skill in codex-start codex-checkpoint codex-learn codex-doctor codex-refactor-memory codex-plan codex-handoff codex-spec codex-spec-run; do
    require_file ".agents/skills/$skill/SKILL.md" ERROR "restore core skill"
  done
  queue_tree .codex/guidelines
  queue_tree .agents/skills
  queue_tree .codex/references
else
  require_dir .claude/rules ERROR "restore core rules"
  for rule in ai-behavior code-health task-management agent-delegation spec-workflow knowledge-management; do
    require_file ".claude/rules/$rule.md" ERROR "restore core rule"
  done
  require_dir .claude/commands ERROR "restore core commands"
  for command in start learn refactor-memory doctor checkpoint plan handoff spec spec-run; do
    require_file ".claude/commands/$command.md" ERROR "restore core command"
  done
  require_dir .claude/agents WARNING "restore agent directory"
  queue_tree .claude/rules
  queue_tree .claude/commands
  queue_tree .claude/agents
  queue_tree .claude/references
fi
queue_file "$LOADER"

for ((include_index=0; include_index<${#INCLUDES[@]}; include_index++)); do
  included=${INCLUDES[$include_index]}
  case "$included" in /*) usage_error "--include must be repository relative" ;; esac
  included_rel=$(normalize "$included") || usage_error "--include escapes repository root"
  safe_source "$included_rel" || usage_error "--include is private, invalid, or symlinked"
  if [ -d "$ROOT/$included_rel" ]; then
    queue_tree "$included_rel"
  elif [ -f "$ROOT/$included_rel" ]; then
    case "$included_rel" in *.md) queue_file "$included_rel" ;; *) usage_error "--include file must be Markdown" ;; esac
  else
    usage_error "--include path does not exist"
  fi
done

PARSER=$SCRIPT_DIR/doctor-check.awk
if [ ! -f "$PARSER" ] || [ ! -r "$PARSER" ] || [ -L "$PARSER" ]; then
  add ERROR D900 "$LAYER_DIR/scripts/doctor-check.awk" 1 "doctor parser missing or unreadable"
  INCOMPLETE=1
fi

# Metadata is checked only on explicitly selected operating-layer files.
check_metadata() {
  meta_rel=$1; meta_kind=$2
  [ "$INCOMPLETE" -eq 0 ] || return
  safe_source "$meta_rel" || return
  [ -f "$ROOT/$meta_rel" ] && [ -r "$ROOT/$meta_rel" ] || return
  case "$meta_kind" in
    rule) required='paths description when_to_use tags' ;;
    skill) required='name description' ;;
    agent) required='name description tools model' ;;
    command) required='description' ;;
  esac
  if ! awk -v mode=meta -v kind="$meta_kind" -v required_keys="$required" \
    -f "$PARSER" "$ROOT/$meta_rel" >"$TMP_DIR/meta"; then
    add ERROR D901 "$meta_rel" 1 "metadata parser failed"; INCOMPLETE=1; return
  fi
  while IFS="$SEP" read -r record level code line message; do
    [ "$record" = F ] && add "$level" "$code" "$meta_rel" "$line" "$message"
  done <"$TMP_DIR/meta"
}

# TOML reader recognizes only the documented top-level simple assignments and
# literal/basic multiline strings. Other constructs are review items.
check_toml() {
  toml_rel=$1; toml_kind=$2
  safe_source "$toml_rel" || return
  [ -f "$ROOT/$toml_rel" ] && [ -r "$ROOT/$toml_rel" ] || return
  awk -v kind="$toml_kind" -v sep="$SEP" '
    function out(l,c,n,m) { print l sep c sep n sep m }
    function trim(s) { sub(/^[ \t]+/,"",s); sub(/[ \t\r]+$/,"",s); return s }
    function quoted(s) { return s ~ /^"([^"\\]|\\.)*"[ \t]*(#.*)?$/ || s ~ /^\047[^\047]*\047[ \t]*(#.*)?$/ }
    BEGIN {
      if(kind=="agent") {
        split("name description model model_reasoning_effort sandbox_mode developer_instructions",a," ")
        for(i in a) need[a[i]]=1
      }
    }
    {
      s=trim($0)
      if(multi!="") {
        if(index(s,multi)) multi=""
        next
      }
      if(s=="" || s ~ /^#/) next
      if(s ~ /^\[[^]]+\][ \t]*(#.*)?$/) {
        table=s; sub(/^\[/,"",table); sub(/\].*/,"",table)
        if(table !~ /^[A-Za-z_][A-Za-z_0-9-]*$/) {
          out("WARNING","D320",NR,"TOML table syntax needs review")
          uncertain=1
        }
        if(kind=="config" && table=="agents") agents=1
        next
      }
      if(s !~ /^[A-Za-z_][A-Za-z_0-9-]*[ \t]*=/) {
        out("WARNING","D320",NR,"TOML syntax needs review")
        uncertain=1
        next
      }
      key=s; sub(/[ \t]*=.*/, "",key)
      value=s; sub(/^[^=]*=/,"",value); value=trim(value)
      if(kind=="agent" && table=="" && key in need) {
        if(seen[key]++) out("ERROR","D321",NR,"duplicate required TOML key")
        if(value ~ /^\047\047\047/ || value ~ /^"""/) {
          delim=substr(value,1,3)
          if(index(substr(value,4),delim)==0) multi=delim
        } else if(!quoted(value)) out("WARNING","D322",NR,"required TOML value needs review")
      }
      if(kind=="config" && table=="agents" && key=="max_concurrent_threads_per_session") {
        if(limit++) out("ERROR","D323",NR,"duplicate concurrency limit")
        if(value ~ /^[+]?[0-9]+(_[0-9]+)+[ \t]*(#.*)?$/)
          out("WARNING","D331",NR,"underscored TOML integer needs review")
        else if(value !~ /^\+?[0-9]+[ \t]*(#.*)?$/ || value+0<1)
          out("ERROR","D324",NR,"concurrency limit must be a positive integer")
        else if(value+0>6) out("WARNING","D325",NR,"concurrency above 6 needs review")
      }
    }
    END {
      if(multi!="") out("ERROR","D326",NR,"unterminated multiline TOML string")
      if(kind=="agent") for(k in need) if(!(k in seen)) {
        if(uncertain) out("WARNING","D330",1,"required TOML key may be missing: " k)
        else out("ERROR","D327",1,"missing required TOML key " k)
      }
      if(kind=="config") {
        if(!agents) {
          if(uncertain) out("WARNING","D330",1,"[agents] table needs review")
          else out("ERROR","D328",1,"missing [agents] table")
        } else if(!limit) {
          if(uncertain) out("WARNING","D330",1,"concurrency limit needs review")
          else out("ERROR","D329",1,"missing concurrency limit")
        }
      }
    }
  ' "$ROOT/$toml_rel" >"$TMP_DIR/toml" || {
    add ERROR D902 "$toml_rel" 1 "TOML parser failed"; INCOMPLETE=1; return;
  }
  while IFS="$SEP" read -r level code line message; do
    [ -n "$level" ] && add "$level" "$code" "$toml_rel" "$line" "$message"
  done <"$TMP_DIR/toml"
}

if [ "$LAYER" = codex ]; then
  if [ -d "$ROOT/.codex/guidelines" ] && [ ! -L "$ROOT/.codex/guidelines" ]; then
    for f in "$ROOT"/.codex/guidelines/*.md; do
      [ -f "$f" ] && check_metadata "${f#"$ROOT/"}" rule
    done
  fi
  if [ -d "$ROOT/.agents/skills" ] && [ ! -L "$ROOT/.agents/skills" ]; then
    for f in "$ROOT"/.agents/skills/*/SKILL.md; do
      [ -f "$f" ] && check_metadata "${f#"$ROOT/"}" skill
    done
  fi
  check_toml .codex/config.toml config
  if [ -d "$ROOT/.codex/agents" ] && [ ! -L "$ROOT/.codex/agents" ]; then
    for f in "$ROOT"/.codex/agents/*.toml; do
      [ -f "$f" ] && check_toml "${f#"$ROOT/"}" agent
    done
  fi
else
  for dir in rules commands agents; do
    [ -d "$ROOT/.claude/$dir" ] && [ ! -L "$ROOT/.claude/$dir" ] || continue
    for f in "$ROOT/.claude/$dir"/*.md; do
      [ -f "$f" ] || continue
      case "$dir" in rules) kind=rule ;; commands) kind='command' ;; agents) kind=agent ;; esac
      check_metadata "${f#"$ROOT/"}" "$kind"
    done
  done
fi

resolve_link() {
  link_source=$1; link_line=$2; link_raw=$3; link_kind=$4
  link_target=$link_raw
  # An angle destination may contain spaces; discard any following title.
  case "$link_target" in
    '<'*) link_target=${link_target#<}; link_target=${link_target%%>*} ;;
    *) case "$link_target" in
         *' "'*) link_target=${link_target%%' "'*} ;;
         *" '"*) link_target=${link_target%%" '"*} ;;
         *' ('*) link_target=${link_target%%' ('*} ;;
       esac ;;
  esac
  case "$link_target" in
    ''|'#'*|*'://'*|mailto:*|data:*|javascript:*|*'{'*|*'}'*|*'<'*|*'>'*|*'*'*|*'?'*|*'['*|*']'*|*'$'*|*'|'*|*"$SEP"*|*$'\r'*|*'
'*) return ;;
  esac
  link_target=${link_target%%#*}
  [ -n "$link_target" ] || return
  case "$link_target" in *\\*) add WARNING D207 "$link_source" "$link_line" "escaped local reference needs review"; return ;; esac
  link_target=${link_target//%20/ }
  link_target=${link_target//%2F/\/}; link_target=${link_target//%2f/\/}
  link_target=${link_target//%2E/.}; link_target=${link_target//%2e/.}
  case "$link_target" in *'%'*) add WARNING D204 "$link_source" "$link_line" "encoded local reference needs review"; return ;; esac
  case "$link_target" in
    /*) link_candidate=${link_target#/} ;;
    *) case "$link_source" in
         */*) link_candidate=${link_source%/*}/$link_target ;;
         *) link_candidate=$link_target ;;
       esac ;;
  esac
  link_rel=$(normalize "$link_candidate") || {
    add WARNING D203 "$link_source" "$link_line" "local reference escapes repository root; review it"; return;
  }
  private_path "$link_rel" && return
  if has_symlink "$link_rel"; then
    add WARNING D202 "$link_source" "$link_line" "local reference is symlinked; skipped"
  elif [ ! -e "$ROOT/$link_rel" ]; then
    add ERROR D201 "$link_source" "$link_line" "missing local $link_kind target: $link_rel"
  fi
}

if [ "$INCOMPLETE" -eq 0 ]; then
  LC_ALL=C sort -u "$SOURCES" >"$TMP_DIR/sources-sorted" || INCOMPLETE=1
  while IFS= read -r md_rel; do
    [ "$INCOMPLETE" -eq 0 ] || break
    [ -n "$md_rel" ] || continue
    if ! awk -v mode=markdown -v layer="$LAYER" -f "$PARSER" \
      "$ROOT/$md_rel" >"$TMP_DIR/links"; then
      add ERROR D903 "$md_rel" 1 "Markdown parser failed"; INCOMPLETE=1; break
    fi
    while IFS="$SEP" read -r record field2 field3 field4 field5; do
      case "$record" in
        L) resolve_link "$md_rel" "$field2" "$field3" "$field4" ;;
        F) add "$field2" "$field3" "$md_rel" "$field4" "$field5" ;;
      esac
    done <"$TMP_DIR/links"
  done <"$TMP_DIR/sources-sorted"
fi

# The existing knowledge checker is the sole owner of K diagnostics. Call it
# exactly once, with selected root/layer/date/threshold, and forward its lines.
KNOWLEDGE=$SCRIPT_DIR/knowledge-check.sh
CONTRACT=0
if [ ! -f "$KNOWLEDGE" ] || [ ! -r "$KNOWLEDGE" ] || [ -L "$KNOWLEDGE" ]; then
  add ERROR D910 "$LAYER_DIR/scripts/knowledge-check.sh" 1 "knowledge checker unavailable"
  INCOMPLETE=1
else
  knowledge_args=(--root "$ROOT" --layer "$LAYER" --fail-on "$FAIL_ON")
  [ -z "$TODAY_OVERRIDE" ] || knowledge_args+=(--today "$TODAY_OVERRIDE")
  bash "$KNOWLEDGE" "${knowledge_args[@]}" >"$TMP_DIR/knowledge" 2>"$TMP_DIR/knowledge-err"
  knowledge_status=$?
  awk -F '|' '$1 ~ /^(ERROR|WARN|WARNING|INFO)$/ && $2 ~ /^K[0-9]+$/ && NF>=4 { print $0 }' \
    "$TMP_DIR/knowledge" >>"$FINDINGS" || INCOMPLETE=1
  case "$knowledge_status" in
    0) ;;
    1) CONTRACT=1 ;;
    *) add ERROR D911 "$LAYER_DIR/scripts/knowledge-check.sh" 1 "knowledge checker failed or incomplete"; INCOMPLETE=1 ;;
  esac
fi

add INFO D000 "$LOADER" 1 "mechanical checks only; semantic doctor review remains"
LC_ALL=C sort "$FINDINGS" || exit 2
[ "$INCOMPLETE" -eq 0 ] || exit 2
[ "$CONTRACT" -eq 0 ] || exit 1
if [ "$FAIL_ON" = warning ]; then
  if grep -Eq '^(ERROR|WARNING|WARN)\|' "$FINDINGS"; then exit 1; fi
else
  if grep -q '^ERROR|' "$FINDINGS"; then exit 1; fi
fi
exit 0
