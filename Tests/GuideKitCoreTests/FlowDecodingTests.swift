import XCTest
@testable import GuideKitCore

final class FlowDecodingTests: XCTestCase {
    private func decode(_ json: String) throws -> Check {
        try JSONDecoder().decode(Check.self, from: Data(json.utf8))
    }

    func testDecodesAllFourChecks() throws {
        XCTAssertEqual(try decode(#"{"targetVisible":"a.b"}"#), .targetVisible("a.b"))
        XCTAssertEqual(try decode(#"{"fact":"a.b","equals":true}"#), .factEquals(key: "a.b", value: .bool(true)))
        XCTAssertEqual(try decode(#"{"fact":"a.b","equals":3}"#), .factEquals(key: "a.b", value: .int(3)))
        XCTAssertEqual(try decode(#"{"fact":"a.b","equals":"x"}"#), .factEquals(key: "a.b", value: .string("x")))
        XCTAssertEqual(try decode(#"{"fact":"a.b","increasedBy":1}"#), .factIncreased(key: "a.b", by: 1))
        XCTAssertEqual(try decode(#"{"tapped":true}"#), .tapped)
    }

    func testPickDefaultsToFirst() throws {
        let json = #"{"target":"t","say":"s","completeWhen":{"tapped":true}}"#
        let step = try JSONDecoder().decode(Step.self, from: Data(json.utf8))
        XCTAssertEqual(step.pick, .first)
        let last = #"{"target":"t","say":"s","pick":"last","completeWhen":{"tapped":true}}"#
        XCTAssertEqual(try JSONDecoder().decode(Step.self, from: Data(last.utf8)).pick, .last)
    }

    func testUnknownCheckThrows() {
        XCTAssertThrowsError(try decode(#"{"nope":1}"#))
        XCTAssertThrowsError(try decode(#"{"tapped":false}"#))
    }

    func testRoundTripsFlow() throws {
        let flow = Flow(id: "f", title: "T", steps: [
            Step(target: "a", say: "one", pick: .last, completeWhen: .targetVisible("b")),
            Step(target: "c", say: "two", completeWhen: .factEquals(key: "k", value: .string("v"))),
            Step(target: "d", say: "three", completeWhen: .factIncreased(key: "n", by: 2)),
            Step(target: "e", say: "four", completeWhen: .tapped),
        ])
        let data = try JSONEncoder().encode(flow)
        XCTAssertEqual(try JSONDecoder().decode(Flow.self, from: data), flow)
    }
}
