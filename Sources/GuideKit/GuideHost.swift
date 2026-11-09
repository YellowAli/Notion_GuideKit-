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

private enum GuideTestEnvironment {
    static let exposesStatus = ProcessInfo.processInfo.environment["GUIDEKIT_TEST"] == "1"
    static let autostartFlowID = ProcessInfo.processInfo.environment["GUIDEKIT_TEST_FLOW"]
}

/// Publishes `controller.status` as JSON so UI tests can follow a walkthrough from another process.
private struct GuideStatusElement: View {
    let controller: GuideController

    private var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(controller.status) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityIdentifier("guidekit.status")
            .accessibilityValue(json)
    }
}

extension View {
    /// Collects guide targets beneath this view, feeds their frames to `controller`, and draws the walkthrough UI.
    /// `launcherBottomClearance` is the gap between the safe area's bottom edge and the `?` button.
    /// The default clears a typical bottom tab bar; raise it when the button would cover other bottom controls.
    public func guideHost(_ controller: GuideController,
                          launcherBottomClearance: CGFloat = 84) -> some View {
        modifier(GuideHostModifier(controller: controller, launcherBottomClearance: launcherBottomClearance))
    }
}
