#!/usr/bin/env bash
# CLAUDART Installer
# Usage (one-liner):
#   curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash
#
# Options (pass after --):
#   (no flags)   Install the Claude Code layer (.claude/)
#   --claude     Install the Claude Code layer (explicit, same as default)
#   --codex      Install the Codex layer (.codex/ + .agents/ + AGENTS.md at root)
#   --both       Install both Claude and Codex layers
#   --project-docs  Add the optional Project Docs module to selected layers
#   --force      Overwrite existing files
#   --help       Show this help text

set -euo pipefail

REPO="vankhaivn/Claudart"
BRANCH="main"
TARBALL_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"

INSTALL_CLAUDE=true
INSTALL_CODEX=false
INSTALL_PROJECT_DOCS=false
FORCE=false

# ── helpers ──────────────────────────────────────────────────────────────────

bold()  { printf '\033[1m%s\033[0m' "$*"; }
green() { printf '\033[32m%s\033[0m' "$*"; }
yellow(){ printf '\033[33m%s\033[0m' "$*"; }
red()   { printf '\033[31m%s\033[0m' "$*"; }

show_help() {
  cat <<EOF2
$(bold "CLAUDART Installer")

USAGE
  curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- [OPTIONS]
  bash install.sh [OPTIONS]

OPTIONS
  (no flags)   Install the Claude Code layer (default)
  --claude     Install the Claude Code layer (explicit)
  --codex      Install the Codex layer instead
  --both       Install both Claude Code and Codex layers
  --project-docs  Add the optional Project Docs module to selected layers
  --force      Overwrite files that already exist
  --help       Show this help text

LAYERS
  Claude Code (default)   .claude/
  Codex                   .codex/  +  .agents/  +  AGENTS.md at project root
  Both                    all of the above

OPTIONAL MODULES
  --project-docs           Project documentation lifecycle commands and references
                          Does not generate or migrate your project documentation
EOF2
}

# ── arg parsing ───────────────────────────────────────────────────────────────

for arg in "$@"; do
  case "$arg" in
    --claude) INSTALL_CLAUDE=true;  INSTALL_CODEX=false ;;
    --codex)  INSTALL_CLAUDE=false; INSTALL_CODEX=true ;;
    --both)   INSTALL_CLAUDE=true;  INSTALL_CODEX=true ;;
    --project-docs) INSTALL_PROJECT_DOCS=true ;;
    --force)  FORCE=true ;;
    --help|-h) show_help; exit 0 ;;
    *) printf '%s Unknown option: %s\n' "$(red "error")" "$arg" >&2; exit 1 ;;
  esac
done

# ── download ──────────────────────────────────────────────────────────────────

DEST="${PWD}"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

printf '\n%s  Downloading CLAUDART from %s …\n' "$(bold "→")" "$REPO"

if command -v curl &>/dev/null; then
  curl -fsSL "$TARBALL_URL" | tar -xz -C "$TMPDIR" --strip-components=1
elif command -v wget &>/dev/null; then
  wget -qO- "$TARBALL_URL" | tar -xz -C "$TMPDIR" --strip-components=1
else
  printf '%s curl or wget is required.\n' "$(red "error")" >&2
  exit 1
fi

# Check the selected module before copying any files.
if [[ "$INSTALL_PROJECT_DOCS" == true ]]; then
  MODULE_ROOT="$TMPDIR/modules/project-docs"
  if { [[ "$INSTALL_CLAUDE" == true ]] && [[ ! -f "$MODULE_ROOT/.claude/commands/project-docs.md" ]]; } ||
     { [[ "$INSTALL_CODEX" == true ]] && [[ ! -f "$MODULE_ROOT/.agents/skills/codex-project-docs/SKILL.md" ]]; }; then
    printf '%s Project Docs payload is missing from the downloaded source.\n' "$(red "error")" >&2
    exit 1
  fi
fi

# ── copy helpers ──────────────────────────────────────────────────────────────

SKIPPED=0
COPIED=0

# Copy a file from an arbitrary src path to an arbitrary dst path (different rel names).
copy_file_from_src() {
  local src_rel="$1"
  local dst_rel="$2"
  local src="$TMPDIR/$src_rel"
  local dst="$DEST/$dst_rel"

  if [[ -f "$dst" && "$FORCE" == false ]]; then
    printf '  %s  %s\n' "$(yellow "skip")" "$dst_rel"
    (( SKIPPED++ )) || true
    return
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  printf '  %s  %s\n' "$(green "copy")" "$dst_rel"
  (( COPIED++ )) || true
}

# Copy a runtime tree, optionally from a module's source directory.
copy_tree() {
  local root="$1"         # e.g. ".claude"
  local prefix="${2:-}"   # e.g. "modules/project-docs/"
  local src_root="$TMPDIR/$prefix$root"

  if [[ ! -d "$src_root" ]]; then
    return
  fi

  while IFS= read -r src_file; do
    local rel="${src_file#"$TMPDIR/$prefix"}"
    copy_file_from_src "$prefix$rel" "$rel"
  done < <(find "$src_root" -type f | sort)
}

# ── install ───────────────────────────────────────────────────────────────────

printf '\n%s  Installing into %s\n' "$(bold "→")" "$DEST"

if [[ "$INSTALL_CLAUDE" == true ]]; then
  printf '\n%s\n' "$(bold "Claude Code layer (.claude/)")"
  copy_tree ".claude"
fi

if [[ "$INSTALL_CODEX" == true ]]; then
  printf '\n%s\n' "$(bold "Codex layer")"

  # Snapshot AGENTS.md state BEFORE copying so we know what the user already had.
  AGENTS_AT_ROOT=false
  AGENTS_IN_CODEX=false
  [[ -f "$DEST/AGENTS.md" ]]        && AGENTS_AT_ROOT=true
  [[ -f "$DEST/.codex/AGENTS.md" ]] && AGENTS_IN_CODEX=true

  copy_tree ".codex"
  copy_tree ".agents"

  # AGENTS.md must live at project root for Codex to auto-load it.
  # • User already had it at root OR in .codex/ → leave everything untouched.
  # • Neither existed → install at root and remove the .codex/ copy that
  #   copy_tree just created (avoid having two conflicting copies).
  if [[ "$AGENTS_AT_ROOT" == false && "$AGENTS_IN_CODEX" == false ]]; then
    copy_file_from_src ".codex/AGENTS.md" "AGENTS.md"
    if [[ -f "$DEST/.codex/AGENTS.md" ]]; then
      rm "$DEST/.codex/AGENTS.md"
      printf '  %s  .codex/AGENTS.md (removed; canonical copy is at root)\n' "$(green "clean")"
    fi
  else
    location="$( [[ "$AGENTS_AT_ROOT" == true ]] && echo "root" || echo ".codex/" )"
    printf '  %s  AGENTS.md (already present at %s, skipping)\n' "$(yellow "skip")" "$location"
    (( SKIPPED++ )) || true
  fi

  # .codex/CODEX.md is deprecated when present; the template uses AGENTS.md as
  # the sole Codex memory index. Remove the stale path during reconciliation.
  if [[ -f "$DEST/.codex/CODEX.md" ]]; then
    rm "$DEST/.codex/CODEX.md"
    printf '  %s  .codex/CODEX.md (deprecated; content consolidated into AGENTS.md)\n' "$(green "clean")"
  fi
fi

if [[ "$INSTALL_PROJECT_DOCS" == true ]]; then
  printf '\n%s\n' "$(bold "Project Docs module (selected layers)")"
  if [[ "$INSTALL_CLAUDE" == true ]]; then
    copy_tree ".claude" "modules/project-docs/"
  fi
  if [[ "$INSTALL_CODEX" == true ]]; then
    copy_tree ".agents" "modules/project-docs/"
  fi
fi

# ── summary ───────────────────────────────────────────────────────────────────

printf '\n%s  Done. %d copied, %d skipped.\n\n' "$(bold "✓")" "$COPIED" "$SKIPPED"

if [[ "$SKIPPED" -gt 0 ]]; then
  printf '%s  Skipped files already exist in your project. Run with --force to overwrite them.\n\n' "$(yellow "note")"
fi

printf '%s\n' "$(bold "Next steps:")"
if [[ "$INSTALL_CLAUDE" == true ]]; then
  printf '  Claude Code  →  open project, run /doctor → /refactor-memory → /doctor once\n'
fi
if [[ "$INSTALL_CODEX" == true ]]; then
  # The dollar-prefixed skill names are intentional literals.
  # shellcheck disable=SC2016
  printf '  Codex        →  open project, run $codex-doctor → $codex-refactor-memory → $codex-doctor once\n'
fi
if [[ "$INSTALL_PROJECT_DOCS" == true ]]; then
  printf '  Project Docs →  use init for a new idea, adopt for an existing project\n'
fi
printf '\n'
