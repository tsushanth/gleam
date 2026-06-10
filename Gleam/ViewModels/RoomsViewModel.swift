import SwiftUI
import SwiftData

@MainActor
final class RoomsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var isAddingRoom = false

    func filteredRooms(_ rooms: [Room]) -> [Room] {
        let sorted = rooms.sorted { $0.aggregateDirtinessScore > $1.aggregateDirtinessScore }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func addRoom(name: String, icon: RoomIcon, to home: Home, context: ModelContext) {
        let sortOrder = home.rooms.count
        let room = Room(name: name, icon: icon.rawValue, sortOrder: sortOrder)
        home.rooms.append(room)
        context.insert(room)
        try? context.save()
        FirebaseAnalyticsService.shared.log(.roomCreated(roomName: name))
    }

    func deleteRoom(_ room: Room, context: ModelContext) {
        context.delete(room)
        try? context.save()
    }
}
