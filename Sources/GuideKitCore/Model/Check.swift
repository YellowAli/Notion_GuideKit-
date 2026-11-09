import Foundation

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
