#!/usr/bin/env bash
# scaffold-agents.sh — Create an AGENTS.md hierarchical context file
# Usage: bash scripts/scaffold-agents.sh [--dir <path>] [--role "description"] [--parent-dirs]
#
# Default directory: current working directory
# Default role description: "expert for this project"

set -euo pipefail

TARGET_DIR="."
ROLE="expert for this project"
CHECK_PARENTS=false

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) TARGET_DIR="$2"; shift 2 ;;
    --role) ROLE="$2"; shift 2 ;;
    --parent-dirs) CHECK_PARENTS=true; shift ;;
    *) echo "Usage: scripts/scaffold-agents.sh [--dir <path>] [--role \"...\"] [--parent-dirs]" >&2
       exit 1 ;;
  esac
done

mkdir -p "$TARGET_DIR"

FILE="$TARGET_DIR/AGENTS.md"

if [ -f "$FILE" ]; then
  echo "ERROR: AGENTS.md already exists at $FILE" >&2
  exit 1
fi

# Check parent directories for existing AGENTS.md files
if [ "$CHECK_PARENTS" = true ]; then
  echo "Checking parent directories for existing AGENTS.md files..."
  RESOLVED_DIR="$(cd "$TARGET_DIR" && pwd)"
  while [ "$RESOLVED_DIR" != "/" ]; do
    RESOLVED_DIR="$(dirname "$RESOLVED_DIR")"
    if [ -f "$RESOLVED_DIR/AGENTS.md" ]; then
      echo "  Found: $RESOLVED_DIR/AGENTS.md"
    fi
  done
  echo ""
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

## Architecture

- `<path>` — <purpose>
- `<path>` — <purpose>

## Boundaries

- ✅ **Always:** <what you should always do>
- ⚠️ **Ask first:** <what needs approval>
- 🚫 **Never:** <what is forbidden>

## Workflow

- Branch from `main`, merge via squash
- Commit messages: `type(scope): description`
CONTEXT

# Replace placeholder with actual role
sed -i '' "s/ROLE_PLACEHOLDER/$ROLE/" "$FILE"

echo "Created $FILE"
echo ""
echo "This is a delta-rules template. Edit to add only the rules specific to this"
echo "directory. Parent AGENTS.md files (if any) will be loaded and merged by Pi."