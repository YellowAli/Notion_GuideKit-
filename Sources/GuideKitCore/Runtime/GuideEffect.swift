import Foundation

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
