import SwiftUI
import GuideKitCore

public protocol GuideFactConvertible {
    var guideFactValue: FactValue { get }
}

extension Bool: GuideFactConvertible { public var guideFactValue: FactValue { .bool(self) } }
extension Int: GuideFactConvertible { public var guideFactValue: FactValue { .int(self) } }
extension String: GuideFactConvertible { public var guideFactValue: FactValue { .string(self) } }

private struct GuideControllerKey: EnvironmentKey {
    static let defaultValue: GuideController? = nil
}

extension EnvironmentValues {
    var guideController: GuideController? {
        get { self[GuideControllerKey.self] }
        set { self[GuideControllerKey.self] = newValue }
    }
}

private struct GuideFactModifier: ViewModifier {
    @Environment(\.guideController) private var controller
    let key: String
    let value: FactValue

    func body(content: Content) -> some View {
        content.onChange(of: value, initial: true) { _, new in
            controller?.reportFact(key, new)
        }
    }
}

extension View {
    /// Reports `value` under `key` on appear and whenever it changes.
    public func guideFact(_ key: String, value: some GuideFactConvertible) -> some View {
        modifier(GuideFactModifier(key: key, value: value.guideFactValue))
    }
}
