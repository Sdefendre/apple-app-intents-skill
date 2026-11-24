# Entities and search

Choose a query according to what the caller supplies and what the app can retrieve:

| Need | Candidate | Behavioral check |
|---|---|---|
| Resolve saved IDs | `EntityQuery.entities(for:)` | Return current authorized records; omit nonexistent records |
| Small complete set in memory | `EnumerableEntityQuery` | Bounded set only; lets Shortcuts auto-generate a Find action without manual predicates ([WWDC25 244](https://developer.apple.com/videos/play/wwdc2025/244/)) |
| User searches by text | `EntityStringQuery` | Match useful names; preserve ambiguity rather than picking arbitrarily |
| Suggested choices | `suggestedEntities()` | Small relevant authorized set; no unbounded remote scan |
| Structured filtering/sorting | `EntityPropertyQuery` | Respect predicates, comparators, sorting, and limits |
| Incoming typed search/value | `IntentValueQuery` | Interpret supported input and resolve appropriate existing values |
| Semantic discovery | `IndexedEntity` + Spotlight | Saved content actually enters and leaves the index |

See [EntityQuery](https://developer.apple.com/documentation/appintents/entityquery), [EnumerableEntityQuery](https://developer.apple.com/documentation/appintents/enumerableentityquery), [EntityStringQuery](https://developer.apple.com/documentation/appintents/entitystringquery), [EntityPropertyQuery](https://developer.apple.com/documentation/appintents/entitypropertyquery), and [IntentValueQuery](https://developer.apple.com/documentation/appintents/intentvaluequery). Do not describe a substring query as semantic search.

## Entity design

Represent the app's useful nouns with [AppEntity](https://developer.apple.com/documentation/appintents/appentity). Keep IDs stable; expose meaningful typed properties and relationships, not opaque JSON or only an ID/title pair when the workflow needs dates, locations, or owners. Use `AppEnum` for genuinely finite choices; give cases durable raw values and localized display names.

When a document or file on disk is itself the canonical record rather than a database row, use [FileEntity](https://developer.apple.com/documentation/appintents/fileentity) with `FileEntityIdentifier` and explicit supported content types ([WWDC24 10134](https://developer.apple.com/videos/play/wwdc2024/10134/)).

Distinguish persistent entities from temporary results. `TransientAppEntity` can represent ephemeral values but is not a replacement for stable identifiers in system annotations or saved references. A display name is not a primary key. Two records named “Planning” should remain distinguishable through subtitles such as folder, date, or owner.

Queries should batch database lookups, return only authorized records, and hydrate current properties. Define deterministic ordering where the UX depends on it. Handle cancellation and offline errors honestly; do not convert every failure into an empty list that pretends the account has no data.

## Entity properties

Control what the system sees, indexes, and eagerly fetches on an entity:

- `@Property`: exposes a stored field to Shortcuts, Siri, and Spotlight (with `indexingKey:` when mapping to a Core Spotlight attribute key).
- `@ComputedProperty`: exposes a cheap derived value via a getter (and supports `indexingKey:` for Spotlight mapping).
- `@DeferredProperty`: exposes an expensive asynchronous getter fetched only when the system explicitly requests it; by default deferred properties are not eagerly serialized or indexed when donating an `IndexedEntity` to Spotlight (newer Siri AI Developer Preview overloads also add `indexingKey:`, `authenticationPolicy:`, and `visibility:` options—check your target SDK and [siri-tools-and-evaluations.md](siri-tools-and-evaluations.md)).
- Plain stored properties without an App Intents wrapper stay internal to your app code and are not exposed to the system. On preview SDKs that support `IntentVisibility`, `@Property`, `@ComputedProperty`, and `@DeferredProperty` also accept `visibility: .internal` (visible to your app and its extensions, hidden from Siri and Shortcuts) and per-property `authenticationPolicy:` for Siri responses.

## Index lifecycle

Apple's [Spotlight integration guide](https://developer.apple.com/documentation/appintents/making-app-entities-available-in-spotlight) describes direct entity indexing, property indexing keys, existing-item association, and named indexes. Build an explicit lifecycle:

| Event | Required application behavior |
|---|---|
| Record created | Save successfully, then submit its entity |
| Indexed property changes | Re-submit the same persistent ID |
| Record deleted | Remove its indexed entity |
| Logout/access revocation | Remove no-longer-accessible indexed content |
| Partial indexing failure | Retain repair work; retry without repeating the business mutation |
| Reindex requested | Rebuild authorized records, bounded for large stores |

For direct entity indexing, consult [IndexedEntityQuery](https://developer.apple.com/documentation/appintents/indexedentityquery) for reindex callbacks on supported SDKs. Existing Core Spotlight item integrations can use their existing delegate path. Check current deletion APIs and identifier mapping; raw app IDs are not automatically equivalent to every Core Spotlight identifier format.

Index only content the product intends to expose. Review sensitive text, attachments, archived items, and account transitions. Test deletion and sign-out using search results, not only database assertions. Indexing may be asynchronous; use bounded eventual assertions instead of a long arbitrary sleep.

## Large and remote catalogs

Index a useful local subset where appropriate and support queries for remote or frequently changing records. A schema's typed search input may carry more than a search string; inspect its variants instead of discarding structured criteria. If the app owns a search screen, inspect the current [System and in-app search domain](https://developer.apple.com/documentation/appintents/app-schema-domain-system-and-in-app-search). Opening that screen does not by itself expose all results as Siri entities.
