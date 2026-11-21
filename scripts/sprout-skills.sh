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
# Can also be run from chezmoi's run_onchange_after_* hook to keep
# the two clusters in sync after `chezmoi apply`.
# ─────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:---dry-run}"

# ── Map: source subtree → target workspace root → relative symlink prefix ──
# Each entry: source dir glob relative to skills-templates/
#               target root where .pi/skills/ lives
#               symlink depth (how many dirs deep the skill dir is)
declare -a WORKSPACES=(
  # analygo packages
  "analygo/hatchet|$HOME/Projects/analygo/packages/hatchet|3"
  "analygo/ui|$HOME/Projects/analygo/packages/ui|3"
  "analygo/contracts|$HOME/Projects/analygo/packages/contracts|3"
  "analygo/aegis|$HOME/Projects/analygo/packages/aegis|3"
  "analygo/apps|$HOME/Projects/analygo/apps|3"
  "analygo/root|$HOME/Projects/analygo|2"
  # hamza-workspace areas
  "hamza-workspace/root|$HOME/hamza-workspace|2"
  "hamza-workspace/strategy|$HOME/hamza-workspace/strategy|2"
  "hamza-workspace/finance|$HOME/hamza-workspace/finance|2"
)

ANALOGO_AGENTS_FILE="$HOME/Projects/analygo/.pi/AGENTS.md"
HAMZA_AGENTS_FILE="$HOME/hamza-workspace/.pi/AGENTS.md"

log()  { printf "  %s\n" "$*"; }
title(){ printf "\n=== %s ===\n\n" "$*"; }

# ── Helpers ──
make_relative_symlink() {
  local target="$1"   # absolute path to source dir
  local link="$2"     # absolute path to symlink to create
  local depth="$3"    # how many dirs deep to strip from target

  mkdir -p "$(dirname "$link")"

  # Compute relative path from link's parent to target
  local link_dir
  link_dir="$(dirname "$link")"
  local relative
  relative="$(realpath --relative-to="$link_dir" "$target" 2>/dev/null || echo "")"
  if [ -z "$relative" ]; then
    # macOS realpath doesn't support --relative-to, fall back to full path
    relative="$target"
  fi

  if [ "$MODE" = "--apply" ]; then
    if [ -L "$link" ] || [ -e "$link" ]; then
      local existing
      existing="$(readlink "$link")"
      if [ "$existing" = "$relative" ] || [ "$existing" = "$target" ]; then
        return 0  # already correct
      fi
      rm -f "$link"
    fi
    ln -s "$relative" "$link"
    log "  ✓ $link → $relative"
  else
    log "  ~ $link → $relative"
  fi
}

prune_broken() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    return 0
  fi
  local count=0
  while IFS= read -r -d '' link; do
    if [ -L "$link" ] && [ ! -e "$link" ]; then
      rm "$link"
      log "  ✗ removed broken: $link"
      count=$((count + 1))
    fi
  done < <(find "$dir" -type l -print0)
  if [ "$count" -gt 0 ]; then
    log "  (removed $count broken symlinks)"
  fi
  # Remove empty dirs
  find "$dir" -type d -empty -delete 2>/dev/null || true
}

# ── Main ──
if [ "$MODE" = "--prune" ]; then
  title "Pruning broken symlinks"
  for entry in "${WORKSPACES[@]}"; do
    target_root="${entry#*|}"
    target_root="${target_root%%|*}"
    prune_broken "$target_root/.pi/skills"
  done
  exit 0
fi

if [ "$MODE" != "--apply" ]; then
  title "DRY-RUN: sprout-skills.sh (pass --apply to execute)"
fi

created=0
for entry in "${WORKSPACES[@]}"; do
  source_sub="${entry%%|*}"
  target_root="${entry#*|}"
  target_root="${target_root%%|*}"
  depth="${entry##*|}"
  source_dir="$REPO_ROOT/skills-templates/$source_sub"

  if [ ! -d "$source_dir" ]; then
    log "  (no source dir: $source_dir — skipping)"
    continue
  fi

  title "$source_sub → $target_root/.pi/skills/"

  # Walk skill directories at the configured depth
  # e.g. depth=2 for hatchet: skills-templates/analygo/hatchet/sk-hatchet-foo/
  #      depth=1 for root:    skills-templates/analygo/root/sk-analygo-pnpm/
  local depth_arg="$depth"
  find "$source_dir" -mindepth 1 -maxdepth "$depth" -type d | while read -r skill_dir; do
    # Only create symlinks for dirs with SKILL.md
    if [ ! -f "$skill_dir/SKILL.md" ]; then
      continue
    fi

    skill_name="$(basename "$skill_dir")"
    link_path="$target_root/.pi/skills/$skill_name"
    make_relative_symlink "$skill_dir" "$link_path" "$depth"
    created=$((created + 1))
  done
done

# Also link the global skills into ~/.pi/agent/skills (already a dir-level symlink)
# but ensure the dir-level symlink itself exists
GLOBAL_SOURCE="$REPO_ROOT/skills-templates/global"
GLOBAL_LINK="$HOME/.pi/agent/skills"
if [ ! -L "$GLOBAL_LINK" ] || [ "$(readlink "$GLOBAL_LINK")" != "$GLOBAL_SOURCE" ] && [ "$(readlink "$GLOBAL_LINK")" != "${GLOBAL_SOURCE%/}" ]; then
  title "Global skills"
  mkdir -p "$(dirname "$GLOBAL_LINK")"
  if [ -e "$GLOBAL_LINK" ] && [ ! -L "$GLOBAL_LINK" ]; then
    rm -rf "$GLOBAL_LINK"
  fi
  if [ "$MODE" = "--apply" ]; then
    ln -sfn "$GLOBAL_SOURCE" "$GLOBAL_LINK"
    log "  ✓ $GLOBAL_LINK → $GLOBAL_SOURCE"
  else
    log "  ~ $GLOBAL_LINK → $GLOBAL_SOURCE"
  fi
else
  title "Global skills"
  log "  ✓ already linked"
fi

# ── Prune broken links after creation ──
if [ "$MODE" = "--apply" ]; then
  title "Pruning broken symlinks"
  for entry in "${WORKSPACES[@]}"; do
    target_root="${entry#*|}"
    target_root="${target_root%%|*}"
    prune_broken "$target_root/.pi/skills"
  done
fi

echo ""
if [ "$MODE" = "--apply" ]; then
  echo "Done. Skills fanned out."
else
  echo "Dry-run complete. Pass --apply to write symlinks."
fi