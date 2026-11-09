import XCTest
@testable import CalendarFeature

@MainActor
final class EventStoreTests: XCTestCase {
    func testAddEventIncrementsCount() {
        let store = EventStore()
        let before = store.events.count
        store.addEvent()
        XCTAssertEqual(store.events.count, before + 1)
        XCTAssertEqual(store.events.last?.title, EventStore.defaultTitle)
    }

    func testCalendarFlowsValidate() {
        let feature = CalendarGuide.feature(prepare: {})
        XCTAssertEqual(feature.loadErrors, [])
        XCTAssertEqual(feature.flows.map(\.id), ["calendar.create_event"])
    }
}
