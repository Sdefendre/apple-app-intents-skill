import Foundation

public struct Note: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var content: String
    public var isPinned: Bool
    public let created: Date
    public var modified: Date
}

public enum NoteError: Error, LocalizedError {
    case emptyName, missingNote, unsupportedInput

    public var errorDescription: String? {
        switch self {
        case .emptyName: "Give the note a name."
        case .missingNote: "This note no longer exists."
        case .unsupportedInput: "FieldNotes supports plain text notes in its Inbox. Rich text, attachments, and other folders are not supported."
        }
    }
}

/// One app process owns this file. Use coordinated storage before adding extensions.
public actor NoteStore {
    private let file: URL

    public init(file: URL) { self.file = file }

    public func all() throws -> [Note] {
        guard FileManager.default.fileExists(atPath: file.path) else { return [] }
        return try JSONDecoder().decode([Note].self, from: Data(contentsOf: file))
            .sorted { $0.created == $1.created ? $0.id.uuidString < $1.id.uuidString : $0.created < $1.created }
    }

    public func resolve(_ identifiers: [UUID]) throws -> [Note] {
        let records = Dictionary(uniqueKeysWithValues: try all().map { ($0.id, $0) })
        return identifiers.compactMap { records[$0] }
    }

    public func search(_ text: String) throws -> [Note] {
        try all().filter { $0.name.localizedStandardContains(text) || $0.content.localizedStandardContains(text) }
    }

    public func create(name: String, content: String, pinned: Bool = false) throws -> Note {
        let clean = try validName(name)
        var notes = try all()
        let now = Date()
        let note = Note(id: UUID(), name: clean, content: content, isPinned: pinned, created: now, modified: now)
        notes.append(note)
        try save(notes)
        return note
    }

    public func update(id: UUID, name: String? = nil, pinned: Bool? = nil) throws -> Note {
        var notes = try all()
        guard let index = notes.firstIndex(where: { $0.id == id }) else { throw NoteError.missingNote }
        if let name { notes[index].name = try validName(name) }
        if let pinned { notes[index].isPinned = pinned }
        notes[index].modified = Date()
        try save(notes)
        return notes[index]
    }

    /// Adds plain text as a new final line. Name, pin state, and identity are unchanged.
    public func append(id: UUID, text: String) throws -> Note {
        let line = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { throw NoteError.unsupportedInput }
        var notes = try all()
        guard let index = notes.firstIndex(where: { $0.id == id }) else { throw NoteError.missingNote }
        notes[index].content = notes[index].content.isEmpty ? line : notes[index].content + "\n" + line
        notes[index].modified = Date()
        try save(notes)
        return notes[index]
    }

    public func delete(id: UUID) throws {
        var notes = try all()
        guard let index = notes.firstIndex(where: { $0.id == id }) else { throw NoteError.missingNote }
        notes.remove(at: index)
        try save(notes)
    }

    private func validName(_ value: String) throws -> String {
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw NoteError.emptyName }
        return clean
    }

    private func save(_ notes: [Note]) throws {
        let data = try JSONEncoder().encode(notes)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: file, options: .atomic)
    }
}
