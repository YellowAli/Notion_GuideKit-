import SwiftUI
import GuideKitCore

private struct GuideFactModifier: ViewModifier {
    @Environment(\.guideController) private var controller
    let key: String
    let value: FactValue

    func body(content: Content) -> some View {
        content
            .onAppear { controller?.reportFact(key, value) }
            .onChange(of: value) { _, new in controller?.reportFact(key, new) }
            .onDisappear { controller?.forgetFact(key) }
    }
}

extension View {
    /// Reports `value` under `key` on appear and whenever it changes, and forgets it on disappear.
    public func guideFact(_ key: String, value: some GuideFactConvertible) -> some View {
        modifier(GuideFactModifier(key: key, value: value.guideFactValue))
    }
}
