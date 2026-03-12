import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized: Bool = false

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization() async throws -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            throw error
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    func scheduleCheckInReminder(for parent: Parent, at time: Date) async throws {
        if !isAuthorized {
            _ = try await requestAuthorization()
        }

        let content = UNMutableNotificationContent()
        content.title = "Check-In Reminder"
        content.body = "\(parent.name ?? "Your parent"), it's time to confirm you're okay!"
        content.sound = .default
        content.badge = 1

        let reminderTime = Calendar.current.date(byAdding: .minute, value: -60, to: time)!
        let triggerComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)

        let identifier = "checkin-reminder-\(parent.id?.uuidString ?? UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await notificationCenter.add(request)
    }

    func scheduleMissedCheckInAlert(for parent: Parent, scheduledTime: Date) async throws {
        if !isAuthorized { return }

        let content = UNMutableNotificationContent()
        content.title = "Missed Check-In"
        content.body = "\(parent.name ?? "Your parent") hasn't confirmed yet. Please check on them."
        content.sound = .defaultCritical
        content.badge = 1

        let missedTime = Calendar.current.date(byAdding: .hour, value: 1, to: scheduledTime)!
        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: missedTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let identifier = "missed-checkin-\(parent.id?.uuidString ?? UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await notificationCenter.add(request)
    }

    func cancelNotifications(for parent: Parent) {
        let parentID = parent.id?.uuidString ?? ""
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            "checkin-reminder-\(parentID)",
            "missed-checkin-\(parentID)"
        ])
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func clearBadge() {
        Task { @MainActor in
            UNUserNotificationCenter.current().setBadgeCount(0)
        }
    }
}
