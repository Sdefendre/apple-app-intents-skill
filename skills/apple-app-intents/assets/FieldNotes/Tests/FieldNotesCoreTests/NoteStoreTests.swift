import Foundation
import Testing
@testable import FieldNotesCore

private func temporaryFile() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("notes.json")
}

@Test func createUpdateAndReopenPreserveIdentityAndContent() async throws {
    let file = try temporaryFile()
    defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
    let store = NoteStore(file: file)
    let created = try await store.create(name: "  Field trip  ", content: "Meet by the oak tree.")
    let updated = try await store.update(id: created.id, name: "Saturday trip", pinned: true)
    #expect(updated.id == created.id)
    #expect(updated.content == "Meet by the oak tree.")
    let reopened = NoteStore(file: file)
    let matches = try await reopened.resolve([created.id])
    #expect(matches == [updated])
    #expect(matches.first?.name == "Saturday trip")
    #expect(matches.first?.isPinned == true)
}

@Test func duplicateNamesStayDistinctAndDeletionRemovesLookup() async throws {
    let file = try temporaryFile()
    defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
    let store = NoteStore(file: file)
    let first = try await store.create(name: "Planning", content: "Garden")
    let second = try await store.create(name: "Planning", content: "Travel")
    #expect(first.id != second.id)
    #expect(try await store.search("Planning").count == 2)
    #expect(try await store.resolve([second.id, first.id]).map(\.id) == [second.id, first.id])
    try await store.delete(id: first.id)
    #expect(try await store.resolve([first.id, second.id]) == [second])
    await #expect(throws: NoteError.self) { try await store.update(id: first.id, name: "Gone") }
}

@Test func invalidUpdatesDoNotChangePersistedState() async throws {
    let file = try temporaryFile()
    defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
    let store = NoteStore(file: file)
    let note = try await store.create(name: "Keep", content: "Original")
    await #expect(throws: NoteError.self) { try await store.update(id: note.id, name: " \n ", pinned: true) }
    #expect(try await NoteStore(file: file).all() == [note])
    await #expect(throws: NoteError.self) { try await store.create(name: "", content: "Invalid") }
    #expect(try await store.all() == [note])
}

@Test func failedWriteDoesNotCreateAnInMemorySuccess() async throws {
    let file = try temporaryFile()
    defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
    let blocker = file.deletingLastPathComponent().appendingPathComponent("not-a-directory")
    try Data("blocked".utf8).write(to: blocker)
    let store = NoteStore(file: blocker.appendingPathComponent("notes.json"))
    await #expect(throws: (any Error).self) { try await store.create(name: "No save", content: "") }
    #expect(try await store.all().isEmpty)
}

@Test func appendAddsALineWithoutChangingIdentityNameOrPin() async throws {
    let file = try temporaryFile()
    defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
    let store = NoteStore(file: file)
    let note = try await store.create(name: "Trail log", content: "", pinned: true)
    _ = try await store.append(id: note.id, text: "  2 × heron — north pond \n")
    let appended = try await store.append(id: note.id, text: "1 × kingfisher")
    #expect(appended.id == note.id)
    #expect(appended.name == "Trail log")
    #expect(appended.isPinned)
    #expect(appended.content == "2 × heron — north pond\n1 × kingfisher")
    #expect(try await NoteStore(file: file).resolve([note.id]) == [appended])
}

@Test func invalidAppendDoesNotChangePersistedState() async throws {
    let file = try temporaryFile()
    defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
    let store = NoteStore(file: file)
    let note = try await store.create(name: "Keep", content: "Original")
    await #expect(throws: NoteError.self) { try await store.append(id: note.id, text: " \n ") }
    await #expect(throws: NoteError.self) { try await store.append(id: UUID(), text: "Orphan") }
    #expect(try await NoteStore(file: file).all() == [note])
}

@Test func observationLinesRejectUntrustedValuesBeforeMutation() throws {
    #expect(try FieldObservationLine.make(subject: " great blue heron ", count: 2, place: "north pond") == "2 × great blue heron — north pond")
    #expect(try FieldObservationLine.make(subject: "fallen oak", count: 1, place: "  ") == "1 × fallen oak")
    #expect(try FieldObservationLine.make(subject: "heron\nDELETE ALL", count: 1, place: "") == "1 × heron DELETE ALL")
    #expect(throws: NoteError.self) { try FieldObservationLine.make(subject: " ", count: 1, place: "") }
    #expect(throws: NoteError.self) { try FieldObservationLine.make(subject: "heron", count: 0, place: "") }
    #expect(throws: NoteError.self) { try FieldObservationLine.make(subject: "heron", count: 10_001, place: "") }
}
