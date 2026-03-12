import Foundation
import BackgroundTasks
import CoreData

class BackgroundTaskService {
    static let shared = BackgroundTaskService()

    private let backgroundTaskIdentifier = "com.zzoutuo.safeparents.check-missed-checkins"

    private init() {}

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundTask(task)
        }
    }

    func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date().addingTimeInterval(3600)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background task scheduled")
        } catch {
            print("Could not schedule background task: \(error)")
        }
    }

    private func handleBackgroundTask(_ task: BGTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            do {
                try await checkMissedCheckIns()
                await MainActor.run {
                    task.setTaskCompleted(success: true)
                }
                scheduleBackgroundTask()
            } catch {
                print("Background task failed: \(error)")
                await MainActor.run {
                    task.setTaskCompleted(success: false)
                }
            }
        }
    }

    private func checkMissedCheckIns() async throws {
        let context = CoreDataStack.shared.viewContext

        let parentRequest: NSFetchRequest<Parent> = Parent.fetchRequest()
        let parents = try context.fetch(parentRequest)

        for parent in parents {
            guard let schedule = parent.checkInSchedule else { continue }

            let shouldCheckIn = ScheduleService.shared.shouldCheckInNow(for: schedule)

            if shouldCheckIn {
                let lastCheckIn = CheckInService.shared.fetchLatestCheckIn(for: parent)

                if let lastCheckInTime = lastCheckIn?.timestamp {
                    let hoursSinceLastCheckIn = Date().timeIntervalSince(lastCheckInTime) / 3600

                    if hoursSinceLastCheckIn > 1 {
                        try await NotificationService.shared.scheduleMissedCheckInAlert(
                            for: parent,
                            scheduledTime: lastCheckInTime
                        )
                    }
                }
            }
        }
    }
}
