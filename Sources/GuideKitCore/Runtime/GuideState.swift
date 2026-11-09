import Foundation

/// Where the runtime is in a walkthrough.
public enum GuideState: Equatable {
    /// No walkthrough is running.
    case idle
    /// The person is on step `step` (zero-based) of `flow`.
    case waiting(flow: Flow, step: Int)
    /// The last step finished.
    case completed(flowID: String)
    /// The walkthrough stopped; see ``GuideFailure``.
    case failed(GuideFailure)
}
