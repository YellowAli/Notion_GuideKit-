import Foundation

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
