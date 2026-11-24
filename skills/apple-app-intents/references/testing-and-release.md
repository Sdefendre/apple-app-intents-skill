# Testing and evidence

## Four gates

| Gate | What it catches | What it does not establish |
|---|---|---|
| Service tests | Incorrect mutations, persistence, authorization, data handling | Metadata discovery or Siri language understanding |
| App build and extraction | Swift types, macros, target membership, schema groups | Runtime selection, indexing, device behavior |
| AppIntentsTesting | Out-of-process intent/query execution and supported system integrations | All real voice, region, hardware, and rollout conditions |
| Device workflows | The actual Shortcuts/Spotlight/Siri experience | Universal success across untested devices/locales |

For OS 27, read [App Intents Testing](https://developer.apple.com/documentation/appintentstesting) and [WWDC26 session 295](https://developer.apple.com/videos/play/wwdc2026/295/). Tests live in an XCUITest bundle, address the app by bundle identifier, and do not import the app's implementation. Follow matching signing-team requirements for the app and runner. This is different from calling `perform()` in a unit test.

Use `IntentDefinitions` to locate exact extracted intent/entity names, run actions, and inspect returned values. Cover query lookup, create-to-update chaining, Spotlight results, and view annotations using current framework APIs. Prefer an actual returned entity over a string parameter when testing identity through a chain. Test-only fixture/reset intents must be hidden and compiled out of release builds; never expose a database-reset intent in a shipping app.

For apps adopting the Siri AI Developer Preview (custom `@AppIntent(.tool)` tools or `Skills.skillsbundle`), see [siri-tools-and-evaluations.md](siri-tools-and-evaluations.md) for **Siri Integration Advisor** and the **`SiriEvaluations`** framework. Those tools require preview-eligible builds and physical devices (development-signed or internal TestFlight only, never external TestFlight or App Store) and complement—rather than substitute for—the four gates above.

## Meaningful service tests

Exercise the shared service with a temporary store and inspect observable results. Reopen the store to verify durability. Check stale IDs, validation failures without mutation, repeated updates, and partial failures. For a new test, introduce a relevant defect briefly in an isolated copy to prove the test detects it. A test that merely asserts a mock indexing call happened cannot prove a searchable entity exists.

## Build the app target

Inspect the project scheme and installed destinations first:

```sh
xcodebuild -version
xcodebuild -showsdks
xcodebuild -list -project YourApp.xcodeproj
xcodebuild -showdestinations -scheme YourApp -project YourApp.xcodeproj
```

Then build/test the real scheme and a listed destination. Preserve build logs with metadata extraction warnings/errors. A Swift package test does not replace an app-target build. Do not suppress App Intents extraction diagnostics to make CI green. For package-defined intents, verify the app discovers the package's metadata.

## Device matrix

Record device model, OS build, app build, language/region, Apple Intelligence state, network state, exact request, observed action/result, and pass/fail. Test applicable rows:

| Scenario | Expected observation |
|---|---|
| Fresh install, first shortcut | Action exists; missing input is requested coherently |
| Cold launch open | The specified record opens after initialization |
| Same-name records | Person can distinguish/select the intended record |
| Deleted/inaccessible ID | No fabricated record or unauthorized data |
| Create → update → read | Same persistent ID and current fields throughout |
| Background, locked device | Execution matches authentication policy |
| Confirmation declined | No mutation or external side effect |
| Offline/service unavailable | Accurate error; no false success |
| Index update/delete/repair | Search reflects current authorized content |
| “This item” / selected list items | Correct entity annotation and resolution |
| Transfer to another app | Destination receives the intended typed content |
| Voice-only | Complete spoken result without depending on a screen |
| Second supported locale | Localized labels, phrases, and disambiguation work |

Report blocked checks explicitly. A simulator can support useful tests but does not substitute for every Siri hardware/service path. Do not invent universal execution time limits or guaranteed indexing latencies.

## Release statement template

“Implemented [capabilities]. Compiled with [Xcode/SDK] for [target]. Passed [named automated checks]. Manually verified [flows] on [device/OS]. Still unverified: [specific flows/availability].”

If no full Xcode or eligible device is available, deliver reviewable source plus concrete commands and that limitation. Never label source inspection alone as “Siri-ready and tested.”
