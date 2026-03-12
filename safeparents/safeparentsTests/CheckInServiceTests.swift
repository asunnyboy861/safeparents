import XCTest
import CoreData
@testable import safeparents

final class CheckInServiceTests: XCTestCase {
    var coreDataStack: CoreDataStack!
    var checkInService: CheckInService!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack.shared
        checkInService = CheckInService(coreDataStack: coreDataStack)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testCreateCheckIn() {
        let context = coreDataStack.viewContext
        let parent = Parent(context: context)
        parent.id = UUID()
        parent.name = "Test Parent"
        parent.role = "parent"

        let checkIn = checkInService.createCheckIn(for: parent, status: .confirmed)

        XCTAssertNotNil(checkIn.id)
        XCTAssertEqual(checkIn.status, CheckInStatus.confirmed.rawValue)
        XCTAssertNotNil(checkIn.timestamp)
    }

    func testConfirmCheckIn() {
        let context = coreDataStack.viewContext
        let parent = Parent(context: context)
        parent.id = UUID()
        parent.name = "Test Parent"

        let checkIn = checkInService.createCheckIn(for: parent, status: .pending)
        checkInService.confirmCheckIn(checkIn, notes: "All good!")

        XCTAssertEqual(checkIn.status, CheckInStatus.confirmed.rawValue)
        XCTAssertEqual(checkIn.notes, "All good!")
    }

    func testFetchLatestCheckIn() {
        let context = coreDataStack.viewContext
        let parent = Parent(context: context)
        parent.id = UUID()
        parent.name = "Test Parent"

        _ = checkInService.createCheckIn(for: parent, status: .confirmed)

        let latestCheckIn = checkInService.fetchLatestCheckIn(for: parent)

        XCTAssertNotNil(latestCheckIn)
    }

    func testGetCheckInStatus_Confirmed() {
        let context = coreDataStack.viewContext
        let parent = Parent(context: context)
        parent.id = UUID()
        parent.name = "Test Parent"

        let checkIn = checkInService.createCheckIn(for: parent, status: .confirmed)

        let status = checkInService.getCheckInStatus(for: parent)

        XCTAssertEqual(status, .confirmed)
    }

    func testGetCheckInStatus_Pending_After24Hours() {
        let context = coreDataStack.viewContext
        let parent = Parent(context: context)
        parent.id = UUID()
        parent.name = "Test Parent"

        let checkIn = checkInService.createCheckIn(for: parent, status: .confirmed)
        checkIn.timestamp = Date().addingTimeInterval(-25 * 3600)

        let status = checkInService.getCheckInStatus(for: parent)

        XCTAssertEqual(status, .pending)
    }
}
