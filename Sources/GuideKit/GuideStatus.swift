import Foundation
import CoreGraphics
import GuideKitCore
import SwiftUI

/// A snapshot of walkthrough progress that is `Codable` so another process can read it.
///
/// When the app runs with the `GUIDEKIT_TEST` environment variable set to `1`, the host publishes this value as JSON on an
/// accessibility element with the identifier `guidekit.status`. `FlowTestDriver` reads it from the UI test process.
///
/// Design: docs/tdd/07-test-driver.md
public struct GuideStatus: Codable, Equatable {
    /// One of `idle`, `waiting`, `completed` or `failed`.
    public var state: String
    /// The running, completed or failed flow's ID. nil when idle.
    public var flowID: String?
    /// While waiting, the guide ID of the current step's target.
    public var target: String?
    /// While waiting, the zero-based index of the current step.
    public var stepIndex: Int?
    /// While waiting, which of several matching views the current step highlights.
    public var pick: Pick?
    /// When failed, the ``GuideFailure`` description.
    public var failure: String?
    /// The IDs of every registered flow, in registration order.
    public var allFlowIDs: [String]

    /// Creates a status snapshot.
    ///
    /// - Parameters:
    ///   - state: `idle`, `waiting`, `completed` or `failed`.
    ///   - flowID: The related flow, if any.
    ///   - target: The current step's target, if waiting.
    ///   - stepIndex: The current step index, if waiting.
    ///   - pick: The current step's pick, if waiting.
    ///   - failure: The failure message, if failed.
    ///   - allFlowIDs: Every registered flow ID.
    public init(state: String, flowID: String? = nil, target: String? = nil, stepIndex: Int? = nil,
                pick: Pick? = nil, failure: String? = nil, allFlowIDs: [String]) {
        self.state = state
        self.flowID = flowID
        self.target = target
        self.stepIndex = stepIndex
        self.pick = pick
        self.failure = failure
        self.allFlowIDs = allFlowIDs
    }
}

/// Publishes `controller.status` as JSON so UI tests can follow a walkthrough from another process.
struct GuideStatusElement: View {
    let controller: GuideController

    private var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(controller.status) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityIdentifier("guidekit.status")
            .accessibilityValue(json)
    }
}

enum GuideTestEnvironment {
    static let exposesStatus = ProcessInfo.processInfo.environment["GUIDEKIT_TEST"] == "1"
    static let autostartFlowID = ProcessInfo.processInfo.environment["GUIDEKIT_TEST_FLOW"]
}
