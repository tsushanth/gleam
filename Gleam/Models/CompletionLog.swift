import SwiftData
import Foundation

@Model
final class CompletionLog {
    var id: UUID
    var completedAt: Date
    var completedByUserID: String
    var notes: String?
    var durationMinutes: Int?

    var task: CleaningTask?

    init(completedByUserID: String, notes: String? = nil) {
        self.id = UUID()
        self.completedAt = .now
        self.completedByUserID = completedByUserID
        self.notes = notes
    }
}
