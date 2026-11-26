// Siri AI Developer Preview (Xcode 27.3+). Runs only in a UI testing target on a
// physical, Siri-enabled device with a dev-signed FieldNotes build from the same
// team. Not yet compiled by this repository: no available toolchain had the SDK.
#if canImport(SiriEvaluations)
import Foundation
import SiriEvaluations
import Testing

private let fieldNotes = IntentDefinitions(bundleIdentifier: "org.example.FieldNotes")
private let createNote = fieldNotes.intents["CreateNoteIntent"]
private let updateNote = fieldNotes.intents["UpdateNoteIntent"]
private let openNote = fieldNotes.intents["OpenNoteIntent"]
private let logObservation = fieldNotes.intents["LogObservationIntent"]

struct FieldNotesEvaluation: Evaluation {
    let name: String
    /// A uniquely named fixture note. The app intentionally ships no reset intent.
    let fixtureNote: String
    let dataset: SiriScenarioLoader

    var evaluators: Evaluators { SiriExpectationEvaluator() }

    func subject(from sample: SiriScenario) async throws -> SiriScenarioSubject {
        _ = try await createNote.makeIntent(
            name: fixtureNote, content: "", attachments: [String](), isPinned: false
        ).run()
        return try await SiriService.run(scenario: sample)
    }

    func aggregateMetrics(using aggregator: inout MetricsAggregator) {
        Self.computeSiriMetrics(into: &aggregator)
    }

    static func named(_ title: String, _ scenario: (String) -> SiriScenario) -> Self {
        let note = "Trail log \(UUID().uuidString.prefix(4))"
        return Self(name: title, fixtureNote: note, dataset: SiriScenarioLoader { scenario(note) })
    }
}

/// A device runs one scenario at a time, so the suite is serialized.
@Suite(.serialized)
struct FieldNotesSiriEvaluations {
    @Test(.evaluates(FieldNotesEvaluation.named("Log into a named note") { note in
        SiriScenario {
            UserTurn("In FieldNotes, log two great blue herons at the north pond in my \(note) note.") {
                Calls { logObservation }
                Calls(.disallowed) { updateNote }
            }
        }
    }))
    func logsIntoNamedNote() async throws {
        #expect(EvaluationContext.current.result.aggregateValue(.mean(of: .intentsAllPass)) == 1)
    }

    @Test(.evaluates(FieldNotesEvaluation.named("Ask which note, then log") { note in
        SiriScenario {
            UserTurn("In FieldNotes, log a fallen oak.")
            // Answers Siri's question about which note, if it asks.
            UserTurn("The \(note) note.")
        } expectation: {
            Calls(.unordered) { logObservation }
            Calls(.disallowed) { updateNote }
        }
    }))
    func asksForMissingNoteBeforeLogging() async throws {
        #expect(EvaluationContext.current.result.aggregateValue(.mean(of: .intentsAllPass)) == 1)
    }

    /// Adopting any tool makes App Shortcuts unavailable to Siri. This checks the
    /// Open Note shortcut's Siri role is still covered, now by a tool.
    @Test(.evaluates(FieldNotesEvaluation.named("Open a note through a tool") { note in
        SiriScenario {
            UserTurn("In FieldNotes, open my \(note) note.") {
                Calls { openNote }
            }
        }
    }))
    func opensNoteThroughTool() async throws {
        #expect(EvaluationContext.current.result.aggregateValue(.mean(of: .intentsAllPass)) == 1)
    }
}
#endif
