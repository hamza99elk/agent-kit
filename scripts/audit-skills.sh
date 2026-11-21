#!/usr/bin/env bash
# audit-skills.sh — check SKILL.md quality in ~/.pi/agent/skills/
SKILLS_DIR="$HOME/.pi/agent/skills"

echo "=== SKILL.md quality audit ==="
echo "Scanning: $SKILLS_DIR"
echo ""

broken=0
passed=0

for entry in "$SKILLS_DIR"/*/; do
  [ -d "$entry" ] || continue
  name="$(basename "$entry")"
  skillfile="$entry/SKILL.md"

  if [ ! -f "$skillfile" ]; then
    echo "❌ $name: missing SKILL.md"
    broken=$((broken + 1))
    continue
  fi

  has_name=0; has_desc=0; has_license=0; has_meta=0
  grep -q "^name:" "$skillfile" 2>/dev/null && has_name=1
  grep -q "^description:" "$skillfile" 2>/dev/null && has_desc=1
  grep -q "^license:" "$skillfile" 2>/dev/null && has_license=1
  grep -q "^metadata:" "$skillfile" 2>/dev/null && has_meta=1

  if [ "$has_name" -eq 0 ] || [ "$has_desc" -eq 0 ]; then
    echo "❌ $name: incomplete frontmatter (name=$has_name desc=$has_desc)"
    broken=$((broken + 1))
  else
    echo "✅ $name ($(wc -c < "$skillfile") bytes)"
    passed=$((passed + 1))
  fi
done

echo ""
total=$((broken + passed))
if [ "$broken" -eq 0 ]; then
  echo "✅ All $passed skills pass."
else
  echo "⚠️  $broken of $total skills have issues."
fi