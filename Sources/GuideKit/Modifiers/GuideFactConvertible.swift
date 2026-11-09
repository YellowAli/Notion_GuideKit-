import GuideKitCore

public protocol GuideFactConvertible {
    var guideFactValue: FactValue { get }
}

extension Bool: GuideFactConvertible { public var guideFactValue: FactValue { .bool(self) } }
extension Int: GuideFactConvertible { public var guideFactValue: FactValue { .int(self) } }
extension String: GuideFactConvertible { public var guideFactValue: FactValue { .string(self) } }
