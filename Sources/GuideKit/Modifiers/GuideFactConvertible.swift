import GuideKitCore

/// A Swift value that can be reported as a fact with `guideFact(_:value:)`. `Bool`, `Int` and `String` conform.
public protocol GuideFactConvertible {
    /// The value as a ``FactValue``.
    var guideFactValue: FactValue { get }
}

extension Bool: GuideFactConvertible { public var guideFactValue: FactValue { .bool(self) } }
extension Int: GuideFactConvertible { public var guideFactValue: FactValue { .int(self) } }
extension String: GuideFactConvertible { public var guideFactValue: FactValue { .string(self) } }
