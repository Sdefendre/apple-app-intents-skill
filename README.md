# Apple App Intents Skill

**Teach your coding agent to build iOS apps that work with Siri, Shortcuts, and Apple Intelligence.**

A free, open-source [Agent Skill](https://agentskills.io/specification) for Claude Code, Codex, OpenClaw, and other agents that can read Markdown instructions. Includes current App Schema guidance, a Swift example, testing workflows, and research grounded in Apple's developer documentation and WWDC transcripts.

**MIT licensed.** Free to use, modify, redistribute, and use in commercial projects. No subscription, API key, hosted service, telemetry, or paid dependency is required to use the skill. Your chosen agent and Apple's development/distribution services have their own requirements.

**[Visit the website and download the skill](https://sdefendre.github.io/apple-app-intents-skill/)**

## Install

Requires Git and Python 3.10+ for the optional installer:

```sh
git clone https://github.com/Sdefendre/apple-app-intents-skill.git
cd apple-app-intents-skill
python3 scripts/install.py --agent codex
```

Choose **one** destination, or repeat for agents you use:

```sh
python3 scripts/install.py --agent claude
python3 scripts/install.py --agent openclaw
python3 scripts/install.py --skills-dir /path/to/your/project/.agents/skills
```

The installer copies the complete skill and refuses to overwrite an existing installation. It never downloads or runs remote code. See [installation and updates](docs/INSTALLATION.md) for manual copies, project scope, version pinning, and other agents.

Reload your agent's skills or start a new session. Ask:

> Use the apple-app-intents skill to build a SwiftUI reading-list app. Let me save articles, find them, mark them read, and open a specific article. Map each capability to the current supported App Schema or a custom intent. Include entity queries, persistence, App Shortcuts, and tests. Explain which Siri capabilities can actually be verified on my SDK and device.

Or add to an existing app:

> Use apple-app-intents to audit this app's Siri integration. Preserve existing shortcuts. Implement the missing entity queries, schema requirements, indexing lifecycle, and cold-launch navigation, then show the build and device-test evidence.

Explicit invocation: `$apple-app-intents` in Codex or `/apple-app-intents` in Claude Code. Other agents can load [SKILL.md](skills/apple-app-intents/SKILL.md) directly together with its relative references.

## What it teaches

- Map real app actions and data to the appropriate Siri/App Schema contracts.
- Build persistent entities, useful queries, composable results, and discoverable App Shortcuts.
- Share services between UI and intents; handle background execution, authentication, and navigation.
- Keep Spotlight content current and support onscreen context and cross-app transfer.
- Use modern APIs for larger collections, cross-device identity, progress, and cancellation when needed.
- Validate business logic, metadata extraction, system execution, and real device flows separately.

The entrypoint loads only the essentials. Eight focused references provide deeper guidance when the task needs it. The included [FieldNotes sample](skills/apple-app-intents/assets/FieldNotes/README.md) demonstrates the OS 27 Notes schemas with real local persistence and explicit limitations.

## Compatibility and scope

The research baseline is **September 10, 2026**, including WWDC26. The sample targets **iOS 27**; the guidance also explains how to preserve older App Intents integrations.

Not every custom intent or schema is discoverable through Siri AI. Apple's current catalog separates primary Siri domains, Shortcuts-specific domains, and other system surfaces. The skill checks semantic fit, required schema groups, individual symbol availability, and runtime eligibility. See the [research report](docs/RESEARCH.md) and [platform guide](skills/apple-app-intents/references/platform-and-schemas.md).

An agent can read the skill on any platform. Building iOS apps requires macOS and full Xcode. Testing Siri needs an eligible device, OS, enabled services, and supported language/region. Source code or a green unit test alone cannot establish a complete Siri experience.

## Explore

| Resource | Purpose |
|---|---|
| [Skill](skills/apple-app-intents/SKILL.md) | Agent instructions and focused reference routing |
| [Research](docs/RESEARCH.md) | Findings, design implications, uncertainties, and cited evidence |
| [Sources and viewing guide](docs/SOURCES.md) | Apple sessions/transcripts, API pages, and Matthew Cassinelli resources |
| [FieldNotes](skills/apple-app-intents/assets/FieldNotes/README.md) | Original SwiftUI/Notes-schema example |
| [Validation](docs/VALIDATION.md) | Actual verification scope and reproduction commands |
| [Evaluation prompts](evals/README.md) | Realistic tasks for testing agent behavior |
| [Contributing](CONTRIBUTING.md) | Improve the skill, examples, and evidence |

## License and attribution

Created by **Steve Defendre**. This repository's original code and documentation are released under the [MIT License](LICENSE), including commercial use. Keep the license notice when redistributing substantial portions.

Apple, Siri, Swift, and Xcode belong to their respective owners. This is an independent community project, not endorsed by Apple, OpenAI, Anthropic, OpenClaw, or Matthew Cassinelli. Linked videos, transcripts, articles, and Apple sample code remain under their original licenses. This repository does not relicense or mirror those works.
