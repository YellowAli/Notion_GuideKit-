import Foundation

public enum GuideFailure: Error, Equatable, CustomStringConvertible {
    case targetNotFound(flowID: String, step: Int, target: String)
    case factNeverReported(flowID: String, step: Int, key: String)
    case wrongFactType(flowID: String, step: Int, key: String)
    case checkNotPassed(flowID: String, step: Int)

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
