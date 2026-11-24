# Review checklist: common App Intents mistakes

Check generated or reviewed code against this list before you report it. Each row names the mistake, why it fails, and what to do instead. For symptoms in a running app, use [troubleshooting.md](troubleshooting.md) instead.

## Identity and data

| Mistake | Why it fails | Do instead |
|---|---|---|
| Picking `.first` when a name matches several records | Two notes called "Planning" make the action change the wrong one | Return all matches, add a distinguishing subtitle, and let the parameter disambiguate ([entities-and-search.md](entities-and-search.md)) |
| Using a display name or array index as the entity ID | Renames and reordering break saved shortcuts and annotations | Use the store's stable identifier |
| Querying an in-memory array filled by a screen | After a cold launch or in another process the array is empty | Query authorized persistent storage ([architecture.md](architecture.md)) |
| Returning an empty list for every query error | An offline or signed-out account looks like an account with no data | Throw or surface the real failure |
| Creating a new `ModelContainer` in `perform()` or reading a SwiftUI `@Query` | Opens a second store or reads state that only exists inside a view | Reuse the app's configured store through a shared service |
| Treating a plain `nil` as "clear" in an update intent | Loses the difference between an omitted value and an explicit clear | Inspect `$parameter.valueState` (`.unset`, `.set(nil)`, `.set(value)`) |
| Reporting failure after the write committed because indexing failed | The user retries and creates duplicates | Return the committed result and queue index repair |

## Execution and results

| Mistake | Why it fails | Do instead |
|---|---|---|
| Starting an unawaited `Task` in `perform()` and returning success | The intent can report success before the work finishes or after it fails | Await the committed operation |
| Returning success after only opening a screen | The requested action never happened | Perform the operation, or describe the result as navigation |
| Confirming after the mutation | Cancelling cannot undo the side effect | Call `requestConfirmation` before any write and let cancellation throw |
| Registering dependencies only in a view's `.task` or `.onAppear` | System-launched intents run before or without that view | Register early in each process that can run the intent |
| Assuming widget or control extensions share the app's in-memory state | Extensions are separate processes | Share storage through an App Group and reload widget timelines after writes |
| Snippet views that mutate state, or a dialog that only makes sense beside a snippet | Snippets can be re-rendered, and voice-only contexts show no view | Keep snippet rendering read-only and make the dialog stand on its own |
| Shipping a test-only reset or fixture intent | Anyone can run it from Shortcuts | Hide it, compile it out of release builds, or use uniquely named fixtures |

## Schemas and Siri AI (Developer Preview)

| Mistake | Why it fails | Do instead |
|---|---|---|
| Relabeling an unrelated object as a note or message to reach Siri | The schema contract does not fit and Siri behaves unpredictably | Choose a matching schema, or ship custom intents and explain the limit ([platform-and-schemas.md](platform-and-schemas.md)) |
| Inventing schema names, such as a Notes delete or open schema | Macros fail or the intent never reaches the intended experience | Read the generated template and current symbol page |
| Adding `.tool` to an intent that adopts a schema Siri already supports | Apple documents this as a build error; the schema already reaches Siri | Use `@AppIntent(.tool, schema:)` only for Shortcuts-only schemas ([ToolIntent](https://developer.apple.com/documentation/appintents/toolintent)) |
| Adopting a tool and leaving App Shortcuts as the only Siri path | Any tool intent makes the app's App Shortcuts unavailable to Siri | Cover each App Shortcut's Siri role with a tool, and keep the App Shortcuts for Spotlight and the Action button ([Apple](https://developer.apple.com/documentation/appintents/bringing-custom-actions-and-content-to-siri)) |
| A "search" tool whose only job is to find an entity | Duplicates the entity query Siri already runs for parameters | Let the entity's query and Spotlight index resolve parameters |
| Trusting model-filled values from a generable entity | Siri can produce empty, out-of-range, or multi-line values | Validate in the service before any write |
| Tool titles and descriptions written in internal jargon | Siri's model cannot tell what the tool does or what a parameter accepts | Describe the action, formats, ranges, and units for a reader who doesn't know the app |
| Promising App Store users the preview features | The preview reaches only development-signed builds and internal TestFlight | State the preview limits and keep a released-SDK path ([siri-tools-and-evaluations.md](siri-tools-and-evaluations.md)) |

## Evidence

| Mistake | Why it fails | Do instead |
|---|---|---|
| Calling a direct `perform()` unit test "Siri verified" | It skips metadata extraction, serialization, and process boundaries | Report each verification gate separately ([testing-and-release.md](testing-and-release.md)) |
| Saying a newer SDK's typecheck proves an older SDK build | Changing Swift language mode does not change the SDK | Build with the target SDK, or label the claim unverified |
| Reporting a passing `SiriEvaluations` run as "Siri works" | It measures the scripted prompts on one device | Report the scenarios and device, and keep manual checks |
