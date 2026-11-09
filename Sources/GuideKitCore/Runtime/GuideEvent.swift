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
