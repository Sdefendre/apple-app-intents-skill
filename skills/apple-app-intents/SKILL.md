---
name: apple-app-intents
description: Build and review iOS apps with App Intents, App Entities, App Shortcuts, App Schemas, widgets, Control Center controls, Focus filters, interactive snippets, and Siri AI custom tools or app skills. Use when adding Siri actions, entity search, onscreen awareness, widget/control configuration, or migrating existing Shortcuts integrations. Includes SDK-aware implementation and validation; does not implement a replacement voice assistant.
license: MIT
metadata:
  author: Steve Defendre
  version: "0.2.0"
  environment: Any Markdown-capable agent. iOS builds need macOS and full Xcode; Siri tests need a supported device and enabled services. Optional helper needs Python 3.10+.
---

# Apple App Intents

Build an app whose real capabilities are usable through Apple's system experiences. Treat intents as public interfaces to the app's existing services. Preserve the requested app, architecture, deployment target, and authorization boundaries.

## Establish the target

Inspect the project, installed Xcode/SDK, minimum OS, existing intents, storage, navigation, and test targets. If useful, run `python3 scripts/doctor.py /path/to/app` from this skill's directory. Its output is an inventory, not a compliance verdict.

Read [platform-and-schemas.md](references/platform-and-schemas.md) before choosing a schema. Distinguish:

- Custom App Intents and App Shortcuts for established system surfaces and invocation phrases.
- Schema-conforming entities and actions for Siri AI's supported domains.
- Features requiring newer SDKs, OS releases, enabled Apple Intelligence, languages, or regions.

The research baseline is **2026-09-10 / WWDC26**. Recheck Apple's current symbol documentation and release notes when choosing APIs. Do not infer runtime availability from a keynote, macro conformance, or an older tutorial. If browsing is unavailable, label the affected claims unverified and use the installed SDK for compilation facts.

## Route by surface

Load only the references needed for the surfaces you are building or reviewing:

| Surface or concern | Reference |
|---|---|
| Schema domains, SDK/OS matrix, migration | [platform-and-schemas.md](references/platform-and-schemas.md) |
| Widgets, controls, Focus filters, snippets, URL/in-app search intents | [intent-types-and-surfaces.md](references/intent-types-and-surfaces.md) |
| Custom Siri tools (`@AppIntent(.tool)`), app skills, Advisor, `SiriEvaluations` (Developer Preview) | [siri-tools-and-evaluations.md](references/siri-tools-and-evaluations.md) |
| Entities, queries, file entities, property wrappers, Spotlight indexing | [entities-and-search.md](references/entities-and-search.md) |
| App Shortcuts, parameter prompts/confirmations, dialog, discovery UI | [shortcuts-and-dialog.md](references/shortcuts-and-dialog.md) |
| Onscreen awareness, transfer representations, donations | [context-and-transfer.md](references/context-and-transfer.md) |
| Service boundaries, `@Dependency`, SwiftData/extensions, execution modes, navigation | [architecture.md](references/architecture.md) |
| Scale, cross-device identity, relevance, long-running/cancellable work | [advanced-2026.md](references/advanced-2026.md) |
| Four verification gates and release evidence | [testing-and-release.md](references/testing-and-release.md) |
| Symptom-to-layer diagnosis | [troubleshooting.md](references/troubleshooting.md) |

## Design the integration

Produce a compact capability map before implementing substantial work:

| User action | Actual service operation | Entity/query | Exact schema or custom intent | Execution/authentication | Evidence needed |
|---|---|---|---|---|---|
| Open an item | Resolve ID and navigate | Persistent item lookup | Matching open schema or `OpenIntent` | Foreground | Cold launch opens that item |

Choose schemas by semantic fit and available system experience. Implement required groups completely. Do not relabel an unrelated object as a message, photo, or note just to obtain Siri discovery. If no supported schema matches, implement useful custom intents/App Shortcuts and explain the discovery limit.

For each selected schema, inspect its **current generated template and symbol page**. Record required property names, types, optionality, result types, and minimum OS. Do not infer names from patterns: the current Notes domain has create/update schemas, not a universal CRUD family. Extra optional parameters may serve Shortcuts but are not necessarily understood by Apple Intelligence.

## Implement one working vertical slice

Start with one meaningful action and its real data, then extend the map. Use [architecture.md](references/architecture.md) for storage, dependencies, concurrency, authentication, and navigation.

1. Model persisted records as `AppEntity` values with stable identifiers and useful display representations. Queries rehydrate current authorized records by identifier; stale or inaccessible IDs never become fabricated records. Read [entities-and-search.md](references/entities-and-search.md).
2. Make `perform()` call the same service as the UI, await the committed operation, and return truthful structured results. Validate inputs and permissions at execution time. Do not report success after only opening a screen or launching an unawaited task.
3. Add the schema macros where they fit. Compile early so metadata extraction and domain-completeness diagnostics can guide implementation. Preserve existing shortcut contracts during migration.
4. Expose a small set of useful `AppShortcut` entry points with app-name phrases and appropriate parameter summaries. Read [shortcuts-and-dialog.md](references/shortcuts-and-dialog.md).
5. For discoverable persistent content, maintain a named Spotlight index through create, update, delete, access revocation, and repair. Type conformance alone does not index data.
6. Add onscreen entities, content transfer, and real UI-interaction donations when they improve the requested workflows. Read [context-and-transfer.md](references/context-and-transfer.md). Match the annotation API to the SDK and view structure.

Use the bundled [FieldNotes example](assets/FieldNotes/README.md) as a pattern source, not a template to impose on unrelated apps. It targets OS 27 and has explicitly documented scope and verification limits. Older deployment targets need their own availability strategy.

For large collections, cross-device identity, contextual relevance, longer work, or multiple execution processes, read [advanced-2026.md](references/advanced-2026.md) before selecting newer APIs.

## Verify the actual system contract

Read [testing-and-release.md](references/testing-and-release.md). Keep these evidence levels separate:

1. Business-service behavior and persistence tests.
2. Swift compilation and **app-target metadata extraction**, including schema diagnostics.
3. AppIntentsTesting in an appropriately configured XCUITest bundle when available.
4. Manual Shortcuts, Spotlight, and Siri tests on the intended device/OS.

Exercise missing parameters, ambiguous names, deleted IDs, denied authorization, offline failures, cold launches, repeated execution, index repair, and cancellation where relevant. Check that chained intents receive useful entities or values. Confirmations must happen before consequential side effects; refreshed ownership metadata complements application authorization rather than replacing it.

For bug reports, use [troubleshooting.md](references/troubleshooting.md) to identify the failing layer before rewriting working code.

## Deliver

Return the implemented capability map, modified files, exact build/test results, and remaining device or service checks. Label capabilities as implemented, compiled, system-tested, or device-verified only when the corresponding evidence exists. Provide concise example utterances and a Shortcuts flow the developer can reproduce.

Do not promise that every app or arbitrary custom action becomes available to unrestricted natural-language Siri requests. Do not add paid services, agent-specific APIs, telemetry, publishing, signing-account changes, or external submissions solely because this skill is active. This skill is free MIT-licensed guidance; it does not waive Apple's platform requirements.
