import SwiftData
import Foundation

@Model
final class Home {
    var id: UUID
    var name: String
    var ownerUserID: String
    var createdAt: Date
    var isPaused: Bool
    var pausedUntil: Date?

    @Relationship(deleteRule: .cascade, inverse: \Room.home)
    var rooms: [Room]

    @Relationship(deleteRule: .cascade, inverse: \HouseholdMember.home)
    var members: [HouseholdMember]

    init(name: String, ownerUserID: String) {
        self.id = UUID()
        self.name = name
        self.ownerUserID = ownerUserID
        self.createdAt = .now
        self.isPaused = false
        self.rooms = []
        self.members = []
    }
}
