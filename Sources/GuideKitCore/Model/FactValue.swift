import Foundation

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
