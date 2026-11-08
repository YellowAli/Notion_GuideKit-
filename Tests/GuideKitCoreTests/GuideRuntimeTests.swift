import XCTest
@testable import GuideKitCore

final class GuideRuntimeTests: XCTestCase {
    private func flow(_ steps: [Step], id: String = "calendar.create_event") -> Flow {
        Flow(id: id, title: "T", steps: steps)
    }

    private func step(_ target: String, _ check: Check) -> Step {
        Step(target: target, say: "say \(target)", completeWhen: check)
    }

    func testHappyPathAdvancesAndCompletes() {
        var rt = GuideRuntime()
        let s1 = step("a", .tapped), s2 = step("b", .targetVisible("c"))
        let f = flow([s1, s2])
        XCTAssertEqual(rt.handle(.start(f, targets: ["a", "b"], facts: [:])), [.present(step: 0, s1)])
        XCTAssertEqual(rt.state, .waiting(flow: f, step: 0))
        XCTAssertEqual(rt.handle(.targetTapped("a")), [.present(step: 1, s2)])
        XCTAssertEqual(rt.state, .waiting(flow: f, step: 1))
        XCTAssertEqual(rt.handle(.targetsChanged(["a", "b", "c"])), [.dismiss])
        XCTAssertEqual(rt.state, .completed(flowID: "calendar.create_event"))
    }

    func testTargetVisiblePasses() {
        var rt = GuideRuntime()
        let f = flow([step("a", .targetVisible("x"))])
        _ = rt.handle(.start(f, targets: ["a"], facts: [:]))
        XCTAssertEqual(rt.handle(.targetsChanged(["a", "x"])), [.dismiss])
        XCTAssertEqual(rt.state, .completed(flowID: f.id))
    }

    func testFactEqualsPasses() {
        var rt = GuideRuntime()
        let f = flow([step("a", .factEquals(key: "k", value: .bool(true)))])
        _ = rt.handle(.start(f, targets: ["a"], facts: ["k": .bool(false)]))
        XCTAssertEqual(rt.handle(.factsChanged(["k": .bool(false)])), [])
        XCTAssertEqual(rt.handle(.factsChanged(["k": .bool(true)])), [.dismiss])
        XCTAssertEqual(rt.state, .completed(flowID: f.id))
    }

    func testFactIncreasedUsesBaseline() {
        var rt = GuideRuntime()
        let f = flow([step("a", .factIncreased(key: "n", by: 1))])
        _ = rt.handle(.start(f, targets: ["a"], facts: ["n": .int(3)]))
        XCTAssertEqual(rt.handle(.factsChanged(["n": .int(3)])), [])
        XCTAssertEqual(rt.state, .waiting(flow: f, step: 0))
        XCTAssertEqual(rt.handle(.factsChanged(["n": .int(4)])), [.dismiss])
        XCTAssertEqual(rt.state, .completed(flowID: f.id))
    }

    func testTappedPassesOnlyForCurrentTarget() {
        var rt = GuideRuntime()
        let f = flow([step("a", .tapped)])
        _ = rt.handle(.start(f, targets: ["a", "b"], facts: [:]))
        XCTAssertEqual(rt.handle(.targetTapped("b")), [])
        XCTAssertEqual(rt.state, .waiting(flow: f, step: 0))
        XCTAssertEqual(rt.handle(.targetTapped("a")), [.dismiss])
    }

    func testAlreadyTrueCheckWaitsForTap() {
        var rt = GuideRuntime()
        let f = flow([step("a", .targetVisible("x"))])
        XCTAssertEqual(rt.handle(.start(f, targets: ["a", "x"], facts: [:])), [.present(step: 0, f.steps[0])])
        XCTAssertEqual(rt.handle(.targetsChanged(["a", "x"])), [])
        XCTAssertEqual(rt.state, .waiting(flow: f, step: 0))
        XCTAssertEqual(rt.handle(.targetTapped("a")), [.dismiss])
    }

    func testIdleUserNeverTimesOut() {
        var rt = GuideRuntime()
        let f = flow([step("a", .factEquals(key: "k", value: .int(1)))])
        let effects = rt.handle(.start(f, targets: ["a"], facts: [:]))
        XCTAssertEqual(effects, [.present(step: 0, f.steps[0])])
        XCTAssertEqual(rt.handle(.timeout(token: 1)), [])
        XCTAssertEqual(rt.state, .waiting(flow: f, step: 0))
    }

    func testMissingTargetFailsOnTimeout() {
        var rt = GuideRuntime()
        let f = flow([step("x", .tapped)])
        XCTAssertEqual(rt.handle(.start(f, targets: [], facts: [:])),
                       [.present(step: 0, f.steps[0]), .scheduleTimeout(token: 1)])
        XCTAssertEqual(rt.handle(.timeout(token: 1)), [.dismiss])
        XCTAssertEqual(rt.state, .failed(.targetNotFound(flowID: f.id, step: 0, target: "x")))
    }

    func testTapThenNoChangeFailsCheckNotPassed() {
        var rt = GuideRuntime()
        let f = flow([step("a", .factEquals(key: "k", value: .int(1)))])
        _ = rt.handle(.start(f, targets: ["a"], facts: ["k": .int(0)]))
        XCTAssertEqual(rt.handle(.targetTapped("a")), [.scheduleTimeout(token: 1)])
        XCTAssertEqual(rt.handle(.timeout(token: 1)), [.dismiss])
        XCTAssertEqual(rt.state, .failed(.checkNotPassed(flowID: f.id, step: 0)))
    }

    func testMissingFactFailsFactNeverReported() {
        var rt = GuideRuntime()
        let f = flow([step("a", .factEquals(key: "k", value: .int(1)))])
        _ = rt.handle(.start(f, targets: ["a"], facts: [:]))
        _ = rt.handle(.targetTapped("a"))
        _ = rt.handle(.timeout(token: 1))
        XCTAssertEqual(rt.state, .failed(.factNeverReported(flowID: f.id, step: 0, key: "k")))
    }

    func testWrongFactTypeFails() {
        var rt = GuideRuntime()
        let f = flow([step("a", .factIncreased(key: "n", by: 1))])
        XCTAssertEqual(rt.handle(.start(f, targets: ["a"], facts: ["n": .string("x")])), [.dismiss])
        XCTAssertEqual(rt.state, .failed(.wrongFactType(flowID: f.id, step: 0, key: "n")))

        var rt2 = GuideRuntime()
        let g = flow([step("a", .factEquals(key: "k", value: .int(1)))])
        _ = rt2.handle(.start(g, targets: ["a"], facts: [:]))
        XCTAssertEqual(rt2.handle(.factsChanged(["k": .string("1")])), [.dismiss])
        XCTAssertEqual(rt2.state, .failed(.wrongFactType(flowID: g.id, step: 0, key: "k")))
    }

    func testStaleTimeoutIgnored() {
        var rt2 = GuideRuntime()
        let g = flow([step("a", .factEquals(key: "k", value: .int(1)))])
        _ = rt2.handle(.start(g, targets: [], facts: [:]))   // token 1
        _ = rt2.handle(.targetTapped("a"))                   // token 2
        XCTAssertEqual(rt2.handle(.timeout(token: 1)), [])
        XCTAssertEqual(rt2.state, .waiting(flow: g, step: 0))
    }

    func testSecondStartIgnored() {
        var rt = GuideRuntime()
        let f = flow([step("a", .tapped)])
        _ = rt.handle(.start(f, targets: ["a"], facts: [:]))
        let other = flow([step("b", .tapped)], id: "other")
        XCTAssertEqual(rt.handle(.start(other, targets: ["b"], facts: [:])), [])
        XCTAssertEqual(rt.state, .waiting(flow: f, step: 0))
    }

    func testCancelDismisses() {
        var rt = GuideRuntime()
        _ = rt.handle(.start(flow([step("a", .tapped)]), targets: ["a"], facts: [:]))
        XCTAssertEqual(rt.handle(.cancel), [.dismiss])
        XCTAssertEqual(rt.state, .idle)
    }

    func testFailureDescriptionNamesFlowStepAndTarget() {
        XCTAssertEqual(GuideFailure.targetNotFound(flowID: "calendar.create_event", step: 0, target: "x").description,
                       "`calendar.create_event` step 1: target `x` not found")
        XCTAssertEqual(GuideFailure.factNeverReported(flowID: "f", step: 1, key: "k").description,
                       "`f` step 2: fact `k` was never reported")
        XCTAssertEqual(GuideFailure.wrongFactType(flowID: "f", step: 1, key: "k").description,
                       "`f` step 2: fact `k` has the wrong type for this check")
        XCTAssertEqual(GuideFailure.checkNotPassed(flowID: "f", step: 2).description,
                       "`f` step 3: completion check did not pass")
    }
}
