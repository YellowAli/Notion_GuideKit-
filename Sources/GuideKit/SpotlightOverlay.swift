import SwiftUI

/// Dims the screen around the current step's target and blocks every touch outside the hole.
///
/// Must be laid out in the same coordinate space as the frames passed to
/// `GuideController.updateTargets`. `safeArea` keeps the tooltip clear of the notch and home indicator.
struct SpotlightOverlay: View {
    let controller: GuideController
    var safeArea = EdgeInsets()

    private static let holePadding: CGFloat = 6
    private static let holeCornerRadius: CGFloat = 10
    private static let tooltipGap: CGFloat = 12
    private static let tooltipMaxWidth: CGFloat = 360
    private static let screenMargin: CGFloat = 16

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var nudges = 0

    var body: some View {
        GeometryReader { proxy in
            if let presentation = controller.presentation {
                let hole = presentation.frame?.insetBy(dx: -Self.holePadding, dy: -Self.holePadding)
                dim(hole: hole, size: proxy.size)
                if let hole { ring(around: hole) }
                tooltip(presentation, hole: hole, size: proxy.size)
            }
        }
        .onChange(of: controller.presentation?.stepIndex, initial: true) { _, _ in
            guard let presentation = controller.presentation else { return }
            AccessibilityNotification.Announcement("\(stepLabel(presentation)). \(presentation.say)").post()
        }
    }

    private func stepLabel(_ presentation: GuidePresentation) -> String {
        "Step \(presentation.stepIndex + 1) of \(presentation.stepCount)"
    }

    // MARK: - Dim and ring

    private func dim(hole: CGRect?, size: CGSize) -> some View {
        var path = Path(CGRect(origin: .zero, size: size))
        if let hole {
            path.addRoundedRect(in: hole, cornerSize: CGSize(width: Self.holeCornerRadius, height: Self.holeCornerRadius))
        }
        return path
            .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))
            .contentShape(path, eoFill: true)
            .onTapGesture { nudges += 1 }
            .accessibilityIdentifier("guide.dim")
            .accessibilityHidden(true)
    }

    private func ring(around hole: CGRect) -> some View {
        RoundedRectangle(cornerRadius: Self.holeCornerRadius)
            .stroke(Color.accentColor, lineWidth: 2)
            .frame(width: hole.width, height: hole.height)
            .phaseAnimator(reduceMotion ? [false] : [false, true]) { view, expanded in
                view
                    .scaleEffect(expanded ? 1.08 : 1)
                    .opacity(expanded ? 0.4 : 1)
            } animation: { _ in
                .easeInOut(duration: 0.8)
            }
            .position(x: hole.midX, y: hole.midY)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // MARK: - Tooltip

    private func tooltip(_ presentation: GuidePresentation, hole: CGRect?, size: CGSize) -> some View {
        let top = safeArea.top + Self.screenMargin
        let bottom = size.height - safeArea.bottom - Self.screenMargin
        var region = top...max(top, bottom)
        var alignment = Alignment.center

        if let hole {
            let roomAbove = hole.minY - Self.tooltipGap - top
            let roomBelow = bottom - (hole.maxY + Self.tooltipGap)
            if roomBelow >= roomAbove {
                region = min(bottom, max(top, hole.maxY + Self.tooltipGap))...bottom
                alignment = .top
            } else {
                region = top...max(top, min(bottom, hole.minY - Self.tooltipGap))
                alignment = .bottom
            }
        }

        return card(presentation)
            .frame(maxWidth: Self.tooltipMaxWidth)
            .padding(.horizontal, Self.screenMargin)
            .frame(width: size.width, height: region.upperBound - region.lowerBound, alignment: alignment)
            .position(x: size.width / 2, y: (region.lowerBound + region.upperBound) / 2)
    }

    private func card(_ presentation: GuidePresentation) -> some View {
        let reduceMotion = reduceMotion
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(stepLabel(presentation))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Exit") { controller.cancel() }
                    .buttonStyle(.plain)
                    .font(.footnote.weight(.semibold))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("guide.exit")
            }
            Text(presentation.say)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
        .padding(.top, 2)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("guide.tooltip")
        .keyframeAnimator(initialValue: CGFloat(0), trigger: nudges) { view, shake in
            // Reduce Motion replaces the shake with a brief fade.
            view
                .offset(x: reduceMotion ? 0 : shake)
                .opacity(reduceMotion ? 1 - abs(shake) / 16 : 1)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(-8, duration: 0.06)
                LinearKeyframe(8, duration: 0.12)
                LinearKeyframe(-4, duration: 0.1)
                LinearKeyframe(0, duration: 0.06)
            }
        }
    }
}
