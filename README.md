# IcePanel plugins

Acornsoft fork of [IcePanel/icepanel-plugin](https://github.com/IcePanel/icepanel-plugin). The skill recipes are host-agnostic — IcePanel REST plus `ICEPANEL_TOKEN` — and work in Claude Code, Grok Build, and other agents that load `SKILL.md`. This pack keeps the upstream Claude Code marketplace and adds Grok Build packaging so Grok agents can use the C4 skills directly.

## Claude Code

```
/plugin marketplace add acornsoft/icepanel-plugin
/plugin install icepanel@icepanel-plugins
```

Upstream catalog (same `.claude-plugin` layout):

```
/plugin marketplace add icepanel/icepanel-plugins
/plugin install icepanel@icepanel-plugins
```

To try it from a local clone instead, point the marketplace at the checkout:

```
/plugin marketplace add ./icepanel-plugin
/plugin install icepanel@icepanel-plugins
```

If the install summary says `Run /reload-plugins to activate.`, run that too.

## Grok Build

Grok discovers each skill as `SKILL.md` in a named folder. User-level root is `$GROK_HOME/skills` (default `~/.grok/skills/`). Plugins, `./.grok/skills/`, and `[skills] paths` in `~/.grok/config.toml` also work. See [Skills, Plugins & Marketplaces](https://docs.x.ai/build/features/skills-plugins-marketplaces) and [`platforms/grok/README.md`](./platforms/grok/README.md).

### Plugin (preferred)

```bash
grok plugin marketplace add acornsoft/icepanel-plugin
grok plugin install icepanel --trust
```

Or install this repository as a plugin without adding a marketplace:

```bash
grok plugin install acornsoft/icepanel-plugin --trust
```

From a local clone: `grok plugin install ./ --trust`. Then `grok inspect` should list `creating-c4-diagrams` and `translating-context-maps` (source `plugin: icepanel`). Slash commands: `/creating-c4-diagrams`, `/translating-context-maps`.

### User skill root

```bash
./scripts/install-grok-skills.sh
```

Windows / PowerShell:

```powershell
./scripts/install-grok-skills.ps1
```

That copies both skills (including `scripts/` and `references/`) into `~/.grok/skills/<skill-name>/`. Use `--project` for `./.grok/skills/` in the current repo, or `--link` to symlink back to this checkout. Prefer plugin install **or** a user-root copy, not both, so slash names stay unambiguous.

## Auth: `ICEPANEL_TOKEN` and `X-API-Key`

Generate an API key in IcePanel under the organization's settings, on the API keys page. Format is `<key-id>:<secret>` — both halves, colon-separated. Put it in the environment; do not commit it.

```bash
export ICEPANEL_TOKEN='<key-id>:<secret>'
```

The helper and any `curl` calls must send **`X-API-Key` alone**. Sending `Authorization: Bearer` as well returns 401, even though the published API reference marks both as required:

```bash
curl -s -H "X-API-Key: $ICEPANEL_TOKEN" https://api.icepanel.io/v1/organizations
```

Python 3 and `curl` are required. The script shells out to `curl` on purpose: Python installs on macOS often lack a configured CA bundle, which fails with `CERTIFICATE_VERIFY_FAILED` against the API.

## Luna Foundry

This repository stands alone as a Grok-friendly pack. Teams using **Luna Foundry Multiagent** can also deploy the same skills through [luna-foundry-config](https://github.com/acornsoft/luna-foundry-config) (`platforms/grok` → `~/.grok/skills/`) via **Luna: Setup Workspace**.

## Skills

### creating-c4-diagrams

Builds and maintains C4 models in IcePanel through its REST API — model objects (actors, systems, apps, stores, components), connections, catalog technologies and icons, and Level 1/2/3 diagrams with hand-authored layout.

It covers the parts that are easy to get wrong: that the model matters more than the diagrams, that a diagram is a story rather than a dump of every edge, that IcePanel has no auto-layout so placement is the whole job, and the places the published API docs disagree with the API.

Includes a helper script for the mechanical work:

```bash
python scripts/icepanel.py import  <landscapeId> model.json   # upsert objects and connections
python scripts/icepanel.py idmap   <landscapeId>              # map import IDs to IcePanel IDs
python scripts/icepanel.py diagram <landscapeId> l2.json      # create a diagram from a layout spec
python scripts/icepanel.py verify  <landscapeId>              # check every diagram for layout problems
```

### translating-context-maps

Turns an image or sketch of a DDD [context map](https://github.com/ddd-crew/context-mapping) into IcePanel model objects and connections. Bounded contexts become a group with a system inside it, upstream/downstream relationships become connections, and the context map patterns — `OHS`, `PL`, `CF`, `ACL`, `SK`, `C/S`, `Partnership` become tags on those connections.

It stops at the import file and hands off to `creating-c4-diagrams`, which does the importing and diagramming.

## Layout

```
.claude-plugin/marketplace.json          Claude Code marketplace catalog (unchanged)
.claude-plugin/plugin.json               Claude Code plugin manifest (unchanged)
.grok-plugin/marketplace.json            Grok Build marketplace catalog
.grok-plugin/plugin.json                 Grok Build plugin metadata
.grok-plugin/plugin-index.json           skill listing for marketplace browse
plugin.json                              Grok plugin manifest (repo-as-plugin)
platforms/grok/README.md                 Grok discovery and install notes
scripts/install-grok-skills.sh           copy/symlink into ~/.grok/skills/
scripts/install-grok-skills.ps1          same, for PowerShell
scripts/check-packaging.sh               layout, JSON, and install-script sanity check
skills/
  creating-c4-diagrams/
    SKILL.md
    references/api.md                    endpoints, schemas, enums, doc corrections
    references/layout.md                 grid, boundaries, line routing, spec format
    references/example.md                a worked three-level build
    scripts/icepanel.py
  translating-context-maps/
    SKILL.md
    references/notation.md               the ddd-crew symbol set, and how sketches mislead
    references/example.md                a worked translation, map to import file
```

## License

Licensed under the [MIT License](./LICENSE).
