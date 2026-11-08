#if os(iOS)
import XCTest
import GuideKit

/// Runs registered walkthroughs against the real app, tapping each step's target through the spotlight.
@MainActor
public struct FlowTestDriver {
    private let testCase: XCTestCase
    private let timeout: TimeInterval

    public init(testCase: XCTestCase, timeout: TimeInterval = 10) {
        self.testCase = testCase
        self.timeout = timeout
    }

    public func allFlowIDs() -> [String] {
        guard let snapshot = readStatus(in: launch(flowID: nil)) else { return [] }
        return snapshot.status.allFlowIDs
    }

    public func run(flowID: String) {
        XCTContext.runActivity(named: "Flow \(flowID)") { _ in
            drive(flowID: flowID)
        }
    }

    public func runAll() {
        let flowIDs = allFlowIDs()
        XCTAssertFalse(flowIDs.isEmpty, "No walkthroughs are registered with the host.")
        flowIDs.forEach(run(flowID:))
    }

    // MARK: - Driving a flow

    private func drive(flowID: String) {
        let app = launch(flowID: flowID)
        guard var snapshot = readStatus(in: app) else { return }
        if snapshot.status.state == "idle" {
            guard let started = waitForChange(from: snapshot, in: app) else {
                XCTFail("`\(flowID)`: the walkthrough never started; is the flow ID registered?")
                return
            }
            snapshot = started
        }

        var lastStep = 1
        while true {
            let status = snapshot.status
            switch status.state {
            case "completed":
                attachScreenshot(of: app, named: "\(flowID)-step\(lastStep)-completed")
                return
            case "failed":
                XCTFail(status.failure ?? "`\(flowID)` failed without a reason")
                return
            case "waiting":
                guard let target = status.target, let index = status.stepIndex else {
                    XCTFail("`\(flowID)`: status is waiting but names no step: \(snapshot.raw)")
                    return
                }
                let step = index + 1
                lastStep = step
                switch waitForTarget(target, pick: status.pick, from: snapshot, in: app) {
                case .changed(let latest):
                    snapshot = latest
                case .timedOut:
                    XCTFail("`\(flowID)` step \(step): target `\(target)` did not appear within \(timeout)s")
                    return
                case .found(let element):
                    attachScreenshot(of: app, named: "\(flowID)-step\(step)")
                    element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                    guard let latest = waitForChange(from: snapshot, in: app) else {
                        XCTFail("`\(flowID)` step \(step): tapping `\(target)` did not advance within \(timeout)s")
                        return
                    }
                    snapshot = latest
                }
            default:
                XCTFail("`\(flowID)`: walkthrough ended unexpectedly with status \(snapshot.raw)")
                return
            }
        }
    }

    private func launch(flowID: String?) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["GUIDEKIT_TEST"] = "1"
        app.launchEnvironment["GUIDEKIT_TEST_FLOW"] = flowID
        app.launch()
        return app
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        testCase.add(attachment)
    }

    // MARK: - Status

    private struct Snapshot {
        var raw: String
        var status: GuideStatus
    }

    private enum TargetWait {
        case found(XCUIElement)
        case changed(Snapshot)
        case timedOut
    }

    private func statusElement(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["guidekit.status"]
    }

    private func readStatus(in app: XCUIApplication) -> Snapshot? {
        let element = statusElement(in: app)
        guard element.waitForExistence(timeout: timeout) else {
            XCTFail("`guidekit.status` not found; is the app using guideHost?")
            return nil
        }
        guard let raw = element.value as? String,
              let status = try? JSONDecoder().decode(GuideStatus.self, from: Data(raw.utf8)) else {
            XCTFail("`guidekit.status` has an unreadable value: \(String(describing: element.value))")
            return nil
        }
        return Snapshot(raw: raw, status: status)
    }

    /// Waits for the status to differ from `snapshot`. Returns nil on timeout.
    private func waitForChange(from snapshot: Snapshot, in app: XCUIApplication) -> Snapshot? {
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value != %@", snapshot.raw),
                                                object: statusElement(in: app))
        guard XCTWaiter().wait(for: [changed], timeout: timeout) == .completed else { return nil }
        return readStatus(in: app)
    }

    /// Waits until the target exists or the status moves on, so a missing target surfaces the runtime's failure.
    private func waitForTarget(_ target: String, pick: Pick?, from snapshot: Snapshot,
                               in app: XCUIApplication) -> TargetWait {
        let query = app.descendants(matching: .any).matching(identifier: target)
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if query.firstMatch.waitForExistence(timeout: 0.25) {
                let last = pick == .last ? query.allElementsBoundByIndex.last : nil
                return .found(last ?? query.firstMatch)
            }
            guard let latest = readStatus(in: app) else { return .timedOut }
            if latest.raw != snapshot.raw { return .changed(latest) }
        }
        return .timedOut
    }
}
#endif
