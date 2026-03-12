import Foundation

struct AppConstants {
    struct CheckIn {
        static let defaultTimeoutMinutes: Int = 60
        static let maxScheduleTimes: Int = 5
        static let defaultReminderMinutes: Int = 60
    }

    struct UI {
        static let checkInButtonSize: CGFloat = 200
        static let checkInIconSize: CGFloat = 60
        static let checkInFontSize: CGFloat = 32
        static let headlineFontSize: CGFloat = 28
        static let bodyFontSize: CGFloat = 17
        static let captionFontSize: CGFloat = 14
        static let cornerRadius: CGFloat = 16
        static let standardPadding: CGFloat = 16
        static let largePadding: CGFloat = 24
    }

    struct Animation {
        static let springResponse: Double = 0.3
        static let springDamping: Double = 0.7
    }

    struct CloudKit {
        static let containerIdentifier: String = "iCloud.com.zzoutuo.safeparents"
    }

    struct UserDefaults {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let currentUserRole = "currentUserRole"
        static let lastSyncDate = "lastSyncDate"
    }

    struct AppGroup {
        static let identifier = "group.com.zzoutuo.safeparents"
        static let parentName = "parentName"
        static let checkInStatus = "checkInStatus"
        static let lastCheckInTime = "lastCheckInTime"
    }
}
