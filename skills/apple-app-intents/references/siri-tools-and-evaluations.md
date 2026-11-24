# Siri AI Developer Preview: custom tools, app skills, and evaluations

> **Preview status:** Features on this page are part of Apple's [Siri AI Developer Preview](https://developer.apple.com/documentation/appintents/siri-ai-developer-preview) (commonly OS 27.3+ betas). APIs, diagnostics, and Siri runtime behavior may change. Availability is limited to Apple Intelligence devices in supported regions for **development-signed builds and internal TestFlight only**—not external TestFlight testers or App Store builds. This skill's research baseline is **2026-09-10 / WWDC26**; recheck Apple's current preview documentation and the installed Xcode SDK before shipping or relying on preview contracts.

## Custom tools (`ToolIntent`)

Apple's [ToolIntent](https://developer.apple.com/documentation/appintents/toolintent) guide lets you promote an existing `AppIntent` with `@AppIntent(.tool)` so Siri AI can call it directly as a tool outside primary schema domains.

- **Write descriptions for an unfamiliar reader.** Give the intent's `title`, `description`, and every parameter's `title` and `description` explicit formats, valid ranges, units, and semantics. Do not assume the model knows your app's internal jargon.
- **Model one-sentence actions.** Good tools represent a complete action a person can ask for in one sentence. Let Siri resolve `AppEntity` parameters through the entity's query instead of inventing a separate "search" tool purely to look up an entity the query should already return.
- **Keep unsuitable intents out of `.tool`.** Poor tool candidates include widget or control configuration intents, low-level helper steps meant only for composing shortcuts, and consequential actions requiring an explicit user commitment such as placing and paying for an order.
- **Respect schema boundaries.** Combining `@AppIntent(.tool, schema: ...)` works only with **Shortcuts-only** schemas. Adding `.tool` to a schema in a primary Siri domain that Siri already supports natively is a **build error**.
- **Understand when Siri invokes tools.** Siri can select a tool when the person names the app, when the app is in the foreground, or when a relevant entity appears in context (verify exact trigger rules on Apple's `ToolIntent` page).
- **Keep App Shortcuts distinct.** Retain `AppShortcutsProvider` for phrase, Spotlight, and Action button entry points, and treat `.tool` intents as a distinct Siri AI path. Do not assume enabling a tool disables App Shortcuts; verify current preview interaction on a preview device and in current release notes.

## Generable entities and card snippets

- **Model-populated inputs:** Mark a `TransientAppEntity` with `@AppEntity(.generable)` ([GenerableEntity](https://developer.apple.com/documentation/appintents/generableentity)) when Siri should construct a transient parameter directly from conversation context without looking up a persisted record. Include clear `title` and `description` metadata on every `@Property`, and use only compiler-supported property types (value types, `AppEnum`, nested `GenerableEntity`, and arrays of those).
- **Custom entity cards:** Conform an `AppEntity` to [SnippetRepresentableEntity](https://developer.apple.com/documentation/appintents/snippetrepresentableentity) and return a [CardSnippet](https://developer.apple.com/documentation/appintents/cardsnippet) (configured with `CardSnippetFamily` and `CardSnippetContext`) when Siri responses or transcripts should show a custom SwiftUI card instead of only a default display representation. Recheck symbol availability on the [Siri AI Developer Preview](https://developer.apple.com/documentation/appintents/siri-ai-developer-preview) page.

## App skills (`Skills.skillsbundle`)

Apple's [app skills guide](https://developer.apple.com/documentation/appintents/orchestrating-complex-actions-with-app-skills) adds multi-step orchestration guidance for Siri AI through a `Skills.skillsbundle` resource.

- **Guidance, not a deterministic script.** A skill explains how tools fit together and what constraints matter; Siri still decides which tools to invoke at runtime. Enforce hard invariants and authorization checks in Swift services, not only in prose.
- **Bundle structure and build validation.** Include at most one `.skillsbundle` per app target, with each skill at `Skills/<skill-name>/SKILL.md` containing the required YAML frontmatter (`name` and `description`). Ensure `Skills.skillsbundle` is in the app target's **Copy Bundle Resources** phase. Xcode compiles and validates the bundle; if the bundle is missing from Copy Bundle Resources or fails validation, Siri receives no skills from the app.
- **Make tools stand on their own first.** A skill adds orchestration context across tools; it cannot rescue vague tool titles, missing parameter descriptions, or broken entity queries.

## Siri Integration Advisor and `SiriEvaluations`

Apple provides two official preview feedback and testing mechanisms alongside the core verification gates:

| Tool | Role | Limits |
|---|---|---|
| **Siri Integration Advisor** (Xcode) | Static review of extracted App Intents metadata, descriptions, parameters, and entity clarity | Static analysis only; does not execute intents or measure live model selection |
| [SiriEvaluations](https://developer.apple.com/documentation/SiriEvaluations/evaluating-your-apps-integration-with-siri) | Scripted multi-turn conversations with expectations (intent calls, entities found, skills loaded) using Swift Testing inside a UI test target | Requires a preview-capable physical device and preview eligibility; measures tested prompts, not every real user request |

Treat Advisor diagnostics and `SiriEvaluations` runs as additions to—not substitutes for—the four evidence gates in [testing-and-release.md](testing-and-release.md) (service tests, app-target build and metadata extraction, `AppIntentsTesting`, and manual device verification).
