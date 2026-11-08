import SwiftUI

private struct GuideHostModifier: ViewModifier {
    let controller: GuideController

    func body(content: Content) -> some View {
        content
            .environment(\.guideController, controller)
            .backgroundPreferenceValue(GuideTargetKey.self) { anchors in
                GeometryReader { proxy in
                    let frames = anchors.mapValues { $0.map { proxy[$0] } }
                    Color.clear
                        .onChange(of: frames, initial: true) { _, new in
                            controller.updateTargets(new)
                        }
                }
                .allowsHitTesting(false)
            }
    }
}

extension View {
    /// Collects guide targets beneath this view and feeds their frames to `controller`.
    public func guideHost(_ controller: GuideController) -> some View {
        modifier(GuideHostModifier(controller: controller))
    }
}
