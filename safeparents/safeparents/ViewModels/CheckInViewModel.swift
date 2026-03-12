import Foundation
import Combine
import SwiftUI

@MainActor
class CheckInViewModel: ObservableObject {
    @Published var parentName: String = "Parent"
    @Published var lastCheckIn: Date?
    @Published var checkInStatus: CheckInStatus = .pending
    @Published var isLoading: Bool = false
    @Published var showSuccessAnimation: Bool = false
    @Published var errorMessage: String?

    private let checkInService: CheckInService
    private let notificationService: NotificationService
    private var currentParent: Parent?

    var greeting: String {
        let timeOfDay = Date().timeOfDay()
        switch timeOfDay {
        case "Morning":
            return "Good Morning"
        case "Afternoon":
            return "Good Afternoon"
        case "Evening":
            return "Good Evening"
        default:
            return "Good Night"
        }
    }

    init(checkInService: CheckInService = .shared, notificationService: NotificationService = .shared) {
        self.checkInService = checkInService
        self.notificationService = notificationService
    }

    func loadParent(_ parent: Parent) {
        currentParent = parent
        parentName = parent.name ?? "Parent"
        refreshStatus()
    }

    func refreshStatus() {
        guard let parent = currentParent else { return }
        checkInStatus = checkInService.getCheckInStatus(for: parent)
        lastCheckIn = checkInService.fetchLatestCheckIn(for: parent)?.timestamp
    }

    func confirmSafety() {
        guard let parent = currentParent else {
            errorMessage = "No parent loaded"
            return
        }

        isLoading = true
        errorMessage = nil

        let checkIn = checkInService.createCheckIn(for: parent, status: .confirmed)
        checkInService.confirmCheckIn(checkIn)

        showSuccessAnimation = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.showSuccessAnimation = false
            self?.isLoading = false
            self?.refreshStatus()
        }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    var lastCheckInText: String {
        guard let lastCheckIn = lastCheckIn else {
            return "No check-ins yet"
        }

        if lastCheckIn.isToday {
            return "Last check-in: Today at \(lastCheckIn.timeString)"
        } else if lastCheckIn.isYesterday {
            return "Last check-in: Yesterday at \(lastCheckIn.timeString)"
        } else {
            return "Last check-in: \(lastCheckIn.relativeString)"
        }
    }

    var statusText: String {
        switch checkInStatus {
        case .pending:
            return "Please confirm you're okay"
        case .confirmed:
            return "✓ You're confirmed safe"
        case .missed:
            return "⚠️ Check-in missed"
        case .custom:
            return "Custom status"
        }
    }

    var statusColor: Color {
        switch checkInStatus {
        case .pending:
            return Color.secondaryText
        case .confirmed:
            return Color.safeGreen
        case .missed:
            return Color.alertRed
        case .custom:
            return Color.infoBlue
        }
    }
}
