# Advanced OS 27 capabilities

Read this only for scale, cross-device workflows, relevance, or long-running operations. Verify each symbol in the selected SDK. These capabilities are optional additions, not prerequisites for every intent.

## Efficient and portable entities

[EntityCollection](https://developer.apple.com/documentation/appintents/entitycollection) carries identifiers without immediately hydrating every record. Consider it for bulk operations that need IDs, then resolve full entities only when required. Authorization and stale-record handling still belong in the service. Do not change a schema-mandated parameter type unless its contract permits it.

[SyncableEntity](https://developer.apple.com/documentation/appintents/syncableentity) describes identity that is already consistent across devices. It does not implement cloud synchronization. Use the actual server/CloudKit identity, or a supported `SyncableEntityIdentifier` mapping between local and stable IDs. A device-local UUID alone does not establish that the same record can be retrieved on another device.

For cheap display lookup, inspect [EntityQuery.displayRepresentations(for:)](https://developer.apple.com/documentation/appintents/entityquery/displayrepresentations(for:)). Return lightweight labels where possible instead of loading full attachments simply to disambiguate a visible item.

## Relevance and structured representations

Apple's [new-capabilities session](https://developer.apple.com/videos/play/wwdc2026/345/) distinguishes searchable content, observed interactions, and contextual suggestions. [RelevantEntities](https://developer.apple.com/documentation/appintents/relevantentities) is a contextual-suggestion API, not a replacement for Spotlight or donation. Use its actual supported contexts and remove expired/inappropriate suggestions. The September 2026 overview text includes legacy wording that differs from its method list; verify the symbol-level methods and SDK rather than copying a guessed signature or relying on a fixed retention period.

The same session uses the name `ValueRepresentation`; the inspected SDK exposes a scoped alias for `IntentValueRepresentation`. Consult [IntentValueRepresentation](https://developer.apple.com/documentation/appintents/intentvaluerepresentation) and the compiler before treating a session name as a standalone top-level symbol. Union values and richer native parameter types can express alternatives without converting everything to strings; preserve the schema's exact accepted types.

## Long operations and cancellation

[LongRunningIntent](https://developer.apple.com/documentation/appintents/longrunningintent) is available in OS 27. It extends background execution through its supported task methods and builds on [ProgressReportingIntent](https://developer.apple.com/documentation/appintents/progressreportingintent) (see [intent-types-and-surfaces.md](intent-types-and-surfaces.md)) to require regular progress reporting. Apple documents a 30-second ordinary background budget on the listed non-macOS platforms; macOS differs. Do not promote that number into a universal foreground limit or a guaranteed extended duration.

[CancellableIntent](https://developer.apple.com/documentation/appintents/cancellableintent), documented from OS 26.4, provides an intent-aware cancellation handler. Stop work promptly, release resources, and preserve recoverable state. A timeout during a remote mutation is not proof that the remote transaction was rolled back. Report and reconcile ambiguous outcomes using the application's service contract.

When multiple app/extension targets contain intents, inspect `allowedExecutionTargets` and `IntentExecutionTargets` in the current SDK. Pick a process that actually has the required services and storage access. `supportedModes` describes foreground/background behavior; it does not by itself select an app versus widget extension. Verify extraction and execution with every participating target.
