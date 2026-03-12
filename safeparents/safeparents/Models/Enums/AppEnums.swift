import Foundation

enum NotificationType: String, Codable {
    case reminder = "reminder"
    case missedCheckIn = "missed_check_in"
    case confirmed = "confirmed"
    case emergency = "emergency"
}

enum UserRole: String, Codable {
    case parent = "parent"
    case child = "child"
    case admin = "admin"
}
