import SwiftUI

/// Dims the screen around the current step's target and blocks every touch outside the hole.
///
/// The hole is the target's frame plus a little padding; taps inside it reach the real control, so the person
/// performs the real action. Taps on the dim shake the card instead of doing anything. The tooltip's Exit button
/// cancels the walkthrough, and each new step is announced to VoiceOver.
///
/// Must be laid out in the same coordinate space as the frames passed to
/// `GuideController.updateTargets`. `safeArea` keeps the tooltip clear of the notch and home indicator.
/// `GuideHost` creates it; apps do not use it directly.
///
/// Reads `GuideController.presentation`; places the card with `TooltipPlacement`.
/// Design: docs/tdd/05-spotlight-and-menu.md
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
        let placement = TooltipPlacement.compute(hole: hole, size: size, safeArea: safeArea,
                                                 gap: Self.tooltipGap, margin: Self.screenMargin)

        return card(presentation)
            .frame(maxWidth: Self.tooltipMaxWidth)
            .padding(.horizontal, Self.screenMargin)
            .frame(width: size.width, height: placement.maxY - placement.minY, alignment: placement.alignment)
            .position(x: size.width / 2, y: (placement.minY + placement.maxY) / 2)
    }

    private func message(_ presentation: GuidePresentation) -> some View {
        Text(presentation.say)
            .font(.body)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func card(_ presentation: GuidePresentation) -> some View {
        let reduceMotion = reduceMotion
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(stepLabel(presentation))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Button { controller.cancel() } label: {
                    Text("Exit")
                        .font(.footnote.weight(.semibold))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("guide.exit")
            }
            .layoutPriority(1)
            // The message scrolls only when it can't fit, so the Exit row is never pushed out.
            ViewThatFits(in: .vertical) {
                message(presentation)
                ScrollView { message(presentation) }
            }
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

/// Where the tooltip card may sit: always inside the safe screen area, and never so short that Exit is lost.
///
/// This is pure geometry, kept apart from `SpotlightOverlay` so it can be unit-tested. With no hole
/// (the target is not on screen) the card may use the whole safe area.
///
/// Design: docs/tdd/05-spotlight-and-menu.md
struct TooltipPlacement: Equatable {
    /// Enough for the Exit row plus some message, even at large text sizes.
    static let minimumHeight: CGFloat = 160

    var minY: CGFloat
    var maxY: CGFloat
    var alignment: Alignment

    /// Picks the side of `hole` with more room. When that side is too short, the region grows
    /// over the hole, because a reachable Exit matters more than an unobstructed target.
    static func compute(hole: CGRect?, size: CGSize, safeArea: EdgeInsets,
                        gap: CGFloat, margin: CGFloat) -> TooltipPlacement {
        let top = safeArea.top + margin
        let bottom = max(top, size.height - safeArea.bottom - margin)
        guard let hole else { return TooltipPlacement(minY: top, maxY: bottom, alignment: .center) }

        let minimum = min(minimumHeight, bottom - top)
        let belowStart = hole.maxY + gap
        let aboveEnd = hole.minY - gap
        if bottom - belowStart >= aboveEnd - top {
            return TooltipPlacement(minY: max(top, min(belowStart, bottom - minimum)), maxY: bottom, alignment: .top)
        }
        return TooltipPlacement(minY: top, maxY: min(bottom, max(aboveEnd, top + minimum)), alignment: .bottom)
    }
}
