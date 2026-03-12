import Foundation
import CoreData

class FamilyService: ObservableObject {
    static let shared = FamilyService()

    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }

    func createFamilyCircle(name: String) -> FamilyCircle {
        let context = coreDataStack.viewContext
        let family = FamilyCircle(context: context)
        family.id = UUID()
        family.name = name
        family.iCloudShareID = nil

        coreDataStack.save()
        return family
    }

    func getFamilyCircle(for parent: Parent) -> FamilyCircle? {
        return parent.familyCircle
    }

    func addMember(name: String, role: UserRole, to family: FamilyCircle) -> Parent {
        let context = coreDataStack.viewContext
        let parent = Parent(context: context)
        parent.id = UUID()
        parent.name = name
        parent.role = role.rawValue
        parent.timeZone = TimeZone.current.identifier
        parent.familyCircle = family

        let schedule = CheckInSchedule(context: context)
        schedule.id = UUID()
        schedule.times = []
        schedule.days = [1,2,3,4,5]
        schedule.reminderOffset = 60
        schedule.parent = parent
        parent.checkInSchedule = schedule

        coreDataStack.save()
        return parent
    }

    func removeMember(_ parent: Parent) {
        let context = coreDataStack.viewContext
        context.delete(parent)
        coreDataStack.save()
    }

    func fetchAllMembers(in family: FamilyCircle) -> [Parent] {
        let request: NSFetchRequest<Parent> = Parent.fetchRequest()
        request.predicate = NSPredicate(format: "familyCircle == %@", family)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Parent.name, ascending: true)]

        do {
            return try coreDataStack.viewContext.fetch(request)
        } catch {
            print("Error fetching family members: \(error)")
            return []
        }
    }

    func deleteFamilyCircle(_ family: FamilyCircle) {
        let context = coreDataStack.viewContext
        context.delete(family)
        coreDataStack.save()
    }
}
