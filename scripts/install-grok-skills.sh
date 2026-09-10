#!/usr/bin/env bash
# Copy IcePanel C4 skills into Grok Build's user (or project) skill root.
# Canonical bodies stay in skills/; this only installs them where Grok looks.
set -euo pipefail

usage() {
  cat <<'EOF'
Install IcePanel C4 skills for Grok Build.

Usage:
  scripts/install-grok-skills.sh [options]

Options:
  --dest DIR    Skill root (default: $GROK_HOME/skills or ~/.grok/skills)
  --project     Install into ./ .grok/skills of the current working directory
  --link        Symlink each skill directory instead of copying
  --dry-run     Print actions without writing
  -h, --help    Show this help

Does not read or write ICEPANEL_TOKEN. Set that in your environment after install.
EOF
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_SRC="${ROOT}/skills"
GROK_HOME="${GROK_HOME:-${HOME}/.grok}"
DEST="${GROK_SKILLS_DIR:-${GROK_HOME}/skills}"
MODE="copy"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest)
      DEST="${2:?--dest requires a directory}"
      shift 2
      ;;
    --project)
      DEST="$(pwd)/.grok/skills"
      shift
      ;;
    --link)
      MODE="link"
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "${SKILLS_SRC}" ]]; then
  echo "error: skills directory not found at ${SKILLS_SRC}" >&2
  exit 1
fi

installed=()
while IFS= read -r skill_md; do
  skill_dir="$(dirname "${skill_md}")"
  name="$(basename "${skill_dir}")"
  target="${DEST}/${name}"
  installed+=("${name}")

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "dry-run: ${MODE} ${skill_dir} -> ${target}"
    continue
  fi

  mkdir -p "${DEST}"
  if [[ -e "${target}" || -L "${target}" ]]; then
    rm -rf "${target}"
  fi

  if [[ "${MODE}" == "link" ]]; then
    ln -s "${skill_dir}" "${target}"
  else
    mkdir -p "${target}"
    # Portable recursive copy (GNU and BSD cp).
    cp -R "${skill_dir}/." "${target}/"
  fi
  echo "installed ${name} -> ${target}"
done < <(find "${SKILLS_SRC}" -mindepth 2 -maxdepth 2 -name SKILL.md | sort)

if [[ ${#installed[@]} -eq 0 ]]; then
  echo "error: no SKILL.md files found under ${SKILLS_SRC}" >&2
  exit 1
fi

cat <<EOF

Grok skill root: ${DEST}
Skills: ${installed[*]}

Next:
  export ICEPANEL_TOKEN='<key-id>:<secret>'   # X-API-Key only; do not commit this
  grok inspect                                # expect creating-c4-diagrams, translating-context-maps
  # slash: /creating-c4-diagrams  /translating-context-maps
EOF
