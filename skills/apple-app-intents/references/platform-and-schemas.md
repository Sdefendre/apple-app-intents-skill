# Platform and schema selection

Baseline checked 2026-09-10. Re-read the linked domain and symbol pages for the SDK in use. An API's introduction version and the rollout of the Siri experience that uses it are different facts.

## Capability layers

| Layer | What to implement | What it establishes |
|---|---|---|
| App Intents foundation | `AppIntent`, typed parameters/results, entity queries | Actions that system surfaces can use; availability varies by surface |
| App Shortcuts | `AppShortcutsProvider`, phrases containing application name | Curated entry points without users first composing a shortcut |
| Siri AI schemas | Matching `@AppIntent(schema:)`, `@AppEntity(schema:)`, `@AppEnum(schema:)` contracts | Structured capabilities the supported Siri domain can interpret |
| Custom Siri tools & app skills (27.3 Developer Preview) | `@AppIntent(.tool)`, optional `Skills.skillsbundle` ([siri-tools-and-evaluations.md](siri-tools-and-evaluations.md)) | Custom actions for Siri AI outside primary schemas; preview-only (dev-signed / internal TestFlight). Adding `.tool` to a primary Siri schema is a build error |
| Content/context | Spotlight, view/entity annotations, transfer representations | Discoverable records, contextual references, cross-app values |
| Runtime delivery | Supported OS, hardware, language/region, Apple Intelligence enabled | Prerequisites for testing the intended Siri experience |

[Apple's framework introduction](https://developer.apple.com/videos/play/wwdc2025/244/) and [WWDC26 schema session](https://developer.apple.com/videos/play/wwdc2026/240/) explain these layers. Do not use a basic App Shortcut as evidence of schema-driven natural-language orchestration.

## Current domain map

Apple's [domain catalog](https://developer.apple.com/documentation/appintents/app-schema-domains) distinguishes:

| Current category | Domains |
|---|---|
| Primary Siri/Apple Intelligence | Audio, Calendar, Camera, Clock, Mail, Maps, Messages, Notes, Phone, Photos, Reminders, System and in-app search |
| Shortcuts-specific | Books, Browser, Files, Journaling, Presentation, Reader, Spreadsheet, Whiteboard, Word processor |
| Separate single-purpose surfaces | Assistant; Visual intelligence |

These categories are a dated lookup aid, not a promise about future releases. For each schema, inspect its **supported system experiences** section. A journaling app may honestly expose notes and photos if those are real features; it should not classify every journal operation as a note action.

Read completeness requirements for [Mail](https://developer.apple.com/documentation/appintents/app-schema-domain-mail), [Messages](https://developer.apple.com/documentation/appintents/app-schema-domain-messages), and [Clock](https://developer.apple.com/documentation/appintents/app-schema-domain-clock). These pages specify groups that must be adopted together. Build the app target and resolve the generated diagnostics; do not satisfy them with success-returning stubs.

## Availability and migration

Use this conservative routing table when an app must keep an older toolchain. It is not a claim that the bundled OS 27 example compiles with that toolchain.

| Selected toolchain / SDK | Starting point | Keep out of that source target |
|---|---|---|
| Xcode 16 / iOS 18 SDK | Custom `AppIntent`, `AppEntity`, queries, `AppShortcutsProvider`; `openAppWhenRun` for legacy foreground behavior. Adopt only schemas actually present in this SDK. | Current OS 27 Notes shapes, `supportedModes`, and `AppIntentsTesting` |
| Xcode 26 / iOS 26 SDK | Existing intent contracts plus `supportedModes` where available; inspect that SDK's schema declarations. | OS 27-only schema fields, `EntityCollection`, and `AppIntentsTesting` |
| Xcode 27 / iOS 27 SDK | Current App Schema templates and the bundled example; use availability and a compatible source layout for older deployment targets. | Any assumption that a newer compiler makes a newer API run on an older OS |

For an older SDK, consult its generated Swift interface and compile the **actual app target with that Xcode version**. Checking Swift 5 language mode with a newer SDK does not establish iOS 18 API compatibility. This project does not yet ship an independently compiled Xcode 16 legacy sample. Preserve working legacy intents while adding newer adapters in separate source/targets if necessary.

- The framework began with iOS 16. Individual APIs were added later; inspect each symbol rather than assigning one minimum version to the whole integration.
- Older material uses `AssistantSchema`. The current SDK uses `AppSchema` and contains compatibility names. Use the terminology and spellings in the selected SDK.
- `supportedModes` is the modern execution-mode API (OS 26-era SDKs). Older targets may need `openAppWhenRun` or a compatible implementation. Do not remove working legacy support without a migration plan.
- Current `.notes.note`, `.notes.createNote`, `.notes.updateNote`, and `.notes.appendText` symbols require OS 27. Their fields differ from older Notes examples. Update renames, moves, or pins a note; it is not where note body text is appended. Appending text is [appendText](https://developer.apple.com/documentation/appintents/appschema/notesintent/appendtext). See also [note](https://developer.apple.com/documentation/appintents/appschema/notesentity/note), [createNote](https://developer.apple.com/documentation/appintents/appschema/notesintent/createnote), and [updateNote](https://developer.apple.com/documentation/appintents/appschema/notesintent/updatenote). Recheck the [Notes domain](https://developer.apple.com/documentation/appintents/app-schema-domain-notes) before assuming the action list is complete.
- Availability guards cannot make an unknown macro or missing SDK symbol compile. Separate newer source/targets when necessary and use an SDK that knows those APIs.

For existing integrations, preserve intent identity, entity IDs, parameter meaning, and enum raw values used by saved shortcuts. When contracts are incompatible, introduce a new schema intent alongside the existing intent. Apple's [migration guidance](https://developer.apple.com/documentation/appintents/making-actions-and-content-discoverable-by-apple-intelligence) describes temporary `isAssistantOnly` use to avoid duplicate actions. Verify its availability and plan retirement rather than deleting the old action immediately.

## Verification source order

Use current Apple symbol documentation and Xcode-generated schema templates for exact contracts, app-target compiler diagnostics for conformance, and device tests for actual Siri behavior. Sessions explain design; samples show integration. Third-party commentary can motivate UX decisions but does not override SDK types or supported surfaces. Record the source URL, SDK, minimum OS, and date beside decisions likely to drift.
