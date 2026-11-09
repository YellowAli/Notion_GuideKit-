import Foundation

/// A guided walkthrough: an ordered list of steps that the runtime checks against the live UI.
///
/// Flows are plain data. Teams usually write them as JSON files in their feature package and load them
/// through `GuideFeature`, but they can also be built in code.
///
/// ```json
/// {
///   "id": "calendar.create_event",
///   "title": "Create an event",
///   "steps": [
///     { "target": "calendar.new_event", "say": "Tap New event.", "completeWhen": { "targetVisible": "calendar.save" } },
///     { "target": "calendar.save", "say": "Tap Save to add the event.", "completeWhen": { "fact": "calendar.event.count", "increasedBy": 1 } }
///   ]
/// }
/// ```
///
/// Use ``FlowValidator`` to check a flow before shipping it. `GuideFeature` does this for you when it loads files.
///
/// Flow, `Step`, `Check` and `FactValue` are the data every other layer reads: decoded from JSON,
/// checked by `FlowValidator`, executed by `GuideRuntime`.
/// Design: docs/tdd/01-flow-model.md
public struct Flow: Codable, Equatable, Sendable {
    /// A dotted, lowercase identifier such as `calendar.create_event`. It must start with the owning feature's namespace and be unique across the app.
    public var id: String
    /// The human-readable name shown in the walkthrough menu, after "Walk me through:".
    public var title: String
    /// The steps in the order the person performs them. A flow with no steps is invalid.
    public var steps: [Step]

    /// Creates a flow.
    ///
    /// - Parameters:
    ///   - id: The dotted, namespaced identifier.
    ///   - title: The name shown in the menu.
    ///   - steps: The ordered steps.
    public init(id: String, title: String, steps: [Step]) {
        self.id = id
        self.title = title
        self.steps = steps
    }
}
