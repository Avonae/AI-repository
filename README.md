All credits to [Haseeb Majid](https://gitlab.com/hmajid2301/nixicle/-/tree/f1378817/modules/aspects/ai/agents)

Portable Claude Code configuration, kept here so every machine runs the same
agents, plugins and hooks.

## Contents

| Path               | What it is                                                    |
| ------------------ | ------------------------------------------------------------- |
| `agents/`          | Subagent definitions, one Markdown file per agent.             |
| `settings.json`    | Model, enabled plugins, plugin marketplaces and the `rtk` hook. |
| `.claude-plugin/`  | Marketplace and plugin manifests. The repository root is the plugin. |

This repository is its own plugin marketplace, named `ai`, holding one plugin,
`avonae-agents`. Installing that plugin is what delivers `agents/`, so the
files MUST NOT be copied into `~/.claude/agents/` as well — a copy becomes a
second source that never sees later commits.

## Install on a new machine

1. Copy `settings.json` to `~/.claude/settings.json`. If a `settings.json` is
   already there, merge it by hand: this file holds machine-independent keys
   only, but a local file may carry extra ones.
2. Install the `rtk` binary, then run `rtk init -g`. `settings.json` registers
   the `rtk hook claude` hook, it does not install the binary. Without the
   binary every `Bash` call fails on the missing hook command.
3. Restart Claude Code. It installs `caveman`, `ansible-skills`, `obsidian` and
   `avonae-agents` on its own from the `enabledPlugins` and
   `extraKnownMarketplaces` declarations.

## Update the agents

Edit `agents/` here and push. On each machine run `/plugin` and update
`avonae-agents`, or `/plugin marketplace update ai`.

## Not stored here

- **Account skills** (`~/.claude/skills/synced/`) — docs, docx, pdf, xlsx and
  the rest sync from the Claude account automatically.
- **Plugin payloads** (`~/.claude/plugins/`) — each machine installs its own
  copy from the marketplace declarations. The install records hold absolute
  paths, so copying them breaks the other machine.
- **Credentials** (`~/.claude/.credentials.json`) — an OAuth token bound to the
  machine that obtained it. It MUST NOT leave that machine.
- **Session state** — transcripts, auto-memory, shell snapshots and caches are
  per-machine and carry absolute paths.
