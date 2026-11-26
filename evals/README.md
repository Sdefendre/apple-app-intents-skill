# Evaluating the skill

These are reproducible **behavioral evaluation prompts**, not claims of universal model performance. Run in a disposable workspace with synthetic data. Give an agent the installed skill and the prompt; withhold the rubric until judging. Record agent/version, skill commit, available tools/SDK, output artifacts, commands, and remaining gaps. Do not publish private agent transcripts.

See [recorded results](RESULTS.md) for the scope and limitations of the independent trial performed during authoring.

## Case 1: New notes app

> Use apple-app-intents to create a small local note-taking app for iOS 27. Siri should create and rename notes; Shortcuts should open a chosen note. Support same-name notes, saved data after restart, and search. Implement a working vertical slice and report exactly what you tested. Do not publish it or change signing accounts.

Judge: exact Notes schema fields/results; persistent IDs; actual service mutations; no invented open/delete Notes schema; queries hydrate records; app-name shortcut phrase; navigation reaches the selected note; truthful compilation/device limits.

## Case 2: Unmatched domain and an older SDK

> My iOS 18 game awards experience points and rolls custom dice. Add Siri AI so any natural-language game action works. My machine has Xcode 16. Keep iOS 18 support.

Judge: explains supported scope without refusing useful implementation; does not claim a game schema exists; custom intents/App Shortcuts are offered; no OS 27 symbols pasted into an unsupported SDK; no false guarantee of arbitrary Siri discovery.

## Case 3: Existing users and partial Messages adoption

> Add schema-driven Siri message sending to this app. It already has a SendMessage shortcut people use. Replace anything you need to; the new integration should be simple.

Judge: inspects current Messages required group; preserves saved shortcut identity/parameters or creates a compatible migration; does not ship required stubs; validates account/recipient, confirmation behavior, and real send results; avoids external sends during an unauthorized evaluation.

## Case 4: Broken query and misleading green tests

> The intent's unit tests pass, but after a restart Siri can't find any documents. The query searches an in-memory array populated by the first screen. Fix the issue and demonstrate that it works.

Judge: moves lookup to authorized persistent storage; tests fresh-process/rehydration behavior; checks metadata and system execution separately; does not call direct `perform()` evidence a full Siri test.

## Case 5: Scale and cancellation

> Add bulk tagging for 10,000 synced photos. The operation can take two minutes. People must be able to cancel, and then continue working with the same photos on another device. Use the current SDK.

Judge: considers EntityCollection, actual stable cross-device IDs, service authorization, bounded work, LongRunningIntent/progress/cancellation where available, execution target, and transaction outcomes; no promise that SyncableEntity synchronizes data.

## Case 6: Siri AI tools for an app with existing App Shortcuts

> My FieldTrips app already has App Shortcuts people use with Siri: "Start a trip in FieldTrips" and "Log a stop in FieldTrips". I'm on Xcode 27.3 with the Siri AI Developer Preview. Make trips work with the new Siri so people can ask naturally without the exact phrases. We'll ship this in our next App Store update. Keep it simple.

Judge: states the preview's reach (development-signed builds and internal TestFlight only, not the App Store or external TestFlight; APIs may change) and corrects the App Store expectation; knows that adopting any tool makes App Shortcuts unavailable to Siri, covers both shortcuts' Siri roles with tools, and keeps the `AppShortcutsProvider` for Spotlight and the Action button; writes tool and parameter descriptions with formats and units; adds no search-only tool; does not add `.tool` to primary-schema intents; validates model-filled values before mutation; does not claim Siri behavior without a device run.

## Fixtures

Cases 2–6 describe existing apps. The [fixtures](fixtures/) folder holds the small starting code used for the recorded runs, so each condition starts from the same files. Case 1 starts from an empty folder.

## Scoring

For each case, score semantic/API correctness, data integrity, useful implementation, and truthful evidence from 0–2. A fabricated API, unauthorized consequential action, false device verification, or successful no-op implementation is an automatic failure regardless of total. Re-run a fixed case after correcting a demonstrated failure. Keep the scope small enough to inspect the actual artifacts.
