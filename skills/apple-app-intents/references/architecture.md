# Architecture and execution

This is a recommended organization, not a mandated directory layout:

```text
App UI ─────────┐
               ├── Application services ── Authorized persistence/API
App Intents ───┘            │
                            └── Index updates and repair
Entity queries ──────────────── Authorized persistence/API
OpenIntent ── Navigation state ── App UI
```

Keep each intent small enough that its parameters, validation, service call, and result can be inspected together. Do not duplicate a second version of the app's business logic for Siri.

## Persistence and process boundaries

An intent may start while the UI has never loaded. Initialize dependencies without relying on a view's `onAppear`, selected tab, or in-memory preview fixture. A persistent identifier must survive process restart, rename, and routine database migrations. A random UUID created while converting a record into an entity is incorrect.

An actor serializes access only inside its own process. If an app and extension share data, choose storage with appropriate multiprocess coordination, real App Group entitlements, and consistent authorization. Adding both targets to a source file does not share singleton memory. Prefer app-target execution until an extension is actually needed.

Await persistence before reporting creation. Commit state only after a durable write succeeds. If indexing fails after a successful save, preserve the committed result and queue or expose index repair; an apparent creation failure can cause the user to retry and create duplicates. For remote operations, reuse the application's transaction/idempotency mechanism where the service supports it. Never invent a framework-wide exactly-once guarantee.

With SwiftData or other local databases, reuse the app's configured store instead of creating a fresh `ModelContainer` inside `perform()`, and do not attempt to read SwiftUI `@Query` properties inside an intent. When an intent runs inside a widget or other extension, open only storage that target is entitled to access (typically an App Group container), and reload affected widget timelines with `WidgetCenter.shared.reloadAllTimelines()` (or `reloadTimelines(ofKind:)`) after committed writes.

## Dependency injection and concurrency

For optional update-schema parameters, distinguish omission from explicit clearing. The macro-generated parameter's `$property.valueState` represents `.unset` (leave unchanged), `.set(value)` (replace), and `.set(nil)` (clear). A plain `property == nil` check loses that intent. Implement clearing in the service or reject it before mutation when the app cannot represent it. Apple's [WWDC26 code-along](https://developer.apple.com/videos/play/wwdc2026/344/) demonstrates this distinction for recurrence updates.

Register dependencies early in the exact process that will run the intent. Use the `@Dependency` property wrapper with [AppDependencyManager](https://developer.apple.com/documentation/appintents/appdependencymanager) (for example, registering during app or extension startup before intents resolve); do not assume registrations from the main app process transfer into a widget or other extension. Small examples may use an actor-backed shared service if the execution scope is explicit.

Use `@MainActor` for UI mutations and navigation. Keep network and expensive parsing work off the main actor. Follow Swift concurrency diagnostics instead of adding blanket `@unchecked Sendable`, `nonisolated(unsafe)`, or unnecessary detached tasks. A fire-and-forget `Task` inside `perform()` can end after the intent has already reported success.

## Execution and authorization

Choose [supportedModes](https://developer.apple.com/documentation/appintents/appintent/supportedmodes) from actual behavior. A save operation can often run in the background. An open action should bring up the target record. Dynamic foreground continuation is useful when the workflow needs UI only in some states; it is not a reason to move every action to the foreground.

Use [authenticationPolicy](https://developer.apple.com/documentation/appintents/appintent/authenticationpolicy) as appropriate for device-level access. Also perform account authorization, record ownership checks, and permission validation in the underlying service. Query results must respect the same access rules. Do not leak unavailable records through suggestion lists or error dialogs.

For consequential operations, validate the final values and obtain necessary confirmation before committing. Cancellation must leave the operation unperformed. OS 27 [OwnershipProvidingEntity](https://developer.apple.com/documentation/appintents/ownershipprovidingentity) supplies sharing/public context to the system; refresh it from current data. This metadata is not an access-control implementation.

## Real navigation

An `OpenIntent` must resolve the requested identifier and route to the corresponding screen, including on cold launch. Store navigation state in something the app actually observes; reconcile it after data loading. Do not equate `openAppWhenRun = true` with opening the requested item. Test a stale/deleted target and give a meaningful result rather than falling back silently to an unrelated item.

When intents live in a Swift package, inspect [AppIntentsPackage](https://developer.apple.com/documentation/appintents/appintentspackage) and metadata inclusion in the app. A library compiling successfully does not prove the app bundle exports its intents.
