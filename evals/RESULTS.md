# Recorded evaluation: 2026-09-10

One independent agent evaluated case 2 from the [prompt set](README.md), using skill commit `1bf896d03b2e068dc409bc3777093c3daabfd3e8` (the skill content was unchanged from the initial publication). The evaluator was Codex `gpt-5.6-sol` at maximum reasoning effort, in a disposable workspace, with the installed Markdown skill, public Apple documentation, and Swift 6.4/macOS 27 Command Line Tools. No full Xcode or iPhoneOS SDK was available. This is a small behavioral smoke evaluation, not an agent benchmark or certification.

## Observed output

The agent produced an iOS 18 game integration plan and a custom dice-intent Swift vertical slice. It correctly identified the lack of a gaming schema, selected custom App Intents and curated App Shortcuts, preserved the requested iOS 18 target, and declined to promise arbitrary natural-language gameplay control. The plan covered shared services, stable player identifiers, authorization, persistent XP changes, parameter validation, and useful returned values.

The dice example passed parsing and typechecking in Swift 5 and Swift 6 language modes using the available **macOS 27** SDK. These results do not establish Xcode 16/iOS 18 compilation or App Intents metadata extraction. The agent explicitly left app-target, system-runtime, and device checks unverified.

| Rubric dimension | Observation |
|---|---|
| Semantic/API routing | Correct domain boundary and legacy strategy; exact old-SDK compatibility remains unverified |
| Data integrity | XP safeguards were specified in the plan; the generated vertical slice was dice, so no XP persistence execution was claimed |
| Useful implementation | Typed dice parameters, service injection, bounds checks, chainable total, dialog, and app-name phrases |
| Truthful evidence | Clearly separated newer-SDK typechecking from old-SDK app builds and Siri device behavior |

No automatic-failure behavior from the rubric was observed. A numeric aggregate would hide unexecuted platform checks, so this record reports the dimensions separately.

## Improvement made

The evaluation found that older-SDK guidance required too much inference. The platform reference now includes explicit Xcode 16, 26, and 27 routing and a warning that changing Swift language mode does not validate an older SDK. A compiled legacy sample remains future work.

The 2026-11-24 trial below is a separate run of cases 1–6. It does not replace this record. The authored FieldNotes example, code review, service tests, and CI builds remain separate evidence in [validation](../docs/VALIDATION.md).

## Comparison trial: 2026-11-24

Six cases, three conditions, one run each: this skill, the public `n0an/App-Intents-Agent-Skill` checkout used only as a comparison condition, and no skill. The judge was not shown to the implementing agent. Agent: Grok 4.7. Toolchain: Swift 6.4.2 Command Line Tools and the macOS 27.2 SDK. No full Xcode, iOS SDK, simulator, or device. Scores are 0–2 for semantic/API correctness, data integrity, useful implementation, and truthful evidence. A fabricated API, an unauthorized external send, a false device claim, or a successful no-op would be an automatic failure. None of those four occurred.

Eight workspaces already held partial files from an interrupted earlier attempt (cases 2 with this skill, 3 with this skill and with no skill, 5 with no skill and with the other skill, and all three case 6 runs). Those cells are marked continued. The other ten cells started from the fixture or an empty directory.

| Case | Condition | Start | Sem | Data | Useful | Evidence | What the artifacts showed |
|---|---|---|---|---|---|---|---|
| 1 Notes | This skill | Clean | 2 | 2 | 2 | 2 | `.notes` create, update, and appendText, stable IDs, file reopen, open navigates to that note. App-target macros were not compiled. |
| 1 Notes | Other skill | Clean | 1 | 2 | 2 | 2 | Persistent notes and app-name phrases. The agent said the installed schema list did not define Notes fields, so create/rename stayed custom and open/search used system schemas. |
| 1 Notes | No skill | Clean | 1 | 2 | 2 | 2 | Persistent notes, `OpenIntent`, and app-name phrases. No Notes-domain schema. |
| 2 Older SDK | This skill | Continued | 2 | 2 | 2 | 2 | Custom iOS 18 intents and shortcuts. No game schema. Preview symbols stayed out of the compiling target. |
| 2 Older SDK | Other skill | Clean | 1 | 2 | 2 | 2 | Useful iOS 18 intents, plus a `ToolIntent` file and an app skill. `ToolIntent` did not compile on this SDK, and that file was then excluded. |
| 2 Older SDK | No skill | Clean | 2 | 2 | 2 | 2 | Custom shortcuts and a local command parser. Preview tools were not compiled in. |
| 3 Messages | This skill | Continued | 2 | 2 | 2 | 2 | Send and draft schemas beside the existing phrase, confirmation before send, service checks passed. The app target did not compile. |
| 3 Messages | Other skill | Clean | 1 | 1 | 2 | 2 | Send and draft schemas replaced a fire-and-forget shortcut. `perform()` delivers without `requestConfirmation`. Macro typecheck failed. The example host was not called. |
| 3 Messages | No skill | Continued | 2 | 2 | 2 | 2 | Send and draft schemas, existing phrase kept, service checks. Example host only. |
| 4 Query | This skill | Clean | 2 | 2 | 2 | 2 | Query reads the JSON files. A fresh process found the documents. `perform()` was not called a Siri test. |
| 4 Query | Other skill | Clean | 2 | 2 | 2 | 2 | Same disk-backed lookup, demonstrated from a new process. |
| 4 Query | No skill | Clean | 2 | 2 | 2 | 2 | Same disk-backed lookup, demonstrated from a new process. |
| 5 Scale | This skill | Clean | 2 | 1 | 2 | 2 | `EntityCollection`, long-running cancel/resume, server IDs in the job. Tests passed. The SDK's identifier string kept only the local UUID, and the report says so. |
| 5 Scale | Other skill | Continued | 2 | 2 | 2 | 1 | The agent left an already-written slice in place and recorded passing checks. That does not isolate the skill. |
| 5 Scale | No skill | Continued | 2 | 1 | 2 | 2 | Long-running job, server IDs, handoff activity. The sync client is still a stub. |
| 6 Preview | This skill | Continued | 2 | 1 | 2 | 2 | Tools only under `SIRI_AI_PREVIEW`. Both shortcut roles covered. Shortcuts kept for Spotlight, the Action button, and the App Store build. Store is in memory. |
| 6 Preview | Other skill | Continued | 1 | 2 | 2 | 2 | `ToolIntent` extensions, persisted trips, preview distribution stated. The report also says the App Store update can ship that conformance. |
| 6 Preview | No skill | Continued | 2 | 1 | 2 | 2 | Tools behind the preview flag, shortcut trade-off stated. One comment also lists the App Store as a place to set the flag, then corrects it. |

The clean cells where this skill changed the outcome are case 1, where it was the only condition that adopted the Notes schemas, and case 2, where the other skill added preview symbols the requested Xcode 16 SDK cannot compile. Case 4 did not separate the conditions. Case 6 was continued rather than clean, and all three conditions stated the preview's dev-signed and internal-TestFlight limit.

After this trial, the Notes domain note in `platform-and-schemas.md` now names `.notes.appendText` as the body-append schema. The trial itself used the skill text from before that sentence. Private transcripts and the disposable workspaces are not in this repository. The starting files for cases 2–6 are in [fixtures](fixtures/).
