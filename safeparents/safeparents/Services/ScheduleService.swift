import Foundation
import CoreData

class ScheduleService: ObservableObject {
    static let shared = ScheduleService()

    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }

    func createSchedule(for parent: Parent, times: [Date] = [], days: [Int] = [1,2,3,4,5], reminderOffset: Int = 60) -> CheckInSchedule {
        let context = coreDataStack.viewContext
        let schedule = CheckInSchedule(context: context)
        schedule.id = UUID()
        schedule.times = times
        schedule.days = days
        schedule.reminderOffset = Int32(reminderOffset)
        schedule.parent = parent

        coreDataStack.save()
        return schedule
    }

    func getSchedule(for parent: Parent) -> CheckInSchedule? {
        return parent.checkInSchedule
    }

    func addCheckInTime(_ time: Date, for schedule: CheckInSchedule) {
        var times = schedule.times ?? []
        times.append(time)
        times.sort { $0.compare($1) == .orderedAscending }
        schedule.times = times
        coreDataStack.save()
    }

    func removeCheckInTime(at index: Int, for schedule: CheckInSchedule) {
        var times = schedule.times ?? []
        guard index < times.count else { return }
        times.remove(at: index)
        schedule.times = times
        coreDataStack.save()
    }

    func updateReminderOffset(_ offset: Int, for schedule: CheckInSchedule) {
        schedule.reminderOffset = Int32(offset)
        coreDataStack.save()
    }

    func updateDays(_ days: [Int], for schedule: CheckInSchedule) {
        schedule.days = days
        coreDataStack.save()
    }

    func shouldCheckInNow(for schedule: CheckInSchedule) -> Bool {
        let days = schedule.days ?? []
        let times = schedule.times ?? []

        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: Date()) - 1
        let currentHour = calendar.component(.hour, from: Date())
        let currentMinute = calendar.component(.minute, from: Date())

        guard days.contains(currentWeekday) else {
            return false
        }

        let currentTimeInMinutes = currentHour * 60 + currentMinute

        for time in times {
            let scheduledHour = calendar.component(.hour, from: time)
            let scheduledMinute = calendar.component(.minute, from: time)
            let scheduledTimeInMinutes = scheduledHour * 60 + scheduledMinute

            if currentTimeInMinutes >= scheduledTimeInMinutes && currentTimeInMinutes < scheduledTimeInMinutes + 30 {
                return true
            }
        }

        return false
    }
}
