import Foundation

// Shoebox: iOS 27 photo organizer, Xcode 27. Photos sync across the user's devices
// through the app's own server; each photo has a server-assigned `serverID`.
struct Photo: Codable, Identifiable {
    let id: UUID            // local database row ID, differs per device
    let serverID: String    // stable across devices
    var tags: Set<String>
}

actor PhotoLibrary {
    static let shared = PhotoLibrary()
    private var photos: [UUID: Photo] = [:]
    func all() -> [Photo] { Array(photos.values) }
    func photos(withServerIDs ids: [String]) -> [Photo] { photos.values.filter { ids.contains($0.serverID) } }
    /// Saves locally, then uploads the change. The server applies tag edits idempotently per (serverID, tag).
    func addTag(_ tag: String, toServerIDs ids: [String]) async throws {
        for id in ids { if let key = photos.first(where: { $0.value.serverID == id })?.key { photos[key]?.tags.insert(tag) } }
        try await SyncClient.shared.uploadTagChange(tag: tag, serverIDs: ids)
    }
}

actor SyncClient {
    static let shared = SyncClient()
    func uploadTagChange(tag: String, serverIDs: [String]) async throws { /* POSTs to the app server in batches of 500 */ }
}
