#!/bin/bash
# Geuneda Claude Code Skills Installer
# Usage:
#   ./install.sh              # Install all skills
#   ./install.sh <skill-name> # Install a specific skill (e.g., ./install.sh geuneda-services)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

install_skill() {
    local skill_name="$1"
    local source_dir="${SCRIPT_DIR}/${skill_name}"
    local target_dir="${SKILLS_DIR}/${skill_name}"

    if [ ! -d "$source_dir" ]; then
        echo "[ERROR] Skill not found: ${skill_name}"
        return 1
    fi

    mkdir -p "$target_dir"
    cp -r "${source_dir}/"* "$target_dir/"
    echo "  [OK] ${skill_name}"
}

echo "Geuneda Claude Code Skills Installer"
echo "====================================="
echo ""

mkdir -p "$SKILLS_DIR"

if [ -n "$1" ]; then
    echo "Installing skill: $1"
    install_skill "$1"
else
    echo "Installing all Geuneda skills..."
    echo ""
    for skill in "${SKILLS[@]}"; do
        install_skill "$skill"
    done
fi

echo ""
echo "Installation complete."
echo "Skills are installed at: ${SKILLS_DIR}"
echo "Restart Claude Code to activate the new skills."
