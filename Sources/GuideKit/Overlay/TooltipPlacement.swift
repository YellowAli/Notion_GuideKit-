import SwiftUI

/// Where the tooltip card may sit: always inside the safe screen area, and never so short that Exit is lost.
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
