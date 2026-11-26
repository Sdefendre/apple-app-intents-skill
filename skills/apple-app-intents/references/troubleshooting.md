# Troubleshooting by failing layer

| Symptom | Inspect first | Focused repair |
|---|---|---|
| Intent missing everywhere | App target membership, App Intents extraction logs, `isDiscoverable`, package metadata | Build/install the correct app target; restore metadata inclusion |
| Works in Shortcuts, absent from Siri AI | Exact schema's supported experiences, domain group completeness, runtime eligibility | Fix the missing schema contract or describe the actual supported surface |
| Schema macro unavailable | Selected SDK, not merely deployment target | Use a compatible SDK or separate older/newer implementations |
| Macro complains about fields | Current symbol/template and required result type | Map exact fields to real services; avoid invented CRUD names |
| Entity picker empty | Default query, account readiness, real persisted records | Fix query hydration and authorized suggestions |
| Wrong same-name item | Search results, display subtitle, arbitrary `.first` choice | Preserve identity and allow disambiguation |
| Saved shortcut breaks after update | Intent identity, parameters, raw enum values, persistent IDs | Preserve old contracts or provide an explicit migration |
| App opens to the home screen | Actual route observation and cold-start loading | Connect `OpenIntent` to a route consumed by the UI |
| Index has stale/deleted records | Update/delete hooks, account changes, repair queue | Reconcile the named index with authorized storage |
| “This” resolves incorrectly | Annotation ID, visible/selected item semantics | Attach the right entity, then verify annotations through system tests |
| Mutation succeeds but user sees failure | Save succeeded before index/donation/network follow-up failed | Separate committed result from secondary repair work |
| Intent works only after opening app | UI-only dependency registration, in-memory state | Initialize real services for intent execution |
| Duplicate records after retries | Ambiguous transaction result, absent service idempotency | Clarify committed state; reuse service-level deduplication where available |
| Stale widget after intent write | App Group container mismatch, missing timeline reload | Write to the shared App Group store and call `WidgetCenter.shared.reloadAllTimelines()` (or `reloadTimelines(ofKind:)`) |
| Widget or control config intent cluttering Shortcuts | Default `isDiscoverable = true` on configuration intent | Set `isDiscoverable = false` when the intent is configuration-only |
| Interactive snippet does not refresh | Control not wired via `Button(intent:)` / `Toggle(isOn:intent:)`, or `SnippetIntent` reading stale state | Trigger mutations from intent-backed controls and read current persisted state in `SnippetIntent.perform()` |
| Focus filter not applied when app is closed | Filter logic lives only in the main app target or unshared storage | Add a Focus filter extension with shared App Group storage if widgets, badges, or notifications must update without the app running |
| Custom tool not selected by Siri AI | Preview eligibility, vague title/descriptions, missing entity query, or invalid `Skills.skillsbundle` | Check preview build/device eligibility, sharpen descriptions, verify Advisor/Copy Bundle Resources; see [siri-tools-and-evaluations.md](siri-tools-and-evaluations.md) |
| App Shortcut phrases stop reaching Siri after adopting tools | Adding any tool intent makes App Shortcuts unavailable to Siri (preview behavior) | Cover each shortcut's Siri role with a tool; keep the App Shortcuts for Spotlight and the Action button ([siri-tools-and-evaluations.md](siri-tools-and-evaluations.md)) |
| Build error combining `.tool` with a schema | Primary Siri domain schema already supported natively by Siri | Remove `.tool` from primary Siri schemas; combine `.tool` only with Shortcuts-only schemas |
| Unit test passes, system flow fails | Extraction, serialization, process boundaries, runtime access | Add out-of-process AppIntentsTesting and manual surface checks |

Reproduce with one precise action and known record before widening scope. Preserve logs with private content redacted. Read the relevant guide in this skill and the current Apple symbol reference; do not “fix” uncertainty by disabling authentication, returning fabricated entities, or swallowing all errors.
