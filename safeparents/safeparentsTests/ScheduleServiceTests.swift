import XCTest
import CoreData
@testable import safeparents

final class ScheduleServiceTests: XCTestCase {
    var coreDataStack: CoreDataStack!
    var scheduleService: ScheduleService!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack.shared
        scheduleService = ScheduleService(coreDataStack: coreDataStack)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testCreateSchedule() {
        let context = coreDataStack.viewContext
        let parent = Parent(context: context)
        parent.id = UUID()
        parent.name = "Test Parent"

        let times = [Date()] as NSObject
        let days = [1, 2, 3, 4, 5] as NSObject

        let schedule = scheduleService.createSchedule(
            for: parent,
            times: [Date()],
            days: [1, 2, 3, 4, 5],
            reminderOffset: 60
        )

        XCTAssertNotNil(schedule.id)
        XCTAssertNotNil(schedule.times)
        XCTAssertEqual(schedule.reminderOffset, 60)
    }

    func testAddCheckInTime() {
        let context = coreDataStack.viewContext
        let parent = Parent(context: context)
        parent.id = UUID()
        parent.name = "Test Parent"

        let schedule = scheduleService.createSchedule(for: parent)

        let newTime = Date.from(hour: 9, minute: 0) ?? Date()
        scheduleService.addCheckInTime(newTime, for: schedule)

        let times = schedule.times as? [Date]
        XCTAssertEqual(times?.count, 1)
    }

    func testRemoveCheckInTime() {
        let context = coreDataStack.viewContext
        let parent = Parent(context: context)
        parent.id = UUID()
        parent.name = "Test Parent"

        let time1 = Date.from(hour: 9, minute: 0) ?? Date()
        let time2 = Date.from(hour: 18, minute: 0) ?? Date()

        let schedule = scheduleService.createSchedule(
            for: parent,
            times: [time1, time2],
            days: [1, 2, 3, 4, 5]
        )

        scheduleService.removeCheckInTime(at: 0, for: schedule)

        let times = schedule.times as? [Date]
        XCTAssertEqual(times?.count, 1)
    }

    func testUpdateReminderOffset() {
        let context = coreDataStack.viewContext
        let parent = Parent(context: context)
        parent.id = UUID()
        parent.name = "Test Parent"

        let schedule = scheduleService.createSchedule(for: parent)

        scheduleService.updateReminderOffset(120, for: schedule)

        XCTAssertEqual(schedule.reminderOffset, 120)
    }

    func testShouldCheckInNow_True() {
        let context = coreDataStack.viewContext
        let parent = Parent(context: context)
        parent.id = UUID()
        parent.name = "Test Parent"

        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentWeekday = calendar.component(.weekday, from: now) - 1

        let targetTime = calendar.date(bySettingHour: currentHour, minute: currentMinute, second: 0, of: now) ?? now

        let schedule = scheduleService.createSchedule(
            for: parent,
            times: [targetTime],
            days: [currentWeekday]
        )

        let shouldCheckIn = scheduleService.shouldCheckInNow(for: schedule)

        XCTAssertTrue(shouldCheckIn, "Should check in when current time matches scheduled time")
    }

    func testShouldCheckInNow_False_WrongDay() {
        let context = coreDataStack.viewContext
        let parent = Parent(context: context)
        parent.id = UUID()
        parent.name = "Test Parent"

        let schedule = scheduleService.createSchedule(
            for: parent,
            times: [Date()],
            days: [6, 0]
        )

        let shouldCheckIn = scheduleService.shouldCheckInNow(for: schedule)

        XCTAssertFalse(shouldCheckIn)
    }

    func testShouldCheckInNow_False_TimeNotReached() {
        let context = coreDataStack.viewContext
        let parent = Parent(context: context)
        parent.id = UUID()
        parent.name = "Test Parent"

        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now) - 1

        let futureHour = (calendar.component(.hour, from: now) + 5) % 24
        let targetTime = calendar.date(bySettingHour: futureHour, minute: 0, second: 0, of: now) ?? now

        let schedule = scheduleService.createSchedule(
            for: parent,
            times: [targetTime],
            days: [currentWeekday]
        )

        let shouldCheckIn = scheduleService.shouldCheckInNow(for: schedule)

        XCTAssertFalse(shouldCheckIn, "Should not check in when scheduled time has not been reached")
    }
}
