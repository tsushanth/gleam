import Foundation

enum RoomIcon: String, CaseIterable, Codable {
    case kitchen     = "fork.knife"
    case bathroom    = "shower"
    case bedroom     = "bed.double"
    case livingRoom  = "sofa"
    case garage      = "car.garage"
    case outdoors    = "leaf"
    case office      = "desktopcomputer"
    case laundry     = "washer"
    case wholeHouse  = "house"
    case custom      = "star"

    var displayName: String {
        switch self {
        case .kitchen:    return "Kitchen"
        case .bathroom:   return "Bathroom"
        case .bedroom:    return "Bedroom"
        case .livingRoom: return "Living Room"
        case .garage:     return "Garage"
        case .outdoors:   return "Outdoors"
        case .office:     return "Office"
        case .laundry:    return "Laundry"
        case .wholeHouse: return "Whole House"
        case .custom:     return "Custom"
        }
    }
}
