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

/// One instruction in a ``Flow``: highlight a target, say what to do, and wait until a check passes.
///
/// Design: docs/tdd/01-flow-model.md
public struct Step: Codable, Equatable, Sendable {
    /// The guide ID of the view to highlight, as passed to `guideTarget(_:)`. If the view is not on screen within a few seconds the walkthrough fails with ``GuideFailure/targetNotFound(flowID:step:target:)``.
    public var target: String
    /// The instruction shown in the tooltip. It must not be empty.
    public var say: String
    /// Which view to highlight when several views share ``target``, such as rows in a list. Defaults to ``Pick/first``.
    public var pick: Pick
    /// The condition that advances to the next step.
    public var completeWhen: Check

    /// Creates a step.
    ///
    /// - Parameters:
    ///   - target: The guide ID of the view to highlight.
    ///   - say: The instruction shown in the tooltip.
    ///   - pick: Which view to highlight when several share the ID. Defaults to the first.
    ///   - completeWhen: The condition that completes the step.
    public init(target: String, say: String, pick: Pick = .first, completeWhen: Check) {
        self.target = target
        self.say = say
        self.pick = pick
        self.completeWhen = completeWhen
    }

    private enum CodingKeys: String, CodingKey {
        case target, say, pick, completeWhen
    }

    /// Decodes a step from JSON. `pick` is optional and defaults to ``Pick/first``.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        target = try c.decode(String.self, forKey: .target)
        say = try c.decode(String.self, forKey: .say)
        pick = try c.decodeIfPresent(Pick.self, forKey: .pick) ?? .first
        completeWhen = try c.decode(Check.self, forKey: .completeWhen)
    }
}

/// Chooses among several views that share one guide ID, in layout (tree) order.
public enum Pick: String, Codable, Sendable {
    /// Highlight the first matching view.
    case first
    /// Highlight the last matching view.
    case last
}

/// The condition that completes a ``Step``.
///
/// A check is only evaluated once it is "armed": if it is already true when the step is shown, the person has
/// not done anything yet, so it waits until the state changes (see ``GuideRuntime``). In JSON each check has its own shape:
///
/// ```json
/// { "targetVisible": "calendar.save" }
/// { "fact": "editor.todo.count", "increasedBy": 1 }
/// { "fact": "settings.dark_mode", "equals": true }
/// { "tapped": true }
/// ```
///
/// `GuideRuntime` evaluates it; `FlowValidator` checks its IDs and increments.
/// Design: docs/tdd/01-flow-model.md
public enum Check: Codable, Equatable, Sendable {
    /// Completes when the view with this guide ID is on screen. Use it to detect that a menu or sheet opened.
    case targetVisible(String)
    /// Completes when the reported fact equals `value`.
    ///
    /// - Parameters:
    ///   - key: The fact key passed to `guideFact(_:value:)`.
    ///   - value: The value to wait for. A fact of a different type fails the walkthrough with ``GuideFailure/wrongFactType(flowID:step:key:)``.
    case factEquals(key: String, value: FactValue)
    /// Completes when an integer fact has grown by at least `by` since the step began.
    ///
    /// - Parameters:
    ///   - key: The fact key passed to `guideFact(_:value:)`.
    ///   - by: The minimum increase. It must be greater than zero.
    case factIncreased(key: String, by: Int)
    /// Completes when the person taps the step's target. Use it when the tap has no observable effect.
    case tapped

    private enum CodingKeys: String, CodingKey {
        case targetVisible, fact, equals, increasedBy, tapped
    }

    /// Decodes a check from one of the JSON shapes listed on ``Check``.
    ///
    /// - Throws: `DecodingError` if the shape is unknown or a `fact` has neither `equals` nor `increasedBy`.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let target = try c.decodeIfPresent(String.self, forKey: .targetVisible) {
            self = .targetVisible(target)
        } else if let key = try c.decodeIfPresent(String.self, forKey: .fact) {
            if c.contains(.equals) {
                self = .factEquals(key: key, value: try c.decode(FactValue.self, forKey: .equals))
            } else if c.contains(.increasedBy) {
                self = .factIncreased(key: key, by: try c.decode(Int.self, forKey: .increasedBy))
            } else {
                throw DecodingError.dataCorruptedError(forKey: .fact, in: c, debugDescription: "fact check needs equals or increasedBy")
            }
        } else if try c.decodeIfPresent(Bool.self, forKey: .tapped) == true {
            self = .tapped
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown check shape"))
        }
    }

    /// Encodes the check using the same JSON shape that ``init(from:)`` reads.
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .targetVisible(let t): try c.encode(t, forKey: .targetVisible)
        case .factEquals(let key, let value):
            try c.encode(key, forKey: .fact)
            try c.encode(value, forKey: .equals)
        case .factIncreased(let key, let by):
            try c.encode(key, forKey: .fact)
            try c.encode(by, forKey: .increasedBy)
        case .tapped: try c.encode(true, forKey: .tapped)
        }
    }
}

/// A value an app reports about itself so a step can check it, such as "the to-do count is 3".
///
/// In JSON a fact value is a bare `true`, number or string. A number that is not an integer fails to decode.
///
/// Design: docs/tdd/01-flow-model.md
public enum FactValue: Codable, Equatable, Sendable {
    /// A Boolean fact.
    case bool(Bool)
    /// An integer fact. Only integers can be used with ``Check/factIncreased(key:by:)``.
    case int(Int)
    /// A string fact.
    case string(String)

    /// Decodes a bool, an integer or a string, trying them in that order.
    ///
    /// - Throws: `DecodingError` if the value is none of those.
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let b = try? c.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? c.decode(Int.self) {
            self = .int(i)
        } else if let s = try? c.decode(String.self) {
            self = .string(s)
        } else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "FactValue must be a bool, int, or string")
        }
    }

    /// Encodes the value as a bare JSON bool, integer or string.
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .bool(let b): try c.encode(b)
        case .int(let i): try c.encode(i)
        case .string(let s): try c.encode(s)
        }
    }
}
