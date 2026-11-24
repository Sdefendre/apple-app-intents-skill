# Installation and updates

The distributable unit is the **entire** `skills/apple-app-intents` directory. Its references, example, helper, and license are self-contained. Do not copy only `SKILL.md`.

## Supported directory conventions

| Agent | Personal installation | Project installation |
|---|---|---|
| Codex | `~/.agents/skills/apple-app-intents` | `.agents/skills/apple-app-intents` |
| Claude Code | `~/.claude/skills/apple-app-intents` | `.claude/skills/apple-app-intents` |
| Cursor | `~/.cursor/skills/apple-app-intents` | `.cursor/skills/apple-app-intents` |
| OpenClaw | `~/.openclaw/skills/apple-app-intents` | `<workspace>/skills/apple-app-intents` |
| Other Markdown/Agent Skills agent | Its configured skills directory | Load `SKILL.md` and preserve relative resource paths |

Paths are based on [OpenAI documentation](https://learn.chatgpt.com/docs/build-skills), [Claude Code documentation](https://code.claude.com/docs/en/skills), [Cursor documentation](https://cursor.com/docs/skills), and [OpenClaw documentation](https://docs.openclaw.ai/tools/skills), checked November 23, 2026. Cursor also loads the Agent Skills locations `~/.agents/skills` and `.agents/skills`. Older Clawdbot installations may use different paths; use their configured workspace directory rather than assuming a current OpenClaw location. Agent compatibility describes the portable format and documented loading paths; it is not a claim that every agent version has been exercised.

## Manual installation

Download a release or clone the repository. Copy `skills/apple-app-intents` into the appropriate skills directory using your file manager. Keep an existing customized copy safe before updating.

The optional Python installer performs the same operation and refuses to overwrite. For a project:

```sh
python3 scripts/install.py --skills-dir /absolute/path/to/project/.claude/skills
```

For a custom OpenClaw workspace:

```sh
python3 scripts/install.py --skills-dir /absolute/path/to/workspace/skills
```

No Python is needed for manual copying or reading the instructions. No vendor SDK, API key, MCP server, plugin subscription, or shell permission override is required to load the skill. Your agent still needs the tools and permissions necessary for the app task you assign.

## Version pinning and updates

Use a published release/tag or a reviewed commit for reproducibility. Record that revision alongside an app's integration work. Fetch newer changes into the clone, inspect the diff, preserve customizations, then move the previous installed directory aside and install the reviewed replacement. Avoid installing the same skill into multiple overlapping locations in one agent.

The installer has no force-overwrite mode. It copies rather than symlinks so the installed skill does not depend on the clone staying in place. Remove an installation by removing that copied skill directory after saving any local changes; no system configuration is changed by the installer.

## Confirm discovery

Reload skills or restart the agent. Invoke the skill by name and ask the agent to identify the loaded file and describe the available references. Run one task from [the evaluation guide](../evals/README.md). If native skill discovery is unavailable, explicitly instruct the agent to read the entrypoint before working.

For iOS builds, install/select an appropriate full Xcode release. The skill itself can still help inspect and plan source when Xcode or a device is unavailable, but the resulting verification report must say which checks were not run.
