#!/usr/bin/env bash
# scaffold-skill.sh — Create a new skill directory with standard layout
# Usage: bash scripts/scaffold-skill.sh <kebab-case-name> [--global]
#   --global : put in ~/.pi/agent/skills/ instead of .pi/skills/

set -euo pipefail

NAME="${1:?Usage: bash scripts/scaffold-skill.sh <name> [--global]}"
BASE_DIR=".pi/skills"
[ "${2:-}" = "--global" ] && BASE_DIR="$HOME/.pi/agent/skills"

SKILL_DIR="$BASE_DIR/$NAME"

if [ -d "$SKILL_DIR" ]; then
  echo "ERROR: Skill '$NAME' already exists at $SKILL_DIR" >&2
  exit 1
fi

mkdir -p "$SKILL_DIR/scripts" "$SKILL_DIR/references" "$SKILL_DIR/assets"

cat > "$SKILL_DIR/SKILL.md" << 'SKILL'
---
name: NAME_PLACEHOLDER
description: >
  <imperative trigger description — max 1024 chars>
---

# NAME_PLACEHOLDER

## Overview



## Gotchas


SKILL

sed -i '' "s/NAME_PLACEHOLDER/$NAME/g" "$SKILL_DIR/SKILL.md"

echo "Created skill at $SKILL_DIR"
echo "Edit $SKILL_DIR/SKILL.md with your instructions."
echo "Add scripts to $SKILL_DIR/scripts/, references to $SKILL_DIR/references/."