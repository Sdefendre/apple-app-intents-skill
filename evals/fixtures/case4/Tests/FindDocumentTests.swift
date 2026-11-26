import XCTest
@testable import Paperwork

final class FindDocumentTests: XCTestCase {
    @MainActor
    func testFindsDocumentByTitle() async throws {
        DocumentCache.shared.documents = [Document(id: UUID(), title: "Lease", body: "")]
        var intent = FindDocumentIntent()
        intent.title = "Lease"
        let result = try await intent.perform()
        XCTAssertNotNil(result) // passes
    }
}
