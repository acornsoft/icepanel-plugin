# Grok Build

This pack is a Grok-native projection of the canonical IcePanel skills in `skills/`. The recipes are host-agnostic (IcePanel REST + `ICEPANEL_TOKEN`); this directory is packaging and install notes, not a second copy of the skill bodies.

Grok Build discovers skills from, in priority order:

- `./.grok/skills/<name>/SKILL.md` (project)
- `~/.grok/skills/<name>/SKILL.md` (user; `$GROK_HOME/skills` when `GROK_HOME` is set)
- an enabled plugin's `skills/` directory
- extra roots in `[skills] paths` in `~/.grok/config.toml`

See [Skills, Plugins & Marketplaces](https://docs.x.ai/build/features/skills-plugins-marketplaces).

## Preferred: install as a plugin

From a clone of this repo, or from GitHub:

```bash
grok plugin marketplace add acornsoft/icepanel-plugin
grok plugin install icepanel --trust
```

Direct install without adding a marketplace:

```bash
grok plugin install acornsoft/icepanel-plugin --trust
```

Then `grok inspect` (or `/skills`) should list `creating-c4-diagrams` and `translating-context-maps` with source `plugin: icepanel`. Slash commands: `/creating-c4-diagrams`, `/translating-context-maps` (qualified as `/icepanel:…` if the name collides).

## Alternative: copy into the user skill root

```bash
./scripts/install-grok-skills.sh
```

Windows / PowerShell:

```powershell
./scripts/install-grok-skills.ps1
```

That writes:

```
$GROK_HOME/skills/creating-c4-diagrams/SKILL.md
$GROK_HOME/skills/translating-context-maps/SKILL.md
```

(`GROK_HOME` defaults to `~/.grok`.) Use `--project` to install into `./.grok/skills/` of the current repo instead. Prefer **one** of plugin install or user-root copy, not both, so slash names stay unambiguous.

## Auth

Set `ICEPANEL_TOKEN` to the IcePanel API key (`<key-id>:<secret>`). Send it as `X-API-Key` only — do not also send `Authorization: Bearer`. Details are in the root README.

## Luna Foundry

Teams using **Luna Foundry Multiagent** can deploy these skills through [luna-foundry-config](https://github.com/acornsoft/luna-foundry-config) (`platforms/grok` → `~/.grok/skills/`). This repository still stands alone if you are not using Luna.
