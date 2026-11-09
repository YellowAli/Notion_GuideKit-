import SwiftUI

/// The idle-state walkthrough UI: a floating button, the list of flows, and the failure card.
struct GuideMenu: View {
    let controller: GuideController

    /// Keeps the floating button above a typical bottom tab bar.
    private static let bottomClearance: CGFloat = 84
    private static let panelMaxWidth: CGFloat = 320

    @State private var isOpen = false
    @State private var failureDismissed = false

    private var isFlowActive: Bool { controller.presentation != nil }
    private var showsFailure: Bool { controller.status.state == "failed" && !failureDismissed }

    var body: some View {
        ZStack {
            if !isFlowActive { launcher }
            if showsFailure { failureCard }
        }
        .onChange(of: isFlowActive) { _, active in
            if active { isOpen = false }
        }
        .onChange(of: controller.status) { _, status in
            guard status.state == "failed" else { return }
            failureDismissed = false
            #if DEBUG
            print("GuideKit walkthrough failed: \(status.failure ?? "unknown reason")")
            #endif
        }
    }

    // MARK: - Launcher

    private var launcher: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if isOpen { panel }
            Button { isOpen.toggle() } label: {
                Image(systemName: isOpen ? "xmark" : "questionmark")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(.background, in: Circle())
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isOpen ? "Close walkthrough menu" : "Walk me through")
            .accessibilityIdentifier("guide.open_menu")
        }
        .padding(.trailing, 16)
        .padding(.bottom, Self.bottomClearance)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }

    private var panel: some View {
        VStack(spacing: 0) {
            ForEach(controller.flows, id: \.id) { flow in
                Button {
                    // A failed flow can fail again with an identical status, so reset here too.
                    failureDismissed = false
                    controller.start(flowID: flow.id)
                } label: {
                    Text("Walk me through: \(flow.title)")
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("guide.menu.\(flow.id)")
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: Self.panelMaxWidth)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
    }

    // MARK: - Failure

    private var failureCard: some View {
        VStack(spacing: 8) {
            Text("Couldn't continue this walkthrough")
                .multilineTextAlignment(.center)
            Button { failureDismissed = true } label: {
                Text("OK")
                    .font(.body.weight(.semibold))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("guide.failure_ok")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 6)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
        .padding(.horizontal, 32)
    }
}
