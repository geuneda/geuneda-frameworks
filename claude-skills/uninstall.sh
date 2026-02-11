#!/bin/bash
# Geuneda Claude Code Skills Uninstaller
# Usage:
#   ./uninstall.sh              # Remove all Geuneda skills
#   ./uninstall.sh <skill-name> # Remove a specific skill

set -e

SKILLS_DIR="${HOME}/.claude/skills"

SKILLS=(
    "geuneda-assetsimporter"
    "geuneda-dataextensions"
    "geuneda-frameworks"
    "geuneda-googlesheetimporter"
    "geuneda-inputextensions"
    "geuneda-nativeui"
    "geuneda-notificationservice"
    "geuneda-services"
    "geuneda-statechart"
    "geuneda-uiservice"
)

remove_skill() {
    local skill_name="$1"
    local target_dir="${SKILLS_DIR}/${skill_name}"

    if [ -d "$target_dir" ]; then
        rm -rf "$target_dir"
        echo "  [OK] Removed: ${skill_name}"
    else
        echo "  [SKIP] Not installed: ${skill_name}"
    fi
}

echo "Geuneda Claude Code Skills Uninstaller"
echo "======================================="
echo ""

if [ -n "$1" ]; then
    echo "Removing skill: $1"
    remove_skill "$1"
else
    echo "Removing all Geuneda skills..."
    echo ""
    for skill in "${SKILLS[@]}"; do
        remove_skill "$skill"
    done
fi

echo ""
echo "Uninstallation complete."
echo "Restart Claude Code to apply changes."
