import SwiftUI

/// Shared look: an off-white page, system sans-serif, hairline dividers, small gray icons.
public enum Theme {
    /// The page background, an off-white.
    public static let page = Color(red: 0.992, green: 0.992, blue: 0.988)
    /// Primary text and icon color.
    public static let ink = Color(red: 0.216, green: 0.208, blue: 0.192)
    /// Secondary text, such as captions.
    public static let secondary = Color(red: 0.467, green: 0.451, blue: 0.431)
    /// Muted icon color.
    public static let icon = Color(red: 0.58, green: 0.565, blue: 0.545)
    /// The color of divider rules.
    public static let hairline = Color.black.opacity(0.09)
    /// The background of a pressed button.
    public static let pressed = Color.black.opacity(0.05)

    /// The standard horizontal content margin, in points.
    public static let margin: CGFloat = 20
    /// The standard corner radius, in points.
    public static let radius: CGFloat = 6
}

/// A one-point-or-thinner rule that stays crisp at every scale.
public struct Hairline: View {
    /// Creates a hairline.
    public init() {}

    /// The rule, half a point tall.
    public var body: some View {
        Theme.hairline.frame(height: 0.5)
    }
}
