import SwiftUI

// RollQuest: iOS 18 deployment target, built with Xcode 16.
struct Player: Codable, Identifiable {
    let id: UUID
    var name: String
    var experience: Int
}

@MainActor
final class GameState: ObservableObject {
    static let shared = GameState()
    @Published private(set) var players: [Player] = []
    private let file = URL.documentsDirectory.appendingPathComponent("players.json")

    init() {
        if let data = try? Data(contentsOf: file) { players = (try? JSONDecoder().decode([Player].self, from: data)) ?? [] }
    }

    func award(_ points: Int, to id: UUID) {
        guard let index = players.firstIndex(where: { $0.id == id }) else { return }
        players[index].experience += points
        try? JSONEncoder().encode(players).write(to: file)
    }

    func rollDice(count: Int, sides: Int) -> [Int] {
        (0..<count).map { _ in Int.random(in: 1...sides) }
    }
}

@main
struct RollQuestApp: App {
    var body: some Scene { WindowGroup { Text("RollQuest") } }
}
