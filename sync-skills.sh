#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${COPILOT_SKILLS_DIR:-${HOME}/.copilot/skills}"

shopt -s nullglob
SKILL_DIRS=("${SOURCE_DIR}"/*/)

echo "Syncing skill folders from ${SOURCE_DIR}"
echo "Target: ${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"

copied=0
for dir in "${SKILL_DIRS[@]}"; do
  skill_name="$(basename "${dir}")"

  if [[ "${skill_name}" == ".github" || "${skill_name}" == ".git" ]]; then
    continue
  fi

  mkdir -p "${TARGET_DIR}/${skill_name}"
  cp -R "${dir}/." "${TARGET_DIR}/${skill_name}/"
  echo "  Copied ${skill_name}"
  copied=$((copied + 1))
done

if [[ "${copied}" -eq 0 ]]; then
  echo "No skill directories found in ${SOURCE_DIR}"
  exit 1
fi

echo "Skill sync completed."
