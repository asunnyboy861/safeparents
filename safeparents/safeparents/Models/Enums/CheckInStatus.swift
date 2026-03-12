import SwiftUI

enum CheckInStatus: Int16, Codable, CaseIterable {
    case pending = 0
    case confirmed = 1
    case missed = 2
    case custom = 3

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .missed: return "Missed"
        case .custom: return "Custom"
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .confirmed: return "checkmark.circle.fill"
        case .missed: return "exclamationmark.triangle.fill"
        case .custom: return "figure.walk"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .secondaryText
        case .confirmed: return .safeGreen
        case .missed: return .alertRed
        case .custom: return .infoBlue
        }
    }
}
