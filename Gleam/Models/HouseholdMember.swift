import SwiftData
import Foundation

@Model
final class HouseholdMember {
    var id: UUID
    var userID: String
    var displayName: String
    var avatarColor: String
    var joinedAt: Date
    var totalPoints: Int
    var weeklyPoints: Int
    var weeklyPointsResetAt: Date

    var home: Home?

    init(userID: String, displayName: String, avatarColor: String = "#4A90D9") {
        self.id = UUID()
        self.userID = userID
        self.displayName = displayName
        self.avatarColor = avatarColor
        self.joinedAt = .now
        self.totalPoints = 0
        self.weeklyPoints = 0
        self.weeklyPointsResetAt = .now
    }
}
