# agent-kit — skill factory justfile
REPO := `pwd`

default:
	@echo "agent-kit — canonical agent skill factory"
	@echo ""
	@echo "just list     List all skills and templates"
	@echo "just count    Count all skills and templates"
	@echo "just audit    Run SKILL.md quality audit"
	@echo "just edit     Open this justfile"

list:
	@echo "=== Global ===";  ls skills-templates/global/
	@echo ""; echo "=== Analygo ==="; ls -d skills-templates/analygo/*/ 2>/dev/null || echo "(none)"
	@echo ""; echo "=== Hamza ==="; ls -d skills-templates/hamza-workspace/*/ 2>/dev/null || echo "(none)"
	@echo ""; echo "=== Agents ==="; ls agents-templates/ 2>/dev/null || echo "(none)"
	@echo ""; echo "=== System ==="; ls system-templates/ 2>/dev/null || echo "(none)"

count:
	@echo "Global:     $$(ls -d skills-templates/global/*/ 2>/dev/null | wc -l)"
	@echo "Analygo:    $$(find skills-templates/analygo -mindepth 2 -maxdepth 2 -type d 2>/dev/null | wc -l)"
	@echo "Hamza:      $$(find skills-templates/hamza-workspace -mindepth 2 -maxdepth 2 -type d 2>/dev/null | wc -l)"
	@echo "Agents:     $$(echo agents-templates/*.AGENTS.md | wc -w)"
	@echo "Systems:    $$(find system-templates -name 'SYSTEM.md' 2>/dev/null | wc -l)"

audit:
	bash scripts/audit-skills.sh

edit:
	$EDITOR {{REPO}}/justfile