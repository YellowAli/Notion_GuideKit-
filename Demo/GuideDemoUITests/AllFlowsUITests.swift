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
