import SwiftUI

/// Collects every tagged view's bounds, keyed by guide ID, up the view tree to the host.
///
/// Several views may share an ID (rows in a list), so each key maps to an array of anchors rather than one.
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
            // Publishes the bounds up to GuideHost; the accessibility ID lets UI tests find the same view.
            .anchorPreference(key: GuideTargetKey.self, value: .bounds) { [id: [$0]] }
            .accessibilityIdentifier(id)
            .simultaneousGesture(TapGesture().onEnded { controller?.reportTap(id) })
    }
}

extension View {
    /// Marks this view as a walkthrough target. `nil` leaves the view unchanged.
    /// Marks this view as a walkthrough target.
    ///
    /// Use it on the controls a flow points at. It records the view's frame for the spotlight, sets the view's
    /// accessibility identifier to `id` so UI tests can find it, and reports taps to the controller. Taps still
    /// reach the view's own gesture handlers.
    ///
    /// ```swift
    /// Button("Save") { save() }
    ///     .guideTarget("calendar.save")
    /// ```
    ///
    /// Shared components usually take an optional ID and forward it here, which is why `nil` is accepted.
    ///
    /// - Parameters:
    ///   - id: A dotted lowercase ID such as `calendar.save`. `nil` leaves the view unchanged.
    ///
    /// Hands the frame to `guideHost`, which feeds `GuideController.updateTargets`; taps go to `reportTap`.
    /// Design: docs/tdd/04-controller-and-modifiers.md
    @ViewBuilder
    public func guideTarget(_ id: String?) -> some View {
        if let id {
            modifier(GuideTargetModifier(id: id))
        } else {
            self
        }
    }
}
