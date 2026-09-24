#!/usr/bin/env bash
# CLAUDART Installer
# Usage (one-liner):
#   curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash
#
# Options (pass after --):
#   (no flags)   Install shared state (.claudart/) and Claude Code (.claude/ + CLAUDE.md)
#   --claude     Install the Claude Code layer (explicit, same as default)
#   --codex      Install shared state and Codex (.codex/ + .agents/ + AGENTS.md)
#   --both       Install both Claude and Codex layers
#   --project-docs  Add the optional Project Docs module to selected layers
#   --force      Refresh adapter files; preserve shared project state
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
  --force      Refresh adapter files; never overwrite shared project state
  --help       Show this help text

SHARED PROJECT STATE
  .claudart/              Seeded once in every mode; existing state is preserved

ADAPTERS
  Claude Code (default)   .claude/  +  CLAUDE.md at project root
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

# Shared state has a fixed, empty seed payload. Never copy live work, handoffs,
# or arbitrary files from the upstream state tree into a project.
STATE_SEEDS=(
  CONTEXT.md JOURNAL.md knowledge/INDEX.md tasks/index.md
  tasks/done/.gitkeep specs/INDEX.md specs/done/.gitkeep
)

# Preflight the complete seed set before any adapter or state write. Refuse
# symlinks and type collisions instead of following them, even with --force.
for seed in "${STATE_SEEDS[@]}"; do
  if [[ ! -f "$TMPDIR/.claudart/$seed" || -L "$TMPDIR/.claudart/$seed" ]]; then
    printf '%s Shared state seed is missing: %s\n' "$(red "error")" "$seed" >&2
    exit 1
  fi
  remaining=".claudart/$seed"
  parent="$DEST"
  while [[ "$remaining" == */* ]]; do
    parent="$parent/${remaining%%/*}"
    remaining="${remaining#*/}"
    if [[ -L "$parent" || ( -e "$parent" && ! -d "$parent" ) ]]; then
      printf '%s Shared state requires real directories: %s\n' "$(red "error")" "$parent" >&2
      exit 1
    fi
  done
  target="$parent/$remaining"
  if [[ -L "$target" || ( -e "$target" && ! -f "$target" ) ]]; then
    printf '%s Shared state seed path has a type conflict: %s\n' "$(red "error")" "$target" >&2
    exit 1
  fi
done

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
    # Runtime loaders are installed at the project root, not inside adapters.
    if [[ "$rel" == .codex/AGENTS.md || "$rel" == .claude/CLAUDE.md ]]; then continue; fi
    copy_file_from_src "$prefix$rel" "$rel"
  done < <(find "$src_root" -type f | sort)
}

# ── install ───────────────────────────────────────────────────────────────────

printf '\n%s  Installing into %s\n' "$(bold "→")" "$DEST"

printf '\n%s\n' "$(bold "Shared project state (.claudart/)")"
for seed in "${STATE_SEEDS[@]}"; do
  if [[ -f "$DEST/.claudart/$seed" ]]; then
    printf '  %s  .claudart/%s (project state)\n' "$(yellow "keep")" "$seed"
    (( SKIPPED++ )) || true
  else
    copy_file_from_src ".claudart/$seed" ".claudart/$seed"
  fi
done

if [[ "$INSTALL_CLAUDE" == true ]]; then
  printf '\n%s\n' "$(bold "Claude Code layer")"
  copy_tree ".claude"

  # Loaders contain project-authored routes. Existing root content is reconciled
  # by the integration protocol, not replaced by a forced payload refresh.
  if [[ -e "$DEST/CLAUDE.md" || -L "$DEST/CLAUDE.md" ]]; then
    printf '  %s  CLAUDE.md (existing project loader)\n' "$(yellow "keep")"
    (( SKIPPED++ )) || true
  else
    copy_file_from_src ".claude/CLAUDE.md" "CLAUDE.md"
  fi
fi

if [[ "$INSTALL_CODEX" == true ]]; then
  printf '\n%s\n' "$(bold "Codex layer")"

  copy_tree ".codex"
  copy_tree ".agents"

  # Loaders contain project-authored routes. Existing root content is reconciled
  # by the integration protocol, not replaced by a forced payload refresh.
  if [[ -e "$DEST/AGENTS.md" || -L "$DEST/AGENTS.md" ]]; then
    printf '  %s  AGENTS.md (existing project loader)\n' "$(yellow "keep")"
    (( SKIPPED++ )) || true
  else
    copy_file_from_src ".codex/AGENTS.md" "AGENTS.md"
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
  printf '%s  Existing project state and root loaders were preserved. Use INTEGRATE.md to reconcile custom instructions; --force refreshes adapter payload only.\n\n' "$(yellow "note")"
fi

printf '%s\n' "$(bold "Next steps:")"
if [[ "$INSTALL_CLAUDE" == true ]]; then
  printf '  Claude Code  →  open project, run /start\n'
fi
if [[ "$INSTALL_CODEX" == true ]]; then
  # The dollar-prefixed skill names are intentional literals.
  # shellcheck disable=SC2016
  printf '  Codex        →  open project, run $codex-start\n'
fi
if [[ "$INSTALL_PROJECT_DOCS" == true ]]; then
  printf '  Project Docs →  use init for a new idea, adopt for an existing project\n'
fi
printf '\n'
