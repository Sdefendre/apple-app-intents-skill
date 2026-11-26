import AppIntents
import Foundation

@available(iOS 27.0, macOS 27.0, *)
func plainText(_ value: AttributedString) throws -> String {
    let text = String(value.characters)
    guard value == AttributedString(text) else { throw NoteError.unsupportedInput }
    return text
}

@available(iOS 27.0, macOS 27.0, *)
@AppIntent(schema: .notes.createNote)
struct CreateNoteIntent {
    static let allowedExecutionTargets: IntentExecutionTargets = .main
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    var name: AttributedString
    var content: AttributedString?
    var attachments: [IntentFile]
    var isPinned: Bool
    var folder: InboxEntity?

    func perform() async throws -> some ReturnsValue<NoteEntity> {
        guard attachments.isEmpty, folder == nil || folder?.id == "inbox" else { throw NoteError.unsupportedInput }
        let note = try await NotesService.shared.create(
            name: plainText(name), content: try content.map(plainText) ?? "", pinned: isPinned
        )
        return .result(value: NoteEntity(note))
    }
}

@available(iOS 27.0, macOS 27.0, *)
@AppIntent(schema: .notes.updateNote)
struct UpdateNoteIntent {
    static let allowedExecutionTargets: IntentExecutionTargets = .main
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    var target: NoteEntity
    var name: AttributedString?
    var attachments: [IntentFile]?
    var isPinned: Bool?
    var folder: InboxEntity?

    func perform() async throws -> some ReturnsValue<NoteEntity> {
        // Unset means unchanged; an explicit nil means clear the property.
        // This store requires a name, a pin state, and the single Inbox folder.
        if case .set(nil) = $name.valueState { throw NoteError.unsupportedInput }
        if case .set(nil) = $isPinned.valueState { throw NoteError.unsupportedInput }
        if case .set(nil) = $folder.valueState { throw NoteError.unsupportedInput }
        // Clearing attachments is valid: this plain-text store has none.
        guard attachments == nil || attachments?.isEmpty == true,
              folder == nil || folder?.id == "inbox" else { throw NoteError.unsupportedInput }
        let note = try await NotesService.shared.update(id: target.id, name: try name.map(plainText), pinned: isPinned)
        return .result(value: NoteEntity(note))
    }
}

@available(iOS 27.0, macOS 27.0, *)
#if SIRI_AI_PREVIEW
// Siri AI Developer Preview: adopting any tool makes App Shortcuts unavailable to
// Siri, so the shortcut's Siri entry point must also exist as a tool. See Preview/.
@AppIntent(.tool)
#endif
struct OpenNoteIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Note"
    static let description = IntentDescription("Opens one existing FieldNotes note in the app.")
    static let supportedModes: IntentModes = .foreground
    static let allowedExecutionTargets: IntentExecutionTargets = .main
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Note", description: "The existing note to show.") var target: NoteEntity
    static var parameterSummary: some ParameterSummary { Summary("Open \(\.$target)") }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard try await !NotesService.shared.store.resolve([target.id]).isEmpty else { throw NoteError.missingNote }
        NoteRoute.shared.open(target.id)
        return .result()
    }
}

@available(iOS 27.0, macOS 27.0, *)
struct FieldNotesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: OpenNoteIntent(), phrases: ["Open a note in \(.applicationName)"],
                    shortTitle: "Open Note", systemImageName: "note.text")
    }
}
