import Foundation
import CoreData
import Combine
import WidgetKit

class CheckInService: ObservableObject {
    static let shared = CheckInService()

    private let coreDataStack: CoreDataStack
    private let cloudKitService: CloudKitSyncService
    @Published var lastCheckIn: CheckIn?

    init(coreDataStack: CoreDataStack = .shared, cloudKitService: CloudKitSyncService = .shared) {
        self.coreDataStack = coreDataStack
        self.cloudKitService = cloudKitService
    }

    func createCheckIn(for parent: Parent, status: CheckInStatus = .pending, notes: String? = nil) -> CheckIn {
        let context = coreDataStack.viewContext
        let checkIn = CheckIn(context: context)
        checkIn.id = UUID()
        checkIn.timestamp = Date()
        checkIn.status = status.rawValue
        checkIn.notes = notes
        checkIn.parent = parent

        coreDataStack.save()
        lastCheckIn = checkIn

        updateWidgetData(parent: parent, status: status, lastCheckInTime: checkIn.timestamp)

        Task {
            do {
                try await cloudKitService.saveToCloud(checkIn)
                print("Check-in synced to CloudKit")
            } catch {
                print("Error syncing check-in to CloudKit: \(error)")
            }
        }

        return checkIn
    }

    func confirmCheckIn(_ checkIn: CheckIn, notes: String? = nil) {
        checkIn.status = CheckInStatus.confirmed.rawValue
        checkIn.timestamp = Date()
        checkIn.notes = notes

        coreDataStack.save()
        lastCheckIn = checkIn

        if let parent = checkIn.parent {
            updateWidgetData(parent: parent, status: .confirmed, lastCheckInTime: checkIn.timestamp)
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "SafeParentsWidget")

        Task {
            do {
                try await cloudKitService.saveToCloud(checkIn)
                print("Check-in confirmation synced to CloudKit")
            } catch {
                print("Error syncing check-in confirmation to CloudKit: \(error)")
            }
        }
    }

    func fetchCheckIns(for parent: Parent, limit: Int? = nil) -> [CheckIn] {
        let request: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
        request.predicate = NSPredicate(format: "parent == %@", parent)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CheckIn.timestamp, ascending: false)]

        if let limit = limit {
            request.fetchLimit = limit
        }

        do {
            return try coreDataStack.viewContext.fetch(request)
        } catch {
            print("Error fetching check-ins: \(error)")
            return []
        }
    }

    func fetchLatestCheckIn(for parent: Parent) -> CheckIn? {
        let request: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
        request.predicate = NSPredicate(format: "parent == %@", parent)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CheckIn.timestamp, ascending: false)]
        request.fetchLimit = 1

        do {
            return try coreDataStack.viewContext.fetch(request).first
        } catch {
            print("Error fetching latest check-in: \(error)")
            return nil
        }
    }

    func deleteCheckIn(_ checkIn: CheckIn) {
        let context = coreDataStack.viewContext
        context.delete(checkIn)
        coreDataStack.save()
    }

    func getCheckInStatus(for parent: Parent) -> CheckInStatus {
        guard let lastCheckIn = fetchLatestCheckIn(for: parent) else {
            return .pending
        }

        let statusRaw = lastCheckIn.status
        let status = CheckInStatus(rawValue: statusRaw) ?? .pending

        if status == .confirmed {
            if let timestamp = lastCheckIn.timestamp {
                let hoursSinceCheckIn = Date().timeIntervalSince(timestamp) / 3600
                if hoursSinceCheckIn > 24 {
                    return .pending
                }
            }
        }

        return status
    }

    func syncFromCloud() async {
        do {
            let records = try await cloudKitService.fetchFromCloud(type: CheckIn.self)
            print("Fetched \(records.count) check-in records from CloudKit")
        } catch {
            print("Error syncing check-ins from CloudKit: \(error)")
        }
    }

    private func updateWidgetData(parent: Parent, status: CheckInStatus, lastCheckInTime: Date?) {
        guard let sharedDefaults = UserDefaults(suiteName: AppConstants.AppGroup.identifier) else {
            return
        }

        sharedDefaults.set(parent.name, forKey: AppConstants.AppGroup.parentName)
        sharedDefaults.set(status.rawValue, forKey: AppConstants.AppGroup.checkInStatus)

        if let lastCheckInTime = lastCheckInTime {
            sharedDefaults.set(lastCheckInTime.timeIntervalSince1970, forKey: AppConstants.AppGroup.lastCheckInTime)
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "SafeParentsWidget")
    }
}
