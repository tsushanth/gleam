import SwiftUI

enum DirtinessLevel: String, CaseIterable {
    case clean
    case soon
    case needsIt
    case urgent

    var color: Color {
        switch self {
        case .clean:    return Color("GleamGreen")
        case .soon:     return Color("GleamYellow")
        case .needsIt:  return Color("GleamOrange")
        case .urgent:   return Color("GleamRed")
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .clean:    return "Clean"
        case .soon:     return "Due soon"
        case .needsIt:  return "Needs cleaning"
        case .urgent:   return "Urgent — clean now"
        }
    }
}
