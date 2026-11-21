#!/usr/bin/env bash
# scaffold-system.sh — Create .pi/SYSTEM.md full system prompt replacement
# Usage: bash scripts/scaffold-system.sh [--dir <path>] [--role "description"] [--with-tools]
#
# Default directory: current working directory (must contain .pi/)
# Default role description: "custom agent for this project"

set -euo pipefail

TARGET_DIR="."
ROLE="custom agent for this project"
WITH_TOOLS=false

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) TARGET_DIR="$2"; shift 2 ;;
    --role) ROLE="$2"; shift 2 ;;
    --with-tools) WITH_TOOLS=true; shift ;;
    *) echo "Usage: scripts/scaffold-system.sh [--dir <path>] [--role \"...\"] [--with-tools]" >&2
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

FILE="$TARGET_DIR/SYSTEM.md"

if [ -f "$FILE" ]; then
  echo "ERROR: SYSTEM.md already exists at $FILE" >&2
  exit 1
fi

echo ""
echo "⚠️  WARNING: SYSTEM.md replaces Pi's ENTIRE system prompt."
echo "   Pi will lose its built-in coding tools (read, write, edit, bash)."
echo "   Only use this for custom non-coding agents."
echo ""
read -p "Are you sure you want to create SYSTEM.md? (y/N) " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "Aborted. Consider using APPEND_SYSTEM.md instead."
  exit 1
fi

if [ "$WITH_TOOLS" = true ]; then
  cat > "$FILE" << 'CONTEXT'
You are an expert ROLE_PLACEHOLDER for this project.

## Available tools

- **read:** Read file contents. Use to examine source files, configs, and docs.
- **bash:** Run shell commands. Use for builds, tests, git operations.
- **web_search:** Search the web for current information.
- **fetch_content:** Fetch a specific URL and extract its content.

## Capabilities

- <action 1>
- <action 2>
- CANNOT: <forbidden actions>

## Domain

- <topic 1>: <key facts>
- <topic 2>: <key facts>

## Boundaries

- ✅ Always: <what you should always do>
- ⚠️ Ask first: <what needs approval>
- 🚫 Never: <what is forbidden>
CONTEXT
else
  cat > "$FILE" << 'CONTEXT'
You are an expert ROLE_PLACEHOLDER for this project.

- You do NOT have access to code manipulation tools (read, write, edit, bash)
- Your output is: <output format>

## Capabilities

- <action 1>
- <action 2>
- CANNOT: <forbidden actions>

## Domain

- <topic 1>: <key facts>
- <topic 2>: <key facts>

## Boundaries

- ✅ Always: <what you should always do>
- ⚠️ Ask first: <what needs approval>
- 🚫 Never: <what is forbidden>
CONTEXT
fi

# Replace placeholder with actual role
sed -i '' "s/ROLE_PLACEHOLDER/$ROLE/" "$FILE"

echo "Created $FILE"
echo ""
echo "⚠️  This file replaces Pi's entire system prompt."
echo "   If you later want additive rules that keep Pi's built-in tools,"
echo "   replace this file with .pi/APPEND_SYSTEM.md instead."
echo ""
echo "Run '/reload' in Pi to apply changes."