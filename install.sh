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
  .claudart/VERSION       Upstream commit of each fully written layer

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

ARCHIVE="$TMPDIR/claudart.tar.gz"
if command -v curl &>/dev/null; then
  curl -fsSL "$TARBALL_URL" > "$ARCHIVE"
elif command -v wget &>/dev/null; then
  wget -qO- "$TARBALL_URL" > "$ARCHIVE"
else
  printf '%s curl or wget is required.\n' "$(red "error")" >&2
  exit 1
fi
tar -xzf "$ARCHIVE" -C "$TMPDIR" --strip-components=1

# GitHub archives carry their source commit in the leading pax header.
UPSTREAM_COMMIT="$(gzip -dc "$ARCHIVE" 2>/dev/null | head -c 1024 |
  LC_ALL=C grep -ao 'comment=[0-9a-f]\{40\}' | head -n 1 | cut -d= -f2)" || true
[[ -n "$UPSTREAM_COMMIT" ]] || UPSTREAM_COMMIT=unknown

# Check the selected module before copying any files.
if [[ "$INSTALL_PROJECT_DOCS" == true ]]; then
  MODULE_ROOT="$TMPDIR/modules/project-docs"
  if { [[ "$INSTALL_CLAUDE" == true ]] && [[ ! -f "$MODULE_ROOT/.claude/commands/cda-project-docs.md" ]]; } ||
     { [[ "$INSTALL_CODEX" == true ]] && [[ ! -f "$MODULE_ROOT/.agents/skills/cda-project-docs/SKILL.md" ]]; }; then
    printf '%s Project Docs payload is missing from the downloaded source.\n' "$(red "error")" >&2
    exit 1
  fi
fi

# Shared state has a fixed, empty seed payload. Never copy live work, handoffs,
# or arbitrary files from the upstream state tree into a project.
STATE_SEEDS=(
  CONTEXT.md JOURNAL.md OWNER.md knowledge/INDEX.md tasks/index.md
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

VERSION_REL=".claudart/VERSION"
if [[ -L "$DEST/$VERSION_REL" || ( -e "$DEST/$VERSION_REL" && ! -f "$DEST/$VERSION_REL" ) ]]; then
  printf '%s Installed version path must be a regular file: %s\n' "$(red "error")" "$DEST/$VERSION_REL" >&2
  exit 1
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
    # Runtime loaders are installed at the project root, not inside adapters.
    if [[ "$rel" == .codex/AGENTS.md || "$rel" == .claude/CLAUDE.md ]]; then continue; fi
    copy_file_from_src "$prefix$rel" "$rel"
  done < <(find "$src_root" -type f | sort)
}

# A layer's base commit is recorded only when its whole payload was written,
# so a skipped older file is never attributed to the new commit.
RECORDED=()
record_if_complete() {
  if [[ "$SKIPPED" -eq "$2" ]]; then
    RECORDED+=("$1")
  fi
}

# Replace the recorded layers' lines and keep every other line.
write_version() {
  local file="$DEST/$VERSION_REL" line key layer keep
  {
    if [[ -f "$file" ]]; then
      while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -n "$line" ]] || continue
        key="${line%%:*}"
        keep=true
        for layer in "${RECORDED[@]}"; do
          if [[ "$key" == "$layer" ]]; then keep=false; fi
        done
        if [[ "$keep" == true ]]; then printf '%s\n' "$line"; fi
      done < "$file"
    fi
    for layer in "${RECORDED[@]}"; do
      printf '%s: %s\n' "$layer" "$UPSTREAM_COMMIT"
    done
  } | LC_ALL=C sort > "$file.tmp"
  mv "$file.tmp" "$file"
  printf '\n%s  %s (%s: %s)\n' "$(green "record")" "$VERSION_REL" "${RECORDED[*]}" "$UPSTREAM_COMMIT"
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
  before=$SKIPPED
  copy_tree ".claude"
  record_if_complete claude "$before"

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

  before=$SKIPPED
  copy_tree ".codex"
  copy_tree ".agents"
  record_if_complete codex "$before"

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
    before=$SKIPPED
    copy_tree ".claude" "modules/project-docs/"
    record_if_complete project-docs/claude "$before"
  fi
  if [[ "$INSTALL_CODEX" == true ]]; then
    before=$SKIPPED
    copy_tree ".agents" "modules/project-docs/"
    record_if_complete project-docs/codex "$before"
  fi
fi

if [[ "${#RECORDED[@]}" -gt 0 ]]; then
  write_version
fi

# ── summary ───────────────────────────────────────────────────────────────────

printf '\n%s  Done. %d copied, %d skipped.\n\n' "$(bold "✓")" "$COPIED" "$SKIPPED"

if [[ "$SKIPPED" -gt 0 ]]; then
  printf '%s  Existing project state and root loaders were preserved. Use INTEGRATE.md to reconcile custom instructions; --force refreshes adapter payload only.\n\n' "$(yellow "note")"
fi

printf '%s\n' "$(bold "Next steps:")"
if [[ "$INSTALL_CLAUDE" == true ]]; then
  printf '  Claude Code  →  open project, run /cda-start\n'
fi
if [[ "$INSTALL_CODEX" == true ]]; then
  # The dollar-prefixed skill names are intentional literals.
  # shellcheck disable=SC2016
  printf '  Codex        →  open project, run $cda-start\n'
fi
if [[ "$INSTALL_PROJECT_DOCS" == true ]]; then
  printf '  Project Docs →  use init for a new idea, adopt for an existing project\n'
fi
printf '\n'
