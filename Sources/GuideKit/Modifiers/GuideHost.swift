import SwiftUI

private struct GuideHostModifier: ViewModifier {
    let controller: GuideController
    let launcherBottomClearance: CGFloat

    @State private var didAutostart = false

    func body(content: Content) -> some View {
        content
            .environment(\.guideController, controller)
            .onAppear {
                guard !didAutostart, let flowID = GuideTestEnvironment.autostartFlowID else { return }
                didAutostart = true
                controller.start(flowID: flowID)
            }
            .overlayPreferenceValue(GuideTargetKey.self) { anchors in
                GeometryReader { outer in
                    ZStack {
                        if GuideTestEnvironment.exposesStatus { GuideStatusElement(controller: controller) }
                        GuideMenu(controller: controller, bottomClearance: launcherBottomClearance)
                        // Next: frames go to controller.updateTargets, which sends the runtime a targetsChanged event.
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
    /// `launcherBottomClearance` is the gap between the safe area's bottom edge and the `?` button.
    /// The default clears a typical bottom tab bar; raise it when the button would cover other bottom controls.
    /// Turns this view into the walkthrough host. Apply it once, at the root of the app's view hierarchy.
    ///
    /// The host provides the controller to descendants, collects the frames of every `guideTarget(_:)`
    /// beneath it, draws the spotlight and tooltip, and adds the floating `?` button that lists registered flows.
    /// Targets in any tab or sheet reach it as long as they are in the same view hierarchy.
    ///
    /// ```swift
    /// AppShell(shell: shell)
    ///     .guideHost(controller, launcherBottomClearance: 120)
    /// ```
    ///
    /// - Parameters:
    ///   - controller: The controller that owns the flows.
    ///   - launcherBottomClearance: The gap between the safe area's bottom edge and the `?` button. The default clears a typical bottom tab bar; raise it when the button would cover other bottom controls.
    /// - Returns: The view wrapped with the walkthrough UI.
    ///
    /// Collects targets from `guideTarget`, hands frames to the controller, and draws `SpotlightOverlay` and `GuideMenu`.
    /// Design: docs/tdd/04-controller-and-modifiers.md
    public func guideHost(_ controller: GuideController,
                          launcherBottomClearance: CGFloat = 84) -> some View {
        modifier(GuideHostModifier(controller: controller, launcherBottomClearance: launcherBottomClearance))
    }
}
