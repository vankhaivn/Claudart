#!/usr/bin/env bash
# CLAUDART Installer
# Usage (one-liner):
#   curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash
#
# Options (pass after --):
#   --claude-only   Install only the Claude Code layer (.claude/ + .claudart/)
#   --codex-only    Install only the Codex layer (AGENTS.md + .codex/ + .agents/ + .claudart/)
#   --force         Overwrite existing files
#   --help          Show this help text
#
# Default (no flags): install both layers.

set -euo pipefail

REPO="vankhaivn/Claudart"
BRANCH="main"
TARBALL_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"

INSTALL_CLAUDE=true
INSTALL_CODEX=true
FORCE=false

# ── helpers ──────────────────────────────────────────────────────────────────

bold()  { printf '\033[1m%s\033[0m' "$*"; }
green() { printf '\033[32m%s\033[0m' "$*"; }
yellow(){ printf '\033[33m%s\033[0m' "$*"; }
red()   { printf '\033[31m%s\033[0m' "$*"; }

show_help() {
  cat <<EOF
$(bold "CLAUDART Installer")

USAGE
  curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- [OPTIONS]
  bash install.sh [OPTIONS]

OPTIONS
  --claude-only   Install only the Claude Code layer
  --codex-only    Install only the Codex layer
  --force         Overwrite files that already exist
  --help          Show this help text

LAYERS
  Claude Code   .claude/  +  .claudart/
  Codex         AGENTS.md  +  .codex/  +  .agents/  +  .claudart/
  Both (default) all of the above
EOF
}

# ── arg parsing ───────────────────────────────────────────────────────────────

for arg in "$@"; do
  case "$arg" in
    --claude-only) INSTALL_CODEX=false ;;
    --codex-only)  INSTALL_CLAUDE=false ;;
    --force)       FORCE=true ;;
    --help|-h)     show_help; exit 0 ;;
    *) printf '%s Unknown option: %s\n' "$(red "error")" "$arg" >&2; exit 1 ;;
  esac
done

if [[ "$INSTALL_CLAUDE" == false && "$INSTALL_CODEX" == false ]]; then
  printf '%s --claude-only and --codex-only cannot both be set.\n' "$(red "error")" >&2
  exit 1
fi

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

# ── copy helpers ──────────────────────────────────────────────────────────────

SKIPPED=0
COPIED=0

# Copy a single file, skipping if it already exists (unless --force).
copy_file() {
  local rel="$1"          # path relative to repo root, e.g. ".claude/CLAUDE.md"
  local src="$TMPDIR/$rel"
  local dst="$DEST/$rel"

  if [[ -f "$dst" && "$FORCE" == false ]]; then
    printf '  %s  %s\n' "$(yellow "skip")" "$rel"
    (( SKIPPED++ )) || true
    return
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  printf '  %s  %s\n' "$(green "copy")" "$rel"
  (( COPIED++ )) || true
}

# Walk every file inside a source tree and call copy_file for each one.
copy_tree() {
  local root="$1"         # e.g. ".claude"
  local src_root="$TMPDIR/$root"

  if [[ ! -d "$src_root" ]]; then
    return
  fi

  while IFS= read -r src_file; do
    local rel="${src_file#"$TMPDIR/"}"
    copy_file "$rel"
  done < <(find "$src_root" -type f | sort)
}

# ── install ───────────────────────────────────────────────────────────────────

printf '\n%s  Installing into %s\n' "$(bold "→")" "$DEST"

# Shared memory core — always installed
printf '\n%s\n' "$(bold "Shared core (.claudart/)")"
copy_tree ".claudart"

if [[ "$INSTALL_CLAUDE" == true ]]; then
  printf '\n%s\n' "$(bold "Claude Code layer (.claude/)")"
  copy_tree ".claude"
fi

if [[ "$INSTALL_CODEX" == true ]]; then
  printf '\n%s\n' "$(bold "Codex layer")"
  copy_file "AGENTS.md"
  copy_tree ".codex"
  copy_tree ".agents"
fi

# ── summary ───────────────────────────────────────────────────────────────────

printf '\n%s  Done. %d copied, %d skipped.\n\n' "$(bold "✓")" "$COPIED" "$SKIPPED"

if [[ "$SKIPPED" -gt 0 ]]; then
  printf '%s  Skipped files already exist in your project. Run with --force to overwrite them.\n\n' "$(yellow "note")"
fi

printf '%s\n' "$(bold "Next steps:")"
if [[ "$INSTALL_CLAUDE" == true ]]; then
  printf '  Claude Code  →  open project, run /doctor to verify, then /refactor-memory\n'
fi
if [[ "$INSTALL_CODEX" == true ]]; then
  printf '  Codex        →  open project, run $codex-doctor to verify\n'
fi
printf '\n'
