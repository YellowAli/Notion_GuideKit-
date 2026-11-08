import SwiftUI

private struct GuideHostModifier: ViewModifier {
    let controller: GuideController

    func body(content: Content) -> some View {
        content
            .environment(\.guideController, controller)
            .overlayPreferenceValue(GuideTargetKey.self) { anchors in
                GeometryReader { outer in
                    ZStack {
                        GuideMenu(controller: controller)
                        // Frames resolve in this reader, so the overlay inside it shares their coordinate space.
                        // It ignores the container safe area so the dim reaches the screen edges.
                        GeometryReader { proxy in
                            let frames = anchors.mapValues { $0.map { proxy[$0] } }
                            SpotlightOverlay(controller: controller, safeArea: outer.safeAreaInsets)
                                .onChange(of: frames, initial: true) { _, new in
                                    controller.updateTargets(new)
                                }
                        }
                        .ignoresSafeArea(.container)
                    }
                }
            }
    }
}

extension View {
    /// Collects guide targets beneath this view, feeds their frames to `controller`, and draws the walkthrough UI.
    public func guideHost(_ controller: GuideController) -> some View {
        modifier(GuideHostModifier(controller: controller))
    }
}
