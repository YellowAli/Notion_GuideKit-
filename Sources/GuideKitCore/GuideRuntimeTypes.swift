import Foundation

/// An input to ``GuideRuntime/handle(_:)``. The UI layer translates what happens on screen into these events.
///
/// Design: docs/tdd/03-runtime.md
public enum GuideEvent {
    /// Begin a flow, given the targets currently on screen and the facts already reported. Ignored while a flow is running.
    case start(Flow, targets: Set<String>, facts: [String: FactValue])
    /// The complete set of reported facts changed.
    case factsChanged([String: FactValue])
    /// The complete set of on-screen target IDs changed.
    case targetsChanged(Set<String>)
    /// The person tapped a target. Only a tap on the current step's target counts.
    case targetTapped(String)
    /// A timer scheduled by ``GuideEffect/scheduleTimeout(token:)`` fired. Stale tokens are ignored.
    case timeout(token: Int)
    /// The person exited the walkthrough.
    case cancel
}

/// Work the runtime asks its host to do. The runtime itself never touches UI or timers.
///
/// Design: docs/tdd/03-runtime.md
public enum GuideEffect: Equatable {
    /// Show `Step` as step number `step` (zero-based).
    case present(step: Int, Step)
    /// Hide the walkthrough UI and cancel any outstanding timers.
    case dismiss
    /// Start one timer. When it fires, send ``GuideEvent/timeout(token:)`` with the same `token`.
    case scheduleTimeout(token: Int)
}

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
