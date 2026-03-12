import Foundation
import CloudKit
import CoreData
import Combine

class CloudKitSyncService: ObservableObject {
    static let shared = CloudKitSyncService()

    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let coreDataStack: CoreDataStack

    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?

    private init() {
        self.container = CKContainer(identifier: AppConstants.CloudKit.containerIdentifier)
        self.privateDatabase = container.privateCloudDatabase
        self.coreDataStack = CoreDataStack.shared
        loadLastSyncDate()
    }

    private func loadLastSyncDate() {
        if let timestamp = UserDefaults.standard.object(forKey: AppConstants.UserDefaults.lastSyncDate) as? Date {
            lastSyncDate = timestamp
        }
    }

    private func saveLastSyncDate() {
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: AppConstants.UserDefaults.lastSyncDate)
    }

    func checkAccountStatus() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            print("Error checking CloudKit account status: \(error)")
            return false
        }
    }

    func saveToCloud<T: NSManagedObject>(_ object: T) async throws {
        let record = try createRecord(from: object)
        _ = try await privateDatabase.save(record)
        saveLastSyncDate()
    }

    func fetchFromCloud<T: NSManagedObject>(type: T.Type) async throws -> [CKRecord] {
        let query = CKQuery(recordType: String(describing: type), predicate: NSPredicate(value: true))
        let (matchResults, _) = try await privateDatabase.records(matching: query)

        return matchResults.compactMap { _, result in
            try? result.get()
        }
    }

    func deleteFromCloud(_ recordID: CKRecord.ID) async throws {
        try await privateDatabase.deleteRecord(withID: recordID)
    }

    func syncAllData() async {
        guard !isSyncing else { return }

        await MainActor.run {
            isSyncing = true
            syncError = nil
        }

        let hasAccount = await checkAccountStatus()
        guard hasAccount else {
            await MainActor.run {
                syncError = CloudKitError.noAccount
                isSyncing = false
            }
            return
        }

        do {
            try await syncCheckIns()
            try await syncSchedules()
            try await syncFamilyCircles()

            await MainActor.run {
                saveLastSyncDate()
                isSyncing = false
            }
        } catch {
            await MainActor.run {
                syncError = error
                isSyncing = false
            }
        }
    }

    private func syncCheckIns() async throws {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()

        let localCheckIns = try context.fetch(request)

        for checkIn in localCheckIns {
            if checkIn.timestamp != nil {
                let record = createCheckInRecord(checkIn)
                _ = try await privateDatabase.save(record)
            }
        }

        let query = CKQuery(recordType: "CheckIn", predicate: NSPredicate(value: true))
        let (matchResults, _) = try await privateDatabase.records(matching: query)

        for (_, result) in matchResults {
            guard let record = try? result.get() else { continue }
            try await processRemoteCheckInRecord(record)
        }
    }

    private func syncSchedules() async throws {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<CheckInSchedule> = CheckInSchedule.fetchRequest()

        let localSchedules = try context.fetch(request)

        for schedule in localSchedules {
            let record = createScheduleRecord(schedule)
            _ = try await privateDatabase.save(record)
        }
    }

    private func syncFamilyCircles() async throws {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<FamilyCircle> = FamilyCircle.fetchRequest()

        let localFamilies = try context.fetch(request)

        for family in localFamilies {
            let record = createFamilyRecord(family)
            _ = try await privateDatabase.save(record)
        }
    }

    private func createRecord(from object: NSManagedObject) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: object.objectID.uriRepresentation().absoluteString)
        let record = CKRecord(recordType: String(describing: type(of: object)), recordID: recordID)

        let keys = Array(object.entity.attributesByName.keys)
        for (key, value) in object.dictionaryWithValues(forKeys: keys) {
            if !(value is NSNull) {
                record[key] = value as? CKRecordValue
            }
        }

        return record
    }

    private func createCheckInRecord(_ checkIn: CheckIn) -> CKRecord {
        let recordID = CKRecord.ID(recordName: checkIn.id?.uuidString ?? UUID().uuidString)
        let record = CKRecord(recordType: "CheckIn", recordID: recordID)

        record["id"] = checkIn.id?.uuidString
        record["timestamp"] = checkIn.timestamp
        record["status"] = checkIn.status
        record["notes"] = checkIn.notes

        return record
    }

    private func createScheduleRecord(_ schedule: CheckInSchedule) -> CKRecord {
        let recordID = CKRecord.ID(recordName: schedule.id?.uuidString ?? UUID().uuidString)
        let record = CKRecord(recordType: "CheckInSchedule", recordID: recordID)

        record["id"] = schedule.id?.uuidString
        record["reminderOffset"] = schedule.reminderOffset

        return record
    }

    private func createFamilyRecord(_ family: FamilyCircle) -> CKRecord {
        let recordID = CKRecord.ID(recordName: family.id?.uuidString ?? UUID().uuidString)
        let record = CKRecord(recordType: "FamilyCircle", recordID: recordID)

        record["id"] = family.id?.uuidString
        record["name"] = family.name

        return record
    }

    private func processRemoteCheckInRecord(_ record: CKRecord) async throws {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString) else { return }

        let context = coreDataStack.viewContext
        let request: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        let existingCheckIns = try context.fetch(request)

        if let existingCheckIn = existingCheckIns.first {
            if let remoteTimestamp = record["timestamp"] as? Date,
               let localTimestamp = existingCheckIn.timestamp,
               remoteTimestamp > localTimestamp {
                existingCheckIn.status = record["status"] as? Int16 ?? 0
                existingCheckIn.timestamp = remoteTimestamp
                existingCheckIn.notes = record["notes"] as? String
            }
        } else {
            let newCheckIn = CheckIn(context: context)
            newCheckIn.id = id
            newCheckIn.timestamp = record["timestamp"] as? Date
            newCheckIn.status = record["status"] as? Int16 ?? 0
            newCheckIn.notes = record["notes"] as? String
        }

        coreDataStack.save()
    }

    enum CloudKitError: LocalizedError {
        case noAccount
        case syncFailed

        var errorDescription: String? {
            switch self {
            case .noAccount:
                return "Please sign in to iCloud to sync your data"
            case .syncFailed:
                return "Failed to sync data with iCloud"
            }
        }
    }
}
