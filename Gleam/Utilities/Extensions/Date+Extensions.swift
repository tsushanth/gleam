import Foundation

extension Date {
    var daysSince: Double {
        Date().timeIntervalSince(self) / 86_400
    }

    func daysSince(_ other: Date) -> Double {
        self.timeIntervalSince(other) / 86_400
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }

    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    static func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return calendar.date(from: components) ?? Date()
    }

    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}
