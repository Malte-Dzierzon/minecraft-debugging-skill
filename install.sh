#!/usr/bin/env bash
# Installs the skill payload (SKILL.md + references/) into local agent
# skill directories. Default mode symlinks, so a later `git pull` updates
# the installed skill. Repo docs (README, LICENSE, tests) are never
# installed.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="minecraft-debugging-skill"

usage() {
  cat <<'EOF'
Usage: install.sh [--agent omp|claude|codex] [--all] [--copy] [--dry-run] [--uninstall] [TARGET_DIR]

  No flags:            symlink into ~/.omp/agent/skills/minecraft-debugging-skill
  --agent <name>:      symlink into that agent's skills dir (SKILL_DIR_<NAME> wins,
                       e.g. SKILL_DIR_CLAUDE=/path ./install.sh --agent claude)
  --all:               symlink into every agent dir that already exists
  --copy:              copy instead of symlink (for runtimes that can't follow links)
  --dry-run:           print what would happen, change nothing
  --uninstall:         remove installed payload (with --agent/--all or TARGET_DIR)
  TARGET_DIR:          explicit install location (SKILL_DIR env also works)
  -h, --help:          this text
EOF
}

target_dir_for_agent() {
  case "$1" in
    omp)    printf '%s' "${SKILL_DIR_OMP:-${SKILL_DIR:-$HOME/.omp/agent/skills}}" ;;
    claude) printf '%s' "${SKILL_DIR_CLAUDE:-$HOME/.claude/skills}" ;;
    codex)  printf '%s' "${SKILL_DIR_CODEX:-${CODEX_HOME:-$HOME/.codex}/skills}" ;;
    *) echo "install.sh: unknown agent '$1' (expected omp, claude, or codex)" >&2; exit 1 ;;
  esac
}

AGENT=""
ALL=0
COPY=0
DRY_RUN=0
UNINSTALL=0
TARGET=""

while [ $# -gt 0 ]; do
  case "$1" in
    --agent) AGENT="${2:?install.sh: --agent needs a value}"; shift 2 ;;
    --all) ALL=1; shift ;;
    --copy) COPY=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "install.sh: unknown flag '$1' (see --help)" >&2; exit 1 ;;
    *) TARGET="$1"; shift ;;
  esac
done

if [ "$ALL" -eq 1 ] && [ -n "$AGENT$TARGET" ]; then
  echo "install.sh: --all cannot be combined with --agent or TARGET_DIR" >&2
  exit 1
fi

targets=()
if [ -n "$TARGET" ]; then
  targets+=("$TARGET")
elif [ "$ALL" -eq 1 ]; then
  for agent in omp claude codex; do
    dir="$(target_dir_for_agent "$agent")"
    if [ -d "$dir" ]; then
      targets+=("$dir/$NAME")
    fi
  done
  if [ "${#targets[@]}" -eq 0 ]; then
    echo "install.sh: --all found no existing agent skills dir; pass TARGET_DIR explicitly" >&2
    exit 1
  fi
else
  targets+=("$(target_dir_for_agent "${AGENT:-omp}")/$NAME")
fi

for dest in "${targets[@]}"; do
  if [ "$UNINSTALL" -eq 1 ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "would remove $dest"
    else
      rm -rf "$dest"
      echo "removed $dest"
    fi
    continue
  fi

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "install.sh: refusing to overwrite real directory/file at $dest (move it aside first)" >&2
    exit 1
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ "$COPY" -eq 1 ]; then
      echo "would copy $SRC/SKILL.md + $SRC/references/ -> $dest"
    else
      echo "would symlink $dest -> $SRC"
    fi
    continue
  fi

  if [ "$COPY" -eq 1 ]; then
    rm -rf "$dest"
    mkdir -p "$dest"
    cp "$SRC/SKILL.md" "$dest/SKILL.md"
    rm -rf "$dest/references"
    cp -a "$SRC/references" "$dest/references"
    echo "copied $NAME -> $dest"
  else
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$SRC" "$dest"
    echo "linked $dest -> $SRC"
  fi
done

if [ "$DRY_RUN" -eq 0 ] && [ "$UNINSTALL" -eq 0 ]; then
  echo "Reload the agent if needed."
fi
