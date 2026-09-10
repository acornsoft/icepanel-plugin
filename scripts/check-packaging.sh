#!/usr/bin/env bash
# Sanity-check IcePanel pack layout for Claude + Grok (no network, no secrets).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0

err() {
  echo "FAIL: $*" >&2
  fail=1
}

ok() {
  echo "ok: $*"
}

need() {
  local path="$1"
  if [[ ! -e "${ROOT}/${path}" ]]; then
    err "missing ${path}"
  else
    ok "${path}"
  fi
}

need ".claude-plugin/marketplace.json"
need ".claude-plugin/plugin.json"
need ".grok-plugin/marketplace.json"
need ".grok-plugin/plugin.json"
need ".grok-plugin/plugin-index.json"
need "plugin.json"
need "platforms/grok/README.md"
need "scripts/install-grok-skills.sh"
need "scripts/install-grok-skills.ps1"
need "skills/creating-c4-diagrams/SKILL.md"
need "skills/creating-c4-diagrams/scripts/icepanel.py"
need "skills/translating-context-maps/SKILL.md"

for json_file in \
  .claude-plugin/marketplace.json \
  .claude-plugin/plugin.json \
  .grok-plugin/marketplace.json \
  .grok-plugin/plugin.json \
  .grok-plugin/plugin-index.json \
  plugin.json
do
  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "${ROOT}/${json_file}"; then
    ok "json ${json_file}"
  else
    err "invalid json ${json_file}"
  fi
done

set +e
python3 - "${ROOT}" <<'PY'
import json, pathlib, re, sys

root = pathlib.Path(sys.argv[1])
fail = 0

def err(msg):
    global fail
    print(f"FAIL: {msg}", file=sys.stderr)
    fail = 1

def ok(msg):
    print(f"ok: {msg}")

claude_mkt = json.loads((root / ".claude-plugin/marketplace.json").read_text())
if claude_mkt.get("name") != "icepanel-plugins":
    err("Claude marketplace name changed")
else:
    ok("Claude marketplace name intact")

plugins = claude_mkt.get("plugins") or []
if not plugins or plugins[0].get("name") != "icepanel":
    err("Claude marketplace plugin name changed")
else:
    ok("Claude plugin name intact")

skills = plugins[0].get("skills") if plugins else None
if skills != ["./skills/creating-c4-diagrams", "./skills/translating-context-maps"]:
    err(f"Claude skill list changed: {skills}")
else:
    ok("Claude skill paths intact")

grok_mkt = json.loads((root / ".grok-plugin/marketplace.json").read_text())
src = (grok_mkt.get("plugins") or [{}])[0].get("source")
if src != {"type": "local", "path": "./"} and src != "./":
    err(f"Grok marketplace source unexpected: {src}")
else:
    ok("Grok marketplace source is this repo")

frontmatter = re.compile(r"\A---\n(.*?)\n---\n", re.S)
for skill in ("creating-c4-diagrams", "translating-context-maps"):
    text = (root / "skills" / skill / "SKILL.md").read_text()
    m = frontmatter.match(text)
    if not m:
        err(f"{skill}: missing YAML frontmatter")
        continue
    block = m.group(1)
    if f"name: {skill}" not in block:
        err(f"{skill}: frontmatter name mismatch")
    elif "description:" not in block:
        err(f"{skill}: missing description")
    else:
        ok(f"{skill} SKILL.md frontmatter")

readme = (root / "README.md").read_text()
for needle in (
    "Grok Build",
    "ICEPANEL_TOKEN",
    "X-API-Key",
    "luna-foundry-config",
    "~/.grok/skills",
    "/plugin marketplace add",
):
    if needle not in readme:
        err(f"README missing {needle!r}")
    else:
        ok(f"README has {needle!r}")

sys.exit(fail)
PY
py_status=$?
set -e
if [[ "${py_status}" -ne 0 ]]; then
  fail=1
fi

tmp="$(mktemp -d)"
cleanup() { rm -rf "${tmp}"; }
trap cleanup EXIT

if ! "${ROOT}/scripts/install-grok-skills.sh" --dest "${tmp}/skills" --dry-run >/dev/null; then
  err "install --dry-run failed"
else
  ok "install --dry-run"
fi

if ! "${ROOT}/scripts/install-grok-skills.sh" --dest "${tmp}/skills" >/dev/null; then
  err "install to temp dest failed"
else
  for skill in creating-c4-diagrams translating-context-maps; do
    if [[ -f "${tmp}/skills/${skill}/SKILL.md" ]]; then
      ok "installed ${skill}/SKILL.md"
    else
      err "install missing ${skill}/SKILL.md"
    fi
  done
  if [[ -f "${tmp}/skills/creating-c4-diagrams/scripts/icepanel.py" ]]; then
    ok "installed icepanel.py helper"
  else
    err "install missing icepanel.py"
  fi
fi

if grep -R -E "(sk_live|sk_test|ICEPANEL_TOKEN=)[A-Za-z0-9:_-]{8,}" \
    --exclude-dir=.git --exclude='*.pyc' "${ROOT}" >/dev/null 2>&1; then
  err "possible secret material in the tree"
else
  ok "no obvious secrets in the tree"
fi

if [[ "${fail}" -ne 0 ]]; then
  echo "packaging check failed" >&2
  exit 1
fi

echo "packaging check passed"
