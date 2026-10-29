#!/usr/bin/env bash
# Installs the skill payload (SKILL.md + references/) into a local agent
# skill directory. Repo docs (README, LICENSE, tests) are never installed.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="minecraft-debugging-skill"
TARGET="${1:-${SKILL_DIR:-$HOME/.omp/agent/skills/$NAME}}"

mkdir -p "$TARGET"
cp "$SRC/SKILL.md" "$TARGET/SKILL.md"
rm -rf "$TARGET/references"
cp -a "$SRC/references" "$TARGET/references"

echo "Installed $NAME -> $TARGET"
echo "Reload the agent if needed."
