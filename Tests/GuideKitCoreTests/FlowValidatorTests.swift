import XCTest
@testable import GuideKitCore

final class FlowValidatorTests: XCTestCase {
    private func step(target: String = "app.button", say: String = "Tap it",
                      check: Check = .tapped) -> Step {
        Step(target: target, say: say, completeWhen: check)
    }

    private func flow(id: String = "team.intro", steps: [Step]? = nil) -> Flow {
        Flow(id: id, title: "Intro", steps: steps ?? [step()])
    }

    func testValidFlowHasNoErrors() {
        XCTAssertEqual(FlowValidator.validate([flow()], namespace: "team"), [])
    }

    func testEmptyFlow() {
        XCTAssertEqual(FlowValidator.validate([flow(steps: [])], namespace: "team"),
                       [.emptyFlow(flowID: "team.intro")])
    }

    func testMalformedFlowID() {
        XCTAssertEqual(FlowValidator.validate([flow(id: "Team.Intro")], namespace: "team"),
                       [.malformedID("Team.Intro")])
    }

    func testMalformedTarget() {
        let f = flow(steps: [step(target: "button")])
        XCTAssertEqual(FlowValidator.validate([f], namespace: "team"), [.malformedID("button")])
    }

    func testMalformedTargetVisibleName() {
        let f = flow(steps: [step(check: .targetVisible("Bad"))])
        XCTAssertEqual(FlowValidator.validate([f], namespace: "team"), [.malformedID("Bad")])
    }

    func testMalformedFactKeys() {
        let f = flow(steps: [
            step(check: .factEquals(key: "nodots", value: .bool(true))),
            step(check: .factIncreased(key: "also bad", by: 1)),
        ])
        XCTAssertEqual(FlowValidator.validate([f], namespace: "team"),
                       [.malformedID("nodots"), .malformedID("also bad")])
    }

    func testDuplicateFlowID() {
        XCTAssertEqual(FlowValidator.validate([flow(), flow()], namespace: "team"),
                       [.duplicateFlowID("team.intro")])
    }

    func testOutsideNamespace() {
        XCTAssertEqual(FlowValidator.validate([flow(id: "other.intro")], namespace: "team"),
                       [.outsideNamespace(flowID: "other.intro", namespace: "team")])
    }

    func testOtherTeamsTargetsAndFactsAreAllowed() {
        let f = flow(steps: [step(target: "other.button",
                                  check: .factEquals(key: "other.done", value: .bool(true)))])
        XCTAssertEqual(FlowValidator.validate([f], namespace: "team"), [])
    }

    func testEmptyInstruction() {
        let f = flow(steps: [step(), step(say: "  \n ")])
        XCTAssertEqual(FlowValidator.validate([f], namespace: "team"),
                       [.emptyInstruction(flowID: "team.intro", step: 1)])
    }

    func testInvalidIncrement() {
        let f = flow(steps: [step(check: .factIncreased(key: "team.count", by: 0))])
        XCTAssertEqual(FlowValidator.validate([f], namespace: "team"),
                       [.invalidIncrement(flowID: "team.intro", step: 0)])
    }

    func testReportsAllErrorsNotJustFirst() {
        let f = flow(steps: [step(say: ""), step(check: .factIncreased(key: "team.count", by: -1))])
        XCTAssertEqual(FlowValidator.validate([f], namespace: "team"),
                       [.emptyInstruction(flowID: "team.intro", step: 0),
                        .invalidIncrement(flowID: "team.intro", step: 1)])
    }

    func testDescriptionsNameFlowAndUseOneBasedSteps() {
        let d = FlowValidationError.emptyInstruction(flowID: "team.intro", step: 0).description
        XCTAssertTrue(d.contains("team.intro"))
        XCTAssertTrue(d.contains("step 1"))
    }
}
