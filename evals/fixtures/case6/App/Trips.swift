import AppIntents
import Foundation

// FieldTrips: iOS 27 app. People use these App Shortcuts with Siri today.
struct Trip: Codable, Identifiable { let id: UUID; var name: String; var stops: [String]; var isActive: Bool }

actor TripStore {
    static let shared = TripStore()
    private var trips: [Trip] = []   // persisted to disk in the real app
    func all() -> [Trip] { trips }
    func start(name: String) -> Trip { let trip = Trip(id: UUID(), name: name, stops: [], isActive: true); trips.append(trip); return trip }
    func addStop(_ place: String, to id: UUID) throws -> Trip {
        guard let index = trips.firstIndex(where: { $0.id == id }) else { throw CocoaError(.fileNoSuchFile) }
        trips[index].stops.append(place); return trips[index]
    }
}

struct TripEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Trip"
    static let defaultQuery = TripQuery()
    let id: UUID
    var name: String
    var displayRepresentation: DisplayRepresentation { "\(name)" }
}

struct TripQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [TripEntity] {
        await TripStore.shared.all().filter { identifiers.contains($0.id) }.map { TripEntity(id: $0.id, name: $0.name) }
    }
    func entities(matching string: String) async throws -> [TripEntity] {
        await TripStore.shared.all().filter { $0.name.localizedStandardContains(string) }.map { TripEntity(id: $0.id, name: $0.name) }
    }
    func suggestedEntities() async throws -> [TripEntity] {
        await TripStore.shared.all().filter(\.isActive).map { TripEntity(id: $0.id, name: $0.name) }
    }
}

struct StartTripIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Trip"
    @Parameter(title: "Name") var name: String
    func perform() async throws -> some ReturnsValue<TripEntity> & ProvidesDialog {
        let trip = await TripStore.shared.start(name: name)
        return .result(value: TripEntity(id: trip.id, name: trip.name), dialog: "Started \(trip.name).")
    }
}

struct LogStopIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Stop"
    @Parameter(title: "Trip") var trip: TripEntity
    @Parameter(title: "Place") var place: String
    func perform() async throws -> some IntentResult & ProvidesDialog {
        _ = try await TripStore.shared.addStop(place, to: trip.id)
        return .result(dialog: "Logged \(place).")
    }
}

struct FieldTripsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartTripIntent(), phrases: ["Start a trip in \(.applicationName)"], shortTitle: "Start Trip", systemImageName: "figure.hiking")
        AppShortcut(intent: LogStopIntent(), phrases: ["Log a stop in \(.applicationName)"], shortTitle: "Log Stop", systemImageName: "mappin")
    }
}
