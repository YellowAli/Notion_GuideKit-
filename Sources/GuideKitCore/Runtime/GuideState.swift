import Foundation

public enum GuideState: Equatable {
    case idle
    case waiting(flow: Flow, step: Int)
    case completed(flowID: String)
    case failed(GuideFailure)
}
