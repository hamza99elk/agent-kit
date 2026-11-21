#!/usr/bin/env bash
# scaffold-append-system.sh — Create .pi/APPEND_SYSTEM.md project guardrail file
# Usage: bash scripts/scaffold-append-system.sh [--dir <path>] [--role "description"] [--check-global]
#
# Default directory: current working directory (must contain .pi/)
# Default role description: "expert for this project"

set -euo pipefail

TARGET_DIR="."
ROLE="expert for this project"
CHECK_GLOBAL=false

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) TARGET_DIR="$2"; shift 2 ;;
    --role) ROLE="$2"; shift 2 ;;
    --check-global) CHECK_GLOBAL=true; shift ;;
    *) echo "Usage: scripts/scaffold-append-system.sh [--dir <path>] [--role \"...\"] [--check-global]" >&2
       exit 1 ;;
  esac
done

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# Warn if this isn't inside a .pi/ directory
if [[ "$TARGET_DIR" != *".pi"* ]]; then
  echo "NOTE: Target directory is not inside .pi/. Ensure a .pi/ directory exists."
  mkdir -p "$TARGET_DIR/.pi"
  TARGET_DIR="$TARGET_DIR/.pi"
fi

FILE="$TARGET_DIR/APPEND_SYSTEM.md"

if [ -f "$FILE" ]; then
  echo "ERROR: APPEND_SYSTEM.md already exists at $FILE" >&2
  exit 1
fi

# Check global APPEND_SYSTEM.md and warn about override
if [ "$CHECK_GLOBAL" = true ]; then
  GLOBAL_FILE="$HOME/.pi/agent/APPEND_SYSTEM.md"
  if [ -f "$GLOBAL_FILE" ]; then
    echo ""
    echo "⚠️  WARNING: Global APPEND_SYSTEM.md found at $GLOBAL_FILE"
    echo "   .pi/APPEND_SYSTEM.md will COMPLETELY REPLACE it (not merge)."
    echo "   Review the global file and consider migrating essential rules:"
    echo "   ---"
    cat "$GLOBAL_FILE"
    echo "   ---"
    echo ""
    read -p "Continue? (y/N) " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
      echo "Aborted."
      exit 1
    fi
  fi
fi

cat > "$FILE" << 'CONTEXT'
You are an expert ROLE_PLACEHOLDER for this project.

- You specialize in <capability>
- Your output: <deliverable>

## Commands

- **Build:** <exact command with flags>
- **Test:** <exact command with flags>
- **Lint:** <exact command with flags>
- **Type-check:** <exact command with flags>

## Project knowledge

- **Tech Stack:** <technologies with versions>
- **File Structure:**
  - `<path>` — <purpose>
  - `<path>` — <purpose>

## Standards

**Naming:**
- Functions: camelCase (`getUserData`)
- Classes: PascalCase (`UserService`)
- Constants: UPPER_SNAKE_CASE (`MAX_RETRIES`)

## Boundaries

- ✅ **Always:** <write to these dirs>, <run these checks before commits>
- ⚠️ **Ask first:** <schema changes>, <adding dependencies>, <modifying CI/CD>
- 🚫 **Never:** <commit secrets>, <edit vendor dirs>, <modify production configs>
CONTEXT

# Replace placeholder with actual role
sed -i '' "s/ROLE_PLACEHOLDER/$ROLE/" "$FILE"

echo "Created $FILE"
echo ""
echo "Run '/reload' in Pi to apply changes."
echo ""
echo "⚠️  Remember: .pi/APPEND_SYSTEM.md replaces ~/.pi/agent/APPEND_SYSTEM.md"
echo "   Essential global rules must be copied into this file."