# Intent types and system surfaces

Choose the narrowest protocol that matches the system surface you are targeting. Keep business logic in shared services rather than duplicating it per surface; see [architecture.md](architecture.md).

| Need | Candidate protocol | Behavioral check |
|---|---|---|
| Generic action | [AppIntent](https://developer.apple.com/documentation/appintents/appintent) | Executes the real service operation and returns a truthful typed result or dialog |
| Open a specific item | [OpenIntent](https://developer.apple.com/documentation/appintents/openintent); [TargetContentProvidingIntent](https://developer.apple.com/documentation/appintents/targetcontentprovidingintent) (iOS 26+) | Resolves the target ID and navigates on cold launch; use `TargetContentProvidingIntent` (`contentIdentifier`) when targeting a specific SwiftUI scene (`UISceneAppIntent` in UIKit) |
| Universal-link open | [URLRepresentableEntity](https://developer.apple.com/documentation/appintents/urlrepresentableentity) + [URLRepresentableIntent](https://developer.apple.com/documentation/appintents/urlrepresentableintent) | Entity maps to a real Universal Link; `perform()` may be omitted so the app's existing URL handler routes the request ([WWDC24 10134](https://developer.apple.com/videos/play/wwdc2024/10134/)) |
| Custom result or confirmation UI | [ShowsSnippetView](https://developer.apple.com/documentation/appintents/showssnippetview); [SnippetIntent](https://developer.apple.com/documentation/appintents/snippetintent) + [ShowsSnippetIntent](https://developer.apple.com/documentation/appintents/showssnippetintent) (iOS 26-era) | Renders quickly without mutating state; spoken dialog still stands alone ([WWDC25 275](https://developer.apple.com/videos/play/wwdc2025/275/)) |
| Widget configuration | [WidgetConfigurationIntent](https://developer.apple.com/documentation/appintents/widgetconfigurationintent) | `@Parameter` properties drive the configuration UI; `perform()` is optional; `parameterSummary` can show or hide dependent fields |
| Control Center, Lock Screen, or Action button configuration | [ControlConfigurationIntent](https://developer.apple.com/documentation/appintents/controlconfigurationintent) | Optional parameters provide defaults or optionality so the system can preview an unconfigured control |
| Focus mode filter | [SetFocusFilterIntent](https://developer.apple.com/documentation/appintents/setfocusfilterintent) | Configured in Focus settings; `perform()` applies active parameters and receives defaults when Focus turns off ([WWDC22 10121](https://developer.apple.com/videos/play/wwdc2022/10121/)) |
| Standard entity deletion | [DeleteIntent](https://developer.apple.com/documentation/appintents/deleteintent) | Pair with matching schema when applicable; validate authorization and confirm before removing data |
| Open in-app search UI | [ShowInAppSearchResultsIntent](https://developer.apple.com/documentation/appintents/showinappsearchresultsintent) and system in-app search schema | Runs in the foreground app target with `criteria` and `searchScopes` ([in-app search guide](https://developer.apple.com/documentation/appintents/making-in-app-search-actions-available-to-siri-and-apple-intelligence)) |
| Incremental progress | [ProgressReportingIntent](https://developer.apple.com/documentation/appintents/progressreportingintent) | Reports real progress; [LongRunningIntent](advanced-2026.md) builds on it for extended background work |
| Legacy foreground handoff | [ForegroundContinuableIntent](https://developer.apple.com/documentation/appintents/foregroundcontinuableintent) | Older OS compatibility path; on OS 26+, prefer `supportedModes` and `continueInForeground` ([architecture.md](architecture.md), [WWDC25 275](https://developer.apple.com/videos/play/wwdc2025/275/)) |

Specialized surface protocols such as [AudioPlaybackIntent](https://developer.apple.com/documentation/appintents/audioplaybackintent) and [CameraCaptureIntent](https://developer.apple.com/documentation/appintents/cameracaptureintent) exist for dedicated media and hardware flows. Consult their current symbol pages only when the app actually implements those surfaces.

## Snippets and confirmation UI

Use `ShowsSnippetView` for static result views, or adopt `SnippetIntent` with `ShowsSnippetIntent` on iOS 26+ when a snippet needs interactive controls or live refresh ([WWDC25 275](https://developer.apple.com/videos/play/wwdc2025/275/)).

- Keep `SnippetIntent.perform()` fast and read-only. It constructs the view from current state and must not perform business mutations.
- Wire interactive snippet controls to separate intents using `Button(intent:)` and `Toggle(isOn:intent:)`. When a control's intent finishes, the system re-runs the snippet intent to refresh the displayed view.
- `requestConfirmation` can present a confirmation snippet before a consequential action. Let a cancelled confirmation throw and abort `perform()` before any mutation occurs.
- Always pair snippets with complete dialog for voice-only contexts; see [shortcuts-and-dialog.md](shortcuts-and-dialog.md).

## Focus filters

With [SetFocusFilterIntent](https://developer.apple.com/documentation/appintents/setfocusfilterintent), people configure per-Focus parameters in Settings and the system invokes `perform()` when that Focus becomes active (and again with default parameter values when the Focus turns off). Use `FocusFilterAppContext` when notifications must be filtered by predicate.

If widgets, notifications, or app badges must update while the main app process is not running, ship a Focus filter extension that shares the same App Group state rather than assuming the app will stay resident.

## Widgets and controls

Widgets and controls frequently execute outside the main app process:

- Share persistent storage through a real App Group container when a widget or control extension reads or writes app data.
- Set `isDiscoverable = false` on pure `WidgetConfigurationIntent` or `ControlConfigurationIntent` types that should not appear as standalone actions in Shortcuts.
- After an intent mutates data displayed by a widget, call `WidgetCenter.shared.reloadAllTimelines()` (or `reloadTimelines(ofKind:)`) so the widget reflects committed state.
- Do not assume `@Dependency` or `AppDependencyManager` registrations from the app process exist in a widget or control extension; register dependencies early in each process that can execute the intent.
