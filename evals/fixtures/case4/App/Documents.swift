import AppIntents
import SwiftUI

// Paperwork: iOS 27 app. Documents are saved as JSON files in Application Support.
struct Document: Codable, Identifiable { let id: UUID; var title: String; var body: String }

enum DocumentFiles {
    static let folder = URL.applicationSupportDirectory.appendingPathComponent("Documents", isDirectory: true)
    static func loadAll() throws -> [Document] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        return try urls.map { try JSONDecoder().decode(Document.self, from: Data(contentsOf: $0)) }
    }
}

@MainActor
final class DocumentCache {
    static let shared = DocumentCache()
    var documents: [Document] = []
}

struct DocumentEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Document"
    static let defaultQuery = DocumentQuery()
    let id: UUID
    var title: String
    var displayRepresentation: DisplayRepresentation { "\(title)" }
}

struct DocumentQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [DocumentEntity] {
        await DocumentCache.shared.documents.filter { identifiers.contains($0.id) }.map { DocumentEntity(id: $0.id, title: $0.title) }
    }
    func entities(matching string: String) async throws -> [DocumentEntity] {
        await DocumentCache.shared.documents.filter { $0.title.localizedStandardContains(string) }.map { DocumentEntity(id: $0.id, title: $0.title) }
    }
}

struct FindDocumentIntent: AppIntent {
    static let title: LocalizedStringResource = "Find Document"
    @Parameter(title: "Title") var title: String
    func perform() async throws -> some ReturnsValue<[DocumentEntity]> {
        .result(value: try await DocumentQuery().entities(matching: title))
    }
}

struct DocumentListView: View {
    @State private var documents: [Document] = []
    var body: some View {
        List(documents) { Text($0.title) }
            .onAppear {
                documents = (try? DocumentFiles.loadAll()) ?? []
                DocumentCache.shared.documents = documents
            }
    }
}

@main
struct PaperworkApp: App { var body: some Scene { WindowGroup { DocumentListView() } } }
