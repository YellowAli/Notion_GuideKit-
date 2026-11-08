import SwiftUI

struct GuideTargetKey: PreferenceKey {
    static let defaultValue: [String: [Anchor<CGRect>]] = [:]
    /// Appends in tree order so `pick: last` means last in layout order.
    static func reduce(value: inout [String: [Anchor<CGRect>]], nextValue: () -> [String: [Anchor<CGRect>]]) {
        value.merge(nextValue()) { $0 + $1 }
    }
}

private struct GuideTargetModifier: ViewModifier {
    @Environment(\.guideController) private var controller
    let id: String

    func body(content: Content) -> some View {
        content
            .anchorPreference(key: GuideTargetKey.self, value: .bounds) { [id: [$0]] }
            .accessibilityIdentifier(id)
            .simultaneousGesture(TapGesture().onEnded { controller?.reportTap(id) })
    }
}

extension View {
    /// Marks this view as a walkthrough target. `nil` leaves the view unchanged.
    @ViewBuilder
    public func guideTarget(_ id: String?) -> some View {
        if let id {
            modifier(GuideTargetModifier(id: id))
        } else {
            self
        }
    }
}
