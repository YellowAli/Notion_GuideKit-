import XCTest
@testable import GuideKit

private final class NSLockedBox: @unchecked Sendable {
    private let lock = NSLock()
    private var flag = false
    func set() { lock.lock(); flag = true; lock.unlock() }
    var value: Bool { lock.lock(); defer { lock.unlock() }; return flag }
}

@MainActor
final class GuideControllerTests: XCTestCase {
    private func flow(_ id: String = "t.f", target: String = "a.b", pick: Pick = .first,
                      check: Check = .tapped) -> Flow {
        Flow(id: id, title: "T", steps: [Step(target: target, say: "Go", pick: pick, completeWhen: check)])
    }

    private func controller(_ flows: [Flow], prepare: @escaping @MainActor () -> Void = {},
                            sleep: @escaping @Sendable (Duration) async -> Void = { _ in try? await Task.sleep(for: .seconds(60)) }) -> GuideController {
        GuideController(features: [GuideFeature(flows: flows, prepare: prepare)], sleep: sleep)
    }

    func testLoadsValidFlowsAndKeepsThemWhenAnotherFileIsMalformed() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let good = dir.appendingPathComponent("good.json")
        let bad = dir.appendingPathComponent("bad.json")
        let invalid = dir.appendingPathComponent("invalid.json")
        try JSONEncoder().encode(flow("t.good")).write(to: good)
        try Data("{ nope".utf8).write(to: bad)
        try JSONEncoder().encode(flow("other.x")).write(to: invalid)

        let result = GuideFeature.load(urls: [bad, good, invalid], namespace: "t")
        XCTAssertEqual(result.flows.map(\.id), ["t.good"])
        XCTAssertEqual(result.errors.count, 2)
    }

    func testPickLastUsesLastFrame() {
        let c = controller([flow(pick: .last)])
        c.updateTargets(["a.b": [CGRect(x: 0, y: 0, width: 1, height: 1), CGRect(x: 5, y: 5, width: 2, height: 2)]])
        c.start(flowID: "t.f")
        XCTAssertEqual(c.presentation?.frame, CGRect(x: 5, y: 5, width: 2, height: 2))
        XCTAssertEqual(c.presentation?.say, "Go")
        XCTAssertEqual(c.presentation?.stepIndex, 0)
        XCTAssertEqual(c.presentation?.stepCount, 1)
    }

    func testPresentationFrameClearsWhenTargetDisappears() {
        let c = controller([flow()])
        let r = CGRect(x: 1, y: 1, width: 3, height: 3)
        c.updateTargets(["a.b": [r]])
        c.start(flowID: "t.f")
        XCTAssertEqual(c.presentation?.frame, r)
        c.updateTargets(["a.b": []])
        XCTAssertNotNil(c.presentation)
        XCTAssertNil(c.presentation?.frame)
        c.updateTargets(["a.b": [r]])
        XCTAssertEqual(c.presentation?.frame, r)
    }

    func testPrepareRunsBeforeStart() {
        var prepared = 0
        let c = controller([flow()], prepare: { prepared += 1 })
        c.start(flowID: "unknown")
        XCTAssertEqual(prepared, 0)
        c.start(flowID: "t.f")
        XCTAssertEqual(prepared, 1)
        c.start(flowID: "t.f")
        XCTAssertEqual(prepared, 1, "prepare must not rerun while a flow is active")
        XCTAssertNotNil(c.presentation)
    }

    func testStatusReflectsStepAndFailure() {
        let c = controller([flow(pick: .last, check: .factEquals(key: "a.k", value: .bool(true)))])
        XCTAssertEqual(c.status, GuideStatus(state: "idle", flowID: nil, target: nil, stepIndex: nil, pick: nil, failure: nil, allFlowIDs: ["t.f"]))
        c.updateTargets(["a.b": [.zero]])
        c.start(flowID: "t.f")
        XCTAssertEqual(c.status.state, "waiting")
        XCTAssertEqual(c.status.flowID, "t.f")
        XCTAssertEqual(c.status.target, "a.b")
        XCTAssertEqual(c.status.stepIndex, 0)
        XCTAssertEqual(c.status.pick, .last)
        c.reportFact("a.k", .bool(true))
        XCTAssertEqual(c.status.state, "completed")
        XCTAssertNil(c.presentation)
        XCTAssertEqual(c.status.flowID, "t.f")
    }

    func testTimeoutFailsAfterInjectedSleep() async {
        let c = controller([flow()], sleep: { _ in })
        c.start(flowID: "t.f")
        for task in c.pendingTimeouts { await task.value }
        XCTAssertEqual(c.status.state, "failed")
        XCTAssertEqual(c.status.failure, GuideFailure.targetNotFound(flowID: "t.f", step: 0, target: "a.b").description)
        XCTAssertNil(c.presentation)
    }

    func testStatusIsObservable() {
        let c = controller([flow()])
        let notified = NSLockedBox()
        withObservationTracking { _ = c.status } onChange: { notified.set() }
        c.start(flowID: "t.f")
        XCTAssertTrue(notified.value)
        XCTAssertEqual(c.status.state, "waiting")
    }

    func testLoadRejectsDuplicateFlowIDsAcrossFilesDeterministically() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let a = dir.appendingPathComponent("a.json")
        let b = dir.appendingPathComponent("b.json")
        try JSONEncoder().encode(Flow(id: "t.dup", title: "A", steps: flow().steps)).write(to: a)
        try JSONEncoder().encode(Flow(id: "t.dup", title: "B", steps: flow().steps)).write(to: b)
        let result = GuideFeature.load(urls: [b, a], namespace: "t")
        XCTAssertEqual(result.flows.map(\.title), ["A"])
        XCTAssertEqual(result.errors, ["b.json: " + FlowValidationError.duplicateFlowID("t.dup").description])
    }

    func testFirstFeatureWinsForDuplicateFlowIDsAcrossFeatures() {
        var ran: [String] = []
        let c = GuideController(features: [
            GuideFeature(flows: [flow("t.dup"), flow("t.one")], prepare: { ran.append("first") }),
            GuideFeature(flows: [flow("t.dup"), flow("t.two")], prepare: { ran.append("second") }),
        ])
        XCTAssertEqual(c.status.allFlowIDs, ["t.dup", "t.one", "t.two"])
        XCTAssertEqual(c.flows.map(\.id), ["t.dup", "t.one", "t.two"])
        c.start(flowID: "t.dup")
        XCTAssertEqual(ran, ["first"])
    }

    func testForgottenFactDoesNotBecomeStaleBaseline() {
        let c = controller([flow(check: .factIncreased(key: "a.k", by: 1))])
        c.reportFact("a.k", .int(2))
        c.forgetFact("a.k")
        c.updateTargets(["a.b": [.zero]])
        c.start(flowID: "t.f")
        c.reportFact("a.k", .int(0))
        XCTAssertEqual(c.status.state, "waiting")
        c.reportFact("a.k", .int(1))
        XCTAssertEqual(c.status.state, "completed")
    }

    func testMissingFlowFilesIsALoadError() {
        let result = GuideFeature.load(urls: [], namespace: "t")
        XCTAssertTrue(result.flows.isEmpty)
        XCTAssertEqual(result.errors.count, 1)
        XCTAssertTrue(result.errors[0].contains("`t`"), result.errors[0])
    }
}
