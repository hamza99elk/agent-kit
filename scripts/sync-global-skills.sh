#!/usr/bin/env bash
# sync-global-skills.sh — Symlink global skills from agent-kit to ~/.pi/agent/skills/
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="$REPO_ROOT/skills-templates/global"
TARGET_DIR="$HOME/.pi/agent/skills"

echo "Syncing global skills..."
echo "  Source: $SOURCE_DIR"
echo "  Target: $TARGET_DIR"
echo ""

# Ensure target exists
mkdir -p "$TARGET_DIR"

count=0
for skill_dir in "$SOURCE_DIR"/*/; do
  # Guard: skip if glob doesn't match
  [ -d "$skill_dir" ] || continue

  name="$(basename "$skill_dir")"
  target="$TARGET_DIR/$name"

  # Guard: skip circular symlinks
  if [ -L "$skill_dir" ]; then
    echo "⚠️  SKIP $name (source is a symlink)"
    continue
  fi

  # Remove existing target if it's not a symlink (i.e., a stale copy)
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    rm -rf "$target"
    echo "  removed copy: $name"
  fi

  # Remove existing symlink if it's broken
  if [ -L "$target" ] && [ ! -e "$target" ]; then
    rm "$target"
    echo "  removed broken link: $name"
  fi

  # Create symlink if it doesn't exist
  if [ ! -e "$target" ]; then
    ln -s "$skill_dir" "$target"
    echo "  linked: $name"
    ((count++))
  else
    # Verify existing symlink is correct
    if [ -L "$target" ]; then
      existing="$(readlink "$target")"
      if [ "$existing" = "$skill_dir" ] || [ "$existing" = "${skill_dir%/}" ]; then
        echo "  OK: $name (already linked)"
      else
        echo "  FIX: $name (relinking: was $existing)"
        rm "$target"
        ln -s "$skill_dir" "$target"
      fi
    fi
  fi
done

echo ""
echo "Done. $count skills linked."