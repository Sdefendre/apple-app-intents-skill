# Siri AI Developer Preview: custom tools, app skills, and evaluations

> **Preview status:** Features on this page are part of Apple's [Siri AI Developer Preview](https://developer.apple.com/documentation/appintents/siri-ai-developer-preview) (commonly OS 27.3+ betas). APIs, diagnostics, and Siri runtime behavior may change. Availability is limited to Apple Intelligence devices in supported regions for **development-signed builds and internal TestFlight only**—not external TestFlight testers or App Store builds. This skill's research baseline is **2026-09-10 / WWDC26**; recheck Apple's current preview documentation and the installed Xcode SDK before shipping or relying on preview contracts.

## Custom tools (`ToolIntent`)

Apple's [ToolIntent](https://developer.apple.com/documentation/appintents/toolintent) and [bringing custom actions and content to Siri](https://developer.apple.com/documentation/appintents/bringing-custom-actions-and-content-to-siri) guides let you promote an existing `AppIntent` with `@AppIntent(.tool)` so Siri AI can call it directly as a tool outside primary schema domains.

- **Write descriptions for an unfamiliar reader.** Give the intent's `title`, `description`, and every parameter's `title` and `description` explicit formats, valid ranges, units, and semantics. Do not assume the model knows your app's internal jargon.
- **Model one-sentence actions.** Good tools represent a complete action a person can ask for in one sentence. Let Siri resolve `AppEntity` parameters through the entity's query instead of inventing a separate "search" tool purely to look up an entity the query should already return.
- **Keep unsuitable intents out of `.tool`.** Poor tool candidates include widget or control configuration intents, low-level helper steps meant only for composing shortcuts, and consequential actions requiring an explicit user commitment such as placing and paying for an order.
- **Respect schema boundaries.** Combining `@AppIntent(.tool, schema: ...)` works only with **Shortcuts-only** schemas. Adding `.tool` to a schema in a primary Siri domain that Siri already supports natively is a **build error**.
- **Understand when Siri invokes tools.** Per Apple's `ToolIntent` and preview docs, Siri can call a tool when a person names the app, when the app is in the foreground, or when a relevant entity from the app appears in a search result—and without naming the app while a Live Activity from the app is active or when continuing a Siri conversation that already mentioned the app.
- **Plan for the App Shortcuts trade-off.** Per Apple's [bringing custom actions and content to Siri](https://developer.apple.com/documentation/appintents/bringing-custom-actions-and-content-to-siri) guide, adding any tool intent makes your app's App Shortcuts unavailable to Siri, so your tool intents must cover the Siri capabilities those App Shortcuts previously provided. App Shortcuts still work in Spotlight and with the Action button—do not remove them.

## Generable entities, property controls, and card snippets

- **Model-populated inputs:** Mark a `TransientAppEntity` with `@AppEntity(.generable)` ([GenerableEntity](https://developer.apple.com/documentation/appintents/generableentity)) when Siri should construct a transient parameter directly from conversation context without looking up a persisted record. Include clear `title` and `description` metadata on every `@Property`, and use only compiler-supported property types (value types, `AppEnum`, nested `GenerableEntity`, and arrays of those).
- **Entity property privacy and visibility:** In the preview SDK, `@Property`, `@ComputedProperty`, and `@DeferredProperty` accept `description`, per-property `authenticationPolicy` (`IntentAuthenticationPolicy`), and `visibility` (`IntentVisibility`, e.g. `.internal` to keep a property accessible only to your app and its extensions rather than Siri or Shortcuts). Property-level `authenticationPolicy` governs Siri responses; if an intent returns sensitive data directly in its result, set `authenticationPolicy` on the intent as well (or set a static `authenticationPolicy` on the entity).
- **Custom entity cards:** Conform an `AppEntity` to [SnippetRepresentableEntity](https://developer.apple.com/documentation/appintents/snippetrepresentableentity) and return a [CardSnippet](https://developer.apple.com/documentation/appintents/cardsnippet) (configured with `CardSnippetFamily` and `CardSnippetContext`) when Siri responses or transcripts should show a custom SwiftUI card instead of only a default display representation. Card snippets are pre-rendered into a static archive that the system can display even when the app is not running: keep views static (text and images), prepare any derived data or images synchronously before returning the view, and note that unsupported families fall back to `displayRepresentation`. Recheck symbol availability on the [Siri AI Developer Preview](https://developer.apple.com/documentation/appintents/siri-ai-developer-preview) page.

## App skills (`Skills.skillsbundle`)

Apple's [app skills guide](https://developer.apple.com/documentation/appintents/orchestrating-complex-actions-with-app-skills) adds multi-step orchestration guidance for Siri AI through a `Skills.skillsbundle` resource.

- **Guidance, not a deterministic script.** A skill explains how tools fit together and what constraints matter; Siri still decides which tools to invoke at runtime. Enforce hard invariants and authorization checks in Swift services, not only in prose.
- **Bundle structure and build validation.** Include at most one `.skillsbundle` per app target in **Copy Bundle Resources**. Each subfolder in `Skills/` represents one skill, uses only lowercase letters, numbers, and hyphens, must be unique across the app, its extensions, and embedded frameworks, and must contain only a `SKILL.md` file (no extra scripts or reference files). Frontmatter supports only `name` and `description`, and the Markdown body is limited to 10,000 characters (read only after metadata matches). Xcode compiles and validates the bundle; if the bundle is missing from Copy Bundle Resources or fails validation, Siri receives no skills from the app.
- **Make tools stand on their own first.** A skill adds orchestration context across tools; it cannot rescue vague tool titles, missing parameter descriptions, or broken entity queries. Refer to intents, parameters, and entities informally by what they do rather than by Swift symbol names, and avoid duplicating metadata already declared in code.

## Siri Integration Advisor and `SiriEvaluations`

Apple provides two official preview feedback and testing mechanisms alongside the core verification gates:

| Tool | Role | Limits |
|---|---|---|
| **Siri Integration Advisor** (Xcode) | Static review of extracted App Intents metadata, descriptions, parameters, and entity clarity | Static analysis only; does not execute intents or measure live model selection |
| [SiriEvaluations](https://developer.apple.com/documentation/SiriEvaluations/evaluating-your-apps-integration-with-siri) | Scripted multi-turn conversations with expectations (intent calls, entities found, skills loaded) using Swift Testing inside a UI test target | Requires a preview-capable physical device and preview eligibility; measures tested prompts, not every real user request |

Treat Advisor diagnostics and `SiriEvaluations` runs as additions to—not substitutes for—the four evidence gates in [testing-and-release.md](testing-and-release.md) (service tests, app-target build and metadata extraction, `AppIntentsTesting`, and manual device verification).
