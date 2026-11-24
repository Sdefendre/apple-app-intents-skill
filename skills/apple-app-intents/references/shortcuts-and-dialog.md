# Shortcuts, parameters, and dialog

Build a few useful entry points around frequent user tasks. Broader parameterized actions can remain available for people composing workflows. Avoid an action for every internal button.

## Parameters and results

Use typed values rather than free-form strings when the framework supports the domain. Provide localized intent titles, parameter labels, display representations, and sensible defaults. A [parameter summary](https://developer.apple.com/documentation/appintents/parametersummary) should read like the action people are composing. Cover meaningful optional parameters without forcing every automation to answer unnecessary questions.

For missing or ambiguous input, prompt during execution with `$parameter.requestValue(...)` or the parameter's disambiguation API rather than arbitrarily picking the first person, document, or account. Before a destructive or consequential mutation, call `requestConfirmation(...)` (check the current `AppIntent` / `IntentParameter` signatures in the selected SDK) and let cancellation abort `perform()` before any write happens. Apple's [AppIntent](https://developer.apple.com/documentation/appintents/appintent) reference is the starting point for current signatures.

Return a typed value or entity when another action should consume the result. Return dialogs that describe what actually happened, and do not claim an external send or save completed when it only started. Voice-only responses need enough information to stand alone; a visual snippet is optional presentation, not the operation itself. Consult [IntentResult](https://developer.apple.com/documentation/appintents/intentresult) and [IntentDialog](https://developer.apple.com/documentation/appintents/intentdialog).

## App Shortcut entry points

Use [AppShortcutsProvider](https://developer.apple.com/documentation/appintents/appshortcutsprovider) and its result-builder syntax. Each phrase needs the application's name token, for example the Swift interpolation `\(.applicationName)`. Verify the current supported phrase/parameter combinations and limits; a provider is a curated catalog, not an unlimited list of synonyms.

Choose discoverable verbs and differentiate actions that sound similar. Use an appropriate SF Symbol and concise short title. Call `YourShortcutsProvider.updateAppShortcutParameters()` on startup and whenever underlying entities referenced by parameterized phrases change. Surface shortcuts inside the app with [SiriTipView](https://developer.apple.com/documentation/appintents/siritipview) and [ShortcutsLink](https://developer.apple.com/documentation/appintents/shortcutslink) where helpful. Test with a fresh installation and after changing the entities used by shortcuts.

Use [App Shortcut phrases](https://developer.apple.com/documentation/appintents/appshortcut) as entry points; do not confuse phrase matching with the complete natural-language Siri AI schema integration. A saved shortcut may have its own user-chosen name.

## Interaction quality

Example acceptance flow for a reading app: search for a saved article, mark that returned article read, and open the same article. Test two articles with the same title, a deleted article, and an offline account. The result should preserve identity all the way through the chain.

When a visual card or inline control clarifies the result or confirmation, return a snippet via `ShowsSnippetView`, or use `SnippetIntent` with `ShowsSnippetIntent` on iOS 26+ for interactive and refreshable snippets ([WWDC25 advances](https://developer.apple.com/videos/play/wwdc2025/275/)). Keep snippet rendering read-only, wire interactive controls to explicit intents rather than private app UI state, and keep a complete spoken dialog for voice-only execution. See [intent-types-and-surfaces.md](intent-types-and-surfaces.md) for snippet and confirmation rules.
