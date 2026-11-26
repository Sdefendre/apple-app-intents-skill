// Siri AI Developer Preview (OS 27.3). Compiled only with SIRI_AI_PREVIEW.
// Written against Apple's documented signatures as of 2026-11-23 and not yet
// compiled by this repository: no available toolchain had the 27.3 SDK.
#if SIRI_AI_PREVIEW
import AppIntents
import Foundation

/// Siri fills this from the request instead of querying the app.
@available(iOS 27.3, macOS 27.3, *)
@AppEntity(.generable)
struct FieldObservation: TransientAppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Field Observation"

    @Property(title: "Subject", description: "What was observed, in a few plain words, such as \"great blue heron\" or \"fallen oak\". No counts or places.")
    var subject: String

    @Property(title: "Count", description: "How many were observed, as a whole number from 1 to 10000. Use 1 when the person gives no number.")
    var count: Int

    @Property(title: "Place", description: "Where it was observed, in plain words, such as \"north pond\". Use an empty string when the person names no place.")
    var place: String

    var displayRepresentation: DisplayRepresentation { "\(count) × \(subject)" }

    init() {}
}

/// A custom action outside the Notes schema: the update schema has no content
/// parameter, so appending an observation is offered as a tool.
@available(iOS 27.3, macOS 27.3, *)
@AppIntent(.tool)
struct LogObservationIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Observation"
    static let description = IntentDescription("Adds one field observation as a new last line of an existing FieldNotes note. It never creates, renames, pins, or deletes a note.")
    static let allowedExecutionTargets: IntentExecutionTargets = .main
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Note", description: "The existing note that collects these observations, such as a trail log.")
    var target: NoteEntity

    @Parameter(title: "Observation", description: "What was observed, how many, and where.")
    var observation: FieldObservation

    func perform() async throws -> some ReturnsValue<NoteEntity> & ProvidesDialog {
        // Model-filled values are validated in the shared core before any write.
        let line = try FieldObservationLine.make(subject: observation.subject, count: observation.count, place: observation.place)
        let note = try await NotesService.shared.append(id: target.id, text: line)
        return .result(value: NoteEntity(note), dialog: "Logged \(line) in \(note.name).")
    }
}
#endif
