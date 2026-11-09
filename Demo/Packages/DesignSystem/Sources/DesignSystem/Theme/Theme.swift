import SwiftUI

/// Shared look: an off-white page, system sans-serif, hairline dividers, small gray icons.
public enum Theme {
    public static let page = Color(red: 0.992, green: 0.992, blue: 0.988)
    public static let ink = Color(red: 0.216, green: 0.208, blue: 0.192)
    public static let secondary = Color(red: 0.467, green: 0.451, blue: 0.431)
    public static let icon = Color(red: 0.58, green: 0.565, blue: 0.545)
    public static let hairline = Color.black.opacity(0.09)
    public static let pressed = Color.black.opacity(0.05)

    public static let margin: CGFloat = 20
    public static let radius: CGFloat = 6
}
