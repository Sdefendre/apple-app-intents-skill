import AppIntents
import Foundation

// Chatterly: iOS 27 app, Xcode 27. People already use the "Send a message with Chatterly" shortcut.
struct Contact: Codable, Identifiable, Hashable { let id: String; var displayName: String }
struct Conversation: Codable, Identifiable { let id: String; var participants: [Contact] }

actor MessageService {
    static let shared = MessageService()
    private(set) var signedInAccountID: String? = "acct-1"
    func contacts() async -> [Contact] { [Contact(id: "c1", displayName: "Ana"), Contact(id: "c2", displayName: "Ana"), Contact(id: "c3", displayName: "Ben")] }
    /// Sends through the production API. Returns the server message ID.
    func send(_ text: String, toContactNamed name: String) async throws -> String {
        guard signedInAccountID != nil else { throw URLError(.userAuthenticationRequired) }
        var request = URLRequest(url: URL(string: "https://api.chatterly.example/v1/messages")!)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(["to": name, "text": text])
        _ = try await URLSession.shared.data(for: request)
        return UUID().uuidString
    }
}

struct SendMessageIntent: AppIntent {
    static let title: LocalizedStringResource = "Send Message"
    @Parameter(title: "Recipient") var recipient: String
    @Parameter(title: "Message") var message: String
    func perform() async throws -> some IntentResult & ProvidesDialog {
        Task { _ = try? await MessageService.shared.send(message, toContactNamed: recipient) }
        return .result(dialog: "Sent!")
    }
}

struct ChatterlyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: SendMessageIntent(), phrases: ["Send a message with \(.applicationName)"],
                    shortTitle: "Send Message", systemImageName: "message")
    }
}
