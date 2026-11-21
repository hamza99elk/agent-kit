#!/usr/bin/env bash
# Table of Contents
# =================
# 1. UNDERSTAND THE MOVE
# 2. REMOVE OLD CHEZMOI STATE  (PHASE 1)
# 3. RUN AGENT-KIT SPROUT      (PHASE 2)
# 4. COMMIT BOTH REPOS         (PHASE 3)
# 5. LATER CLEANUP             (PHASE 4)

# 1. UNDERSTAND THE MOVE
# ========================
# 
# ┌─────────────────────────────────────────────────────────────────────────┐
# │ PRiOR STATE: EVERYTHING in ~/hamza-workspace/chezmoi/                  │
# │                                                                         │
# │  chezmoi/                                                              │
# │  ├── dot_config/...          ✅ Shell, editor, terminal                 │
# │  ├── dot_gitconfig            ✅ Cluster 1                              │
# │  ├── plans/                  ❌ 87 plan files → Cluster 3               │
# │  ├── Projects/analygo/.../   ❌ Skill symlinks → Cluster 2              │
# │  ├── hamza-workspace/.../    ❌ Skill symlinks → Cluster 2              │
# │  ├── security/               ❌ → Cluster 4 (mac-hardening)             │
# │  └── private_Library/        ❌ → Cluster 4                            │
# └─────────────────────────────────────────────────────────────────────────┘
# 
# NEW STATE:
# 
#  ┌── Clusters ──────────────────────────────────────────────────────────────────────┐
#  │                                                                                   │
#  │ 1. Machine Core  ~/hamza-workspace/chezmoi                                       │
#  │    (chezmoi)  ── Shell, editor, terminal, gitconfig, starship                    │
#  │                 + thin run_onchange_after_hook that triggers sprout-skills.sh    │
#  │                                                                                   │
#  │ 2. AI Harness   ~/Projects/agent-kit                                              │
#  │    (git)      ── skills/, agents/, system/                                       │
#  │                 + scripts/sprout-skills.sh  ← the fan-out engine                 │
#  │                                                                                   │
#  │ 3. Work/Notes   ~/notes                                                           │
#  │    (zk/git)   ── plans/, architecture notes, daily scratch                       │
#  │                                                                                   │
#  │ 4. Mac Hardening ~/ops/mac-hardening                                              │
#  │    (git)      ── security/, Brave policies, LaunchAgents                         │
#  │                 + justfile with lockdown/content-toggle recipes                   │
#  └───────────────────────────────────────────────────────────────────────────────────┘

# 2. REMOVE OLD CHEZMOI STATE  (PHASE 1)
# ========================================

# These directories were removed from the chezmoi source tree:
#
#   rm -rf ~/hamza-workspace/chezmoi/plans/
#   rm -rf ~/hamza-workspace/chezmoi/hamza-workspace/
#   rm -rf ~/hamza-workspace/chezmoi/Projects/
#
# The plans/ content was moved to ~/notes/plans/active/ .
# The per-project skill files were removed (replaced by sprout-skills.sh).

# 3. RUN AGENT-KIT SPROUT      (PHASE 2)
# ========================================

# After this README is committed, run:
#
#   cd ~/Projects/agent-kit
#   bash scripts/sprout-skills.sh --apply
#
# This will recreate all .pi/skills/ symlinks across:
#   - ~/Projects/analygo/packages/{hatchet,ui,contracts,aegis}
#   - ~/Projects/analygo/apps
#   - ~/Projects/analygo
#   - ~/hamza-workspace
#   - ~/hamza-workspace/strategy
#   - ~/hamza-workspace/finance
#
# The ~/.pi/agent/skills directory-level symlink is also maintained by this script.

# 4. COMMIT BOTH REPOS         (PHASE 3)
# ========================================

# After sprout-skills.sh --apply succeeds:
#
#   cd ~/hamza-workspace/chezmoi
#   git add -A && git commit -m "refactor: strip Plans/Projects/hamza-workspace to agent-kit/notes"
#
#   cd ~/Projects/agent-kit
#   git add scripts/sprout-skills.sh
#   git commit -m "feat: add sprout-skills.sh — standalone symlink fan-out engine"
#
#   cd ~/notes
#   git init && git add plans/ && git commit -m "initial: plans from chezmoi extraction"
#
#   cd ~/ops/mac-hardening
#   git init && git add security/ private_Library/
#   git commit -m "initial: mac-hardening from chezmoi extraction"

# 5. LATER CLEANUP             (PHASE 4)
# ========================================

# [ ] Archive ~/plans (old deploy target) and ~/Projects/analygo/.references/{plans}
#     after verifying nothing depends on them
# [ ] Create run_onchange_after_sprout-skills.sh.tmpl in chezmoi that calls:
#       cd ~/Projects/agent-kit && bash scripts/sprout-skills.sh --apply
# [ ] Move security/ and Library/ content to ~/ops/mac-hardening/ 
#     and strip from chezmoi
# [ ] Split justfile: keep apply/link-db in chezmoi; move lockdown/unlock/content-*
#     to mac-hardening/justfile