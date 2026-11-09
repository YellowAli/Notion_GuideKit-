import Foundation
import CoreGraphics
import GuideKitCore

public struct GuideStatus: Codable, Equatable {
    public var state: String
    public var flowID: String?
    public var target: String?
    public var stepIndex: Int?
    public var pick: Pick?
    public var failure: String?
    public var allFlowIDs: [String]

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
