#!/usr/bin/env bash
# ── sprout-skills.sh ─────────────────────────────────────────────────────
# Standalone symlink fan-out from agent-kit (Cluster 2) to all workspace
# .pi/skills/ directories.
#
# This is the ONLY bridge between Cluster 2 (agent-kit) and the workspace
# tree. It is NOT chezmoi-managed. Run it after adding/renaming/deleting
# a skill in any skills-templates/ subdirectory.
#
# Usage:
#   bash scripts/sprout-skills.sh            # dry-run
#   bash scripts/sprout-skills.sh --apply    # write symlinks
#   bash scripts/sprout-skills.sh --prune    # remove broken links only
#
# Can also be called by the chezmoi run_onchange_after_* hook.
# ─────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:---dry-run}"

SKILLS_DIR="$REPO_ROOT/skills-templates"

# ── Workspace Map ────────────────────────────────────────────────────────
# Each entry: source_subdir|target_root
#   source_subdir is relative to skills-templates/
#   target_root is the workspace dir whose .pi/skills/ gets populated
WORKSPACES=(
  "analygo/hatchet|$HOME/Projects/analygo/packages/hatchet"
  "analygo/ui|$HOME/Projects/analygo/packages/ui"
  "analygo/contracts|$HOME/Projects/analygo/packages/contracts"
  "analygo/aegis|$HOME/Projects/analygo/packages/aegis"
  "analygo/apps|$HOME/Projects/analygo/apps"
  "analygo/root|$HOME/Projects/analygo"
  "hamza-workspace/root|$HOME/hamza-workspace"
  "hamza-workspace/strategy|$HOME/hamza-workspace/strategy"
  "hamza-workspace/finance|$HOME/hamza-workspace/finance"
)

log()  { printf "  %s\n" "$*"; }
title(){ printf "\n=== %s ===\n\n" "$*"; }

make_relative_symlink() {
  local target="$1" link="$2"
  mkdir -p "$(dirname "$link")"
  local link_dir relative
  link_dir="$(dirname "$link")"
  # Use absolute paths to avoid macOS realpath limitations
  relative="$target"

  if [ "$MODE" = "--apply" ]; then
    if [ -L "$link" ] || [ -e "$link" ]; then
      local existing
      existing="$(readlink "$link")"
      [ "$existing" = "$relative" ] || [ "$existing" = "${relative%/}" ] && return 0
      rm -f "$link"
    fi
    ln -s "$relative" "$link"
    log "  ✓ $link"
  else
    log "  ~ $link → $relative"
  fi
}

prune_broken() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  local count=0
  while IFS= read -r -d '' link; do
    if [ -L "$link" ] && [ ! -e "$link" ]; then
      rm "$link"
      count=$((count + 1))
    fi
  done < <(find "$dir" -type l -print0)
  [ "$count" -gt 0 ] && log "  (removed $count broken symlinks)"
  find "$dir" -type d -empty -delete 2>/dev/null || true
}

fanout_workspace() {
  local source_sub="$1" target_root="$2"
  local source_dir="$SKILLS_DIR/$source_sub"

  [ -d "$source_dir" ] || { log "  (no source dir: $source_sub)"; return 0; }

  title "$source_sub → $target_root/.pi/skills/"

  local count=0
  while IFS= read -r -d '' skill_dir; do
    local skill_name
    skill_name="$(basename "$skill_dir")"
    local link_path="$target_root/.pi/skills/$skill_name"
    make_relative_symlink "$skill_dir" "$link_path"
    count=$((count + 1))
  done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -type d -print0)

  [ "$count" -eq 0 ] && log "  (no skill dirs found)"
  return 0
}

ensure_global_link() {
  local global_source="$SKILLS_DIR/global"
  local global_link="$HOME/.pi/agent/skills"

  title "Global skills"
  if [ -L "$global_link" ] && [ "$(readlink "$global_link")" = "$global_source" ]; then
    log "  ✓ already linked"
    return 0
  fi
  [ -e "$global_link" ] && rm -rf "$global_link"
  mkdir -p "$(dirname "$global_link")"
  [ "$MODE" = "--apply" ] && ln -sfn "$global_source" "$global_link" && log "  ✓ linked"
  [ "$MODE" != "--apply" ] && log "  ~ $global_link → $global_source"
}

# ── Main ──
case "$MODE" in
  --prune)
    title "Pruning broken symlinks"
    for entry in "${WORKSPACES[@]}"; do
      prune_broken "${entry#*|}/.pi/skills"
    done
    exit 0
    ;;
  --apply) ;;
  *)
    title "DRY-RUN (pass --apply to execute)" ;;
esac

for entry in "${WORKSPACES[@]}"; do
  IFS='|' read -r source_sub target_root <<< "$entry"
  fanout_workspace "$source_sub" "$target_root"
done

ensure_global_link

if [ "$MODE" = "--apply" ]; then
  title "Pruning broken symlinks"
  for entry in "${WORKSPACES[@]}"; do
    IFS='|' read -r _ target_root _ <<< "$entry"
    prune_broken "$target_root/.pi/skills"
  done
  echo ""
  echo "Done. Skills fanned out."
else
  echo ""
  echo "Dry-run complete. Pass --apply to write symlinks."
fi