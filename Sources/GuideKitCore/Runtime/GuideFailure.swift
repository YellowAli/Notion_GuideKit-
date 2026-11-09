import Foundation

/// Why a walkthrough stopped. `step` is zero-based; `description` shows it one-based.
public enum GuideFailure: Error, Equatable, CustomStringConvertible {
    /// The step's target did not appear, or vanished before the person tapped it, and stayed absent for the timeout.
    case targetNotFound(flowID: String, step: Int, target: String)
    /// The person tapped the target but the fact the check depends on was never reported. Usually a missing `guideFact`.
    case factNeverReported(flowID: String, step: Int, key: String)
    /// The reported fact has a different type than the check needs, such as a string where `factIncreased` needs an integer.
    case wrongFactType(flowID: String, step: Int, key: String)
    /// The person tapped the target but the completion check still did not pass within the timeout.
    case checkNotPassed(flowID: String, step: Int)

    /// A one-line message naming the flow, the one-based step and the cause.
    public var description: String {
        switch self {
        case .targetNotFound(let id, let step, let target):
            return "`\(id)` step \(step + 1): target `\(target)` not found"
        case .factNeverReported(let id, let step, let key):
            return "`\(id)` step \(step + 1): fact `\(key)` was never reported"
        case .wrongFactType(let id, let step, let key):
            return "`\(id)` step \(step + 1): fact `\(key)` has the wrong type for this check"
        case .checkNotPassed(let id, let step):
            return "`\(id)` step \(step + 1): completion check did not pass"
        }
    }
}
