import XCTest
import GuideKitTesting

@MainActor
final class AllFlowsUITests: XCTestCase {
    private let timeout: TimeInterval = 10
    /// How long a blocked tap gets to show any effect before we conclude it had none.
    private let blockedTapWindow: TimeInterval = 1.5

    func testEveryRegisteredFlowCompletes() {
        FlowTestDriver(testCase: self).runAll()
    }

    func testTapOutsideHoleIsBlocked() {
        let app = launch(flowID: "editor.add_todo")
        waitForStatus(in: app, state: "waiting", flowID: "editor.add_todo", stepIndex: 0)

        let share = element("editor.share_button", in: app)
        XCTAssertTrue(share.waitForExistence(timeout: timeout))
        let linkCopied = app.staticTexts["Link copied"]
        let blockMenu = element("editor.block_menu_todo", in: app)

        share.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        assertNeverAppears(linkCopied, "The Share button received a tap through the dim.")
        XCTAssertFalse(blockMenu.exists, "A tap outside the hole opened the block menu.")
        XCTAssertEqual(currentStatus(in: app)?.stepIndex, 0, "A tap outside the hole changed the step.")

        tapCenter(of: element("editor.add_block_button", in: app))
        waitForStatus(in: app, state: "waiting", flowID: "editor.add_todo", stepIndex: 1)
        XCTAssertTrue(blockMenu.waitForExistence(timeout: timeout))

        // With the walkthrough over, the same control must respond, so the blocked tap above was meaningful.
        tapCenter(of: blockMenu)
        waitForStatus(in: app, state: "completed", flowID: "editor.add_todo")
        tapCenter(of: share)
        XCTAssertTrue(linkCopied.waitForExistence(timeout: timeout), "Share should respond once the dim is gone.")
    }

    func testExitEndsWalkthrough() {
        let app = launch(flowID: "editor.add_todo")
        waitForStatus(in: app, state: "waiting", flowID: "editor.add_todo", stepIndex: 0)

        let exit = element("guide.exit", in: app)
        XCTAssertTrue(exit.waitForExistence(timeout: timeout))
        exit.tap()

        waitForStatus(in: app, state: "idle")
        XCTAssertFalse(exit.exists, "Exit should disappear with the walkthrough.")
    }

    func testMenuStartsWalkthrough() {
        let app = launch(flowID: nil)
        waitForStatus(in: app, state: "idle")

        let openMenu = element("guide.open_menu", in: app)
        XCTAssertTrue(openMenu.waitForExistence(timeout: timeout))
        openMenu.tap()

        let item = element("guide.menu.editor.add_todo", in: app)
        XCTAssertTrue(item.waitForExistence(timeout: timeout))
        item.tap()

        waitForStatus(in: app, state: "waiting", flowID: "editor.add_todo", stepIndex: 0)
    }

    func testNewEventThenSaveWithoutWalkthrough() {
        let app = launch(flowID: nil)
        waitForStatus(in: app, state: "idle")
        tapTab("calendar", in: app)

        let newEvent = element("calendar.new_event", in: app)
        XCTAssertTrue(newEvent.waitForExistence(timeout: timeout))
        let events = app.descendants(matching: .any).matching(identifier: "calendar.event")
        XCTAssertEqual(events.count, 1, "Calendar should start with its seeded event.")
        tapCenter(of: newEvent)

        let save = element("calendar.save", in: app)
        XCTAssertTrue(save.waitForExistence(timeout: timeout))
        let launcher = element("guide.open_menu", in: app)
        XCTAssertFalse(save.frame.intersects(launcher.frame), "The ? button covers Save.")
        tapCenter(of: save)

        waitForCount(of: events, toEqual: 2)
    }

    func testBlockSurvivesSwitchingTabs() {
        let app = launch(flowID: nil)
        waitForStatus(in: app, state: "idle")
        addBlock("editor.block_menu_todo", in: app)
        let todo = element("editor.block.todo", in: app)
        XCTAssertTrue(todo.waitForExistence(timeout: timeout))

        tapTab("calendar", in: app)
        XCTAssertTrue(element("calendar.new_event", in: app).waitForExistence(timeout: timeout))
        tapTab("editor", in: app)

        XCTAssertTrue(element("editor.add_block_button", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(todo.waitForExistence(timeout: timeout), "The added block was lost when switching tabs.")
    }

    func testFlowStartedWithBlockMenuOpenCompletes() {
        let app = launch(flowID: nil)
        waitForStatus(in: app, state: "idle")

        let plus = element("editor.add_block_button", in: app)
        XCTAssertTrue(plus.waitForExistence(timeout: timeout))
        tapCenter(of: plus)
        let todoItem = element("editor.block_menu_todo", in: app)
        XCTAssertTrue(todoItem.waitForExistence(timeout: timeout))

        startFromMenu("editor.add_todo", in: app)
        waitForStatus(in: app, state: "waiting", flowID: "editor.add_todo", stepIndex: 0)
        waitForAbsence(of: todoItem)

        tapCenter(of: plus)
        waitForStatus(in: app, state: "waiting", flowID: "editor.add_todo", stepIndex: 1)
        XCTAssertTrue(todoItem.waitForExistence(timeout: timeout))
        tapCenter(of: todoItem)
        waitForStatus(in: app, state: "completed", flowID: "editor.add_todo")
    }

    func testFlowStartedWithTurnIntoPanelOpenCompletes() {
        let app = launch(flowID: nil)
        waitForStatus(in: app, state: "idle")

        let handle = element("editor.block_handle", in: app)
        XCTAssertTrue(handle.waitForExistence(timeout: timeout))
        tapCenter(of: handle)
        let toggleItem = element("editor.turn_into_toggle", in: app)
        XCTAssertTrue(toggleItem.waitForExistence(timeout: timeout))

        startFromMenu("editor.turn_into_toggle", in: app)
        waitForStatus(in: app, state: "waiting", flowID: "editor.turn_into_toggle", stepIndex: 0)
        waitForAbsence(of: toggleItem)

        tapCenter(of: handle)
        waitForStatus(in: app, state: "waiting", flowID: "editor.turn_into_toggle", stepIndex: 1)
        XCTAssertTrue(toggleItem.waitForExistence(timeout: timeout))
        tapCenter(of: toggleItem)
        waitForStatus(in: app, state: "completed", flowID: "editor.turn_into_toggle")
    }

    // MARK: - Helpers

    private func launch(flowID: String?) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["GUIDEKIT_TEST"] = "1"
        app.launchEnvironment["GUIDEKIT_TEST_FLOW"] = flowID
        app.launch()
        return app
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func tapTab(_ tab: String, in app: XCUIApplication) {
        let button = element("tab.\(tab)", in: app)
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        tapCenter(of: button)
    }

    private func waitForCount(of query: XCUIElementQuery, toEqual count: Int,
                              file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == %d", count), object: query)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed,
                       "Expected \(count) matches, found \(query.count)", file: file, line: line)
    }

    private func addBlock(_ menuItem: String, in app: XCUIApplication) {
        let plus = element("editor.add_block_button", in: app)
        XCTAssertTrue(plus.waitForExistence(timeout: timeout))
        tapCenter(of: plus)
        let item = element(menuItem, in: app)
        XCTAssertTrue(item.waitForExistence(timeout: timeout))
        tapCenter(of: item)
    }

    private func startFromMenu(_ flowID: String, in app: XCUIApplication) {
        let openMenu = element("guide.open_menu", in: app)
        XCTAssertTrue(openMenu.waitForExistence(timeout: timeout))
        openMenu.tap()
        let item = element("guide.menu.\(flowID)", in: app)
        XCTAssertTrue(item.waitForExistence(timeout: timeout))
        item.tap()
    }

    private func waitForAbsence(of element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: timeout), .completed,
                       "\(element) should have gone away.", file: file, line: line)
    }

    private func tapCenter(of element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func currentStatus(in app: XCUIApplication) -> GuideStatus? {
        guard let raw = element("guidekit.status", in: app).value as? String else { return nil }
        return try? JSONDecoder().decode(GuideStatus.self, from: Data(raw.utf8))
    }

    private func waitForStatus(in app: XCUIApplication, state: String, flowID: String? = nil, stepIndex: Int? = nil,
                               file: StaticString = #filePath, line: UInt = #line) {
        var fragments = ["\"state\":\"\(state)\""]
        if let flowID { fragments.append("\"flowID\":\"\(flowID)\"") }
        if let stepIndex { fragments.append("\"stepIndex\":\(stepIndex)") }
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: fragments.map {
            NSPredicate(format: "value CONTAINS %@", $0)
        })
        let status = element("guidekit.status", in: app)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: status)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Expected \(fragments), last status: \(String(describing: status.value))",
                       file: file, line: line)
    }

    private func assertNeverAppears(_ element: XCUIElement, _ message: String,
                                    file: StaticString = #filePath, line: UInt = #line) {
        let appeared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true"), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [appeared], timeout: blockedTapWindow), .timedOut, message,
                       file: file, line: line)
    }
}
