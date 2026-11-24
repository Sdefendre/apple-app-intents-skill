import AppIntents
import CoreSpotlight
import Foundation
import Observation

@available(iOS 27.0, macOS 27.0, *)
actor NotesService {
    static let shared = NotesService()
    let store: NoteStore
    private(set) var indexNeedsRepair = false
    private var lastIndexJob: Task<Void, Error>?
    private var indexGeneration = UUID()

    init() {
        let root = URL.applicationSupportDirectory.appendingPathComponent("FieldNotes", isDirectory: true)
        store = NoteStore(file: root.appendingPathComponent("notes.json"))
    }

    func create(name: String, content: String, pinned: Bool) async throws -> Note {
        let note = try await store.create(name: name, content: content, pinned: pinned)
        await repairAfterMutation()
        await NoteChanges.shared.committed()
        return note
    }

    func update(id: UUID, name: String?, pinned: Bool?) async throws -> Note {
        let note = try await store.update(id: id, name: name, pinned: pinned)
        await repairAfterMutation()
        await NoteChanges.shared.committed()
        return note
    }

    func append(id: UUID, text: String) async throws -> Note {
        let note = try await store.append(id: id, text: text)
        await repairAfterMutation()
        await NoteChanges.shared.committed()
        return note
    }

    func delete(id: UUID) async throws {
        try await store.delete(id: id)
        // For this tiny local store, rebuilding reconciles deletions without assuming
        // Core Spotlight's generated entity identifier format equals UUID.uuidString.
        await repairAfterMutation()
        await NoteChanges.shared.committed()
    }

    private func repairAfterMutation() async {
        do { try await rebuildIndex() }
        catch { /* Committed data is returned; rebuildIndex retains repair status. */ }
    }

    func rebuildIndex() async throws {
        indexNeedsRepair = true
        let generation = UUID()
        indexGeneration = generation
        let previous = lastIndexJob
        // Actors are reentrant at await. Chain jobs so an older snapshot cannot
        // overwrite a newer one or resurrect a deleted note in the index.
        let job = Task {
            if let previous { _ = try? await previous.value }
            try await self.performIndexRebuild()
        }
        lastIndexJob = job
        try await job.value
        if indexGeneration == generation { indexNeedsRepair = false }
    }

    private func performIndexRebuild() async throws {
        let entities = try await store.all().map(NoteEntity.init)
        // Keep the non-Sendable index local to this serialized job. Sharing an
        // actor property with its concurrent async API violates Swift 6 isolation.
        let index = CSSearchableIndex(name: "FieldNotes.notes")
        try await index.deleteAllSearchableItems()
        try await index.indexAppEntities(entities)
    }
}

@available(iOS 27.0, macOS 27.0, *)
@MainActor @Observable
final class NoteChanges {
    static let shared = NoteChanges()
    private(set) var revision = UUID()
    func committed() { revision = UUID() }
}

@available(iOS 27.0, macOS 27.0, *)
@MainActor @Observable
final class NoteRoute {
    static let shared = NoteRoute()
    var path: [UUID] = []
    func open(_ id: UUID) { path = [id] }
}
